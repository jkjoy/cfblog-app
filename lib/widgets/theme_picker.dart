import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_theme.dart';
import '../theme/theme_controller.dart';
import 'app_chrome.dart';

/// Surface card that lets the user pick one of the curated palettes.
/// Selection is applied immediately and persisted by [ThemeController].
class ThemePickerSection extends StatelessWidget {
  const ThemePickerSection({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeController.instance,
      builder: (context, _) {
        final active = ThemeController.instance.palette;
        final theme = Theme.of(context);
        final compact = isCompactLayout(context);
        return SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '外观主题',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: compact ? 4 : 6),
              Text(
                '选择配色方案，设置将立即生效并保存在本地。',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
              SizedBox(height: compact ? 12 : 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final columns = width >= 720
                      ? 3
                      : width >= 420
                          ? 2
                          : 1;
                  const spacing = 10.0;
                  final tileWidth =
                      (width - spacing * (columns - 1)) / columns;
                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      for (final palette in AppPalettes.all)
                        SizedBox(
                          width: tileWidth,
                          child: _PaletteTile(
                            palette: palette,
                            active: palette.id == active.id,
                            onTap: () {
                              ThemeController.instance.setPalette(palette);
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PaletteTile extends StatelessWidget {
  const _PaletteTile({
    required this.palette,
    required this.active,
    required this.onTap,
  });

  final AppPalette palette;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: active
                ? palette.accent.withValues(alpha: 0.10)
                : AppTheme.surfaceMuted,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: active
                  ? palette.accent.withValues(alpha: 0.55)
                  : AppTheme.border,
              width: active ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              _PalettePreview(palette: palette),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            palette.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (active)
                          Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: palette.accent,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      palette.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}

class _PalettePreview extends StatelessWidget {
  const _PalettePreview({required this.palette});

  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: palette.canvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 6,
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: palette.accent,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: palette.textMuted,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
