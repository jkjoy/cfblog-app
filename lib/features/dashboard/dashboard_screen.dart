import 'package:flutter/material.dart';

import '../../core/cfblog_api.dart';
import '../../core/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_chrome.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.api,
    required this.config,
    required this.discovery,
    required this.session,
    required this.onOpenPosts,
    required this.onOpenTaxonomies,
    required this.onOpenLinks,
    required this.onOpenSystem,
    required this.onOpenPages,
    required this.onOpenMoments,
    required this.onOpenMedia,
    required this.onOpenComments,
  });

  final CfblogApi api;
  final AppConfig config;
  final DiscoveryInfo? discovery;
  final SessionState session;
  final VoidCallback onOpenPosts;
  final VoidCallback onOpenTaxonomies;
  final VoidCallback onOpenLinks;
  final VoidCallback onOpenSystem;
  final VoidCallback onOpenPages;
  final VoidCallback onOpenMoments;
  final VoidCallback onOpenMedia;
  final VoidCallback onOpenComments;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<DashboardSnapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.getDashboardSnapshot();
  }

  Future<void> _reload({bool refresh = true}) async {
    final next = widget.api.getDashboardSnapshot(refresh: refresh);
    setState(() {
      _future = next;
    });
    await next;
  }

  @override
  Widget build(BuildContext context) {
    final compact = isCompactLayout(context);
    return RefreshIndicator(
      onRefresh: () => _reload(refresh: true),
      child: ListView(
        padding: pageContentPadding(context),
        children: [
          SurfaceCard(
            padding: const EdgeInsets.all(0),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.inkPanel, AppTheme.inkPanelSoft],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    BorderRadius.circular(compact ? 18 : 22),
              ),
              child: Padding(
                padding: EdgeInsets.all(compact ? 12 : 16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '工作区入口',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.inkMuted,
                                fontWeight: FontWeight.w500,
                                fontSize: 11,
                                letterSpacing: 0.4,
                              ),
                        ),
                        SizedBox(height: compact ? 10 : 12),
                        Wrap(
                          spacing: compact ? 6 : 8,
                          runSpacing: compact ? 6 : 8,
                          children: [
                            _WorkspaceLaunchCard(
                              title: '文章',
                              icon: Icons.article_rounded,
                              tint: const Color(0xFF60A5FA),
                              onTap: widget.onOpenPosts,
                              dark: true,
                            ),
                            _WorkspaceLaunchCard(
                              title: '页面',
                              icon: Icons.web_rounded,
                              tint: const Color(0xFF5EEAD4),
                              onTap: widget.onOpenPages,
                              dark: true,
                            ),
                            _WorkspaceLaunchCard(
                              title: '动态',
                              icon: Icons.bolt_rounded,
                              tint: AppTheme.warning,
                              onTap: widget.onOpenMoments,
                              dark: true,
                            ),
                            _WorkspaceLaunchCard(
                              title: '评论',
                              icon: Icons.forum_rounded,
                              tint: AppTheme.success,
                              onTap: widget.onOpenComments,
                              dark: true,
                            ),
                            _WorkspaceLaunchCard(
                              title: '媒体',
                              icon: Icons.perm_media_rounded,
                              tint: const Color(0xFFF472B6),
                              onTap: widget.onOpenMedia,
                              dark: true,
                            ),
                            _WorkspaceLaunchCard(
                              title: '分类标签',
                              icon: Icons.folder_copy_rounded,
                              tint: const Color(0xFF34D399),
                              onTap: widget.onOpenTaxonomies,
                              dark: true,
                            ),
                            _WorkspaceLaunchCard(
                              title: '友链',
                              icon: Icons.link_rounded,
                              tint: const Color(0xFFFBBF24),
                              onTap: widget.onOpenLinks,
                              dark: true,
                            ),
                            _WorkspaceLaunchCard(
                              title: '系统',
                              icon: Icons.tune_rounded,
                              tint: const Color(0xFFA78BFA),
                              onTap: widget.onOpenSystem,
                              dark: true,
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          SizedBox(height: compact ? 12 : 16),
          FutureBuilder<DashboardSnapshot>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const BootPanel(
                  title: '正在同步总览数据',
                  subtitle: '加载文章、页面、评论和媒体统计。',
                );
              }

              if (snapshot.hasError) {
                return InfoBanner(
                  message: snapshot.error.toString().replaceFirst(
                    'Exception: ',
                    '',
                  ),
                  isError: true,
                );
              }

              final data = snapshot.data!;
              return Column(
                children: [
                  SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                '核心指标',
                                style: (compact
                                        ? Theme.of(context).textTheme.titleLarge
                                        : Theme.of(context).textTheme.headlineSmall)
                                    ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () => _reload(refresh: true),
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('刷新'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppTheme.textMuted,
                                minimumSize: const Size(0, 36),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: compact ? 16 : 24),
                        Wrap(
                          spacing: compact ? 10 : 14,
                          runSpacing: compact ? 10 : 14,
                          children: [
                            _QuickMetricTile(
                              label: '文章',
                              value: '${data.posts}',
                              icon: Icons.article_rounded,
                              tint: const Color(0xFF60A5FA),
                            ),
                            _QuickMetricTile(
                              label: '页面',
                              value: '${data.pages}',
                              icon: Icons.web_rounded,
                              tint: const Color(0xFF5EEAD4),
                            ),
                            _QuickMetricTile(
                              label: '动态',
                              value: '${data.moments}',
                              icon: Icons.bolt_rounded,
                              tint: AppTheme.warning,
                            ),
                            _QuickMetricTile(
                              label: '评论',
                              value: '${data.comments}',
                              icon: Icons.forum_rounded,
                              tint: AppTheme.success,
                            ),
                            _QuickMetricTile(
                              label: '媒体',
                              value: '${data.media}',
                              icon: Icons.perm_media_rounded,
                              tint: const Color(0xFFF472B6),
                            ),
                            _QuickMetricTile(
                              label: '用户',
                              value: '${data.users}',
                              icon: Icons.people_alt_rounded,
                              tint: const Color(0xFFA78BFA),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuickMetricTile extends StatelessWidget {
  const _QuickMetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactLayout(context);
    final theme = Theme.of(context);
    return Container(
      width: compact ? 112 : 136,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: tint),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w500,
                    fontSize: 11,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 10),
          Text(
            value,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.4,
              height: 1.0,
              fontSize: compact ? 20 : 22,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceLaunchCard extends StatelessWidget {
  const _WorkspaceLaunchCard({
    required this.title,
    required this.icon,
    required this.tint,
    required this.onTap,
    this.dark = false,
  });

  final String title;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactLayout(context);
    final width = compact ? 78.0 : 96.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
        child: Ink(
          width: width,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: compact ? 10 : 12,
          ),
          decoration: BoxDecoration(
            color: dark
                ? Colors.white.withValues(alpha: 0.06)
                : AppTheme.surfaceMuted,
            borderRadius: BorderRadius.circular(compact ? 12 : 14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: tint),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                  color: dark ? Colors.white : AppTheme.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
