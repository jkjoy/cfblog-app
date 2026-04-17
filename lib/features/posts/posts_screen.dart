import 'package:flutter/material.dart';

import '../../core/cfblog_api.dart';
import '../../core/formatters.dart';
import '../../core/models.dart';
import 'post_editor_screen.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_chrome.dart';

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
  int _total = 0;
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

  Future<void> _loadPosts() async {
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
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _posts = data.items;
        _total = data.total;
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
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => PostEditorScreen(api: widget.api, postId: postId),
      ),
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
    return RefreshIndicator(
      onRefresh: _loadPosts,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        children: [
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeading(
                  title: '文章列表',
                  subtitle: '筛选、审阅和编辑都已经合并进这条内容工作流里。',
                  trailing: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: _loadPosts,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('刷新'),
                      ),
                      FilledButton.icon(
                        onPressed: () => _openEditor(),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('写文章'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 720;
                    final searchField = TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _submitSearch(),
                      decoration: const InputDecoration(
                        labelText: '搜索文章',
                        hintText: '按标题、摘要或 slug 搜索',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    );

                    if (stacked) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          searchField,
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: _submitSearch,
                            child: const Text('搜索'),
                          ),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: searchField),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: _submitSearch,
                          child: const Text('搜索'),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                SelectionChipBar<String>(
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
                const SizedBox(height: 16),
                Text(
                  '当前共 $_total 篇，第 $_page / $_totalPages 页',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_error != null) ...[
            InfoBanner(message: _error!, isError: true),
            const SizedBox(height: 16),
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
                padding: const EdgeInsets.only(bottom: 14),
                child: _PostCard(
                  post: post,
                  onEdit: () => _openEditor(postId: post.id),
                ),
              ),
            ),
          const SizedBox(height: 4),
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
    final excerpt = stripHtml(post.excerpt);
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _Badge(
                label: statusLabel(post.status),
                background: AppTheme.accentSoft,
                foreground: AppTheme.accent,
              ),
              if (post.authorName.isNotEmpty)
                _Badge(
                  label: post.authorName,
                  background: const Color(0xFFE4EFEB),
                  foreground: AppTheme.success,
                ),
              _Badge(
                label: post.slug.isEmpty ? '未设置 slug' : post.slug,
                background: AppTheme.surfaceMuted,
                foreground: AppTheme.text,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            stripHtml(post.title).isEmpty ? '未命名文章' : stripHtml(post.title),
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 10),
          Text(
            excerpt.isEmpty ? '这篇文章还没有摘要，建议补一段列表导语。' : excerpt,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _InlineMeta(
                    icon: Icons.schedule_rounded,
                    label: formatDate(
                      post.modified.isEmpty ? post.date : post.modified,
                    ),
                  ),
                  _InlineMeta(
                    icon: Icons.mode_comment_outlined,
                    label: '${post.commentCount} 评论',
                  ),
                  _InlineMeta(
                    icon: Icons.visibility_outlined,
                    label: '${post.viewCount} 浏览',
                  ),
                ],
              ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (post.sticky)
                    _Badge(
                      label: '置顶',
                      background: const Color(0xFFE4EFEB),
                      foreground: AppTheme.success,
                    ),
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('编辑'),
                  ),
                ],
              ),
            ],
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

class _InlineMeta extends StatelessWidget {
  const _InlineMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppTheme.textMuted),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
