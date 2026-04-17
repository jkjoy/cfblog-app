import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color canvas = Color(0xFFF1ECE4);
  static const Color surface = Color(0xFFFFFCF7);
  static const Color surfaceMuted = Color(0xFFF6F0E8);
  static const Color border = Color(0xFFD7CBBE);
  static const Color text = Color(0xFF1E2824);
  static const Color textMuted = Color(0xFF67736D);
  static const Color accent = Color(0xFFD96C3D);
  static const Color accentSoft = Color(0xFFF6D7C8);
  static const Color success = Color(0xFF2F7A59);
  static const Color warning = Color(0xFFA46A18);
  static const Color danger = Color(0xFFAB4949);
  static const Color inkPanel = Color(0xFF173630);
  static const Color inkPanelSoft = Color(0xFF22443E);
  static const Color inkMuted = Color(0xFFC2D0CA);

  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: accent,
          brightness: Brightness.light,
        ).copyWith(
          primary: accent,
          secondary: const Color(0xFF21544B),
          surface: surface,
          surfaceContainerHighest: surfaceMuted,
          outline: border,
          error: danger,
          onPrimary: Colors.white,
          onSurface: text,
          onSecondary: Colors.white,
        );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: canvas,
    );

    final bodyText = GoogleFonts.ibmPlexSansTextTheme(base.textTheme);
    final display = GoogleFonts.spaceGroteskTextTheme(base.textTheme);

    return base.copyWith(
      splashFactory: InkRipple.splashFactory,
      textTheme: bodyText.copyWith(
        displayLarge: display.displayLarge?.copyWith(
          color: text,
          fontWeight: FontWeight.w700,
        ),
        displayMedium: display.displayMedium?.copyWith(
          color: text,
          fontWeight: FontWeight.w700,
        ),
        displaySmall: display.displaySmall?.copyWith(
          color: text,
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: display.headlineLarge?.copyWith(
          color: text,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: display.headlineMedium?.copyWith(
          color: text,
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: display.headlineSmall?.copyWith(
          color: text,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: display.titleLarge?.copyWith(
          color: text,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: bodyText.titleMedium?.copyWith(
          color: text,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: bodyText.bodyLarge?.copyWith(color: text, height: 1.45),
        bodyMedium: bodyText.bodyMedium?.copyWith(color: text, height: 1.45),
        bodySmall: bodyText.bodySmall?.copyWith(color: textMuted, height: 1.4),
      ),
      dividerColor: border,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: bodyText.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: const BorderSide(color: border),
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: bodyText.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: text,
          minimumSize: const Size(0, 48),
          textStyle: bodyText.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: accent, width: 1.4),
        ),
        hintStyle: bodyText.bodyMedium?.copyWith(color: textMuted),
        labelStyle: bodyText.bodyMedium?.copyWith(color: textMuted),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surfaceMuted,
        selectedColor: inkPanel,
        side: const BorderSide(color: border),
        labelStyle: bodyText.bodyMedium?.copyWith(
          color: text,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: bodyText.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: accentSoft,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => bodyText.bodySmall?.copyWith(
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w600,
            color: text,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: inkPanel,
        contentTextStyle: bodyText.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
