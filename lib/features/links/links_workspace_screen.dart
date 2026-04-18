import 'package:flutter/material.dart';

import '../../core/cfblog_api.dart';
import '../../core/formatters.dart';
import '../../core/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_chrome.dart';

enum _LinksWorkspaceKind { links, categories }

class LinksWorkspaceScreen extends StatefulWidget {
  const LinksWorkspaceScreen({super.key, required this.api});

  final CfblogApi api;

  @override
  State<LinksWorkspaceScreen> createState() => _LinksWorkspaceScreenState();
}

class _LinksWorkspaceScreenState extends State<LinksWorkspaceScreen> {
  _LinksWorkspaceKind _kind = _LinksWorkspaceKind.links;
  bool _loading = true;
  bool _isError = false;
  String? _message;
  List<WpLink> _links = const [];
  List<WpLinkCategory> _allCategories = const [];
  List<WpLinkCategory> _categoryItems = const [];
  int _page = 1;
  int _totalPages = 1;
  String _visible = 'yes';

  bool get _isLinks => _kind == _LinksWorkspaceKind.links;

  @override
  void initState() {
    super.initState();
    _loadWorkspace();
  }

  Future<void> _loadWorkspace({bool refresh = false}) async {
    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final categoriesFuture = widget.api.listLinkCategories(refresh: refresh);
      if (_isLinks) {
        final results = await Future.wait<Object>([
          categoriesFuture,
          widget.api.listLinks(
            page: _page,
            perPage: 12,
            visible: _visible,
            refresh: refresh,
          ),
        ]);
        if (!mounted) {
          return;
        }
        final categories = results[0] as List<WpLinkCategory>;
        final links = results[1] as PagedResponse<WpLink>;
        setState(() {
          _allCategories = categories;
          _categoryItems = const [];
          _links = links.items;
          _totalPages = links.totalPages;
          _isError = false;
        });
      } else {
        final categories = await categoriesFuture;
        if (!mounted) {
          return;
        }
        final start = (_page - 1) * 12;
        final pageItems = categories.skip(start).take(12).toList();
        setState(() {
          _allCategories = categories;
          _categoryItems = pageItems;
          _links = const [];
          _totalPages = categories.isEmpty
              ? 1
              : (categories.length / 12).ceil();
          _isError = false;
        });
      }
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

  void _switchKind(_LinksWorkspaceKind kind) {
    if (_kind == kind) {
      return;
    }
    setState(() {
      _kind = kind;
      _page = 1;
      _totalPages = 1;
    });
    _loadWorkspace();
  }

  Future<void> _openLinkEditor({WpLink? link}) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LinkEditorSheet(
        api: widget.api,
        categories: _allCategories,
        link: link,
      ),
    );

    if (changed == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      await _loadWorkspace();
      messenger.showSnackBar(
        SnackBar(content: Text(link == null ? '友链已创建' : '友链已更新')),
      );
    }
  }

  Future<void> _openCategoryEditor({WpLinkCategory? category}) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _LinkCategoryEditorSheet(api: widget.api, category: category),
    );

    if (changed == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      await _loadWorkspace();
      messenger.showSnackBar(
        SnackBar(content: Text(category == null ? '友链分类已创建' : '友链分类已更新')),
      );
    }
  }

  Future<void> _deleteLink(WpLink link) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除友链'),
        content: Text('确定要删除「${link.name}」吗？'),
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
      await widget.api.deleteLink(link.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _isError = false;
        _message = '友链已删除';
      });
      await _loadWorkspace();
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

  Future<void> _deleteCategory(WpLinkCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除友链分类'),
        content: Text('确定要删除「${category.name}」吗？'),
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
      await widget.api.deleteLinkCategory(category.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _isError = false;
        _message = '友链分类已删除';
      });
      await _loadWorkspace();
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
      onRefresh: () => _loadWorkspace(refresh: true),
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
                      onPressed: () => _loadWorkspace(refresh: true),
                      style: toolbarButtonStyle,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('刷新'),
                    ),
                    FilledButton.icon(
                      onPressed: _isLinks
                          ? () => _openLinkEditor()
                          : () => _openCategoryEditor(),
                      style: toolbarButtonStyle,
                      icon: Icon(
                        _isLinks
                            ? Icons.add_link_rounded
                            : Icons.label_rounded,
                      ),
                      label: Text(_isLinks ? '新建友链' : '新建友链分类'),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 10 : 12),
                SegmentedButton<_LinksWorkspaceKind>(
                  segments: const [
                    ButtonSegment<_LinksWorkspaceKind>(
                      value: _LinksWorkspaceKind.links,
                      icon: Icon(Icons.link_rounded),
                      label: Text('友链'),
                    ),
                    ButtonSegment<_LinksWorkspaceKind>(
                      value: _LinksWorkspaceKind.categories,
                      icon: Icon(Icons.account_tree_rounded),
                      label: Text('友链分类'),
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
                if (_isLinks) ...[
                  SizedBox(height: compact ? 10 : 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SelectionChipBar<String>(
                      items: const ['yes', 'no'],
                      value: _visible,
                      labelBuilder: visibleLabel,
                      onSelected: (visible) {
                        setState(() {
                          _visible = visible;
                          _page = 1;
                        });
                        _loadWorkspace();
                      },
                    ),
                  ),
                ],
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
              title: _isLinks ? '正在加载友链' : '正在加载友链分类',
              subtitle: '同步站点链接配置和当前筛选状态。',
            )
          else if (_isLinks && _links.isEmpty)
            const EmptyStateCard(
              title: '当前没有友链',
              subtitle: '先建一个分类，再添加常用站点和推荐链接。',
            )
          else if (!_isLinks && _categoryItems.isEmpty)
            const EmptyStateCard(
              title: '当前没有友链分类',
              subtitle: '建立分类后，友链列表的归类和排序会更清晰。',
            )
          else if (_isLinks)
            ..._links.map(
              (link) => Padding(
                padding: EdgeInsets.only(bottom: compact ? 10 : 14),
                child: _LinkCard(
                  link: link,
                  onEdit: () => _openLinkEditor(link: link),
                  onDelete: () => _deleteLink(link),
                ),
              ),
            )
          else
            ..._categoryItems.map(
              (category) => Padding(
                padding: EdgeInsets.only(bottom: compact ? 10 : 14),
                child: _LinkCategoryCard(
                  category: category,
                  onEdit: () => _openCategoryEditor(category: category),
                  onDelete: () => _deleteCategory(category),
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
              _loadWorkspace();
            },
            onNext: () {
              setState(() {
                _page += 1;
              });
              _loadWorkspace();
            },
          ),
        ],
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({
    required this.link,
    required this.onEdit,
    required this.onDelete,
  });

  final WpLink link;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactLayout(context);
    final title = link.name.isEmpty ? '未命名友链' : link.name;
    final category = link.category?.name.isNotEmpty == true
        ? link.category!.name
        : '未分类';
    return SurfaceCard(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 10 : 12,
      ),
      child: Row(
        children: [
          _LinkAvatar(url: link.avatar, label: title),
          const SizedBox(width: 10),
          _LinkBadge(
            label: visibleLabel(link.visible),
            tint: AppTheme.success,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$title · $category',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: compact ? 98 : 132,
            child: Text(
              formatCompactDate(
                link.updatedAt.isEmpty ? link.createdAt : link.updatedAt,
              ),
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
            tooltip: '编辑友链',
            icon: const Icon(Icons.edit_rounded),
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: '删除友链',
            icon: const Icon(Icons.delete_outline_rounded),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _LinkCategoryCard extends StatelessWidget {
  const _LinkCategoryCard({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  final WpLinkCategory category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactLayout(context);
    return SurfaceCard(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 10 : 12,
      ),
      child: Row(
        children: [
          _LinkBadge(label: '友链分类', tint: const Color(0xFF7A5A25)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${category.name.isEmpty ? '未命名分类' : category.name} · ${category.count} 条',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: onEdit,
            tooltip: '编辑友链分类',
            icon: const Icon(Icons.edit_rounded),
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            onPressed: onDelete,
            tooltip: '删除友链分类',
            icon: const Icon(Icons.delete_outline_rounded),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _LinkBadge extends StatelessWidget {
  const _LinkBadge({required this.label, required this.tint});

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

class _LinkAvatar extends StatelessWidget {
  const _LinkAvatar({required this.url, required this.label});

  final String url;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          url,
          width: 42,
          height: 42,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _AvatarFallback(label: label),
        ),
      );
    }
    return _AvatarFallback(label: label);
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppTheme.accentSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        (label.isEmpty ? 'L' : label.characters.first).toUpperCase(),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppTheme.inkPanel,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LinkEditorSheet extends StatefulWidget {
  const _LinkEditorSheet({
    required this.api,
    required this.categories,
    this.link,
  });

  final CfblogApi api;
  final List<WpLinkCategory> categories;
  final WpLink? link;

  bool get isEditing => link != null;

  @override
  State<_LinkEditorSheet> createState() => _LinkEditorSheetState();
}

class _LinkEditorSheetState extends State<_LinkEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _urlController;
  late final TextEditingController _avatarController;
  late final TextEditingController _categoryIdController;
  late final TextEditingController _ratingController;
  late final TextEditingController _sortOrderController;
  late final TextEditingController _descriptionController;

  bool _saving = false;
  String? _error;
  int? _selectedCategoryId;
  String _target = '_blank';
  String _visible = 'yes';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.link?.name ?? '');
    _urlController = TextEditingController(text: widget.link?.url ?? '');
    _avatarController = TextEditingController(text: widget.link?.avatar ?? '');
    _categoryIdController = TextEditingController(
      text: widget.link?.category?.id != null
          ? '${widget.link!.category!.id}'
          : '',
    );
    _ratingController = TextEditingController(
      text: widget.link == null ? '0' : '${widget.link!.rating}',
    );
    _sortOrderController = TextEditingController(
      text: widget.link == null ? '0' : '${widget.link!.sortOrder}',
    );
    _descriptionController = TextEditingController(
      text: widget.link?.description ?? '',
    );
    _selectedCategoryId = widget.link?.category?.id ?? _defaultCategoryId;
    _target = widget.link?.target.isNotEmpty == true
        ? widget.link!.target
        : '_blank';
    _visible = widget.link?.visible.isNotEmpty == true
        ? widget.link!.visible
        : 'yes';
  }

  int? get _defaultCategoryId =>
      widget.categories.isEmpty ? null : widget.categories.first.id;

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _avatarController.dispose();
    _categoryIdController.dispose();
    _ratingController.dispose();
    _sortOrderController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty ||
        _urlController.text.trim().isEmpty) {
      setState(() {
        _error = '名称和链接地址不能为空';
      });
      return;
    }

    final categoryId =
        _selectedCategoryId ??
        int.tryParse(_categoryIdController.text.trim()) ??
        _defaultCategoryId;
    if (categoryId == null) {
      setState(() {
        _error = '请先提供友链分类';
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'url': _urlController.text.trim(),
      'avatar': _avatarController.text.trim(),
      'category_id': categoryId,
      'target': _target,
      'visible': _visible,
      'rating': int.tryParse(_ratingController.text.trim()) ?? 0,
      'sort_order': int.tryParse(_sortOrderController.text.trim()) ?? 0,
      'description': _descriptionController.text.trim(),
    };

    try {
      if (widget.isEditing) {
        await widget.api.updateLink(widget.link!.id, payload);
      } else {
        await widget.api.createLink(payload);
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
                  SectionHeading(
                    title: widget.isEditing ? '编辑友链' : '新建友链',
                    subtitle: '优先处理名称、分类和展示状态，再补头像、描述和排序。',
                  ),
                  const SizedBox(height: 18),
                  if (_error != null) ...[
                    InfoBanner(message: _error!, isError: true),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: '名称'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _urlController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(labelText: '链接地址'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _avatarController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(labelText: '头像 URL'),
                  ),
                  const SizedBox(height: 14),
                  if (widget.categories.isNotEmpty)
                    DropdownButtonFormField<int>(
                      initialValue: _selectedCategoryId,
                      items: widget.categories
                          .map(
                            (category) => DropdownMenuItem<int>(
                              value: category.id,
                              child: Text(category.name),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryId = value;
                        });
                      },
                      decoration: const InputDecoration(labelText: '所属分类'),
                    )
                  else
                    TextField(
                      controller: _categoryIdController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '所属分类 ID'),
                    ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked = constraints.maxWidth < 720;
                      final targetField = DropdownButtonFormField<String>(
                        initialValue: _target,
                        items: const [
                          DropdownMenuItem(value: '_blank', child: Text('新窗口')),
                          DropdownMenuItem(value: '_self', child: Text('当前窗口')),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _target = value;
                          });
                        },
                        decoration: const InputDecoration(labelText: '打开方式'),
                      );

                      final visibleField = DropdownButtonFormField<String>(
                        initialValue: _visible,
                        items: const [
                          DropdownMenuItem(value: 'yes', child: Text('展示')),
                          DropdownMenuItem(value: 'no', child: Text('隐藏')),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _visible = value;
                          });
                        },
                        decoration: const InputDecoration(labelText: '展示状态'),
                      );

                      if (stacked) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            targetField,
                            const SizedBox(height: 12),
                            visibleField,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: targetField),
                          const SizedBox(width: 12),
                          Expanded(child: visibleField),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked = constraints.maxWidth < 720;
                      final ratingField = TextField(
                        controller: _ratingController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '评分'),
                      );
                      final sortField = TextField(
                        controller: _sortOrderController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: '排序'),
                      );

                      if (stacked) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ratingField,
                            const SizedBox(height: 12),
                            sortField,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: ratingField),
                          const SizedBox(width: 12),
                          Expanded(child: sortField),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _descriptionController,
                    minLines: 4,
                    maxLines: 7,
                    decoration: const InputDecoration(
                      labelText: '描述',
                      hintText: '简单说明站点内容、推荐理由或合作关系。',
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

class _LinkCategoryEditorSheet extends StatefulWidget {
  const _LinkCategoryEditorSheet({required this.api, this.category});

  final CfblogApi api;
  final WpLinkCategory? category;

  bool get isEditing => category != null;

  @override
  State<_LinkCategoryEditorSheet> createState() =>
      _LinkCategoryEditorSheetState();
}

class _LinkCategoryEditorSheetState extends State<_LinkCategoryEditorSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _slugController;
  late final TextEditingController _descriptionController;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _slugController = TextEditingController(text: widget.category?.slug ?? '');
    _descriptionController = TextEditingController(
      text: widget.category?.description ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _error = '分类名称不能为空';
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
    }..removeWhere((key, value) => value == null);

    try {
      if (widget.isEditing) {
        await widget.api.updateLinkCategory(widget.category!.id, payload);
      } else {
        await widget.api.createLinkCategory(payload);
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
                  SectionHeading(
                    title: widget.isEditing ? '编辑友链分类' : '新建友链分类',
                    subtitle: '先定义分类名称和语义，再回到友链列表做归类与排序。',
                  ),
                  const SizedBox(height: 18),
                  if (_error != null) ...[
                    InfoBanner(message: _error!, isError: true),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: '名称'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _slugController,
                    decoration: const InputDecoration(labelText: 'Slug'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _descriptionController,
                    minLines: 4,
                    maxLines: 7,
                    decoration: const InputDecoration(
                      labelText: '描述',
                      hintText: '说明这个分类承载哪些友链或推荐场景。',
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
