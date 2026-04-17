import 'package:flutter/material.dart';

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
  List<WpTerm> _categories = const [];
  List<WpTerm> _tags = const [];
  final Set<int> _selectedCategoryIds = <int>{};
  final Set<int> _selectedTagIds = <int>{};

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_refreshDraftState);
    _excerptController.addListener(_refreshDraftState);
    _contentController.addListener(_refreshDraftState);
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

  void _refreshDraftState() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _bootstrap() async {
    setState(() {
      _booting = true;
      _error = null;
    });
    try {
      final refsFuture = widget.api.getPostReferences();
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

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? '编辑文章' : '新建文章';

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
              padding: const EdgeInsets.only(right: 16),
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
                  onRefresh: _bootstrap,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      SurfaceCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SectionHeading(
                              title: title,
                              subtitle: widget.isEditing
                                  ? '在同一页处理标题、摘要、正文和发布状态，减少来回切换。'
                                  : '先写核心内容，再逐步补充分类、标签和封面信息。',
                            ),
                            const SizedBox(height: 18),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: _postStatusOptions.map((status) {
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
                            const SizedBox(height: 18),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceMuted,
                                borderRadius: BorderRadius.circular(22),
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
                                          ).textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '打开后会优先展示在前台内容流中，适合公告或重点文章。',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
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
                      const SizedBox(height: 16),
                      if (_error != null) ...[
                        InfoBanner(message: _error!, isError: true),
                        const SizedBox(height: 16),
                      ],
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            SurfaceCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SectionHeading(
                                    title: '内容主区',
                                    subtitle: '先把标题、摘要和正文写完整，这部分决定文章质量。',
                                  ),
                                  const SizedBox(height: 18),
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
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _excerptController,
                                    minLines: 3,
                                    maxLines: 5,
                                    decoration: const InputDecoration(
                                      labelText: '摘要',
                                      hintText: '用于列表摘要、SEO 简述或卡片预览。',
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _contentController,
                                    minLines: 12,
                                    maxLines: 20,
                                    decoration: const InputDecoration(
                                      labelText: '正文',
                                      hintText: '支持直接填写原始正文内容。',
                                      alignLabelWithHint: true,
                                    ),
                                    validator: (value) {
                                      if ((value ?? '').trim().isEmpty) {
                                        return '请填写正文';
                                      }
                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            SurfaceCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SectionHeading(
                                    title: '结构与发布',
                                    subtitle: '这部分影响链接结构、发布时间和封面展示。',
                                  ),
                                  const SizedBox(height: 18),
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
                                            const SizedBox(height: 12),
                                            dateField,
                                          ],
                                        );
                                      }

                                      return Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(child: slugField),
                                          const SizedBox(width: 12),
                                          Expanded(child: dateField),
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 14),
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
                                            const SizedBox(height: 12),
                                            imageUrlField,
                                          ],
                                        );
                                      }

                                      return Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(child: mediaField),
                                          const SizedBox(width: 12),
                                          Expanded(child: imageUrlField),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            SurfaceCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SectionHeading(
                                    title: '分类与标签',
                                    subtitle: '用多选芯片处理引用数据，比传统下拉更适合移动端。',
                                  ),
                                  const SizedBox(height: 18),
                                  _TermSelector(
                                    title: '分类',
                                    emptyText: '当前没有分类可选。',
                                    items: _categories,
                                    selectedIds: _selectedCategoryIds,
                                    onToggle: (id) => _toggleSelection(
                                      _selectedCategoryIds,
                                      id,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  _TermSelector(
                                    title: '标签',
                                    emptyText: '当前没有标签可选。',
                                    items: _tags,
                                    selectedIds: _selectedTagIds,
                                    onToggle: (id) =>
                                        _toggleSelection(_selectedTagIds, id),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            SurfaceCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SectionHeading(
                                    title: '保存前检查',
                                    subtitle: '确保状态、摘要和正文都已经准备好，再提交到远端。',
                                  ),
                                  const SizedBox(height: 18),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
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
                                        label: _sticky ? '将作为置顶文章' : '普通文章',
                                      ),
                                    ],
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
    required this.title,
    required this.emptyText,
    required this.items,
    required this.selectedIds,
    required this.onToggle,
  });

  final String title;
  final String emptyText;
  final List<WpTerm> items;
  final Set<int> selectedIds;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 10),
        if (items.isEmpty)
          Text(emptyText, style: Theme.of(context).textTheme.bodySmall)
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: items.map((item) {
              return FilterChip(
                label: Text(item.name),
                selected: selectedIds.contains(item.id),
                onSelected: (_) => onToggle(item.id),
              );
            }).toList(),
          ),
      ],
    );
  }
}

class _ReviewPill extends StatelessWidget {
  const _ReviewPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.textMuted),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
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
