import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_palette.dart';
import 'theme_controller.dart';

/// Exposes the active palette as static getters so existing call sites
/// (`AppTheme.canvas`, `AppTheme.accent` …) continue to work while the
/// underlying palette can be swapped at runtime.
class AppTheme {
  const AppTheme._();

  static AppPalette get palette => ThemeController.instance.palette;

  static Color get canvas => palette.canvas;
  static Color get surface => palette.surface;
  static Color get surfaceMuted => palette.surfaceMuted;
  static Color get border => palette.border;
  static Color get text => palette.text;
  static Color get textMuted => palette.textMuted;
  static Color get accent => palette.accent;
  static Color get accentSoft => palette.accentSoft;
  static Color get onAccent => palette.onAccent;
  static Color get success => palette.success;
  static Color get warning => palette.warning;
  static Color get danger => palette.danger;
  static Color get inkPanel => palette.inkPanel;
  static Color get inkPanelSoft => palette.inkPanelSoft;
  static Color get inkMuted => palette.inkMuted;
  static Color get infoBg => palette.infoBg;
  static Color get infoBorder => palette.infoBorder;
  static Color get errorBg => palette.errorBg;
  static Color get errorBorder => palette.errorBorder;
  static Color get shadow => palette.shadow;

  /// Builds a [ThemeData] from the given [palette]. Each palette has its own
  /// cached theme so rebuilds on switch are cheap.
  static ThemeData themeFor(AppPalette palette) {
    final scheme = ColorScheme.fromSeed(
      seedColor: palette.accent,
      brightness: palette.brightness,
    ).copyWith(
      primary: palette.accent,
      onPrimary: palette.onAccent,
      surface: palette.surface,
      onSurface: palette.text,
      surfaceContainerHighest: palette.surfaceMuted,
      outline: palette.border,
      outlineVariant: palette.border,
      error: palette.danger,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: palette.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.canvas,
      canvasColor: palette.canvas,
    );

    final bodyText = GoogleFonts.interTextTheme(base.textTheme);

    return base.copyWith(
      splashFactory: InkRipple.splashFactory,
      textTheme: bodyText.copyWith(
        displayLarge: bodyText.displayLarge?.copyWith(
          color: palette.text,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.8,
        ),
        displayMedium: bodyText.displayMedium?.copyWith(
          color: palette.text,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.6,
        ),
        displaySmall: bodyText.displaySmall?.copyWith(
          color: palette.text,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
        headlineLarge: bodyText.headlineLarge?.copyWith(
          color: palette.text,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        headlineMedium: bodyText.headlineMedium?.copyWith(
          color: palette.text,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        headlineSmall: bodyText.headlineSmall?.copyWith(
          color: palette.text,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        titleLarge: bodyText.titleLarge?.copyWith(
          color: palette.text,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.1,
        ),
        titleMedium: bodyText.titleMedium?.copyWith(
          color: palette.text,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: bodyText.titleSmall?.copyWith(
          color: palette.text,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: bodyText.bodyLarge?.copyWith(color: palette.text, height: 1.5),
        bodyMedium: bodyText.bodyMedium?.copyWith(color: palette.text, height: 1.5),
        bodySmall: bodyText.bodySmall?.copyWith(color: palette.textMuted, height: 1.45),
      ),
      dividerColor: palette.border,
      iconTheme: IconThemeData(color: palette.text, size: 18),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.accent,
          foregroundColor: palette.onAccent,
          disabledBackgroundColor: palette.surfaceMuted,
          disabledForegroundColor: palette.textMuted,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: bodyText.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.text,
          disabledForegroundColor: palette.textMuted,
          side: BorderSide(color: palette.border),
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: bodyText.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.text,
          minimumSize: const Size(0, 40),
          textStyle: bodyText.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: palette.textMuted,
          hoverColor: palette.accent.withValues(alpha: 0.10),
          splashFactory: InkRipple.splashFactory,
          minimumSize: const Size(36, 36),
          iconSize: 18,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceMuted,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: palette.accent, width: 1.4),
        ),
        hintStyle: bodyText.bodyMedium?.copyWith(color: palette.textMuted),
        labelStyle: bodyText.bodyMedium?.copyWith(color: palette.textMuted),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: palette.surfaceMuted,
        selectedColor: palette.accent,
        side: BorderSide(color: palette.border),
        labelStyle: bodyText.bodyMedium?.copyWith(
          color: palette.text,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: bodyText.bodyMedium?.copyWith(
          color: palette.onAccent,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.surface,
        indicatorColor: palette.accentSoft,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => bodyText.bodySmall?.copyWith(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? palette.accent
                : palette.textMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? palette.accent
                : palette.textMuted,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: palette.inkPanelSoft,
        contentTextStyle: bodyText.bodyMedium?.copyWith(color: palette.text),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: palette.border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        surfaceTintColor: Colors.transparent,
      ).copyWith(backgroundColor: palette.surface),
      dividerTheme: DividerThemeData(color: palette.border, space: 1),
      progressIndicatorTheme:
          ProgressIndicatorThemeData(color: palette.accent),
    );
  }

  /// Convenience: theme for the current palette.
  static ThemeData active() => themeFor(palette);

  /// Back-compat shim for existing tests and legacy call sites.
  static ThemeData light() => themeFor(palette);
}
