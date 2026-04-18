import 'package:flutter/material.dart';

import '../../core/cfblog_api.dart';
import '../../core/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_chrome.dart';

enum _TaxonomyKind { category, tag }

class TaxonomiesScreen extends StatefulWidget {
  const TaxonomiesScreen({super.key, required this.api});

  final CfblogApi api;

  @override
  State<TaxonomiesScreen> createState() => _TaxonomiesScreenState();
}

class _TaxonomiesScreenState extends State<TaxonomiesScreen> {
  final TextEditingController _searchController = TextEditingController();

  _TaxonomyKind _kind = _TaxonomyKind.category;
  bool _loading = true;
  bool _isError = false;
  String? _message;
  List<WpTerm> _items = const [];
  int _page = 1;
  int _totalPages = 1;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadTerms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _isCategory => _kind == _TaxonomyKind.category;

  String get _createLabel => _isCategory ? '新建分类' : '新建标签';

  Future<void> _loadTerms({bool refresh = false}) async {
    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final result = _isCategory
          ? await widget.api.listCategories(
              page: _page,
              perPage: 12,
              search: _search,
              refresh: refresh,
            )
          : await widget.api.listTags(
              page: _page,
              perPage: 12,
              search: _search,
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

  void _submitSearch() {
    setState(() {
      _page = 1;
      _search = _searchController.text.trim();
    });
    _loadTerms();
  }

  Future<void> _openEditor({WpTerm? term}) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _TaxonomyEditorSheet(api: widget.api, kind: _kind, term: term),
    );

    if (changed == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      await _loadTerms();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            term == null
                ? (_isCategory ? '分类已创建' : '标签已创建')
                : (_isCategory ? '分类已更新' : '标签已更新'),
          ),
        ),
      );
    }
  }

  Future<void> _delete(WpTerm term) async {
    final noun = _isCategory ? '分类' : '标签';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('删除$noun'),
        content: Text('确定要删除「${term.name}」吗？'),
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
      if (_isCategory) {
        await widget.api.deleteCategory(term.id);
      } else {
        await widget.api.deleteTag(term.id);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _isError = false;
        _message = '$noun已删除';
      });
      await _loadTerms();
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

  void _switchKind(_TaxonomyKind kind) {
    if (_kind == kind) {
      return;
    }
    setState(() {
      _kind = kind;
      _page = 1;
      _totalPages = 1;
      _search = '';
      _searchController.clear();
    });
    _loadTerms();
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
      onRefresh: () => _loadTerms(refresh: true),
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
                      onPressed: () => _loadTerms(refresh: true),
                      style: toolbarButtonStyle,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('刷新'),
                    ),
                    FilledButton.icon(
                      onPressed: () => _openEditor(),
                      style: toolbarButtonStyle,
                      icon: Icon(
                        _isCategory
                            ? Icons.create_new_folder_rounded
                            : Icons.sell_rounded,
                      ),
                      label: Text(_createLabel),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 10 : 12),
                SegmentedButton<_TaxonomyKind>(
                  segments: const [
                    ButtonSegment<_TaxonomyKind>(
                      value: _TaxonomyKind.category,
                      icon: Icon(Icons.folder_copy_rounded),
                      label: Text('分类'),
                    ),
                    ButtonSegment<_TaxonomyKind>(
                      value: _TaxonomyKind.tag,
                      icon: Icon(Icons.local_offer_rounded),
                      label: Text('标签'),
                    ),
                  ],
                  selected: {_kind},
                  onSelectionChanged: (selection) {
                    if (selection.isEmpty) {
                      return;
                    }
                    _switchKind(selection.first);
                  },
                ),
                SizedBox(height: compact ? 10 : 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 860;
                    final searchField = TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _submitSearch(),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: _isCategory ? '搜索分类' : '搜索标签',
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
                        children: [searchField],
                      );
                    }

                    return Row(children: [Expanded(child: searchField)]);
                  },
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
            BootPanel(
              title: _isCategory ? '正在加载分类' : '正在加载标签',
              subtitle: '同步远程内容结构和当前筛选结果。',
            )
          else if (_items.isEmpty)
            EmptyStateCard(
              title: _isCategory ? '当前没有分类' : '当前没有标签',
              subtitle: _isCategory
                  ? '创建几个核心分类后，文章编辑时就能直接挂接结构。'
                  : '建立清晰的主题标签后，文章检索和聚合会更顺手。',
            )
          else
            ..._items.map(
              (term) => Padding(
                padding: EdgeInsets.only(bottom: compact ? 10 : 14),
                child: _TaxonomyCard(
                  kind: _kind,
                  term: term,
                  onEdit: () => _openEditor(term: term),
                  onDelete: () => _delete(term),
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
              _loadTerms();
            },
            onNext: () {
              setState(() {
                _page += 1;
              });
              _loadTerms();
            },
          ),
        ],
      ),
    );
  }
}

class _TaxonomyCard extends StatelessWidget {
  const _TaxonomyCard({
    required this.kind,
    required this.term,
    required this.onEdit,
    required this.onDelete,
  });

  final _TaxonomyKind kind;
  final WpTerm term;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  bool get _isCategory => kind == _TaxonomyKind.category;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactLayout(context);
    final title =
        term.name.isEmpty ? (_isCategory ? '未命名分类' : '未命名标签') : term.name;
    return SurfaceCard(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 10 : 12,
      ),
      child: Row(
        children: [
          _TermBadge(
            label: _isCategory ? '分类' : '标签',
            tint: _isCategory ? const Color(0xFF21544B) : AppTheme.accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$title · ${term.count} 篇',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          if (_isCategory && term.parent > 0) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.subdirectory_arrow_right_rounded,
              size: 16,
              color: AppTheme.textMuted,
            ),
          ],
          const SizedBox(width: 4),
          IconButton(
            onPressed: onEdit,
            tooltip: _isCategory ? '编辑分类' : '编辑标签',
            icon: const Icon(Icons.edit_rounded),
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: _isCategory ? '删除分类' : '删除标签',
            icon: const Icon(Icons.delete_outline_rounded),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _TermBadge extends StatelessWidget {
  const _TermBadge({required this.label, required this.tint});

  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: tint,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _TaxonomyEditorSheet extends StatefulWidget {
  const _TaxonomyEditorSheet({
    required this.api,
    required this.kind,
    this.term,
  });

  final CfblogApi api;
  final _TaxonomyKind kind;
  final WpTerm? term;

  bool get isEditing => term != null;
  bool get isCategory => kind == _TaxonomyKind.category;

  @override
  State<_TaxonomyEditorSheet> createState() => _TaxonomyEditorSheetState();
}

class _TaxonomyEditorSheetState extends State<_TaxonomyEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _slugController;
  late final TextEditingController _parentController;
  late final TextEditingController _descriptionController;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.term?.name ?? '');
    _slugController = TextEditingController(text: widget.term?.slug ?? '');
    _parentController = TextEditingController(
      text: widget.term == null || widget.term!.parent == 0
          ? ''
          : '${widget.term!.parent}',
    );
    _descriptionController = TextEditingController(
      text: widget.term?.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _parentController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _error = widget.isCategory ? '分类名称不能为空' : '标签名称不能为空';
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'slug': _slugController.text.trim().isEmpty
          ? null
          : _slugController.text.trim(),
      'description': _descriptionController.text.trim(),
      if (widget.isCategory)
        'parent': int.tryParse(_parentController.text.trim()),
    }..removeWhere((key, value) => value == null);

    try {
      if (widget.isCategory) {
        if (widget.isEditing) {
          await widget.api.updateCategory(widget.term!.id, payload);
        } else {
          await widget.api.createCategory(payload);
        }
      } else {
        if (widget.isEditing) {
          await widget.api.updateTag(widget.term!.id, payload);
        } else {
          await widget.api.createTag(payload);
        }
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
    final noun = widget.isCategory ? '分类' : '标签';
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
                  SectionHeading(
                    title: widget.isEditing ? '编辑$noun' : '新建$noun',
                    subtitle: widget.isCategory
                        ? '优先保证名称、slug 和层级清晰，文章归档会更稳定。'
                        : '标签更适合轻量补充主题，保持简洁会更易维护。',
                  ),
                  const SizedBox(height: 18),
                  if (_error != null) ...[
                    InfoBanner(message: _error!, isError: true),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: '$noun名称'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _slugController,
                    decoration: const InputDecoration(labelText: 'Slug'),
                  ),
                  if (widget.isCategory) ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: _parentController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '父分类 ID'),
                    ),
                  ],
                  const SizedBox(height: 14),
                  TextField(
                    controller: _descriptionController,
                    minLines: 4,
                    maxLines: 7,
                    decoration: InputDecoration(
                      labelText: '描述',
                      hintText: widget.isCategory
                          ? '介绍这个分类适合承载哪些文章。'
                          : '描述标签的使用场景和主题边界。',
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
