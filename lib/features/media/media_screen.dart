import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/cfblog_api.dart';
import '../../core/formatters.dart';
import '../../core/media_upload.dart';
import '../../core/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_chrome.dart';

class MediaScreen extends StatefulWidget {
  const MediaScreen({super.key, required this.api});

  final CfblogApi api;

  @override
  State<MediaScreen> createState() => _MediaScreenState();
}

class _MediaScreenState extends State<MediaScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _altController = TextEditingController();
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  bool _loading = true;
  bool _uploading = false;
  String? _message;
  bool _isError = false;
  List<WpMedia> _items = const [];
  int _page = 1;
  int _totalPages = 1;
  PlatformFile? _selectedFile;

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _altController.dispose();
    _captionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadMedia({bool refresh = false}) async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final result = await widget.api.listMedia(
        page: _page,
        perPage: 12,
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

  Future<void> _chooseFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: kIsWeb,
    );

    if (result == null || result.files.isEmpty || !mounted) {
      return;
    }

    final file = result.files.first;
    setState(() {
      _selectedFile = file;
      if (_titleController.text.trim().isEmpty) {
        _titleController.text = file.name;
      }
    });
  }

  Future<void> _upload() async {
    final file = _selectedFile;
    if (file == null) {
      setState(() {
        _isError = true;
        _message = '请先选择文件';
      });
      return;
    }

    setState(() {
      _uploading = true;
      _message = null;
    });

    try {
      final mimeType = detectUploadMimeType(
        fileName: file.name,
        bytes: file.bytes,
      );
      await widget.api.uploadMedia(
        fileName: file.name,
        filePath: file.path,
        bytes: file.bytes,
        mimeType: mimeType,
        fields: {
          'title': _titleController.text.trim().isEmpty
              ? file.name
              : _titleController.text.trim(),
          'alt_text': _altController.text.trim(),
          'caption': _captionController.text.trim(),
          'description': _descriptionController.text.trim(),
        },
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _selectedFile = null;
        _titleController.clear();
        _altController.clear();
        _captionController.clear();
        _descriptionController.clear();
        _isError = false;
        _message = '媒体上传成功';
      });
      await _loadMedia();
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
          _uploading = false;
        });
      }
    }
  }

  Future<void> _openEdit(WpMedia item) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MediaEditSheet(api: widget.api, media: item),
    );

    if (changed == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      await _loadMedia();
      messenger.showSnackBar(const SnackBar(content: Text('媒体信息已更新')));
    }
  }

  Future<void> _remove(WpMedia item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除媒体'),
        content: Text(
          '确定要删除「${stripHtml(item.title).isEmpty ? item.slug : stripHtml(item.title)}」吗？',
        ),
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
      await widget.api.deleteMedia(item.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _isError = false;
        _message = '媒体已删除';
      });
      await _loadMedia();
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
      onRefresh: () => _loadMedia(refresh: true),
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
                      onPressed: () => _loadMedia(refresh: true),
                      style: toolbarButtonStyle,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('刷新'),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 10 : 12),
                _UploadCard(
                  selectedFile: _selectedFile,
                  titleController: _titleController,
                  altController: _altController,
                  captionController: _captionController,
                  descriptionController: _descriptionController,
                  uploading: _uploading,
                  onChooseFile: _chooseFile,
                  onUpload: _upload,
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
            const BootPanel(title: '正在加载媒体', subtitle: '同步远程媒体列表和当前页状态。')
          else if (_items.isEmpty)
            const EmptyStateCard(
              title: '媒体库还是空的',
              subtitle: '上传第一份图片、视频或文档后，这里会出现素材卡片。',
            )
          else
            ..._items.map(
              (item) => Padding(
                padding: EdgeInsets.only(bottom: compact ? 10 : 14),
                child: _MediaCard(
                  item: item,
                  onEdit: () => _openEdit(item),
                  onDelete: () => _remove(item),
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
      ),
    );
  }
}

class _UploadCard extends StatelessWidget {
  const _UploadCard({
    required this.selectedFile,
    required this.titleController,
    required this.altController,
    required this.captionController,
    required this.descriptionController,
    required this.uploading,
    required this.onChooseFile,
    required this.onUpload,
  });

  final PlatformFile? selectedFile;
  final TextEditingController titleController;
  final TextEditingController altController;
  final TextEditingController captionController;
  final TextEditingController descriptionController;
  final bool uploading;
  final VoidCallback onChooseFile;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactLayout(context);
    return Container(
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(compact ? 20 : 24),
        border: Border.all(color: AppTheme.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 920;
          final actions = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onChooseFile,
                icon: const Icon(Icons.attach_file_rounded),
                label: Text(selectedFile == null ? '选择文件' : '重新选择'),
              ),
              FilledButton.icon(
                onPressed: uploading ? null : onUpload,
                icon: uploading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_upload_rounded),
                label: Text(uploading ? '上传中...' : '上传'),
              ),
            ],
          );

          final fileSummary = Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _UploadMetaChip(
                icon: selectedFile == null
                    ? Icons.photo_library_outlined
                    : Icons.insert_drive_file_outlined,
                label: selectedFile?.name ?? '未选择文件',
              ),
              if (selectedFile != null)
                _UploadMetaChip(
                  icon: Icons.scale_outlined,
                  label: formatBytes(selectedFile!.size),
                ),
              if (selectedFile?.extension?.isNotEmpty == true)
                _UploadMetaChip(
                  icon: Icons.category_outlined,
                  label: selectedFile!.extension!,
                ),
            ],
          );

          final fields = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, fieldConstraints) {
                  final narrow = fieldConstraints.maxWidth < 680;
                  final titleField = TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: '标题',
                    ),
                  );
                  final altField = TextField(
                    controller: altController,
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: '替代文本',
                    ),
                  );

                  if (narrow) {
                    return Column(
                      children: [
                        titleField,
                        const SizedBox(height: 10),
                        altField,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: titleField),
                      const SizedBox(width: 10),
                      Expanded(child: altField),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, fieldConstraints) {
                  final narrow = fieldConstraints.maxWidth < 680;
                  final captionField = TextField(
                    controller: captionController,
                    minLines: 1,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: '说明',
                    ),
                  );
                  final descriptionField = TextField(
                    controller: descriptionController,
                    minLines: 1,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: '描述',
                    ),
                  );

                  if (narrow) {
                    return Column(
                      children: [
                        captionField,
                        const SizedBox(height: 10),
                        descriptionField,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: captionField),
                      const SizedBox(width: 10),
                      Expanded(child: descriptionField),
                    ],
                  );
                },
              ),
            ],
          );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                fileSummary,
                const SizedBox(height: 10),
                actions,
                const SizedBox(height: 12),
                fields,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: fileSummary),
                  const SizedBox(width: 12),
                  actions,
                ],
              ),
              const SizedBox(height: 12),
              fields,
            ],
          );
        },
      ),
    );
  }
}

class _UploadMetaChip extends StatelessWidget {
  const _UploadMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.textMuted),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  const _MediaCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  final WpMedia item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactLayout(context);
    final title = stripHtml(item.title).isEmpty ? item.slug : stripHtml(item.title);
    return SurfaceCard(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 10 : 12,
      ),
      child: Row(
        children: [
          _MediaPreview(item: item),
          const SizedBox(width: 10),
          _Tag(label: item.mediaType.isEmpty ? '媒体' : item.mediaType),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title.isEmpty ? '未命名媒体' : title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: compact ? 120 : 168,
            child: Text(
              _mediaMeta(item),
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
            tooltip: '编辑媒体',
            icon: const Icon(Icons.edit_rounded),
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: '删除媒体',
            icon: const Icon(Icons.delete_outline_rounded),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _MediaPreview extends StatelessWidget {
  const _MediaPreview({required this.item});

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
                  const _MediaFallback(),
            ),
          )
        : const _MediaFallback();

    return Container(
      width: 46,
      height: 46,
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

class _MediaFallback extends StatelessWidget {
  const _MediaFallback();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(
        Icons.insert_drive_file_rounded,
        size: 22,
        color: AppTheme.textMuted,
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

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

String _mediaMeta(WpMedia item) {
  final parts = <String>[
    formatCompactDate(item.modified.isEmpty ? item.date : item.modified),
  ];
  if (item.mediaDetails?.fileSize case final int size when size > 0) {
    parts.add(formatBytes(size));
  }
  return parts.join(' · ');
}

class _MediaEditSheet extends StatefulWidget {
  const _MediaEditSheet({required this.api, required this.media});

  final CfblogApi api;
  final WpMedia media;

  @override
  State<_MediaEditSheet> createState() => _MediaEditSheetState();
}

class _MediaEditSheetState extends State<_MediaEditSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _altController;
  late final TextEditingController _captionController;
  late final TextEditingController _descriptionController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: stripHtml(widget.media.title),
    );
    _altController = TextEditingController(text: widget.media.altText);
    _captionController = TextEditingController(
      text: stripHtml(widget.media.caption),
    );
    _descriptionController = TextEditingController(
      text: stripHtml(widget.media.description),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _altController.dispose();
    _captionController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.api.updateMedia(widget.media.id, {
        'title': _titleController.text.trim(),
        'alt_text': _altController.text.trim(),
        'caption': _captionController.text.trim(),
        'description': _descriptionController.text.trim(),
      });
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
                    title: '编辑媒体信息',
                    subtitle: '调整标题、替代文本和说明，不需要重新上传文件。',
                  ),
                  const SizedBox(height: 18),
                  if (_error != null) ...[
                    InfoBanner(message: _error!, isError: true),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: '标题'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _altController,
                    decoration: const InputDecoration(labelText: '替代文本'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _captionController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: '说明'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: '描述'),
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
