import 'package:flutter/material.dart';

import '../../core/cfblog_api.dart';
import '../../core/formatters.dart';
import '../../core/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_chrome.dart';

enum _SystemKind { users, settings }

enum _SettingFieldType {
  text,
  textarea,
  multiline,
  email,
  url,
  password,
  toggle,
}

class SystemWorkspaceScreen extends StatefulWidget {
  const SystemWorkspaceScreen({
    super.key,
    required this.api,
    required this.session,
  });

  final CfblogApi api;
  final SessionState session;

  @override
  State<SystemWorkspaceScreen> createState() => _SystemWorkspaceScreenState();
}

class _SystemWorkspaceScreenState extends State<SystemWorkspaceScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, TextEditingController> _settingControllers =
      <String, TextEditingController>{};
  final Map<String, bool> _settingToggles = <String, bool>{};

  _SystemKind _kind = _SystemKind.users;
  bool _loading = true;
  bool _savingSettings = false;
  bool _isError = false;
  String? _message;

  List<SessionUser> _users = const [];
  int _page = 1;
  int _total = 0;
  int _totalPages = 1;
  String _search = '';
  String _role = '';

  bool get _isUsers => _kind == _SystemKind.users;
  bool get _isAdmin => widget.session.user.primaryRole == 'administrator';

  @override
  void initState() {
    super.initState();
    for (final section in _settingsSections) {
      for (final field in section.fields) {
        if (field.type == _SettingFieldType.toggle) {
          _settingToggles[field.key] = false;
        } else {
          _settingControllers[field.key] = TextEditingController();
        }
      }
    }
    _loadCurrent();
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (final controller in _settingControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCurrent() async {
    if (_isUsers) {
      await _loadUsers();
    } else {
      await _loadSettings();
    }
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final result = await widget.api.listUsers(
        page: _page,
        perPage: 12,
        search: _search,
        role: _role,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _users = result.items;
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

  Future<void> _loadSettings() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final data = await widget.api.getSettings(admin: _isAdmin);
      for (final section in _settingsSections) {
        for (final field in section.fields) {
          if (field.type == _SettingFieldType.toggle) {
            final defaultValue = switch (field.key) {
              'mail_notifications_enabled' => data[field.key] == '1',
              'notify_admin_on_comment' => data[field.key] != '0',
              'notify_commenter_on_reply' => data[field.key] != '0',
              _ => data[field.key] == '1',
            };
            _settingToggles[field.key] = defaultValue;
          } else {
            final controller = _settingControllers[field.key]!;
            controller.text = field.key == 'webhook_events'
                ? (data[field.key] ?? '').split(',').join('\n')
                : (data[field.key] ?? '');
          }
        }
      }

      if (!mounted) {
        return;
      }
      setState(() {
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

  void _switchKind(_SystemKind kind) {
    if (_kind == kind) {
      return;
    }
    setState(() {
      _kind = kind;
      _message = null;
      _isError = false;
      if (kind == _SystemKind.users) {
        _page = 1;
      }
    });
    _loadCurrent();
  }

  void _submitSearch() {
    setState(() {
      _search = _searchController.text.trim();
      _page = 1;
    });
    _loadUsers();
  }

  Future<void> _saveSettings() async {
    if (!_isAdmin) {
      setState(() {
        _isError = true;
        _message = '当前账号不是管理员，不能保存设置。';
      });
      return;
    }

    setState(() {
      _savingSettings = true;
      _message = null;
    });

    final payload = <String, String>{};
    for (final section in _settingsSections) {
      for (final field in section.fields) {
        if (field.type == _SettingFieldType.toggle) {
          payload[field.key] = (_settingToggles[field.key] ?? false)
              ? '1'
              : '0';
        } else if (field.key == 'webhook_events') {
          payload[field.key] = _settingControllers[field.key]!.text
              .split('\n')
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .join(',');
        } else {
          payload[field.key] = _settingControllers[field.key]!.text.trim();
        }
      }
    }

    try {
      await widget.api.updateSettings(payload);
      if (!mounted) {
        return;
      }
      setState(() {
        _isError = false;
        _message = '设置已保存';
      });
      await _loadSettings();
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
          _savingSettings = false;
        });
      }
    }
  }

  Future<void> _openUserEditor({SessionUser? user}) async {
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _UserEditorSheet(api: widget.api, user: user),
    );

    if (changed == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      await _loadUsers();
      messenger.showSnackBar(
        SnackBar(content: Text(user == null ? '用户已创建' : '用户已更新')),
      );
    }
  }

  Future<void> _deleteUser(SessionUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除用户'),
        content: Text('确定要删除「${user.name}」吗？'),
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
      await widget.api.deleteUser(user.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _isError = false;
        _message = '用户已删除';
      });
      await _loadUsers();
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
      onRefresh: _loadCurrent,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        children: [
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeading(
                  title: '系统管理',
                  subtitle: _isUsers
                      ? '集中处理成员账号、角色和资料字段，保持后台权限边界清晰。'
                      : '站点基础、通知和社交资料统一在这里维护，减少配置分散。',
                  trailing: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.tonalIcon(
                        onPressed: _loadCurrent,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('刷新'),
                      ),
                      if (_isUsers)
                        FilledButton.icon(
                          onPressed: _isAdmin ? () => _openUserEditor() : null,
                          icon: const Icon(Icons.person_add_alt_1_rounded),
                          label: const Text('新建用户'),
                        )
                      else
                        FilledButton.icon(
                          onPressed: _savingSettings || !_isAdmin
                              ? null
                              : _saveSettings,
                          icon: _savingSettings
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_rounded),
                          label: Text(_savingSettings ? '保存中...' : '保存设置'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SegmentedButton<_SystemKind>(
                  segments: const [
                    ButtonSegment<_SystemKind>(
                      value: _SystemKind.users,
                      icon: Icon(Icons.people_alt_rounded),
                      label: Text('用户'),
                    ),
                    ButtonSegment<_SystemKind>(
                      value: _SystemKind.settings,
                      icon: Icon(Icons.settings_suggest_rounded),
                      label: Text('设置'),
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
                if (_isUsers) ...[
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked = constraints.maxWidth < 720;
                      final searchField = TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _submitSearch(),
                        decoration: const InputDecoration(
                          labelText: '搜索用户',
                          hintText: '按用户名、邮箱或显示名搜索',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                      );

                      final roleField = DropdownButtonFormField<String>(
                        initialValue: _role,
                        items: const [
                          DropdownMenuItem(value: '', child: Text('全部角色')),
                          DropdownMenuItem(
                            value: 'administrator',
                            child: Text('管理员'),
                          ),
                          DropdownMenuItem(value: 'editor', child: Text('编辑')),
                          DropdownMenuItem(value: 'author', child: Text('作者')),
                          DropdownMenuItem(
                            value: 'contributor',
                            child: Text('投稿者'),
                          ),
                          DropdownMenuItem(
                            value: 'subscriber',
                            child: Text('订阅者'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _role = value ?? '';
                            _page = 1;
                          });
                          _loadUsers();
                        },
                        decoration: const InputDecoration(labelText: '角色筛选'),
                      );

                      if (stacked) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            searchField,
                            const SizedBox(height: 12),
                            roleField,
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _submitSearch,
                              child: const Text('搜索'),
                            ),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: searchField),
                          const SizedBox(width: 12),
                          SizedBox(width: 180, child: roleField),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: _submitSearch,
                            child: const Text('搜索'),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '当前共 $_total 位用户，第 $_page / $_totalPages 页',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  Text(
                    _isAdmin
                        ? '当前账号拥有管理员权限，可以直接保存系统设置。'
                        : '当前账号不是管理员，仅可查看公开或授权可见的设置字段。',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_message != null) ...[
            InfoBanner(message: _message!, isError: _isError),
            const SizedBox(height: 16),
          ],
          if (!_isAdmin) ...[
            InfoBanner(
              message: _isUsers
                  ? '非管理员建议只做查看，用户新增、编辑和删除通常会被后端拒绝。'
                  : '非管理员不能保存系统设置。',
              isError: false,
            ),
            const SizedBox(height: 16),
          ],
          if (_loading)
            BootPanel(
              title: _isUsers ? '正在加载用户' : '正在加载设置',
              subtitle: _isUsers ? '同步用户列表和角色筛选结果。' : '同步站点配置与系统选项。',
            )
          else if (_isUsers)
            ..._buildUsersContent(context)
          else
            ..._buildSettingsContent(context),
        ],
      ),
    );
  }

  List<Widget> _buildUsersContent(BuildContext context) {
    if (_users.isEmpty) {
      return const [
        EmptyStateCard(title: '当前没有用户', subtitle: '创建账号后，就可以继续分配角色、头像和简介资料。'),
      ];
    }

    return [
      ..._users.map(
        (user) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: _UserCard(
            user: user,
            canManage: _isAdmin,
            onEdit: () => _openUserEditor(user: user),
            onDelete: () => _deleteUser(user),
          ),
        ),
      ),
      const SizedBox(height: 4),
      PaginationCard(
        currentPage: _page,
        totalPages: _totalPages,
        onPrevious: () {
          setState(() {
            _page -= 1;
          });
          _loadUsers();
        },
        onNext: () {
          setState(() {
            _page += 1;
          });
          _loadUsers();
        },
      ),
    ];
  }

  List<Widget> _buildSettingsContent(BuildContext context) {
    return _settingsSections
        .map(
          (section) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeading(
                    title: section.title,
                    subtitle: section.subtitle,
                  ),
                  const SizedBox(height: 18),
                  ...section.fields.expand((field) {
                    return [
                      _buildSettingField(field),
                      const SizedBox(height: 14),
                    ];
                  }).toList()..removeLast(),
                ],
              ),
            ),
          ),
        )
        .toList();
  }

  Widget _buildSettingField(_SettingField field) {
    if (field.type == _SettingFieldType.toggle) {
      return Container(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    field.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (field.helper.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      field.helper,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Switch(
              value: _settingToggles[field.key] ?? false,
              onChanged: !_isAdmin
                  ? null
                  : (value) {
                      setState(() {
                        _settingToggles[field.key] = value;
                      });
                    },
            ),
          ],
        ),
      );
    }

    final controller = _settingControllers[field.key]!;
    final keyboardType = switch (field.type) {
      _SettingFieldType.email => TextInputType.emailAddress,
      _SettingFieldType.url => TextInputType.url,
      _ => TextInputType.text,
    };
    final multiline =
        field.type == _SettingFieldType.textarea ||
        field.type == _SettingFieldType.multiline;
    final obscureText = field.type == _SettingFieldType.password;

    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: _isAdmin,
      minLines: multiline ? 3 : 1,
      maxLines: multiline ? 6 : 1,
      decoration: InputDecoration(
        labelText: field.label,
        helperText: field.helper.isEmpty ? null : field.helper,
        alignLabelWithHint: multiline,
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.canManage,
    required this.onEdit,
    required this.onDelete,
  });

  final SessionUser user;
  final bool canManage;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String get _avatarUrl {
    if (user.avatarUrls['96'] case final String value when value.isNotEmpty) {
      return value;
    }
    if (user.avatarUrls['48'] case final String value when value.isNotEmpty) {
      return value;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _UserAvatar(name: user.name, avatarUrl: _avatarUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name.isEmpty ? '未命名用户' : user.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user.email.isEmpty ? user.slug : user.email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SystemBadge(
                label: roleLabel(user.primaryRole),
                tint: const Color(0xFF6A5168),
              ),
              _SystemBadge(
                label: user.slug.isEmpty ? '未设置用户名' : user.slug,
                tint: AppTheme.inkPanel,
              ),
              if (user.registeredDate.isNotEmpty)
                _SystemBadge(
                  label: formatDate(user.registeredDate),
                  tint: AppTheme.warning,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            user.description.isEmpty ? '暂无简介' : user.description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: canManage ? onEdit : null,
                icon: const Icon(Icons.edit_rounded),
                label: const Text('编辑'),
              ),
              FilledButton.tonalIcon(
                onPressed: canManage ? onDelete : null,
                icon: const Icon(Icons.person_remove_alt_1_rounded),
                label: const Text('删除'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.name, required this.avatarUrl});

  final String name;
  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.network(
          avatarUrl,
          width: 54,
          height: 54,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _UserAvatarFallback(name: name),
        ),
      );
    }
    return _UserAvatarFallback(name: name);
  }
}

class _UserAvatarFallback extends StatelessWidget {
  const _UserAvatarFallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: AppTheme.accentSoft,
        borderRadius: BorderRadius.circular(18),
      ),
      alignment: Alignment.center,
      child: Text(
        (name.isEmpty ? 'U' : name.characters.first).toUpperCase(),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppTheme.inkPanel,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SystemBadge extends StatelessWidget {
  const _SystemBadge({required this.label, required this.tint});

  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

class _UserEditorSheet extends StatefulWidget {
  const _UserEditorSheet({required this.api, this.user});

  final CfblogApi api;
  final SessionUser? user;

  bool get isEditing => user != null;

  @override
  State<_UserEditorSheet> createState() => _UserEditorSheetState();
}

class _UserEditorSheetState extends State<_UserEditorSheet> {
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _displayNameController;
  late final TextEditingController _avatarUrlController;
  late final TextEditingController _bioController;

  bool _saving = false;
  String? _error;
  String _role = 'subscriber';

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user?.slug ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _passwordController = TextEditingController();
    _displayNameController = TextEditingController(
      text: widget.user?.name ?? '',
    );
    _avatarUrlController = TextEditingController(
      text: widget.user?.avatarUrls['96'] ?? '',
    );
    _bioController = TextEditingController(
      text: widget.user?.description ?? '',
    );
    _role = widget.user?.primaryRole.isNotEmpty == true
        ? widget.user!.primaryRole
        : 'subscriber';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    _avatarUrlController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_usernameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty) {
      setState(() {
        _error = '用户名和邮箱不能为空';
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final payload = <String, dynamic>{
      'username': _usernameController.text.trim(),
      'email': _emailController.text.trim(),
      'password': _passwordController.text.trim().isEmpty
          ? null
          : _passwordController.text.trim(),
      'display_name': _displayNameController.text.trim(),
      'role': _role,
      'avatar_url': _avatarUrlController.text.trim(),
      'bio': _bioController.text.trim(),
    }..removeWhere((key, value) => value == null);

    try {
      if (widget.isEditing) {
        await widget.api.updateUser(widget.user!.id, payload);
      } else {
        await widget.api.createUser(payload);
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
                    title: widget.isEditing ? '编辑用户' : '新建用户',
                    subtitle: '先定义账号身份和显示名，再补头像地址和简介。',
                  ),
                  const SizedBox(height: 18),
                  if (_error != null) ...[
                    InfoBanner(message: _error!, isError: true),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(labelText: '用户名'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: '邮箱'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: '密码',
                      helperText: widget.isEditing ? '留空则保持现有密码' : null,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(labelText: '显示名'),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _role,
                    items: const [
                      DropdownMenuItem(
                        value: 'administrator',
                        child: Text('管理员'),
                      ),
                      DropdownMenuItem(value: 'editor', child: Text('编辑')),
                      DropdownMenuItem(value: 'author', child: Text('作者')),
                      DropdownMenuItem(
                        value: 'contributor',
                        child: Text('投稿者'),
                      ),
                      DropdownMenuItem(value: 'subscriber', child: Text('订阅者')),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _role = value;
                      });
                    },
                    decoration: const InputDecoration(labelText: '角色'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _avatarUrlController,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(labelText: '头像 URL'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _bioController,
                    minLines: 4,
                    maxLines: 7,
                    decoration: const InputDecoration(
                      labelText: '简介',
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

class _SettingsSection {
  const _SettingsSection({
    required this.title,
    required this.subtitle,
    required this.fields,
  });

  final String title;
  final String subtitle;
  final List<_SettingField> fields;
}

class _SettingField {
  const _SettingField({
    required this.key,
    required this.label,
    required this.type,
    this.helper = '',
  });

  final String key;
  final String label;
  final _SettingFieldType type;
  final String helper;
}

const List<_SettingsSection> _settingsSections = [
  _SettingsSection(
    title: '站点基础',
    subtitle: '基础品牌字段、管理员邮箱和站点视觉资源都放在这里。',
    fields: [
      _SettingField(
        key: 'site_title',
        label: '站点标题',
        type: _SettingFieldType.text,
      ),
      _SettingField(
        key: 'site_url',
        label: '站点 URL',
        type: _SettingFieldType.url,
      ),
      _SettingField(
        key: 'admin_email',
        label: '管理员邮箱',
        type: _SettingFieldType.email,
      ),
      _SettingField(
        key: 'site_description',
        label: '站点描述',
        type: _SettingFieldType.textarea,
      ),
      _SettingField(
        key: 'site_keywords',
        label: '关键词',
        type: _SettingFieldType.text,
      ),
      _SettingField(
        key: 'site_author',
        label: '作者',
        type: _SettingFieldType.text,
      ),
      _SettingField(
        key: 'site_favicon',
        label: 'Favicon URL',
        type: _SettingFieldType.url,
      ),
      _SettingField(
        key: 'site_logo',
        label: 'Logo URL',
        type: _SettingFieldType.url,
      ),
    ],
  ),
  _SettingsSection(
    title: '通知与邮件',
    subtitle: '控制发件信息和评论相关邮件通知策略。',
    fields: [
      _SettingField(
        key: 'mail_from_name',
        label: '发件人名称',
        type: _SettingFieldType.text,
      ),
      _SettingField(
        key: 'mail_from_email',
        label: '发件人邮箱',
        type: _SettingFieldType.email,
      ),
      _SettingField(
        key: 'mail_notifications_enabled',
        label: '开启邮件通知',
        type: _SettingFieldType.toggle,
      ),
      _SettingField(
        key: 'notify_admin_on_comment',
        label: '新评论通知管理员',
        type: _SettingFieldType.toggle,
      ),
      _SettingField(
        key: 'notify_commenter_on_reply',
        label: '回复时通知评论者',
        type: _SettingFieldType.toggle,
      ),
    ],
  ),
  _SettingsSection(
    title: '前台展示',
    subtitle: '前台公告、页脚和额外 Head 代码都在这一组。',
    fields: [
      _SettingField(
        key: 'site_notice',
        label: '站点公告',
        type: _SettingFieldType.textarea,
      ),
      _SettingField(
        key: 'site_icp',
        label: '备案号',
        type: _SettingFieldType.text,
      ),
      _SettingField(
        key: 'site_footer_text',
        label: '页脚文本',
        type: _SettingFieldType.textarea,
      ),
      _SettingField(
        key: 'head_html',
        label: 'Head 自定义代码',
        type: _SettingFieldType.multiline,
      ),
    ],
  ),
  _SettingsSection(
    title: '社交与联系',
    subtitle: '维护对外联系方式和社交媒体账号入口。',
    fields: [
      _SettingField(
        key: 'social_telegram',
        label: 'Telegram',
        type: _SettingFieldType.text,
      ),
      _SettingField(key: 'social_x', label: 'X', type: _SettingFieldType.text),
      _SettingField(
        key: 'social_mastodon',
        label: 'Mastodon',
        type: _SettingFieldType.text,
      ),
      _SettingField(
        key: 'social_email',
        label: '联系邮箱',
        type: _SettingFieldType.email,
      ),
      _SettingField(
        key: 'social_qq',
        label: 'QQ',
        type: _SettingFieldType.text,
      ),
    ],
  ),
  _SettingsSection(
    title: 'Webhook',
    subtitle: '适合对接外部自动化、通知系统和发布链路。',
    fields: [
      _SettingField(
        key: 'webhook_url',
        label: 'Webhook URL',
        type: _SettingFieldType.url,
      ),
      _SettingField(
        key: 'webhook_secret',
        label: 'Webhook Secret',
        type: _SettingFieldType.password,
      ),
      _SettingField(
        key: 'webhook_events',
        label: 'Webhook 事件',
        type: _SettingFieldType.multiline,
        helper: '每行一个事件，保存时会自动转成逗号分隔。',
      ),
    ],
  ),
];
