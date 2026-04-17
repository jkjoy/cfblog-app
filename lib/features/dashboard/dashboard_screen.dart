import 'package:flutter/material.dart';

import '../../core/cfblog_api.dart';
import '../../core/formatters.dart';
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
                padding: const EdgeInsets.all(24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final stacked = constraints.maxWidth < 760;
                    final intro = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.discovery?.name.isEmpty ?? true
                              ? '内容运营指挥台'
                              : widget.discovery!.name,
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '围绕移动端内容运营重构的 Flutter 工作台。先看站点状态，再直达具体模块。',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppTheme.inkMuted),
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _HeroTag(
                              icon: Icons.public_rounded,
                              label: widget.config.baseUrl,
                            ),
                            _HeroTag(
                              icon: Icons.verified_user_rounded,
                              label: roleLabel(widget.session.user.primaryRole),
                            ),
                          ],
                        ),
                      ],
                    );

                    final actionPanel = Container(
                      margin: EdgeInsets.only(top: stacked ? 20 : 0),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '今日建议',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '优先处理评论与待发布内容，再巡检页面、友链和系统设置，让整站状态保持稳定。',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.inkMuted),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              FilledButton.tonalIcon(
                                onPressed: widget.onOpenComments,
                                icon: const Icon(Icons.forum_rounded),
                                label: const Text('进入评论审核'),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: widget.onOpenPosts,
                                icon: const Icon(Icons.article_rounded),
                                label: const Text('进入文章列表'),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: widget.onOpenPages,
                                icon: const Icon(Icons.web_rounded),
                                label: const Text('管理页面'),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: widget.onOpenTaxonomies,
                                icon: const Icon(Icons.folder_copy_rounded),
                                label: const Text('整理分类标签'),
                              ),
                              OutlinedButton.icon(
                                onPressed: widget.onOpenLinks,
                                icon: const Icon(Icons.link_rounded),
                                label: const Text('维护友链'),
                              ),
                              OutlinedButton.icon(
                                onPressed: widget.onOpenSystem,
                                icon: const Icon(Icons.tune_rounded),
                                label: const Text('系统管理'),
                              ),
                              OutlinedButton.icon(
                                onPressed: widget.onOpenMoments,
                                icon: const Icon(Icons.bolt_rounded),
                                label: const Text('处理动态'),
                              ),
                              OutlinedButton.icon(
                                onPressed: widget.onOpenMedia,
                                icon: const Icon(Icons.perm_media_rounded),
                                label: const Text('打开媒体库'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );

                    if (stacked) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [intro, actionPanel],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 7, child: intro),
                        const SizedBox(width: 18),
                        Expanded(flex: 5, child: actionPanel),
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
                        SectionHeading(
                          title: '核心指标',
                          subtitle: '保持高频内容和反馈面板在同一屏内可读。',
                          trailing: OutlinedButton.icon(
                            onPressed: _reload,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('刷新'),
                          ),
                        ),
                        SizedBox(height: compact ? 12 : 18),
                        Wrap(
                          spacing: compact ? 10 : 12,
                          runSpacing: compact ? 10 : 12,
                          children: [
                            MetricTile(
                              label: '文章',
                              value: '${data.posts}',
                              icon: Icons.article_rounded,
                              tint: AppTheme.accent,
                            ),
                            MetricTile(
                              label: '页面',
                              value: '${data.pages}',
                              icon: Icons.web_rounded,
                              tint: const Color(0xFF21544B),
                            ),
                            MetricTile(
                              label: '动态',
                              value: '${data.moments}',
                              icon: Icons.bolt_rounded,
                              tint: AppTheme.warning,
                            ),
                            MetricTile(
                              label: '评论',
                              value: '${data.comments}',
                              icon: Icons.forum_rounded,
                              tint: AppTheme.success,
                            ),
                            MetricTile(
                              label: '媒体',
                              value: '${data.media}',
                              icon: Icons.perm_media_rounded,
                              tint: const Color(0xFF6953B4),
                            ),
                            MetricTile(
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
                  SizedBox(height: compact ? 12 : 16),
                  SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionHeading(
                          title: '工作区入口',
                          subtitle: compact ? '' : '把高频运营动作压缩进一屏，减少在不同模块间来回寻找。',
                        ),
                        SizedBox(height: compact ? 10 : 18),
                        Wrap(
                          spacing: compact ? 8 : 12,
                          runSpacing: compact ? 8 : 12,
                          children: [
                            _WorkspaceLaunchCard(
                              title: '文章',
                              icon: Icons.article_rounded,
                              tint: AppTheme.accent,
                              onTap: widget.onOpenPosts,
                            ),
                            _WorkspaceLaunchCard(
                              title: '页面',
                              icon: Icons.web_rounded,
                              tint: const Color(0xFF21544B),
                              onTap: widget.onOpenPages,
                            ),
                            _WorkspaceLaunchCard(
                              title: '动态',
                              icon: Icons.bolt_rounded,
                              tint: AppTheme.warning,
                              onTap: widget.onOpenMoments,
                            ),
                            _WorkspaceLaunchCard(
                              title: '评论',
                              icon: Icons.forum_rounded,
                              tint: AppTheme.success,
                              onTap: widget.onOpenComments,
                            ),
                            _WorkspaceLaunchCard(
                              title: '媒体',
                              icon: Icons.perm_media_rounded,
                              tint: const Color(0xFF6953B4),
                              onTap: widget.onOpenMedia,
                            ),
                            _WorkspaceLaunchCard(
                              title: '分类标签',
                              icon: Icons.folder_copy_rounded,
                              tint: const Color(0xFF21544B),
                              onTap: widget.onOpenTaxonomies,
                            ),
                            _WorkspaceLaunchCard(
                              title: '友链',
                              icon: Icons.link_rounded,
                              tint: const Color(0xFF7A5A25),
                              onTap: widget.onOpenLinks,
                            ),
                            _WorkspaceLaunchCard(
                              title: '系统',
                              icon: Icons.tune_rounded,
                              tint: const Color(0xFF6A5168),
                              onTap: widget.onOpenSystem,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: compact ? 12 : 16),
                  SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionHeading(
                          title: '最近文章',
                          subtitle: '用最近更新内容快速判断当前写作节奏、互动量和浏览趋势。',
                        ),
                        SizedBox(height: compact ? 12 : 18),
                        if (data.recentPosts.isEmpty)
                          const EmptyStateCard(
                            title: '还没有可展示的文章',
                            subtitle: '发布新内容后，这里会出现最近更新的文章。',
                          )
                        else
                          ...data.recentPosts.map(
                            (post) => Padding(
                              padding: EdgeInsets.only(
                                bottom: compact ? 10 : 12,
                              ),
                              child: _PostPreviewCard(post: post),
                            ),
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

class _HeroTag extends StatelessWidget {
  const _HeroTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostPreviewCard extends StatelessWidget {
  const _PostPreviewCard({required this.post});

  final WpPost post;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stripHtml(post.title),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            stripHtml(post.excerpt).isEmpty
                ? '这篇文章还没有摘要。'
                : stripHtml(post.excerpt),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetaPill(
                icon: Icons.schedule_rounded,
                label: formatDate(
                  post.modified.isEmpty ? post.date : post.modified,
                ),
              ),
              _MetaPill(
                icon: Icons.mode_comment_outlined,
                label: '${post.commentCount} 评论',
              ),
              _MetaPill(
                icon: Icons.visibility_outlined,
                label: '${post.viewCount} 浏览',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.textMuted),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
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
  });

  final String title;
  final IconData icon;
  final Color tint;
  final VoidCallback onTap;

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
            color: AppTheme.surfaceMuted,
            borderRadius: BorderRadius.circular(compact ? 18 : 22),
            border: Border.all(color: AppTheme.border),
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
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
