import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../core/cfblog_api.dart';
import '../../core/formatters.dart';
import '../../core/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_chrome.dart';

class PostEditorScreen extends StatefulWidget {
  const PostEditorScreen({super.key, required this.api, this.postId});

  final CfblogApi api;
  final int? postId;

  bool get isEditing => postId != null;

  @override
  State<PostEditorScreen> createState() => _PostEditorScreenState();
}

enum _PostContentMode { write, preview }

class _PostEditorScreenState extends State<PostEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _slugController = TextEditingController();
  final _dateController = TextEditingController();
  final _featuredMediaController = TextEditingController();
  final _featuredImageUrlController = TextEditingController();
  final _excerptController = TextEditingController();
  final _contentController = TextEditingController();

  bool _booting = true;
  bool _saving = false;
  String? _error;
  String _status = 'draft';
  bool _sticky = false;
  _PostContentMode _contentMode = _PostContentMode.write;
  List<WpTerm> _categories = const [];
  List<WpTerm> _tags = const [];
  final Set<int> _selectedCategoryIds = <int>{};
  final Set<int> _selectedTagIds = <int>{};

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _slugController.dispose();
    _dateController.dispose();
    _featuredMediaController.dispose();
    _featuredImageUrlController.dispose();
    _excerptController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap({bool refresh = false}) async {
    setState(() {
      _booting = true;
      _error = null;
    });
    try {
      final refsFuture = widget.api.getPostReferences(refresh: refresh);
      final postFuture = widget.isEditing
          ? widget.api.getPost(widget.postId!)
          : Future<WpPost?>.value(null);
      final results = await Future.wait<Object?>([refsFuture, postFuture]);
      final refs = results[0] as PostReferences;
      final post = results[1] as WpPost?;

      _categories = refs.categories;
      _tags = refs.tags;

      if (post != null) {
        _titleController.text = stripHtml(post.title);
        _slugController.text = post.slug;
        _status = post.status.isEmpty ? 'draft' : post.status;
        _sticky = post.sticky;
        _dateController.text = post.date;
        _featuredMediaController.text = post.featuredMedia > 0
            ? '${post.featuredMedia}'
            : '';
        _featuredImageUrlController.text = post.featuredImageUrl;
        _excerptController.text = stripHtml(
          post.rawExcerpt.isEmpty ? post.excerpt : post.rawExcerpt,
        );
        _contentController.text = post.rawContent.isEmpty
            ? stripHtml(post.content)
            : post.rawContent;
        _selectedCategoryIds
          ..clear()
          ..addAll(post.categories);
        _selectedTagIds
          ..clear()
          ..addAll(post.tags);
      }
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
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_contentController.text.trim().isEmpty) {
      setState(() {
        _error = '请填写正文';
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
      'sticky': _sticky,
      'date': _dateController.text.trim().isEmpty
          ? null
          : _dateController.text.trim(),
      'featured_media': int.tryParse(_featuredMediaController.text.trim()),
      'featured_image_url': _featuredImageUrlController.text.trim().isEmpty
          ? null
          : _featuredImageUrlController.text.trim(),
      'categories': _selectedCategoryIds.toList()..sort(),
      'tags': _selectedTagIds.toList()..sort(),
      'excerpt': _excerptController.text.trim(),
      'content': _contentController.text.trim(),
    }..removeWhere((key, value) => value == null);

    try {
      if (widget.isEditing) {
        await widget.api.updatePost(widget.postId!, payload);
      } else {
        await widget.api.createPost(payload);
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

  void _toggleSelection(Set<int> bucket, int id) {
    setState(() {
      if (bucket.contains(id)) {
        bucket.remove(id);
      } else {
        bucket.add(id);
      }
    });
  }

  Future<void> _insertFromMediaLibrary() async {
    final media = await showModalBottomSheet<WpMedia>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PostMediaPickerSheet(api: widget.api),
    );

    if (media == null || !mounted) {
      return;
    }

    final label = stripHtml(media.title).isEmpty ? '媒体文件' : stripHtml(media.title);
    final alt = media.altText.isEmpty ? label : media.altText;
    final snippet = media.isImage
        ? '\n![$alt](${media.sourceUrl})\n'
        : '\n[$label](${media.sourceUrl})\n';

    _insertContentSnippet(snippet);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('媒体已插入正文')));
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

  void _wrapSelection(
    String prefix,
    String suffix, {
    String placeholder = '内容',
  }) {
    final value = _contentController.value;
    final selection = value.selection;
    final hasSelection = selection.isValid && selection.start != selection.end;
    final start = selection.isValid ? selection.start : value.text.length;
    final end = selection.isValid ? selection.end : value.text.length;
    final selectedText = hasSelection
        ? value.text.substring(start, end)
        : placeholder;
    final snippet = '$prefix$selectedText$suffix';
    final nextText = value.text.replaceRange(start, end, snippet);
    final nextOffset = start + snippet.length;

    _contentController.value = value.copyWith(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextOffset),
      composing: TextRange.empty,
    );
  }

  void _insertLinePrefix(String prefix, {String placeholder = '内容'}) {
    final value = _contentController.value;
    final selection = value.selection;
    final hasSelection = selection.isValid && selection.start != selection.end;
    final start = selection.isValid ? selection.start : value.text.length;
    final end = selection.isValid ? selection.end : value.text.length;
    final selectedText = hasSelection
        ? value.text.substring(start, end)
        : placeholder;
    final snippet = '\n$prefix$selectedText\n';
    final nextText = value.text.replaceRange(start, end, snippet);
    final nextOffset = start + snippet.length;

    _contentController.value = value.copyWith(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextOffset),
      composing: TextRange.empty,
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? '编辑文章' : '新建文章';
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
                label: Text(_saving ? '保存中...' : '保存文章'),
              ),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: _booting
              ? const Center(
                  child: BootPanel(
                    title: '正在准备编辑器',
                    subtitle: '加载文章详情、分类和标签引用。',
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _bootstrap(refresh: true),
                  child: ListView(
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
                            Wrap(
                              spacing: compact ? 8 : 10,
                              runSpacing: compact ? 8 : 10,
                              children: _postStatusOptions.map((status) {
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
                            Container(
                              padding: EdgeInsets.all(compact ? 10 : 12),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceMuted,
                                borderRadius: BorderRadius.circular(
                                  compact ? 16 : 18,
                                ),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '置顶文章',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        SizedBox(height: compact ? 4 : 6),
                                        Text(
                                          '优先展示在前台内容流。',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: _sticky,
                                    onChanged: (value) {
                                      setState(() {
                                        _sticky = value;
                                      });
                                    },
                                  ),
                                ],
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
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            SurfaceCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '内容主区',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                      ),
                                      FilledButton.tonalIcon(
                                        onPressed: _insertFromMediaLibrary,
                                        icon: const Icon(
                                          Icons.add_photo_alternate_rounded,
                                        ),
                                        label: const Text('插入媒体'),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: compact ? 10 : 12),
                                  TextFormField(
                                    controller: _titleController,
                                    decoration: const InputDecoration(
                                      labelText: '标题',
                                    ),
                                    validator: (value) {
                                      if ((value ?? '').trim().isEmpty) {
                                        return '请填写标题';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: compact ? 10 : 14),
                                  TextFormField(
                                    controller: _excerptController,
                                    minLines: 2,
                                    maxLines: compact ? 3 : 4,
                                    decoration: const InputDecoration(
                                      labelText: '摘要',
                                      hintText: '用于列表摘要、SEO 简述或卡片预览。',
                                    ),
                                  ),
                                  SizedBox(height: compact ? 10 : 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Markdown 正文',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                      ),
                                      SegmentedButton<_PostContentMode>(
                                        segments: const [
                                          ButtonSegment<_PostContentMode>(
                                            value: _PostContentMode.write,
                                            icon: Icon(Icons.edit_rounded),
                                            label: Text('编辑'),
                                          ),
                                          ButtonSegment<_PostContentMode>(
                                            value: _PostContentMode.preview,
                                            icon: Icon(Icons.visibility_rounded),
                                            label: Text('预览'),
                                          ),
                                        ],
                                        selected: {_contentMode},
                                        onSelectionChanged: (selection) {
                                          if (selection.isEmpty) {
                                            return;
                                          }
                                          setState(() {
                                            _contentMode = selection.first;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: compact ? 10 : 12),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        _MarkdownToolButton(
                                          icon: Icons.title_rounded,
                                          tooltip: '标题',
                                          onPressed: () => _insertLinePrefix(
                                            '# ',
                                            placeholder: '标题',
                                          ),
                                        ),
                                        _MarkdownToolButton(
                                          icon: Icons.format_bold_rounded,
                                          tooltip: '加粗',
                                          onPressed: () => _wrapSelection(
                                            '**',
                                            '**',
                                            placeholder: '加粗内容',
                                          ),
                                        ),
                                        _MarkdownToolButton(
                                          icon: Icons.format_italic_rounded,
                                          tooltip: '斜体',
                                          onPressed: () => _wrapSelection(
                                            '_',
                                            '_',
                                            placeholder: '斜体内容',
                                          ),
                                        ),
                                        _MarkdownToolButton(
                                          icon: Icons.code_rounded,
                                          tooltip: '代码',
                                          onPressed: () => _wrapSelection(
                                            '`',
                                            '`',
                                            placeholder: 'code',
                                          ),
                                        ),
                                        _MarkdownToolButton(
                                          icon: Icons.format_list_bulleted_rounded,
                                          tooltip: '列表',
                                          onPressed: () => _insertLinePrefix(
                                            '- ',
                                            placeholder: '列表项',
                                          ),
                                        ),
                                        _MarkdownToolButton(
                                          icon: Icons.format_quote_rounded,
                                          tooltip: '引用',
                                          onPressed: () => _insertLinePrefix(
                                            '> ',
                                            placeholder: '引用内容',
                                          ),
                                        ),
                                        _MarkdownToolButton(
                                          icon: Icons.link_rounded,
                                          tooltip: '链接',
                                          onPressed: () => _wrapSelection(
                                            '[',
                                            '](https://)',
                                            placeholder: '链接文本',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: compact ? 10 : 12),
                                  if (_contentMode == _PostContentMode.write)
                                    TextFormField(
                                      controller: _contentController,
                                      minLines: compact ? 7 : 10,
                                      maxLines: compact ? 12 : 16,
                                      decoration: const InputDecoration(
                                        labelText: '正文',
                                        hintText: '使用 Markdown 编写正文内容。',
                                        alignLabelWithHint: true,
                                      ),
                                    )
                                  else
                                    ValueListenableBuilder<TextEditingValue>(
                                      valueListenable: _contentController,
                                      builder: (context, value, _) {
                                        return Container(
                                          width: double.infinity,
                                          constraints: BoxConstraints(
                                            minHeight: compact ? 220 : 280,
                                          ),
                                          padding: EdgeInsets.all(
                                            compact ? 12 : 14,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppTheme.surfaceMuted,
                                            borderRadius: BorderRadius.circular(
                                              compact ? 18 : 22,
                                            ),
                                            border: Border.all(
                                              color: AppTheme.border,
                                            ),
                                          ),
                                          child: value.text.trim().isEmpty
                                              ? Text(
                                                  '暂无预览内容',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color:
                                                            AppTheme.textMuted,
                                                      ),
                                                )
                                              : MarkdownBody(
                                                  data: value.text,
                                                  shrinkWrap: true,
                                                ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(height: compact ? 12 : 16),
                            SurfaceCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '结构与发布',
                                    style: Theme.of(context).textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  SizedBox(height: compact ? 10 : 12),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final stacked =
                                          constraints.maxWidth < 720;
                                      final slugField = TextFormField(
                                        controller: _slugController,
                                        decoration: const InputDecoration(
                                          labelText: 'Slug',
                                        ),
                                      );
                                      final dateField = TextFormField(
                                        controller: _dateController,
                                        decoration: const InputDecoration(
                                          labelText: '发布时间',
                                          hintText: '2026-04-17T12:00:00',
                                        ),
                                      );

                                      if (stacked) {
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            slugField,
                                            SizedBox(
                                              height: compact ? 10 : 12,
                                            ),
                                            dateField,
                                          ],
                                        );
                                      }

                                      return Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(child: slugField),
                                          SizedBox(width: compact ? 8 : 12),
                                          Expanded(child: dateField),
                                        ],
                                      );
                                    },
                                  ),
                                  SizedBox(height: compact ? 10 : 14),
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final stacked =
                                          constraints.maxWidth < 720;
                                      final mediaField = TextFormField(
                                        controller: _featuredMediaController,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          labelText: '封面媒体 ID',
                                        ),
                                      );
                                      final imageUrlField = TextFormField(
                                        controller: _featuredImageUrlController,
                                        keyboardType: TextInputType.url,
                                        decoration: const InputDecoration(
                                          labelText: '封面图片 URL',
                                        ),
                                      );

                                      if (stacked) {
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            mediaField,
                                            SizedBox(
                                              height: compact ? 10 : 12,
                                            ),
                                            imageUrlField,
                                          ],
                                        );
                                      }

                                      return Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(child: mediaField),
                                          SizedBox(width: compact ? 8 : 12),
                                          Expanded(child: imageUrlField),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: compact ? 12 : 16),
                            SurfaceCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '分类',
                                    style: Theme.of(context).textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  SizedBox(height: compact ? 10 : 12),
                                  _TermSelector(
                                    emptyText: '当前没有分类可选。',
                                    items: _categories,
                                    selectedIds: _selectedCategoryIds,
                                    onToggle: (id) => _toggleSelection(
                                      _selectedCategoryIds,
                                      id,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: compact ? 12 : 16),
                            SurfaceCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '标签',
                                    style: Theme.of(context).textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  SizedBox(height: compact ? 10 : 12),
                                  _TermSelector(
                                    emptyText: '当前没有标签可选。',
                                    items: _tags,
                                    selectedIds: _selectedTagIds,
                                    onToggle: (id) =>
                                        _toggleSelection(_selectedTagIds, id),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: compact ? 12 : 16),
                            SurfaceCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '保存前检查',
                                    style: Theme.of(context).textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  SizedBox(height: compact ? 10 : 12),
                                  AnimatedBuilder(
                                    animation: Listenable.merge([
                                      _titleController,
                                      _excerptController,
                                      _contentController,
                                    ]),
                                    builder: (context, _) {
                                      return Wrap(
                                        spacing: compact ? 8 : 10,
                                        runSpacing: compact ? 8 : 10,
                                        children: [
                                          _ReviewPill(
                                            icon: Icons.article_outlined,
                                            label:
                                                _titleController.text.trim().isEmpty
                                                ? '标题未填写'
                                                : '标题已填写',
                                          ),
                                          _ReviewPill(
                                            icon: Icons.description_outlined,
                                            label:
                                                _excerptController.text
                                                    .trim()
                                                    .isEmpty
                                                ? '摘要可选'
                                                : '摘要已填写',
                                          ),
                                          _ReviewPill(
                                            icon: Icons.edit_note_rounded,
                                            label:
                                                _contentController.text
                                                    .trim()
                                                    .isEmpty
                                                ? '正文未填写'
                                                : '正文已填写',
                                          ),
                                          _ReviewPill(
                                            icon: Icons.push_pin_outlined,
                                            label:
                                                _sticky ? '将作为置顶文章' : '普通文章',
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

class _TermSelector extends StatelessWidget {
  const _TermSelector({
    required this.emptyText,
    required this.items,
    required this.selectedIds,
    required this.onToggle,
  });

  final String emptyText;
  final List<WpTerm> items;
  final Set<int> selectedIds;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactLayout(context);
    return SizedBox(
      width: double.infinity,
      child: items.isEmpty
          ? Text(emptyText, style: Theme.of(context).textTheme.bodySmall)
          : Wrap(
              spacing: compact ? 8 : 10,
              runSpacing: compact ? 8 : 10,
              children: items.map((item) {
                return FilterChip(
                  visualDensity: compact
                      ? VisualDensity.compact
                      : VisualDensity.standard,
                  materialTapTargetSize: compact
                      ? MaterialTapTargetSize.shrinkWrap
                      : MaterialTapTargetSize.padded,
                  label: Text(item.name),
                  selected: selectedIds.contains(item.id),
                  onSelected: (_) => onToggle(item.id),
                );
              }).toList(),
            ),
    );
  }
}

class _ReviewPill extends StatelessWidget {
  const _ReviewPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactLayout(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 14 : 16, color: AppTheme.textMuted),
          SizedBox(width: compact ? 6 : 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _MarkdownToolButton extends StatelessWidget {
  const _MarkdownToolButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: IconButton.filledTonal(
        onPressed: onPressed,
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, size: 18),
      ),
    );
  }
}

const List<String> _postStatusOptions = <String>[
  'publish',
  'draft',
  'pending',
  'private',
];

class _PostMediaPickerSheet extends StatefulWidget {
  const _PostMediaPickerSheet({required this.api});

  final CfblogApi api;

  @override
  State<_PostMediaPickerSheet> createState() => _PostMediaPickerSheetState();
}

class _PostMediaPickerSheetState extends State<_PostMediaPickerSheet> {
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
                '选择一张图片或文件，直接插入正文。',
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
                        subtitle: '先上传图片或文件，再回来插入正文。',
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
                                return _PostMediaRow(
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

class _PostMediaRow extends StatelessWidget {
  const _PostMediaRow({
    required this.item,
    required this.onTap,
  });

  final WpMedia item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = stripHtml(item.title).isEmpty ? item.slug : stripHtml(item.title);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            _PostMediaThumb(item: item),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isEmpty ? '未命名媒体' : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.mediaType.isEmpty ? '媒体' : item.mediaType} · ${formatCompactDate(item.date)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}

class _PostMediaThumb extends StatelessWidget {
  const _PostMediaThumb({required this.item});

  final WpMedia item;

  @override
  Widget build(BuildContext context) {
    if (item.isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          item.sourceUrl,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const _PostMediaFallback(),
        ),
      );
    }

    return const _PostMediaFallback();
  }
}

class _PostMediaFallback extends StatelessWidget {
  const _PostMediaFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: const Icon(
        Icons.insert_drive_file_rounded,
        size: 20,
        color: AppTheme.textMuted,
      ),
    );
  }
}
