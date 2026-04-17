import 'package:flutter/material.dart';

import '../../core/cfblog_api.dart';
import '../../core/formatters.dart';
import '../../core/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_chrome.dart';

class MomentsScreen extends StatefulWidget {
  const MomentsScreen({super.key, required this.api});

  final CfblogApi api;

  @override
  State<MomentsScreen> createState() => _MomentsScreenState();
}

class _MomentsScreenState extends State<MomentsScreen> {
  bool _loading = true;
  String? _message;
  bool _isError = false;
  List<WpMoment> _items = const [];
  int _page = 1;
  int _total = 0;
  int _totalPages = 1;
  String _status = 'all';

  static const _statusOptions = <String>['all', 'publish', 'draft', 'private'];

  @override
  void initState() {
    super.initState();
    _loadMoments();
  }

  Future<void> _loadMoments() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final result = await widget.api.listMoments(
        page: _page,
        perPage: 12,
        status: _status,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _items = result.items;
        _total = result.total;
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

  Future<void> _openEditor({WpMoment? moment}) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MomentEditorSheet(api: widget.api, moment: moment),
    );

    if (changed == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      await _loadMoments();
      messenger.showSnackBar(
        SnackBar(content: Text(moment == null ? '动态已创建' : '动态已更新')),
      );
    }
  }

  Future<void> _delete(WpMoment moment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除动态'),
        content: Text('确定要删除这条动态吗？'),
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
      await widget.api.deleteMoment(moment.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _isError = false;
        _message = '动态已删除';
      });
      await _loadMoments();
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
    return RefreshIndicator(
      onRefresh: _loadMoments,
      child: ListView(
        padding: pageContentPadding(context),
        children: [
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeading(
                  title: '动态管理',
                  subtitle: '适合高频短内容和素材串联，强调发布速度和状态切换。',
                  trailing: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: _loadMoments,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('刷新'),
                      ),
                      FilledButton.icon(
                        onPressed: () => _openEditor(),
                        icon: const Icon(Icons.bolt_rounded),
                        label: const Text('发动态'),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: isCompactLayout(context) ? 12 : 18),
                SelectionChipBar<String>(
                  items: _statusOptions,
                  value: _status,
                  labelBuilder: (status) =>
                      status == 'all' ? '全部' : statusLabel(status),
                  onSelected: (status) {
                    setState(() {
                      _status = status;
                      _page = 1;
                    });
                    _loadMoments();
                  },
                ),
                SizedBox(height: isCompactLayout(context) ? 10 : 16),
                Text(
                  '当前共 $_total 条，第 $_page / $_totalPages 页',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
          SizedBox(height: isCompactLayout(context) ? 12 : 16),
          if (_message != null) ...[
            InfoBanner(message: _message!, isError: _isError),
            SizedBox(height: isCompactLayout(context) ? 12 : 16),
          ],
          if (_loading)
            const BootPanel(title: '正在加载动态', subtitle: '同步远程动态列表和当前筛选状态。')
          else if (_items.isEmpty)
            const EmptyStateCard(
              title: '当前没有动态',
              subtitle: '可以发一条短内容，顺手挂上媒体链接。',
            )
          else
            ..._items.map(
              (moment) => Padding(
                padding: EdgeInsets.only(bottom: isCompactLayout(context) ? 10 : 14),
                child: _MomentCard(
                  moment: moment,
                  onEdit: () => _openEditor(moment: moment),
                  onDelete: () => _delete(moment),
                ),
              ),
            ),
          SizedBox(height: isCompactLayout(context) ? 2 : 4),
          PaginationCard(
            currentPage: _page,
            totalPages: _totalPages,
            onPrevious: () {
              setState(() {
                _page -= 1;
              });
              _loadMoments();
            },
            onNext: () {
              setState(() {
                _page += 1;
              });
              _loadMoments();
            },
          ),
        ],
      ),
    );
  }
}

class _MomentCard extends StatelessWidget {
  const _MomentCard({
    required this.moment,
    required this.onEdit,
    required this.onDelete,
  });

  final WpMoment moment;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MomentBadge(label: statusLabel(moment.status)),
              _MomentBadge(label: '${moment.likeCount} 赞'),
              _MomentBadge(label: '${moment.commentCount} 评论'),
              _MomentBadge(label: '${moment.viewCount} 浏览'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppTheme.accentSoft,
                child: Text(
                  (moment.authorName.isEmpty
                          ? '动'
                          : moment.authorName.substring(0, 1))
                      .toUpperCase(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.inkPanel,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _momentPreview(stripHtml(moment.content), maxLength: 42),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      stripHtml(moment.content).isEmpty
                          ? '这条动态还没有可读内容。'
                          : stripHtml(moment.content),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (moment.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MomentBadge(label: '媒体 ${moment.mediaUrls.length} 个'),
                ...moment.mediaUrls
                    .take(2)
                    .map((url) => _MomentBadge(label: _momentMediaLabel(url))),
              ],
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              Text(
                moment.authorName.isEmpty ? '未知作者' : moment.authorName,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                formatDate(
                  moment.modified.isEmpty ? moment.date : moment.modified,
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded),
                label: const Text('编辑'),
              ),
              FilledButton.tonalIcon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('删除'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MomentBadge extends StatelessWidget {
  const _MomentBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _MomentEditorSheet extends StatefulWidget {
  const _MomentEditorSheet({required this.api, this.moment});

  final CfblogApi api;
  final WpMoment? moment;

  @override
  State<_MomentEditorSheet> createState() => _MomentEditorSheetState();
}

class _MomentEditorSheetState extends State<_MomentEditorSheet> {
  late final TextEditingController _contentController;
  late final TextEditingController _mediaUrlsController;
  bool _saving = false;
  String? _error;
  String _status = 'publish';

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(
      text: widget.moment == null
          ? ''
          : (widget.moment!.rawContent.isEmpty
                ? stripHtml(widget.moment!.content)
                : widget.moment!.rawContent),
    );
    _mediaUrlsController = TextEditingController(
      text: widget.moment == null ? '' : widget.moment!.mediaUrls.join('\n'),
    );
    _status = widget.moment?.status.isEmpty == false
        ? widget.moment!.status
        : 'publish';
  }

  @override
  void dispose() {
    _contentController.dispose();
    _mediaUrlsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_contentController.text.trim().isEmpty) {
      setState(() {
        _error = '内容不能为空';
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final payload = <String, dynamic>{
      'status': _status,
      'content': _contentController.text.trim(),
      'media_urls': _mediaUrlsController.text
          .split('\n')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(),
    };

    try {
      if (widget.moment == null) {
        await widget.api.createMoment(payload);
      } else {
        await widget.api.updateMoment(widget.moment!.id, payload);
      }

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
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
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeading(
                    title: '动态编辑器',
                    subtitle: '适合移动端快速发短内容，也能顺手挂接媒体 URL。',
                  ),
                  const SizedBox(height: 18),
                  if (_error != null) ...[
                    InfoBanner(message: _error!, isError: true),
                    const SizedBox(height: 16),
                  ],
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: ['publish', 'draft', 'private'].map((status) {
                      return ChoiceChip(
                        label: Text(statusLabel(status)),
                        selected: _status == status,
                        onSelected: (_) {
                          setState(() {
                            _status = status;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _contentController,
                    minLines: 5,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: '内容',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _mediaUrlsController,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      labelText: '媒体 URL',
                      hintText: '每行一个 URL，可直接引用 R2 地址。',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(false),
                        child: const Text('取消'),
                      ),
                      FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(_saving ? '保存中...' : '保存'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _momentPreview(String content, {required int maxLength}) {
  if (content.isEmpty) {
    return '动态';
  }
  if (content.length <= maxLength) {
    return content;
  }
  return '${content.substring(0, maxLength)}...';
}

String _momentMediaLabel(String url) {
  final uri = Uri.tryParse(url);
  final lastSegment = uri?.pathSegments.isNotEmpty == true
      ? uri!.pathSegments.last
      : url;
  if (lastSegment.length <= 18) {
    return lastSegment;
  }
  return '${lastSegment.substring(0, 18)}...';
}
