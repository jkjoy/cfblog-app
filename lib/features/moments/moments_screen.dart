import 'package:flutter/material.dart';

import '../../core/cfblog_api.dart';
import '../../core/formatters.dart';
import '../../core/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_chrome.dart';

Future<bool?> showMomentEditorSheet(
  BuildContext context, {
  required CfblogApi api,
  WpMoment? moment,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _MomentEditorSheet(api: api, moment: moment),
  );
}

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
  int _totalPages = 1;
  String _status = 'all';

  static const _statusOptions = <String>['all', 'publish', 'draft', 'private'];

  @override
  void initState() {
    super.initState();
    _loadMoments();
  }

  Future<void> _loadMoments({bool refresh = false}) async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final result = await widget.api.listMoments(
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

  Future<void> _openEditor({WpMoment? moment}) async {
    final changed = await showMomentEditorSheet(
      context,
      api: widget.api,
      moment: moment,
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
      onRefresh: () => _loadMoments(refresh: true),
      child: ListView(
        padding: pageContentPadding(context),
        children: [
          SurfaceCard(
            padding: EdgeInsets.all(compact ? 12 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => _loadMoments(refresh: true),
                      style: toolbarButtonStyle,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('刷新'),
                    ),
                    FilledButton.icon(
                      onPressed: () => _openEditor(),
                      style: toolbarButtonStyle,
                      icon: const Icon(Icons.bolt_rounded),
                      label: const Text('发动态'),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 10 : 12),
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
                      _loadMoments();
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: compact ? 12 : 16),
          if (_message != null) ...[
            InfoBanner(message: _message!, isError: _isError),
            SizedBox(height: compact ? 12 : 16),
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
                padding: EdgeInsets.only(bottom: compact ? 10 : 14),
                child: _MomentCard(
                  moment: moment,
                  onEdit: () => _openEditor(moment: moment),
                  onDelete: () => _delete(moment),
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
    final compact = isCompactLayout(context);
    final preview = _momentPreview(stripHtml(moment.content), maxLength: 56);
    return SurfaceCard(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 10 : 12,
      ),
      child: Row(
        children: [
          _MomentBadge(label: statusLabel(moment.status)),
          if (moment.mediaUrls.isNotEmpty) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.photo_library_outlined,
              size: 16,
              color: AppTheme.textMuted,
            ),
          ],
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              preview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: compact ? 74 : 84,
            child: Text(
              formatCompactDate(moment.modified.isEmpty ? moment.date : moment.modified),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: onEdit,
            tooltip: '编辑动态',
            icon: const Icon(Icons.edit_rounded),
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: '删除动态',
            icon: const Icon(Icons.delete_outline_rounded),
            visualDensity: VisualDensity.compact,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

  Future<void> _insertFromMediaLibrary({required bool intoContent}) async {
    final media = await showModalBottomSheet<WpMedia>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MomentMediaPickerSheet(api: widget.api),
    );

    if (media == null || !mounted) {
      return;
    }

    final title = stripHtml(media.title).isEmpty ? '媒体文件' : stripHtml(media.title);
    final alt = media.altText.isEmpty ? title : media.altText;

    if (intoContent) {
      final snippet = media.isImage
          ? '\n![$alt](${media.sourceUrl})\n'
          : '\n[$title](${media.sourceUrl})\n';
      _insertContentSnippet(snippet);
    } else {
      final current = _mediaUrlsController.text.trim();
      _mediaUrlsController.text = current.isEmpty
          ? media.sourceUrl
          : '$current\n${media.sourceUrl}';
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(intoContent ? '媒体已插入内容' : '媒体地址已加入列表')));
  }

  void _insertContentSnippet(String snippet) {
    final value = _contentController.value;
    final selection = value.selection;
    final start = selection.isValid ? selection.start : value.text.length;
    final end = selection.isValid ? selection.end : value.text.length;
    final safeStart = start < 0 ? value.text.length : start;
    final safeEnd = end < 0 ? value.text.length : end;
    final nextText = value.text.replaceRange(safeStart, safeEnd, snippet);
    final caretOffset = safeStart + snippet.length;

    _contentController.value = value.copyWith(
      text: nextText,
      selection: TextSelection.collapsed(offset: caretOffset),
      composing: TextRange.empty,
    );
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
    final compact = isCompactLayout(context);

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
                  Text(
                    '内容',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: compact ? 8 : 10),
                  TextField(
                    controller: _contentController,
                    minLines: 5,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      alignLabelWithHint: true,
                      hintText: '输入动态内容，也可以直接插入媒体链接。',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '媒体 URL',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => _insertFromMediaLibrary(intoContent: false),
                        icon: const Icon(Icons.photo_library_rounded),
                        label: const Text('从媒体库添加'),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 8 : 10),
                  TextField(
                    controller: _mediaUrlsController,
                    minLines: 3,
                    maxLines: 6,
                    decoration: const InputDecoration(
                      hintText: '每行一个 URL，可直接引用媒体库文件地址。',
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

class _MomentMediaPickerSheet extends StatefulWidget {
  const _MomentMediaPickerSheet({required this.api});

  final CfblogApi api;

  @override
  State<_MomentMediaPickerSheet> createState() => _MomentMediaPickerSheetState();
}

class _MomentMediaPickerSheetState extends State<_MomentMediaPickerSheet> {
  bool _loading = true;
  String? _error;
  List<WpMedia> _items = const [];
  int _page = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  Future<void> _loadMedia({bool refresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await widget.api.listMedia(
        page: _page,
        perPage: 24,
        refresh: refresh,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _items = result.items;
        _totalPages = result.totalPages;
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

  @override
  Widget build(BuildContext context) {
    final compact = isCompactLayout(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 24, 10, 10),
        child: SurfaceCard(
          padding: EdgeInsets.fromLTRB(
            compact ? 12 : 14,
            compact ? 10 : 12,
            compact ? 12 : 14,
            compact ? 12 : 14,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '媒体库',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => _loadMedia(refresh: true),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('刷新'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '选择一张图片或文件，插入动态内容或媒体列表。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.62,
                ),
                child: _loading
                    ? const BootPanel(
                        title: '正在加载媒体',
                        subtitle: '同步媒体库内容。',
                      )
                    : _error != null
                    ? InfoBanner(message: _error!, isError: true)
                    : _items.isEmpty
                    ? const EmptyStateCard(
                        title: '媒体库为空',
                        subtitle: '先上传图片或文件，再回来插入动态。',
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: _items.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final item = _items[index];
                                return _MomentMediaRow(
                                  item: item,
                                  onTap: () => Navigator.of(context).pop(item),
                                );
                              },
                            ),
                          ),
                          if (_totalPages > 1) ...[
                            const SizedBox(height: 10),
                            PaginationCard(
                              currentPage: _page,
                              totalPages: _totalPages,
                              onPrevious: () {
                                setState(() {
                                  _page -= 1;
                                });
                                _loadMedia();
                              },
                              onNext: () {
                                setState(() {
                                  _page += 1;
                                });
                                _loadMedia();
                              },
                            ),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MomentMediaRow extends StatelessWidget {
  const _MomentMediaRow({required this.item, required this.onTap});

  final WpMedia item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactLayout(context);
    final title = stripHtml(item.title).isEmpty ? item.slug : stripHtml(item.title);
    return SurfaceCard(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 10 : 12,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Row(
          children: [
            _MomentMediaPreview(item: item),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title.isEmpty ? '未命名媒体' : title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              formatCompactDate(item.modified.isEmpty ? item.date : item.modified),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _MomentMediaPreview extends StatelessWidget {
  const _MomentMediaPreview({required this.item});

  final WpMedia item;

  @override
  Widget build(BuildContext context) {
    final preview = item.isImage
        ? ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              item.sourceUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const _MomentMediaFallback(),
            ),
          )
        : const _MomentMediaFallback();

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: preview,
    );
  }
}

class _MomentMediaFallback extends StatelessWidget {
  const _MomentMediaFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.insert_drive_file_rounded,
        size: 20,
        color: AppTheme.textMuted,
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
