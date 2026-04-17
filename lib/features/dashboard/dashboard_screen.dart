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

  Future<void> _reload() async {
    final next = widget.api.getDashboardSnapshot();
    setState(() {
      _future = next;
    });
    await next;
  }

  @override
  Widget build(BuildContext context) {
    final compact = isCompactLayout(context);
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        padding: pageContentPadding(context),
        children: [
          SurfaceCard(
            padding: const EdgeInsets.all(0),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.inkPanel, AppTheme.inkPanelSoft],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.all(Radius.circular(30)),
              ),
              child: Padding(
                padding: EdgeInsets.all(compact ? 16 : 22),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '工作区入口',
                          style: (compact
                                  ? Theme.of(context).textTheme.titleSmall
                                  : Theme.of(context).textTheme.titleMedium)
                              ?.copyWith(
                                color: AppTheme.inkMuted,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        SizedBox(height: compact ? 10 : 14),
                        Wrap(
                          spacing: compact ? 8 : 12,
                          runSpacing: compact ? 8 : 12,
                          children: [
                            _WorkspaceLaunchCard(
                              title: '文章',
                              icon: Icons.article_rounded,
                              tint: AppTheme.accent,
                              onTap: widget.onOpenPosts,
                              dark: true,
                            ),
                            _WorkspaceLaunchCard(
                              title: '页面',
                              icon: Icons.web_rounded,
                              tint: const Color(0xFF8CC5B7),
                              onTap: widget.onOpenPages,
                              dark: true,
                            ),
                            _WorkspaceLaunchCard(
                              title: '动态',
                              icon: Icons.bolt_rounded,
                              tint: const Color(0xFFE0BC78),
                              onTap: widget.onOpenMoments,
                              dark: true,
                            ),
                            _WorkspaceLaunchCard(
                              title: '评论',
                              icon: Icons.forum_rounded,
                              tint: const Color(0xFF9DDFBF),
                              onTap: widget.onOpenComments,
                              dark: true,
                            ),
                            _WorkspaceLaunchCard(
                              title: '媒体',
                              icon: Icons.perm_media_rounded,
                              tint: const Color(0xFFC2B4FF),
                              onTap: widget.onOpenMedia,
                              dark: true,
                            ),
                            _WorkspaceLaunchCard(
                              title: '分类标签',
                              icon: Icons.folder_copy_rounded,
                              tint: const Color(0xFF8CC5B7),
                              onTap: widget.onOpenTaxonomies,
                              dark: true,
                            ),
                            _WorkspaceLaunchCard(
                              title: '友链',
                              icon: Icons.link_rounded,
                              tint: const Color(0xFFE2C28D),
                              onTap: widget.onOpenLinks,
                              dark: true,
                            ),
                            _WorkspaceLaunchCard(
                              title: '系统',
                              icon: Icons.tune_rounded,
                              tint: const Color(0xFFD6BFE0),
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
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _reload,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('刷新'),
                            ),
                          ],
                        ),
                        SizedBox(height: compact ? 12 : 18),
                        Wrap(
                          spacing: compact ? 10 : 12,
                          runSpacing: compact ? 10 : 12,
                          children: [
                            _QuickMetricTile(
                              label: '文章',
                              value: '${data.posts}',
                              icon: Icons.article_rounded,
                              tint: AppTheme.accent,
                            ),
                            _QuickMetricTile(
                              label: '页面',
                              value: '${data.pages}',
                              icon: Icons.web_rounded,
                              tint: const Color(0xFF21544B),
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
                              tint: const Color(0xFF6953B4),
                            ),
                            _QuickMetricTile(
                              label: '用户',
                              value: '${data.users}',
                              icon: Icons.people_alt_rounded,
                              tint: const Color(0xFF7A5A25),
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
      width: compact ? 104 : 126,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(compact ? 18 : 20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 30 : 34,
            height: compact ? 30 : 34,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(compact ? 10 : 12),
            ),
            child: Icon(icon, size: compact ? 16 : 18, color: tint),
          ),
          SizedBox(height: compact ? 8 : 10),
          Text(
            value,
            style: (compact ? theme.textTheme.titleMedium : theme.textTheme.titleLarge)
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w700,
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
    final width = compact ? 104.0 : 132.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 18 : 22),
        child: Ink(
          width: width,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: compact ? 12 : 14,
          ),
          decoration: BoxDecoration(
            color: dark
                ? Colors.white.withValues(alpha: 0.08)
                : AppTheme.surfaceMuted,
            borderRadius: BorderRadius.circular(compact ? 18 : 22),
            border: Border.all(
              color: dark
                  ? Colors.white.withValues(alpha: 0.12)
                  : AppTheme.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: compact ? 34 : 38,
                height: compact ? 34 : 38,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(compact ? 10 : 12),
                ),
                child: Icon(icon, size: compact ? 18 : 20, color: tint),
              ),
              SizedBox(height: compact ? 10 : 12),
              Text(
                title,
                maxLines: compact ? 2 : 1,
                overflow: TextOverflow.ellipsis,
                style: (compact
                        ? Theme.of(context).textTheme.titleSmall
                        : Theme.of(context).textTheme.titleMedium)
                    ?.copyWith(
                      fontWeight: FontWeight.w800,
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
