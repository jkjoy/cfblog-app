import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'core/cfblog_api.dart';
import 'core/formatters.dart';
import 'core/models.dart';
import 'core/session_store.dart';
import 'features/auth/connection_screen.dart';
import 'features/comments/comments_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/links/links_workspace_screen.dart';
import 'features/media/media_screen.dart';
import 'features/moments/moments_screen.dart';
import 'features/pages/pages_screen.dart';
import 'features/posts/posts_screen.dart';
import 'features/system/system_workspace_screen.dart';
import 'features/taxonomies/taxonomies_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/app_chrome.dart';

class CfblogApp extends StatelessWidget {
  const CfblogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CFBlog APP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const _AppBootstrapper(),
    );
  }
}

class _AppBootstrapper extends StatefulWidget {
  const _AppBootstrapper();

  @override
  State<_AppBootstrapper> createState() => _AppBootstrapperState();
}

class _AppBootstrapperState extends State<_AppBootstrapper> {
  final SessionStore _store = const SessionStore();

  bool _booting = true;
  AppConfig _config = const AppConfig(baseUrl: '');
  SessionState? _session;
  DiscoveryInfo? _discovery;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final savedConfig = await _store.loadConfig();
      final savedSession = await _store.loadSession();

      if (savedConfig != null) {
        _config = savedConfig;
      }

      if (_config.baseUrl.isNotEmpty) {
        try {
          _discovery = await CfblogApi(_config.baseUrl).getDiscovery();
        } catch (_) {
          _discovery = null;
        }
      }

      if (_config.baseUrl.isNotEmpty && savedSession != null) {
        try {
          final user = await CfblogApi(
            _config.baseUrl,
            token: savedSession.token,
          ).getCurrentUser();
          _session = SessionState(token: savedSession.token, user: user);
          await _store.saveSession(_session!);
        } catch (_) {
          await _store.clearSession();
          _session = null;
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _booting = false;
        });
      }
    }
  }

  Future<DiscoveryInfo> _inspectSite(String baseUrl) async {
    final normalized = normalizeBaseUrl(baseUrl);
    final api = CfblogApi(normalized);
    final discovery = await api.getDiscovery();
    final nextConfig = AppConfig(baseUrl: normalized);
    await _store.saveConfig(nextConfig);
    if (!mounted) {
      return discovery;
    }
    setState(() {
      _config = nextConfig;
      _discovery = discovery;
    });
    return discovery;
  }

  Future<void> _login({
    required String baseUrl,
    required String username,
    required String password,
  }) async {
    final normalized = normalizeBaseUrl(baseUrl);
    final api = CfblogApi(normalized);
    final session = await api.login(username: username, password: password);

    DiscoveryInfo? discovery = _discovery;
    if (_config.baseUrl != normalized || discovery == null) {
      try {
        discovery = await api.getDiscovery();
      } catch (_) {
        discovery = null;
      }
    }

    final nextConfig = AppConfig(baseUrl: normalized);
    await _store.saveConfig(nextConfig);
    await _store.saveSession(session);

    if (!mounted) {
      return;
    }
    setState(() {
      _config = nextConfig;
      _discovery = discovery;
      _session = session;
    });
  }

  Future<void> _logout() async {
    await _store.clearSession();
    if (!mounted) {
      return;
    }
    setState(() {
      _session = null;
    });
  }

  Future<void> _resetSite() async {
    await Future.wait([_store.clearConfig(), _store.clearSession()]);
    if (!mounted) {
      return;
    }
    setState(() {
      _config = const AppConfig(baseUrl: '');
      _session = null;
      _discovery = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_booting) {
      return const AppBackdrop(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: BootPanel(
              title: '启动 Flutter 工作台',
              subtitle: '正在检查本地站点配置与会话状态。',
            ),
          ),
        ),
      );
    }

    if (_session == null) {
      return ConnectionScreen(
        initialUrl: _config.baseUrl,
        initialDiscovery: _discovery,
        onInspect: _inspectSite,
        onLogin: _login,
      );
    }

    return WorkspaceShell(
      config: _config,
      discovery: _discovery,
      session: _session!,
      onLogout: _logout,
      onResetSite: _resetSite,
    );
  }
}

enum WorkspaceTab {
  overview,
  posts,
  taxonomies,
  links,
  system,
  pages,
  moments,
  media,
  comments,
}

class WorkspaceShell extends StatefulWidget {
  const WorkspaceShell({
    super.key,
    required this.config,
    required this.discovery,
    required this.session,
    required this.onLogout,
    required this.onResetSite,
    this.client,
    this.initialTab = WorkspaceTab.overview,
  });

  final AppConfig config;
  final DiscoveryInfo? discovery;
  final SessionState session;
  final Future<void> Function() onLogout;
  final Future<void> Function() onResetSite;
  final http.Client? client;
  final WorkspaceTab initialTab;

  @override
  State<WorkspaceShell> createState() => _WorkspaceShellState();
}

class _WorkspaceShellState extends State<WorkspaceShell> {
  late WorkspaceTab _currentTab;

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
  }

  void _selectTab(WorkspaceTab tab) {
    if (!mounted) {
      return;
    }
    setState(() {
      _currentTab = tab;
    });
  }

  Future<void> _openMobileWorkspaceSheet() async {
    final selected = await showModalBottomSheet<WorkspaceTab>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _MobileWorkspaceSheet(currentTab: _currentTab),
    );

    if (selected != null) {
      _selectTab(selected);
    }
  }

  Future<void> _openMobileSiteSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _MobileSiteSheet(
        config: widget.config,
        discovery: widget.discovery,
        session: widget.session,
        onResetSite: widget.onResetSite,
        onLogout: widget.onLogout,
      ),
    );
  }

  Future<void> _openMobileMomentComposer(CfblogApi api) async {
    final changed = await showMomentEditorSheet(context, api: api);
    if (changed == true) {
      _selectTab(WorkspaceTab.moments);
    }
  }

  Future<void> _openMobilePostComposer(CfblogApi api) async {
    final changed = await openPostEditorScreen(context, api: api);
    if (changed == true) {
      _selectTab(WorkspaceTab.posts);
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = CfblogApi(
      widget.config.baseUrl,
      token: widget.session.token,
      client: widget.client,
    );
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 1080;
    final currentItem = _workspaceItemFor(_currentTab);

    final screen = switch (_currentTab) {
      WorkspaceTab.overview => DashboardScreen(
        api: api,
        config: widget.config,
        discovery: widget.discovery,
        session: widget.session,
        onOpenPosts: () => _selectTab(WorkspaceTab.posts),
        onOpenTaxonomies: () => _selectTab(WorkspaceTab.taxonomies),
        onOpenLinks: () => _selectTab(WorkspaceTab.links),
        onOpenSystem: () => _selectTab(WorkspaceTab.system),
        onOpenPages: () => _selectTab(WorkspaceTab.pages),
        onOpenMoments: () => _selectTab(WorkspaceTab.moments),
        onOpenMedia: () => _selectTab(WorkspaceTab.media),
        onOpenComments: () => _selectTab(WorkspaceTab.comments),
      ),
      WorkspaceTab.posts => PostsScreen(api: api),
      WorkspaceTab.taxonomies => TaxonomiesScreen(api: api),
      WorkspaceTab.links => LinksWorkspaceScreen(api: api),
      WorkspaceTab.system => SystemWorkspaceScreen(
        api: api,
        session: widget.session,
      ),
      WorkspaceTab.pages => PagesScreen(api: api),
      WorkspaceTab.moments => MomentsScreen(api: api),
      WorkspaceTab.media => MediaScreen(api: api),
      WorkspaceTab.comments => CommentsScreen(api: api),
    };

    return AppBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        bottomNavigationBar: isWide
            ? null
            : _MobileBottomNavigation(
                currentTab: _currentTab,
                onSelect: _selectTab,
                onComposePost: () => _openMobilePostComposer(api),
                onComposeMoment: () => _openMobileMomentComposer(api),
              ),
        body: SafeArea(
          child: isWide
              ? Row(
                  children: [
                    _Sidebar(
                      config: widget.config,
                      session: widget.session,
                      currentTab: _currentTab,
                      onSelect: _selectTab,
                      onLogout: widget.onLogout,
                      onResetSite: widget.onResetSite,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 20, 20),
                        child: Column(
                          children: [
                            _TopBar(
                              session: widget.session,
                              config: widget.config,
                              discovery: widget.discovery,
                              onLogout: widget.onLogout,
                              onResetSite: widget.onResetSite,
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 260),
                                child: KeyedSubtree(
                                  key: ValueKey(_currentTab),
                                  child: screen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                      child: _MobileWorkspaceHeader(
                        item: currentItem,
                        discovery: widget.discovery,
                        session: widget.session,
                        onOpenSiteSheet: _openMobileSiteSheet,
                        onOpenMore: _openMobileWorkspaceSheet,
                      ),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        child: KeyedSubtree(
                          key: ValueKey(_currentTab),
                          child: screen,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.config,
    required this.session,
    required this.currentTab,
    required this.onSelect,
    required this.onLogout,
    required this.onResetSite,
  });

  final AppConfig config;
  final SessionState session;
  final WorkspaceTab currentTab;
  final ValueChanged<WorkspaceTab> onSelect;
  final Future<void> Function() onLogout;
  final Future<void> Function() onResetSite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 292,
      margin: const EdgeInsets.fromLTRB(20, 16, 0, 20),
      decoration: BoxDecoration(
        color: AppTheme.inkPanel,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x240F1614),
            blurRadius: 36,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CFBlog APP',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              config.baseUrl,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.inkMuted,
              ),
            ),
            const SizedBox(height: 20),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppTheme.inkPanelSoft,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.accentSoft,
                      child: Text(
                        (session.user.name.isEmpty
                                ? 'C'
                                : session.user.name.characters.first)
                            .toUpperCase(),
                        style: theme.textTheme.titleLarge?.copyWith(
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
                            session.user.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            roleLabel(session.user.primaryRole),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.inkMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _SidebarAction(
              label: '总览',
              icon: Icons.space_dashboard_rounded,
              active: currentTab == WorkspaceTab.overview,
              onTap: () => onSelect(WorkspaceTab.overview),
            ),
            const SizedBox(height: 8),
            _SidebarAction(
              label: '文章',
              icon: Icons.article_rounded,
              active: currentTab == WorkspaceTab.posts,
              onTap: () => onSelect(WorkspaceTab.posts),
            ),
            const SizedBox(height: 8),
            _SidebarAction(
              label: '分类标签',
              icon: Icons.folder_copy_rounded,
              active: currentTab == WorkspaceTab.taxonomies,
              onTap: () => onSelect(WorkspaceTab.taxonomies),
            ),
            const SizedBox(height: 8),
            _SidebarAction(
              label: '友链',
              icon: Icons.link_rounded,
              active: currentTab == WorkspaceTab.links,
              onTap: () => onSelect(WorkspaceTab.links),
            ),
            const SizedBox(height: 8),
            _SidebarAction(
              label: '系统',
              icon: Icons.tune_rounded,
              active: currentTab == WorkspaceTab.system,
              onTap: () => onSelect(WorkspaceTab.system),
            ),
            const SizedBox(height: 8),
            _SidebarAction(
              label: '页面',
              icon: Icons.web_rounded,
              active: currentTab == WorkspaceTab.pages,
              onTap: () => onSelect(WorkspaceTab.pages),
            ),
            const SizedBox(height: 8),
            _SidebarAction(
              label: '动态',
              icon: Icons.bolt_rounded,
              active: currentTab == WorkspaceTab.moments,
              onTap: () => onSelect(WorkspaceTab.moments),
            ),
            const SizedBox(height: 8),
            _SidebarAction(
              label: '媒体',
              icon: Icons.perm_media_rounded,
              active: currentTab == WorkspaceTab.media,
              onTap: () => onSelect(WorkspaceTab.media),
            ),
            const SizedBox(height: 8),
            _SidebarAction(
              label: '评论',
              icon: Icons.forum_rounded,
              active: currentTab == WorkspaceTab.comments,
              onTap: () => onSelect(WorkspaceTab.comments),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: onResetSite,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              icon: const Icon(Icons.swap_horiz_rounded),
              label: const Text('切换站点'),
            ),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('退出登录'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileWorkspaceHeader extends StatelessWidget {
  const _MobileWorkspaceHeader({
    required this.item,
    required this.discovery,
    required this.session,
    required this.onOpenSiteSheet,
    required this.onOpenMore,
  });

  final _WorkspaceNavItem item;
  final DiscoveryInfo? discovery;
  final SessionState session;
  final VoidCallback onOpenSiteSheet;
  final VoidCallback onOpenMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final siteLabel = discovery?.name ?? session.user.name;
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.tint.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, size: 20, color: item.tint),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  siteLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            onPressed: onOpenSiteSheet,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(10),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.surfaceMuted,
              foregroundColor: AppTheme.text,
            ),
            icon: const Icon(Icons.dns_rounded, size: 18),
            tooltip: '站点信息',
          ),
          const SizedBox(width: 6),
          IconButton.filled(
            onPressed: onOpenMore,
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.all(10),
            style: IconButton.styleFrom(
              backgroundColor: item.tint,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.grid_view_rounded, size: 18),
            tooltip: '全部工作区',
          ),
        ],
      ),
    );
  }
}

class _MobileBottomNavigation extends StatelessWidget {
  const _MobileBottomNavigation({
    required this.currentTab,
    required this.onSelect,
    required this.onComposePost,
    required this.onComposeMoment,
  });

  final WorkspaceTab currentTab;
  final ValueChanged<WorkspaceTab> onSelect;
  final VoidCallback onComposePost;
  final VoidCallback onComposeMoment;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      child: SurfaceCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: _MobileNavItem(
                icon: Icons.space_dashboard_rounded,
                label: '总览',
                selected: currentTab == WorkspaceTab.overview,
                onTap: () => onSelect(WorkspaceTab.overview),
              ),
            ),
            Expanded(
              child: _MobileComposeItem(
                icon: Icons.bolt_rounded,
                label: '发动态',
                selected: currentTab == WorkspaceTab.moments,
                onTap: onComposeMoment,
              ),
            ),            
            Expanded(
              child: _MobileComposeItem(
                icon: Icons.edit_note_rounded,
                label: '写文章',
                selected: currentTab == WorkspaceTab.posts,
                onTap: onComposePost,
              ),
            ),
            Expanded(
              child: _MobileNavItem(
                icon: Icons.perm_media_rounded,
                label: '媒体库',
                selected: currentTab == WorkspaceTab.media,
                onTap: () => onSelect(WorkspaceTab.media),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileNavItem extends StatelessWidget {
  const _MobileNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppTheme.accent : AppTheme.textMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileComposeItem extends StatelessWidget {
  const _MobileComposeItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: selected ? AppTheme.accent : AppTheme.inkPanel,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: selected ? AppTheme.accent : AppTheme.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileWorkspaceSheet extends StatelessWidget {
  const _MobileWorkspaceSheet({required this.currentTab});

  final WorkspaceTab currentTab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 28, 10, 10),
        child: SurfaceCard(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '全部工作区',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '按内容类型分组，快速跳转到对应模块。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.52,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final group in _workspaceGroups) ...[
                        _MobileWorkspaceGroup(
                          group: group,
                          currentTab: currentTab,
                        ),
                        const SizedBox(height: 14),
                      ],
                    ]..removeLast(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MobileWorkspaceGroup extends StatelessWidget {
  const _MobileWorkspaceGroup({
    required this.group,
    required this.currentTab,
  });

  final _WorkspaceNavGroup group;
  final WorkspaceTab currentTab;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              group.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.surfaceMuted,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${group.items.length} 项',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          group.subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.textMuted,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 340 ? 3 : 2;
            final spacing = 8.0;
            final tileWidth =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final item in group.items)
                  _MobileWorkspaceTile(
                    item: item,
                    active: item.tab == currentTab,
                    width: tileWidth,
                    onTap: () => Navigator.of(context).pop(item.tab),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _MobileWorkspaceTile extends StatelessWidget {
  const _MobileWorkspaceTile({
    required this.item,
    required this.active,
    required this.width,
    required this.onTap,
  });

  final _WorkspaceNavItem item;
  final bool active;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: active ? item.tint.withValues(alpha: 0.14) : AppTheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active ? item.tint.withValues(alpha: 0.34) : AppTheme.border,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: active
                    ? item.tint.withValues(alpha: 0.18)
                    : AppTheme.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.icon,
                size: 16,
                color: active ? item.tint : AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileSiteSheet extends StatelessWidget {
  const _MobileSiteSheet({
    required this.config,
    required this.discovery,
    required this.session,
    required this.onResetSite,
    required this.onLogout,
  });

  final AppConfig config;
  final DiscoveryInfo? discovery;
  final SessionState session;
  final Future<void> Function() onResetSite;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final siteLabel = discovery?.name ?? session.user.name;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 28, 10, 10),
        child: SurfaceCard(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '站点信息',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceMuted,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      siteLabel,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      config.baseUrl,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '当前身份：${roleLabel(session.user.primaryRole)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await onResetSite();
                      },
                      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                      label: const Text('切换站点'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await onLogout();
                      },
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('退出'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkspaceNavItem {
  const _WorkspaceNavItem({
    required this.tab,
    required this.label,
    required this.icon,
    required this.tint,
    required this.group,
  });

  final WorkspaceTab tab;
  final String label;
  final IconData icon;
  final Color tint;
  final _WorkspaceNavGroupKey group;
}

enum _WorkspaceNavGroupKey { essentials, publishing, operations, system }

class _WorkspaceNavGroup {
  const _WorkspaceNavGroup({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.items,
  });

  final _WorkspaceNavGroupKey key;
  final String title;
  final String subtitle;
  final List<_WorkspaceNavItem> items;
}

_WorkspaceNavItem _workspaceItemFor(WorkspaceTab tab) {
  return _workspaceItems.firstWhere((item) => item.tab == tab);
}

const List<_WorkspaceNavItem> _workspaceItems = [
  _WorkspaceNavItem(
    tab: WorkspaceTab.overview,
    label: '总览',
    icon: Icons.space_dashboard_rounded,
    tint: AppTheme.accent,
    group: _WorkspaceNavGroupKey.essentials,
  ),
  _WorkspaceNavItem(
    tab: WorkspaceTab.posts,
    label: '文章',
    icon: Icons.article_rounded,
    tint: AppTheme.inkPanel,
    group: _WorkspaceNavGroupKey.publishing,
  ),
  _WorkspaceNavItem(
    tab: WorkspaceTab.taxonomies,
    label: '分类标签',
    icon: Icons.folder_copy_rounded,
    tint: Color(0xFF21544B),
    group: _WorkspaceNavGroupKey.publishing,
  ),
  _WorkspaceNavItem(
    tab: WorkspaceTab.links,
    label: '友链',
    icon: Icons.link_rounded,
    tint: Color(0xFF7A5A25),
    group: _WorkspaceNavGroupKey.operations,
  ),
  _WorkspaceNavItem(
    tab: WorkspaceTab.system,
    label: '系统',
    icon: Icons.tune_rounded,
    tint: Color(0xFF6A5168),
    group: _WorkspaceNavGroupKey.system,
  ),
  _WorkspaceNavItem(
    tab: WorkspaceTab.pages,
    label: '页面',
    icon: Icons.web_rounded,
    tint: Color(0xFF4C6A61),
    group: _WorkspaceNavGroupKey.publishing,
  ),
  _WorkspaceNavItem(
    tab: WorkspaceTab.moments,
    label: '动态',
    icon: Icons.bolt_rounded,
    tint: AppTheme.warning,
    group: _WorkspaceNavGroupKey.operations,
  ),
  _WorkspaceNavItem(
    tab: WorkspaceTab.media,
    label: '媒体',
    icon: Icons.perm_media_rounded,
    tint: Color(0xFF6953B4),
    group: _WorkspaceNavGroupKey.publishing,
  ),
  _WorkspaceNavItem(
    tab: WorkspaceTab.comments,
    label: '评论',
    icon: Icons.forum_rounded,
    tint: AppTheme.success,
    group: _WorkspaceNavGroupKey.operations,
  ),
];

List<_WorkspaceNavGroup> get _workspaceGroups => [
  _WorkspaceNavGroup(
    key: _WorkspaceNavGroupKey.essentials,
    title: '常用入口',
    subtitle: '保留最先需要触达的工作台入口。',
    items: _workspaceItems
        .where((item) => item.group == _WorkspaceNavGroupKey.essentials)
        .toList(),
  ),
  _WorkspaceNavGroup(
    key: _WorkspaceNavGroupKey.publishing,
    title: '内容发布',
    subtitle: '管理文章、页面、媒体以及内容组织结构。',
    items: _workspaceItems
        .where((item) => item.group == _WorkspaceNavGroupKey.publishing)
        .toList(),
  ),
  _WorkspaceNavGroup(
    key: _WorkspaceNavGroupKey.operations,
    title: '互动运营',
    subtitle: '处理评论、动态和站点外部关系维护。',
    items: _workspaceItems
        .where((item) => item.group == _WorkspaceNavGroupKey.operations)
        .toList(),
  ),
  _WorkspaceNavGroup(
    key: _WorkspaceNavGroupKey.system,
    title: '系统设置',
    subtitle: '查看用户、权限与全局配置能力。',
    items: _workspaceItems
        .where((item) => item.group == _WorkspaceNavGroupKey.system)
        .toList(),
  ),
];

class _SidebarAction extends StatelessWidget {
  const _SidebarAction({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: active
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active
              ? Colors.white.withValues(alpha: 0.22)
              : Colors.transparent,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        leading: Icon(icon, color: Colors.white),
        title: Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.session,
    required this.config,
    required this.discovery,
    required this.onLogout,
    required this.onResetSite,
  });

  final SessionState session;
  final AppConfig config;
  final DiscoveryInfo? discovery;
  final Future<void> Function() onLogout;
  final Future<void> Function() onResetSite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked = constraints.maxWidth < 760;
          final siteInfo = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                discovery?.name ?? session.user.name,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                config.baseUrl,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          );
          final actions = Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: onResetSite,
                icon: const Icon(Icons.settings_ethernet_rounded),
                label: const Text('切换站点'),
              ),
              FilledButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('退出'),
              ),
            ],
          );

          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                siteInfo,
                const SizedBox(height: 12),
                actions,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: siteInfo),
              const SizedBox(width: 12),
              actions,
            ],
          );
        },
      ),
    );
  }
}
