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
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  suffixIcon: IconButton(
                    onPressed: _submitSearch,
                    tooltip: '搜索',
                    iconSize: 18,
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
                        TextButton.icon(
                          onPressed: () => _loadPosts(refresh: true),
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('刷新'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.textMuted,
                            minimumSize: const Size(0, 36),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () => _openEditor(),
                          style: toolbarButtonStyle,
                          icon: const Icon(Icons.add_rounded, size: 16),
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
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: () => _loadPosts(refresh: true),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('刷新'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textMuted,
                      minimumSize: const Size(0, 40),
                    ),
                  ),
                  const SizedBox(width: 6),
                  FilledButton.icon(
                    onPressed: () => _openEditor(),
                    style: toolbarButtonStyle,
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('写文章'),
                  ),
                ],
              );
            },
          ),
          SizedBox(height: compact ? 12 : 16),
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
          SizedBox(height: compact ? 16 : 24),
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
                padding: EdgeInsets.only(bottom: compact ? 10 : 12),
                child: _PostCard(
                  post: post,
                  onEdit: () => _openEditor(postId: post.id),
                ),
              ),
            ),
          SizedBox(height: compact ? 4 : 8),
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
    final theme = Theme.of(context);
    final title = stripHtml(post.title).isEmpty ? '未命名文章' : stripHtml(post.title);
    final rawTime = post.modified.isEmpty ? post.date : post.modified;
    return SurfaceCard(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 20,
        vertical: compact ? 14 : 16,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useShortTime = compact || constraints.maxWidth < 640;
          final timestamp = formatCompactDate(rawTime, withYear: !useShortTime);

          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          statusLabel(post.status),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (post.sticky) ...[
                          const SizedBox(width: 10),
                          Icon(
                            Icons.push_pin_outlined,
                            size: 13,
                            color: AppTheme.textMuted,
                          ),
                        ],
                        const SizedBox(width: 10),
                        Text(
                          '·',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            timestamp,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.textMuted,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onEdit,
                tooltip: '编辑文章',
                iconSize: 16,
                icon: const Icon(Icons.edit_outlined),
                style: IconButton.styleFrom(
                  foregroundColor: AppTheme.textMuted,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

