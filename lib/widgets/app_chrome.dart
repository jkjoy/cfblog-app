import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

bool isCompactLayout(BuildContext context) => MediaQuery.sizeOf(context).width < 720;

EdgeInsets pageContentPadding(
  BuildContext context, {
  double top = 0,
  double bottom = 20,
}) {
  final compact = isCompactLayout(context);
  return EdgeInsets.fromLTRB(
    compact ? 12 : 16,
    top,
    compact ? 12 : 16,
    compact ? 14 : bottom,
  );
}

class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppTheme.canvas),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -60,
            child: _GlowBlob(
              size: 320,
              colors: [AppTheme.accentSoft, AppTheme.canvas],
            ),
          ),
          Positioned(
            right: -80,
            top: 100,
            child: _GlowBlob(
              size: 280,
              colors: [Color(0x33D96C3D), Color(0x00D96C3D)],
            ),
          ),
          Positioned(
            bottom: -120,
            right: -40,
            child: _GlowBlob(
              size: 380,
              colors: [Color(0x22173630), Color(0x00FFFFFF)],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactLayout(context);
    final defaultPadding = padding == const EdgeInsets.all(20);
    final resolvedPadding = defaultPadding
        ? EdgeInsets.all(compact ? 14 : 20)
        : padding;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(compact ? 22 : 30),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Color(0x140F1614),
            blurRadius: compact ? 20 : 30,
            offset: Offset(0, compact ? 10 : 18),
          ),
        ],
      ),
      child: Padding(padding: resolvedPadding, child: child),
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = isCompactLayout(context);
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: compact
              ? theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)
              : theme.textTheme.headlineSmall,
        ),
        SizedBox(height: compact ? 4 : 6),
        Text(
          subtitle,
          maxLines: compact ? 2 : null,
          overflow: compact ? TextOverflow.ellipsis : null,
          style: (compact ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium)
              ?.copyWith(color: AppTheme.textMuted),
        ),
      ],
    );

    if (compact && trailing != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock,
          const SizedBox(height: 10),
          trailing!,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleBlock),
        if (trailing case final Widget widget) ...[
          const SizedBox(width: 12),
          widget,
        ],
      ],
    );
  }
}

class ActionSectionHeader extends StatelessWidget {
  const ActionSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const <Widget>[],
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = isCompactLayout(context);
    final hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (compact
                        ? theme.textTheme.titleLarge
                        : theme.textTheme.headlineSmall)
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(width: 12),
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < actions.length; i++) ...[
                        if (i > 0) SizedBox(width: compact ? 8 : 10),
                        actions[i],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        if (hasSubtitle) ...[
          SizedBox(height: compact ? 4 : 6),
          Text(
            subtitle!,
            maxLines: compact ? 2 : null,
            overflow: compact ? TextOverflow.ellipsis : null,
            style: (compact ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium)
                ?.copyWith(color: AppTheme.textMuted),
          ),
        ],
      ],
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
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
    final theme = Theme.of(context);
    final compact = isCompactLayout(context);
    return Container(
      width: compact ? 172 : 220,
      padding: EdgeInsets.all(compact ? 14 : 18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(compact ? 18 : 24),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 36 : 42,
            height: compact ? 36 : 42,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(compact ? 12 : 14),
            ),
            child: Icon(icon, size: compact ? 18 : 22, color: tint),
          ),
          SizedBox(height: compact ? 10 : 16),
          Text(
            value,
            style: (compact ? theme.textTheme.titleLarge : theme.textTheme.headlineSmall)?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactLayout(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 16,
        vertical: compact ? 10 : 14,
      ),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFF8E8E6) : const Color(0xFFEAF4EE),
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
        border: Border.all(
          color: isError ? const Color(0xFFD8A7A3) : const Color(0xFFB8D0C0),
        ),
      ),
      child: Text(message),
    );
  }
}

class EmptyStateCard extends StatelessWidget {
  const EmptyStateCard({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = isCompactLayout(context);
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleLarge),
          SizedBox(height: compact ? 6 : 8),
          Text(
            subtitle,
            style: (compact ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium)?.copyWith(
              color: AppTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class BootPanel extends StatelessWidget {
  const BootPanel({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = isCompactLayout(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: SurfaceCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.8),
            ),
            SizedBox(height: compact ? 12 : 18),
            Text(
              title,
              style: compact ? theme.textTheme.titleLarge : theme.textTheme.headlineSmall,
            ),
            SizedBox(height: compact ? 6 : 8),
            Text(
              subtitle,
              style: (compact ? theme.textTheme.bodySmall : theme.textTheme.bodyMedium)?.copyWith(
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PaginationCard extends StatelessWidget {
  const PaginationCard({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
    this.nextLabel = '下一页',
  });

  final int currentPage;
  final int totalPages;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactLayout(context);
    return SurfaceCard(
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: currentPage <= 1 ? null : onPrevious,
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('上一页'),
            ),
          ),
          SizedBox(width: compact ? 8 : 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: currentPage >= totalPages ? null : onNext,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(nextLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class SelectionChipBar<T> extends StatelessWidget {
  const SelectionChipBar({
    super.key,
    required this.items,
    required this.value,
    required this.labelBuilder,
    required this.onSelected,
  });

  final List<T> items;
  final T value;
  final String Function(T item) labelBuilder;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactLayout(context);
    return Wrap(
      spacing: compact ? 8 : 10,
      runSpacing: compact ? 8 : 10,
      children: items.map((item) {
        return ChoiceChip(
          visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
          materialTapTargetSize: compact
              ? MaterialTapTargetSize.shrinkWrap
              : MaterialTapTargetSize.padded,
          label: Text(labelBuilder(item)),
          selected: item == value,
          onSelected: (_) => onSelected(item),
        );
      }).toList(),
    );
  }
}
