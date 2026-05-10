import 'package:flutter/material.dart';

/// A self-contained color palette. All UI tokens the app needs live here so a
/// single switch can reshape the whole interface.
@immutable
class AppPalette {
  const AppPalette({
    required this.id,
    required this.name,
    required this.description,
    required this.brightness,
    required this.canvas,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.accent,
    required this.accentSoft,
    required this.onAccent,
    required this.success,
    required this.warning,
    required this.danger,
    required this.inkPanel,
    required this.inkPanelSoft,
    required this.inkMuted,
    required this.infoBg,
    required this.infoBorder,
    required this.errorBg,
    required this.errorBorder,
    required this.shadow,
  });

  final String id;
  final String name;
  final String description;
  final Brightness brightness;

  final Color canvas;
  final Color surface;
  final Color surfaceMuted;
  final Color border;
  final Color text;
  final Color textMuted;
  final Color accent;
  final Color accentSoft;
  final Color onAccent;
  final Color success;
  final Color warning;
  final Color danger;
  final Color inkPanel;
  final Color inkPanelSoft;
  final Color inkMuted;
  final Color infoBg;
  final Color infoBorder;
  final Color errorBg;
  final Color errorBorder;
  final Color shadow;

  bool get isDark => brightness == Brightness.dark;
}

/// Curated list of themes exposed to the user.
class AppPalettes {
  AppPalettes._();

  /// Default — dark graphite with amber accent.
  static const AppPalette midnight = AppPalette(
    id: 'midnight',
    name: '深夜琥珀',
    description: '墨黑底 · 琥珀点缀',
    brightness: Brightness.dark,
    canvas: Color(0xFF0E0F13),
    surface: Color(0xFF171A21),
    surfaceMuted: Color(0xFF20242D),
    border: Color(0xFF2A2F3B),
    text: Color(0xFFECEDF0),
    textMuted: Color(0xFF8A91A0),
    accent: Color(0xFFF4A340),
    accentSoft: Color(0xFF3A2A17),
    onAccent: Color(0xFF1A1200),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    inkPanel: Color(0xFF1B1F28),
    inkPanelSoft: Color(0xFF252A35),
    inkMuted: Color(0xFFA6ADBB),
    infoBg: Color(0xFF1C2A1F),
    infoBorder: Color(0xFF2F5034),
    errorBg: Color(0xFF2A1B1D),
    errorBorder: Color(0xFF5A2E32),
    shadow: Color(0x66000000),
  );

  /// Deep slate with icy blue — Nord style.
  static const AppPalette nord = AppPalette(
    id: 'nord',
    name: '极夜冰蓝',
    description: '石墨底 · 冰蓝点缀',
    brightness: Brightness.dark,
    canvas: Color(0xFF0F1720),
    surface: Color(0xFF1A2432),
    surfaceMuted: Color(0xFF223040),
    border: Color(0xFF2E3D50),
    text: Color(0xFFE5EEF6),
    textMuted: Color(0xFF8FA1B4),
    accent: Color(0xFF7EC8E3),
    accentSoft: Color(0xFF1A2F3F),
    onAccent: Color(0xFF071721),
    success: Color(0xFF68D391),
    warning: Color(0xFFF6C75A),
    danger: Color(0xFFF08A8A),
    inkPanel: Color(0xFF18212E),
    inkPanelSoft: Color(0xFF223040),
    inkMuted: Color(0xFFA8BACD),
    infoBg: Color(0xFF17293A),
    infoBorder: Color(0xFF28476A),
    errorBg: Color(0xFF2A1B1D),
    errorBorder: Color(0xFF5A2E32),
    shadow: Color(0x66000000),
  );

  /// Deep forest with emerald accent.
  static const AppPalette forest = AppPalette(
    id: 'forest',
    name: '深林翡翠',
    description: '森绿底 · 翡翠点缀',
    brightness: Brightness.dark,
    canvas: Color(0xFF0C1412),
    surface: Color(0xFF131E1B),
    surfaceMuted: Color(0xFF1B2926),
    border: Color(0xFF263530),
    text: Color(0xFFE6EEEB),
    textMuted: Color(0xFF8A9B95),
    accent: Color(0xFF5EEAD4),
    accentSoft: Color(0xFF152B27),
    onAccent: Color(0xFF041611),
    success: Color(0xFF86EFAC),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    inkPanel: Color(0xFF16221F),
    inkPanelSoft: Color(0xFF1F2D29),
    inkMuted: Color(0xFFA6BAB2),
    infoBg: Color(0xFF152B27),
    infoBorder: Color(0xFF2F5048),
    errorBg: Color(0xFF2A1B1D),
    errorBorder: Color(0xFF5A2E32),
    shadow: Color(0x66000000),
  );

  /// Rich plum with magenta accent.
  static const AppPalette plum = AppPalette(
    id: 'plum',
    name: '夜幕绯红',
    description: '紫夜底 · 绯红点缀',
    brightness: Brightness.dark,
    canvas: Color(0xFF120E17),
    surface: Color(0xFF1C1624),
    surfaceMuted: Color(0xFF271F32),
    border: Color(0xFF342940),
    text: Color(0xFFEDE7F2),
    textMuted: Color(0xFF9A8FAB),
    accent: Color(0xFFF472B6),
    accentSoft: Color(0xFF33182A),
    onAccent: Color(0xFF1A0712),
    success: Color(0xFF4ADE80),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFFF8787),
    inkPanel: Color(0xFF1F1828),
    inkPanelSoft: Color(0xFF2B2238),
    inkMuted: Color(0xFFB0A4C0),
    infoBg: Color(0xFF1C2A1F),
    infoBorder: Color(0xFF2F5034),
    errorBg: Color(0xFF2E1721),
    errorBorder: Color(0xFF5C2A3D),
    shadow: Color(0x66000000),
  );

  /// Neutral graphite monochrome.
  static const AppPalette mono = AppPalette(
    id: 'mono',
    name: '纯粹灰调',
    description: '中性灰 · 无色点缀',
    brightness: Brightness.dark,
    canvas: Color(0xFF101012),
    surface: Color(0xFF17171A),
    surfaceMuted: Color(0xFF202024),
    border: Color(0xFF2B2B30),
    text: Color(0xFFEDEDEF),
    textMuted: Color(0xFF8C8C92),
    accent: Color(0xFFE6E6EA),
    accentSoft: Color(0xFF2A2A2E),
    onAccent: Color(0xFF0C0C0E),
    success: Color(0xFF8FDCAE),
    warning: Color(0xFFE7C56C),
    danger: Color(0xFFEF9898),
    inkPanel: Color(0xFF17171A),
    inkPanelSoft: Color(0xFF202024),
    inkMuted: Color(0xFFA4A4A9),
    infoBg: Color(0xFF1C2A1F),
    infoBorder: Color(0xFF2F5034),
    errorBg: Color(0xFF2A1B1D),
    errorBorder: Color(0xFF5A2E32),
    shadow: Color(0x80000000),
  );

  /// Off-white daylight theme for those who prefer light.
  static const AppPalette daylight = AppPalette(
    id: 'daylight',
    name: '晨曦日光',
    description: '象牙白 · 靛蓝点缀',
    brightness: Brightness.light,
    canvas: Color(0xFFF6F5F2),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF1EFEA),
    border: Color(0xFFE3DFD8),
    text: Color(0xFF1B1D22),
    textMuted: Color(0xFF6B7280),
    accent: Color(0xFF4F46E5),
    accentSoft: Color(0xFFE4E2FB),
    onAccent: Color(0xFFFFFFFF),
    success: Color(0xFF16A34A),
    warning: Color(0xFFB45309),
    danger: Color(0xFFB91C1C),
    inkPanel: Color(0xFF1F2328),
    inkPanelSoft: Color(0xFF2A2F36),
    inkMuted: Color(0xFFC8CBD1),
    infoBg: Color(0xFFE9F5EE),
    infoBorder: Color(0xFFBEDDC6),
    errorBg: Color(0xFFFBECEB),
    errorBorder: Color(0xFFE8BDBA),
    shadow: Color(0x14000000),
  );

  static const List<AppPalette> all = [
    midnight,
    nord,
    forest,
    plum,
    mono,
    daylight,
  ];

  static AppPalette byId(String? id) {
    if (id == null) return midnight;
    for (final palette in all) {
      if (palette.id == id) return palette;
    }
    return midnight;
  }
}
