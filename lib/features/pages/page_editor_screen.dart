import 'package:flutter/material.dart';

import '../../core/cfblog_api.dart';
import '../../core/formatters.dart';
import '../../widgets/app_chrome.dart';

class PageEditorScreen extends StatefulWidget {
  const PageEditorScreen({super.key, required this.api, this.pageId});

  final CfblogApi api;
  final int? pageId;

  bool get isEditing => pageId != null;

  @override
  State<PageEditorScreen> createState() => _PageEditorScreenState();
}

class _PageEditorScreenState extends State<PageEditorScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _slugController = TextEditingController();
  final TextEditingController _parentController = TextEditingController();
  final TextEditingController _excerptController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  bool _booting = true;
  bool _saving = false;
  String? _error;
  String _status = 'draft';
  String _commentStatus = 'open';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _slugController.dispose();
    _parentController.dispose();
    _excerptController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (!widget.isEditing) {
      setState(() {
        _booting = false;
      });
      return;
    }

    setState(() {
      _booting = true;
      _error = null;
    });

    try {
      final page = await widget.api.getPage(widget.pageId!);
      _titleController.text = stripHtml(page.title);
      _slugController.text = page.slug;
      _parentController.text = page.parent > 0 ? '${page.parent}' : '';
      _excerptController.text = stripHtml(
        page.rawExcerpt.isEmpty ? page.excerpt : page.rawExcerpt,
      );
      _contentController.text = page.rawContent.isEmpty
          ? stripHtml(page.content)
          : page.rawContent;
      _status = page.status.isEmpty ? 'draft' : page.status;
      _commentStatus = page.commentStatus.isEmpty ? 'open' : page.commentStatus;
    } catch (error) {
      _error = error.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) {
        setState(() {
          _booting = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      setState(() {
        _error = '标题和正文不能为空';
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final payload = <String, dynamic>{
      'title': _titleController.text.trim(),
      'slug': _slugController.text.trim().isEmpty
          ? null
          : _slugController.text.trim(),
      'status': _status,
      'parent': int.tryParse(_parentController.text.trim()),
      'comment_status': _commentStatus,
      'excerpt': _excerptController.text.trim(),
      'content': _contentController.text.trim(),
    }..removeWhere((key, value) => value == null);

    try {
      if (widget.isEditing) {
        await widget.api.updatePage(widget.pageId!, payload);
      } else {
        await widget.api.createPage(payload);
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
    final title = widget.isEditing ? '编辑页面' : '新建页面';
    final compact = isCompactLayout(context);

    return AppBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(title),
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          actions: [
            Padding(
              padding: EdgeInsets.only(right: compact ? 12 : 16),
              child: FilledButton.icon(
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
                label: Text(_saving ? '保存中...' : '保存页面'),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: _booting
              ? const Center(
                  child: BootPanel(
                    title: '正在准备页面编辑器',
                    subtitle: '加载页面详情和当前发布状态。',
                  ),
                )
              : ListView(
                  padding: pageContentPadding(
                    context,
                    top: compact ? 4 : 8,
                    bottom: compact ? 18 : 24,
                  ),
                  children: [
                    SurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '发布状态',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: compact ? 10 : 12),
                          if (_error != null) ...[
                            InfoBanner(message: _error!, isError: true),
                            SizedBox(height: compact ? 12 : 16),
                          ],
                          Wrap(
                            spacing: compact ? 8 : 10,
                            runSpacing: compact ? 8 : 10,
                            children: _pageStatusOptions.map((status) {
                              return ChoiceChip(
                                visualDensity: compact
                                    ? VisualDensity.compact
                                    : VisualDensity.standard,
                                materialTapTargetSize: compact
                                    ? MaterialTapTargetSize.shrinkWrap
                                    : MaterialTapTargetSize.padded,
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
                          SizedBox(height: compact ? 10 : 12),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final stacked = constraints.maxWidth < 720;
                              final titleField = TextField(
                                controller: _titleController,
                                decoration: const InputDecoration(
                                  labelText: '标题',
                                ),
                              );
                              final slugField = TextField(
                                controller: _slugController,
                                decoration: const InputDecoration(
                                  labelText: 'Slug',
                                ),
                              );

                              if (stacked) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    titleField,
                                    SizedBox(height: compact ? 10 : 12),
                                    slugField,
                                  ],
                                );
                              }

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: titleField),
                                  SizedBox(width: compact ? 8 : 12),
                                  Expanded(child: slugField),
                                ],
                              );
                            },
                          ),
                          SizedBox(height: compact ? 10 : 14),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final stacked = constraints.maxWidth < 720;
                              final parentField = TextField(
                                controller: _parentController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: '父页面 ID',
                                ),
                              );
                              final commentStatusField =
                                  DropdownButtonFormField<String>(
                                    initialValue: _commentStatus,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'open',
                                        child: Text('评论开放'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'closed',
                                        child: Text('评论关闭'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      if (value == null) {
                                        return;
                                      }
                                      setState(() {
                                        _commentStatus = value;
                                      });
                                    },
                                    decoration: const InputDecoration(
                                      labelText: '评论状态',
                                    ),
                                  );

                              if (stacked) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    parentField,
                                    SizedBox(height: compact ? 10 : 12),
                                    commentStatusField,
                                  ],
                                );
                              }

                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: parentField),
                                  SizedBox(width: compact ? 8 : 12),
                                  Expanded(child: commentStatusField),
                                ],
                              );
                            },
                          ),
                          SizedBox(height: compact ? 10 : 14),
                          TextField(
                            controller: _excerptController,
                            minLines: 2,
                            maxLines: compact ? 3 : 4,
                            decoration: const InputDecoration(
                              labelText: '摘要',
                              hintText: '适合 About、归档和说明性页面的简短导语。',
                            ),
                          ),
                          SizedBox(height: compact ? 10 : 14),
                          TextField(
                            controller: _contentController,
                            minLines: compact ? 7 : 10,
                            maxLines: compact ? 12 : 16,
                            decoration: const InputDecoration(
                              labelText: '正文',
                              alignLabelWithHint: true,
                            ),
                          ),
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

const List<String> _pageStatusOptions = <String>[
  'publish',
  'draft',
  'pending',
  'private',
];
