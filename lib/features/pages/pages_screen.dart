import 'package:flutter/material.dart';

import '../../core/cfblog_api.dart';
import '../../core/formatters.dart';
import '../../core/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_chrome.dart';
import 'page_editor_screen.dart';

class PagesScreen extends StatefulWidget {
  const PagesScreen({super.key, required this.api});

  final CfblogApi api;

  @override
  State<PagesScreen> createState() => _PagesScreenState();
}

class _PagesScreenState extends State<PagesScreen> {
  bool _loading = true;
  String? _message;
  bool _isError = false;
  List<WpPost> _items = const [];
  int _page = 1;
  int _totalPages = 1;
  String _status = 'all';

  static const _statusOptions = <String>[
    'all',
    'publish',
    'draft',
    'pending',
    'private',
  ];

  @override
  void initState() {
    super.initState();
    _loadPages();
  }

  Future<void> _loadPages({bool refresh = false}) async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final result = await widget.api.listPages(
        page: _page,
        perPage: 12,
        status: _status,
        refresh: refresh,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _items = result.items;
        _totalPages = result.totalPages;
        _isError = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isError = true;
        _message = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _openEditor({int? pageId}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => PageEditorScreen(api: widget.api, pageId: pageId),
      ),
    );

    if (changed == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      await _loadPages();
      messenger.showSnackBar(
        SnackBar(content: Text(pageId == null ? '页面已创建' : '页面已更新')),
      );
    }
  }

  Future<void> _delete(WpPost page) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除页面'),
        content: Text('确定要删除「${stripHtml(page.title)}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await widget.api.deletePage(page.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _isError = false;
        _message = '页面已删除';
      });
      await _loadPages();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isError = true;
        _message = error.toString().replaceFirst('Exception: ', '');
      });
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
      onRefresh: () => _loadPages(refresh: true),
      child: ListView(
        padding: pageContentPadding(context),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton.icon(
                onPressed: () => _loadPages(refresh: true),
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
                icon: const Icon(Icons.note_add_outlined, size: 16),
                label: const Text('新建页面'),
              ),
            ],
          ),
          SizedBox(height: compact ? 12 : 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SelectionChipBar<String>(
              items: _statusOptions,
              value: _status,
              labelBuilder: (status) =>
                  status == 'all' ? '全部' : statusLabel(status),
              onSelected: (status) {
                setState(() {
                  _status = status;
                  _page = 1;
                });
                _loadPages();
              },
            ),
          ),
          SizedBox(height: compact ? 16 : 24),
          if (_message != null) ...[
            InfoBanner(message: _message!, isError: _isError),
            SizedBox(height: compact ? 12 : 16),
          ],
          if (_loading)
            const BootPanel(title: '正在加载页面', subtitle: '同步远程页面列表和当前筛选状态。')
          else if (_items.isEmpty)
            const EmptyStateCard(
              title: '当前没有页面',
              subtitle: '可以新建一个说明页、友链页或归档页。',
            )
          else
            ..._items.map(
              (page) => Padding(
                padding: EdgeInsets.only(bottom: compact ? 10 : 12),
                child: _PageCard(
                  page: page,
                  onEdit: () => _openEditor(pageId: page.id),
                  onDelete: () => _delete(page),
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
              _loadPages();
            },
            onNext: () {
              setState(() {
                _page += 1;
              });
              _loadPages();
            },
          ),
        ],
      ),
    );
  }
}

class _PageCard extends StatelessWidget {
  const _PageCard({
    required this.page,
    required this.onEdit,
    required this.onDelete,
  });

  final WpPost page;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactLayout(context);
    final theme = Theme.of(context);
    final title =
        stripHtml(page.title).isEmpty ? '未命名页面' : stripHtml(page.title);
    final timestamp = formatCompactDate(
      page.modified.isEmpty ? page.date : page.modified,
    );
    return SurfaceCard(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 20,
        vertical: compact ? 14 : 16,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (page.parent > 0) ...[
                      Icon(
                        Icons.subdirectory_arrow_right_rounded,
                        size: 14,
                        color: AppTheme.textMuted,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      statusLabel(page.status),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
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
            tooltip: '编辑页面',
            iconSize: 16,
            icon: const Icon(Icons.edit_outlined),
            style: IconButton.styleFrom(foregroundColor: AppTheme.textMuted),
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: '删除页面',
            iconSize: 16,
            icon: const Icon(Icons.delete_outline_rounded),
            style: IconButton.styleFrom(foregroundColor: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
