import 'package:flutter/material.dart';

import '../../core/cfblog_api.dart';
import '../../core/formatters.dart';
import '../../core/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_chrome.dart';

enum CommentScope { post, moment }

class CommentsScreen extends StatefulWidget {
  const CommentsScreen({super.key, required this.api});

  final CfblogApi api;

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  CommentScope _scope = CommentScope.post;
  String _status = 'all';
  bool _loading = true;
  String? _message;
  bool _isError = false;
  List<WpComment> _items = const [];
  int _page = 1;
  int _totalPages = 1;

  static const _statusOptions = <String>[
    'all',
    'approved',
    'pending',
    'spam',
    'trash',
  ];

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final result = _scope == CommentScope.post
          ? await widget.api.listComments(
              page: _page,
              perPage: 12,
              status: _status,
            )
          : await widget.api.listMomentComments(
              page: _page,
              perPage: 12,
              status: _status,
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

  Future<void> _openEditor({WpComment? comment}) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _CommentEditorSheet(api: widget.api, scope: _scope, comment: comment),
    );

    if (changed == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      await _loadComments();
      messenger.showSnackBar(
        SnackBar(content: Text(comment == null ? '评论已创建' : '评论已更新')),
      );
    }
  }

  Future<void> _changeStatus(WpComment item, String status) async {
    try {
      if (_scope == CommentScope.post) {
        await widget.api.updateComment(item.id, {'status': status});
      } else {
        await widget.api.updateMomentComment(item.moment, item.id, {
          'status': status,
        });
      }
      if (!mounted) {
        return;
      }
      await _loadComments();
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

  Future<void> _delete(WpComment item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除评论'),
        content: Text('确定要删除来自「${item.authorName}」的这条评论吗？'),
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
      if (_scope == CommentScope.post) {
        await widget.api.deleteComment(item.id);
      } else {
        await widget.api.deleteMomentComment(item.moment, item.id);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _isError = false;
        _message = '评论已删除';
      });
      await _loadComments();
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
    final isPost = _scope == CommentScope.post;
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
      onRefresh: _loadComments,
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
                      onPressed: _loadComments,
                      style: toolbarButtonStyle,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('刷新'),
                    ),
                    FilledButton.icon(
                      onPressed: () => _openEditor(),
                      style: toolbarButtonStyle,
                      icon: const Icon(Icons.add_comment_rounded),
                      label: Text(isPost ? '补录评论' : '补录动态评论'),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 10 : 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SelectionChipBar<CommentScope>(
                    items: CommentScope.values,
                    value: _scope,
                    labelBuilder: (scope) =>
                        scope == CommentScope.post ? '文章评论' : '动态评论',
                    onSelected: (scope) {
                      setState(() {
                        _scope = scope;
                        _page = 1;
                      });
                      _loadComments();
                    },
                  ),
                ),
                SizedBox(height: compact ? 10 : 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SelectionChipBar<String>(
                    items: _statusOptions,
                    value: _status,
                    labelBuilder: commentStatusLabel,
                    onSelected: (status) {
                      setState(() {
                        _status = status;
                        _page = 1;
                      });
                      _loadComments();
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
            const BootPanel(title: '正在加载评论', subtitle: '同步远程评论列表和当前筛选状态。')
          else if (_items.isEmpty)
            EmptyStateCard(
              title: isPost ? '当前没有文章评论' : '当前没有动态评论',
              subtitle: '可以切换状态筛选，或者手动补录一条评论。',
            )
          else
            ..._items.map(
              (item) => Padding(
                padding: EdgeInsets.only(bottom: compact ? 10 : 14),
                child: _CommentCard(
                  comment: item,
                  scope: _scope,
                  onEdit: () => _openEditor(comment: item),
                  onDelete: () => _delete(item),
                  onApprove: () => _changeStatus(item, 'approved'),
                  onPending: () => _changeStatus(item, 'pending'),
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
              _loadComments();
            },
            onNext: () {
              setState(() {
                _page += 1;
              });
              _loadComments();
            },
          ),
        ],
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({
    required this.comment,
    required this.scope,
    required this.onEdit,
    required this.onDelete,
    required this.onApprove,
    required this.onPending,
  });

  final WpComment comment;
  final CommentScope scope;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onApprove;
  final VoidCallback onPending;

  @override
  Widget build(BuildContext context) {
    final targetLabel = scope == CommentScope.post
        ? (comment.postTitle.isEmpty
              ? '文章 #${comment.post == 0 ? '-' : comment.post}'
              : comment.postTitle)
        : '动态 #${comment.moment == 0 ? '-' : comment.moment}';
    final compact = isCompactLayout(context);
    final author = comment.authorName.isEmpty ? '匿名用户' : comment.authorName;
    final content = stripHtml(comment.content);
    final preview = content.isEmpty ? targetLabel : '$author · $content';

    return SurfaceCard(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 10 : 12,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 900;
          final actions = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: onApprove,
                tooltip: '通过评论',
                icon: const Icon(Icons.check_circle_outline_rounded),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: onPending,
                tooltip: '标记待审',
                icon: const Icon(Icons.schedule_rounded),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: onEdit,
                tooltip: '编辑评论',
                icon: const Icon(Icons.edit_rounded),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: onDelete,
                tooltip: '删除评论',
                icon: const Icon(Icons.delete_outline_rounded),
                visualDensity: VisualDensity.compact,
              ),
            ],
          );

          final main = Row(
            children: [
              _CommentBadge(label: commentStatusLabel(comment.status)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  preview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: compact ? 122 : 180,
                child: Text(
                  '$targetLabel · ${formatCompactDate(comment.date)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                main,
                const SizedBox(height: 6),
                Align(alignment: Alignment.centerRight, child: actions),
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: main),
              const SizedBox(width: 4),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _CommentBadge extends StatelessWidget {
  const _CommentBadge({required this.label});

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

class _CommentEditorSheet extends StatefulWidget {
  const _CommentEditorSheet({
    required this.api,
    required this.scope,
    this.comment,
  });

  final CfblogApi api;
  final CommentScope scope;
  final WpComment? comment;

  @override
  State<_CommentEditorSheet> createState() => _CommentEditorSheetState();
}

class _CommentEditorSheetState extends State<_CommentEditorSheet> {
  late final TextEditingController _targetController;
  late final TextEditingController _parentController;
  late final TextEditingController _authorNameController;
  late final TextEditingController _authorEmailController;
  late final TextEditingController _authorUrlController;
  late final TextEditingController _authorIpController;
  late final TextEditingController _contentController;

  bool _saving = false;
  String? _error;
  String _status = 'approved';

  @override
  void initState() {
    super.initState();
    final comment = widget.comment;
    _targetController = TextEditingController(
      text: widget.scope == CommentScope.post
          ? '${comment?.post == 0 || comment == null ? '' : comment.post}'
          : '${comment?.moment == 0 || comment == null ? '' : comment.moment}',
    );
    _parentController = TextEditingController(
      text: comment == null || comment.parent == 0 ? '' : '${comment.parent}',
    );
    _authorNameController = TextEditingController(
      text: comment?.authorName ?? '',
    );
    _authorEmailController = TextEditingController(
      text: comment?.authorEmail ?? '',
    );
    _authorUrlController = TextEditingController(
      text: comment?.authorUrl ?? '',
    );
    _authorIpController = TextEditingController(text: comment?.authorIp ?? '');
    _contentController = TextEditingController(
      text: comment == null ? '' : stripHtml(comment.content),
    );
    _status = comment?.status.isEmpty == false ? comment!.status : 'approved';
  }

  @override
  void dispose() {
    _targetController.dispose();
    _parentController.dispose();
    _authorNameController.dispose();
    _authorEmailController.dispose();
    _authorUrlController.dispose();
    _authorIpController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final payload = <String, dynamic>{
      widget.scope == CommentScope.post ? 'post' : 'moment': int.tryParse(
        _targetController.text.trim(),
      ),
      'parent': int.tryParse(_parentController.text.trim()),
      'status': _status,
      'author_name': _authorNameController.text.trim(),
      'author_email': _authorEmailController.text.trim(),
      'author_url': _authorUrlController.text.trim(),
      'author_ip': _authorIpController.text.trim(),
      'content': _contentController.text.trim(),
    }..removeWhere((key, value) => value == null || value == '');

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      if (widget.scope == CommentScope.post) {
        if (widget.comment == null) {
          await widget.api.createComment(payload);
        } else {
          await widget.api.updateComment(widget.comment!.id, payload);
        }
      } else {
        final momentId =
            int.tryParse(_targetController.text.trim()) ??
            widget.comment?.moment ??
            0;
        if (widget.comment == null) {
          await widget.api.createMomentComment(momentId, payload);
        } else {
          await widget.api.updateMomentComment(
            momentId,
            widget.comment!.id,
            payload,
          );
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
    final title = widget.comment == null
        ? (widget.scope == CommentScope.post ? '补录评论' : '补录动态评论')
        : '编辑评论';

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
                    title: title,
                    subtitle: '处理状态、作者信息和评论内容，适合快速审核或手工补录。',
                  ),
                  const SizedBox(height: 18),
                  if (_error != null) ...[
                    InfoBanner(message: _error!, isError: true),
                    const SizedBox(height: 16),
                  ],
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _CommentsScreenState._statusOptions
                        .where((item) => item != 'all')
                        .map(
                          (item) => ChoiceChip(
                            label: Text(commentStatusLabel(item)),
                            selected: _status == item,
                            onSelected: (_) {
                              setState(() {
                                _status = item;
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _targetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: widget.scope == CommentScope.post
                          ? '文章 ID'
                          : '动态 ID',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _parentController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: '父评论 ID'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _authorNameController,
                    decoration: const InputDecoration(labelText: '作者名'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _authorEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: '作者邮箱'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _authorUrlController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(labelText: '作者网址'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _authorIpController,
                    decoration: const InputDecoration(labelText: '作者 IP'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _contentController,
                    minLines: 4,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: '评论内容',
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
