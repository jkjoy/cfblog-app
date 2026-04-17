import 'package:flutter/material.dart';

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
      title: 'CFBlog Flutter',
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
  });

  final AppConfig config;
  final DiscoveryInfo? discovery;
  final SessionState session;
  final Future<void> Function() onLogout;
  final Future<void> Function() onResetSite;

  @override
  State<WorkspaceShell> createState() => _WorkspaceShellState();
}

class _WorkspaceShellState extends State<WorkspaceShell> {
  WorkspaceTab _currentTab = WorkspaceTab.overview;

  @override
  Widget build(BuildContext context) {
    final api = CfblogApi(widget.config.baseUrl, token: widget.session.token);
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 1080;

    final screen = switch (_currentTab) {
      WorkspaceTab.overview => DashboardScreen(
        api: api,
        config: widget.config,
        discovery: widget.discovery,
        session: widget.session,
        onOpenPosts: () => setState(() => _currentTab = WorkspaceTab.posts),
        onOpenTaxonomies: () =>
            setState(() => _currentTab = WorkspaceTab.taxonomies),
        onOpenLinks: () => setState(() => _currentTab = WorkspaceTab.links),
        onOpenSystem: () => setState(() => _currentTab = WorkspaceTab.system),
        onOpenPages: () => setState(() => _currentTab = WorkspaceTab.pages),
        onOpenMoments: () => setState(() => _currentTab = WorkspaceTab.moments),
        onOpenMedia: () => setState(() => _currentTab = WorkspaceTab.media),
        onOpenComments: () =>
            setState(() => _currentTab = WorkspaceTab.comments),
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
        body: SafeArea(
          child: isWide
              ? Row(
                  children: [
                    _Sidebar(
                      config: widget.config,
                      session: widget.session,
                      currentTab: _currentTab,
                      onSelect: (tab) => setState(() => _currentTab = tab),
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
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _TopBar(
                        session: widget.session,
                        config: widget.config,
                        discovery: widget.discovery,
                        onLogout: widget.onLogout,
                        onResetSite: widget.onResetSite,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: _CompactWorkspaceSwitch(
                        currentTab: _currentTab,
                        onSelect: (tab) => setState(() => _currentTab = tab),
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
              'CFBlog Flutter',
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

class _CompactWorkspaceSwitch extends StatelessWidget {
  const _CompactWorkspaceSwitch({
    required this.currentTab,
    required this.onSelect,
  });

  final WorkspaceTab currentTab;
  final ValueChanged<WorkspaceTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final item in _workspaceItems) ...[
              _CompactWorkspaceChip(
                item: item,
                active: item.tab == currentTab,
                onTap: () => onSelect(item.tab),
              ),
              const SizedBox(width: 10),
            ],
          ]..removeLast(),
        ),
      ),
    );
  }
}

class _CompactWorkspaceChip extends StatelessWidget {
  const _CompactWorkspaceChip({
    required this.item,
    required this.active,
    required this.onTap,
  });

  final _WorkspaceNavItem item;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: active ? item.tint.withValues(alpha: 0.16) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? item.tint.withValues(alpha: 0.34) : AppTheme.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: 18,
              color: active ? item.tint : AppTheme.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              item.label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: active ? AppTheme.text : AppTheme.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
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
  });

  final WorkspaceTab tab;
  final String label;
  final IconData icon;
  final Color tint;
}

const List<_WorkspaceNavItem> _workspaceItems = [
  _WorkspaceNavItem(
    tab: WorkspaceTab.overview,
    label: '总览',
    icon: Icons.space_dashboard_rounded,
    tint: AppTheme.accent,
  ),
  _WorkspaceNavItem(
    tab: WorkspaceTab.posts,
    label: '文章',
    icon: Icons.article_rounded,
    tint: AppTheme.inkPanel,
  ),
  _WorkspaceNavItem(
    tab: WorkspaceTab.taxonomies,
    label: '分类标签',
    icon: Icons.folder_copy_rounded,
    tint: Color(0xFF21544B),
  ),
  _WorkspaceNavItem(
    tab: WorkspaceTab.links,
    label: '友链',
    icon: Icons.link_rounded,
    tint: Color(0xFF7A5A25),
  ),
  _WorkspaceNavItem(
    tab: WorkspaceTab.system,
    label: '系统',
    icon: Icons.tune_rounded,
    tint: Color(0xFF6A5168),
  ),
  _WorkspaceNavItem(
    tab: WorkspaceTab.pages,
    label: '页面',
    icon: Icons.web_rounded,
    tint: Color(0xFF4C6A61),
  ),
  _WorkspaceNavItem(
    tab: WorkspaceTab.moments,
    label: '动态',
    icon: Icons.bolt_rounded,
    tint: AppTheme.warning,
  ),
  _WorkspaceNavItem(
    tab: WorkspaceTab.media,
    label: '媒体',
    icon: Icons.perm_media_rounded,
    tint: Color(0xFF6953B4),
  ),
  _WorkspaceNavItem(
    tab: WorkspaceTab.comments,
    label: '评论',
    icon: Icons.forum_rounded,
    tint: AppTheme.success,
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
          return Flex(
            direction: stacked ? Axis.vertical : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                fit: stacked ? FlexFit.loose : FlexFit.tight,
                child: Column(
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
                ),
              ),
              SizedBox(width: stacked ? 0 : 12, height: stacked ? 12 : 0),
              Wrap(
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
              ),
            ],
          );
        },
      ),
    );
  }
}
