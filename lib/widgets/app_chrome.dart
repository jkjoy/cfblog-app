import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

bool isCompactLayout(BuildContext context) => MediaQuery.sizeOf(context).width < 720;

EdgeInsets pageContentPadding(
  BuildContext context, {
  double top = 0,
  double bottom = 24,
}) {
  final compact = isCompactLayout(context);
  return EdgeInsets.fromLTRB(
    compact ? 14 : 20,
    top,
    compact ? 14 : 20,
    compact ? 18 : bottom,
  );
}

class AppBackdrop extends StatelessWidget {
  const AppBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: AppTheme.canvas),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -60,
            child: _GlowBlob(
              size: 320,
              colors: [
                AppTheme.accent.withValues(alpha: 0.14),
                AppTheme.canvas.withValues(alpha: 0),
              ],
            ),
          ),
          Positioned(
            right: -80,
            top: 100,
            child: _GlowBlob(
              size: 280,
              colors: [
                AppTheme.accent.withValues(alpha: 0.10),
                AppTheme.canvas.withValues(alpha: 0),
              ],
            ),
          ),
          Positioned(
            bottom: -120,
            right: -40,
            child: _GlowBlob(
              size: 380,
              colors: [
                AppTheme.inkPanelSoft.withValues(alpha: 0.40),
                AppTheme.canvas.withValues(alpha: 0),
              ],
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
    this.outlined = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Draw a thin outline instead of the default shadow. Useful for cards that
  /// sit on busy backgrounds (e.g. inside gradients).
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final compact = isCompactLayout(context);
    final defaultPadding = padding == const EdgeInsets.all(20);
    final resolvedPadding = defaultPadding
        ? EdgeInsets.all(compact ? 18 : 24)
        : padding;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
        border: outlined ? Border.all(color: AppTheme.border) : null,
        boxShadow: outlined
            ? null
            : [
                BoxShadow(
                  color: AppTheme.shadow,
                  blurRadius: compact ? 14 : 20,
                  offset: Offset(0, compact ? 4 : 8),
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
          style: (compact
                  ? theme.textTheme.titleLarge
                  : theme.textTheme.headlineSmall)
              ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.2),
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
                    ?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.2,
                    ),
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
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 20,
        vertical: compact ? 16 : 20,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: tint),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 18 : 24),
          Text(
            value,
            style: (compact
                    ? theme.textTheme.headlineSmall
                    : theme.textTheme.headlineMedium)
                ?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              height: 1.0,
              fontFeatures: const [FontFeature.tabularFigures()],
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
        horizontal: compact ? 12 : 14,
        vertical: compact ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: isError ? AppTheme.errorBg : AppTheme.infoBg,
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            size: 16,
            color: isError ? AppTheme.danger : AppTheme.success,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isError ? AppTheme.danger : AppTheme.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
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
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 16 : 20,
        vertical: compact ? 16 : 20,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 18,
            color: AppTheme.textMuted,
          ),
          SizedBox(width: compact ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: compact ? 4 : 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
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
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 16 : 20,
          vertical: compact ? 16 : 20,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: const CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: compact ? 10 : 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: compact ? 4 : 6),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
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
    final theme = Theme.of(context);
    final pageLabel = '第 $currentPage / $totalPages 页';

    final prevEnabled = currentPage > 1;
    final nextEnabled = currentPage < totalPages;

    final labelStyle = theme.textTheme.bodySmall?.copyWith(
      color: AppTheme.textMuted,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 8,
        vertical: compact ? 8 : 12,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: prevEnabled ? onPrevious : null,
            iconSize: 18,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            tooltip: '上一页',
            icon: Icon(
              Icons.arrow_back_rounded,
              color: prevEnabled ? AppTheme.text : AppTheme.textMuted,
            ),
          ),
          Expanded(
            child: Text(
              pageLabel,
              textAlign: TextAlign.center,
              style: labelStyle,
            ),
          ),
          IconButton(
            onPressed: nextEnabled ? onNext : null,
            iconSize: 18,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            tooltip: nextLabel,
            icon: Icon(
              Icons.arrow_forward_rounded,
              color: nextEnabled ? AppTheme.accent : AppTheme.textMuted,
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
