import 'package:flutter/material.dart';

import '../../core/cfblog_api.dart';
import '../../core/formatters.dart';
import '../../core/models.dart';
import 'post_editor_screen.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_chrome.dart';

Future<bool?> openPostEditorScreen(
  BuildContext context, {
  required CfblogApi api,
  int? postId,
}) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (context) => PostEditorScreen(api: api, postId: postId),
    ),
  );
}

class PostsScreen extends StatefulWidget {
  const PostsScreen({super.key, required this.api});

  final CfblogApi api;

  @override
  State<PostsScreen> createState() => _PostsScreenState();
}

class _PostsScreenState extends State<PostsScreen> {
  final TextEditingController _searchController = TextEditingController();

  bool _loading = true;
  String? _error;
  List<WpPost> _posts = const [];
  int _page = 1;
  int _totalPages = 1;
  String _search = '';
  String _status = 'publish';

  static const _statusOptions = <String>[
    'publish',
    'draft',
    'pending',
    'private',
  ];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts({bool refresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.api.listPosts(
        page: _page,
        perPage: 12,
        search: _search,
        status: _status,
        refresh: refresh,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _posts = data.items;
        _totalPages = data.totalPages;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _submitSearch() {
    setState(() {
      _search = _searchController.text.trim();
      _page = 1;
    });
    _loadPosts();
  }

  Future<void> _openEditor({int? postId}) async {
    final changed = await openPostEditorScreen(
      context,
      api: widget.api,
      postId: postId,
    );

    if (changed == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      await _loadPosts();
      messenger.showSnackBar(
        SnackBar(content: Text(postId == null ? '文章已创建' : '文章已更新')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = isCompactLayout(context);
    final toolbarButtonStyle = FilledButton.styleFrom(
      visualDensity: VisualDensity.compact,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 10 : 12,
      ),
    );

    return RefreshIndicator(
      onRefresh: () => _loadPosts(refresh: true),
      child: ListView(
        padding: pageContentPadding(context),
        children: [
          SurfaceCard(
            padding: EdgeInsets.all(compact ? 12 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 860;
                    final searchField = TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _submitSearch(),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: '搜索标题',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: IconButton(
                          onPressed: _submitSearch,
                          tooltip: '搜索',
                          icon: const Icon(Icons.arrow_forward_rounded),
                        ),
                      ),
                    );

                    if (stacked) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          searchField,
                          SizedBox(height: compact ? 10 : 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton.tonalIcon(
                                onPressed: () => _loadPosts(refresh: true),
                                style: toolbarButtonStyle,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('刷新'),
                              ),
                              FilledButton.icon(
                                onPressed: () => _openEditor(),
                                style: toolbarButtonStyle,
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('写文章'),
                              ),
                            ],
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: searchField),
                        const SizedBox(width: 10),
                        FilledButton.tonalIcon(
                          onPressed: () => _loadPosts(refresh: true),
                          style: toolbarButtonStyle,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('刷新'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: () => _openEditor(),
                          style: toolbarButtonStyle,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('写文章'),
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: compact ? 10 : 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SelectionChipBar<String>(
                    items: _statusOptions,
                    value: _status,
                    labelBuilder: statusLabel,
                    onSelected: (status) {
                      setState(() {
                        _status = status;
                        _page = 1;
                      });
                      _loadPosts();
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: compact ? 12 : 16),
          if (_error != null) ...[
            InfoBanner(message: _error!, isError: true),
            SizedBox(height: compact ? 12 : 16),
          ],
          if (_loading)
            const BootPanel(title: '正在加载文章', subtitle: '同步远程列表并刷新筛选结果。')
          else if (_posts.isEmpty)
            const EmptyStateCard(
              title: '当前筛选没有文章',
              subtitle: '可以调整状态或搜索条件后再次刷新。',
            )
          else
            ..._posts.map(
              (post) => Padding(
                padding: EdgeInsets.only(bottom: compact ? 10 : 14),
                child: _PostCard(
                  post: post,
                  onEdit: () => _openEditor(postId: post.id),
                ),
              ),
            ),
          SizedBox(height: compact ? 2 : 4),
          PaginationCard(
            currentPage: _page,
            totalPages: _totalPages,
            onPrevious: () {
              setState(() {
                _page -= 1;
              });
              _loadPosts();
            },
            onNext: () {
              setState(() {
                _page += 1;
              });
              _loadPosts();
            },
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.onEdit});

  final WpPost post;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactLayout(context);
    final title = stripHtml(post.title).isEmpty ? '未命名文章' : stripHtml(post.title);
    final timeLabel = _formatPostListTimestamp(
      post.modified.isEmpty ? post.date : post.modified,
      compact: compact,
    );
    return SurfaceCard(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 10 : 12,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useShortTime = compact || constraints.maxWidth < 640;
          final timestamp = useShortTime
              ? _formatPostListTimestamp(
                  post.modified.isEmpty ? post.date : post.modified,
                  compact: true,
                )
              : timeLabel;
          final timeWidth = useShortTime ? 74.0 : 124.0;

          return Row(
            children: [
              _Badge(
                label: statusLabel(post.status),
                background: AppTheme.accentSoft,
                foreground: AppTheme.accent,
              ),
              if (post.sticky) ...[
                const SizedBox(width: 8),
                Icon(Icons.push_pin_rounded, size: 16, color: AppTheme.success),
              ],
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: timeWidth,
                child: Text(
                  timestamp,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textMuted,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: onEdit,
                tooltip: '编辑文章',
                icon: const Icon(Icons.edit_rounded),
                visualDensity: VisualDensity.compact,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

String _formatPostListTimestamp(String raw, {required bool compact}) {
  if (raw.isEmpty) {
    return '未设置';
  }

  final date = DateTime.tryParse(raw)?.toLocal();
  if (date == null) {
    return raw;
  }

  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');

  if (compact) {
    return '$month-$day $hour:$minute';
  }

  return '${date.year}-$month-$day $hour:$minute';
}
