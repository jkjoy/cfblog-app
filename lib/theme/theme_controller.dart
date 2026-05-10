import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_palette.dart';

/// Lightweight singleton that exposes the active palette and notifies
/// listeners when it changes. Persists selection via [SharedPreferences].
class ThemeController extends ChangeNotifier {
  ThemeController._();

  static final ThemeController instance = ThemeController._();

  static const _storageKey = 'cfblog_flutter_palette_id';

  AppPalette _palette = AppPalettes.midnight;
  AppPalette get palette => _palette;

  bool _loaded = false;
  bool get loaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_storageKey);
      if (saved != null && saved.isNotEmpty) {
        _palette = AppPalettes.byId(saved);
      }
    } catch (_) {
      // Fall back to default palette silently.
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setPalette(AppPalette next) async {
    if (_palette.id == next.id) return;
    _palette = next;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, next.id);
    } catch (_) {
      // Persistence is best-effort.
    }
  }
}
