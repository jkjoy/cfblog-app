import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ApiCacheStore {
  ApiCacheStore._();

  static final ApiCacheStore instance = ApiCacheStore._();

  static const _indexKey = 'cfblog_flutter_api_cache_index_v1';
  static const _entryPrefix = 'cfblog_flutter_api_cache_v1::';

  static SharedPreferences? _prefs;
  static final Map<String, CachedHttpResponse> _memory =
      <String, CachedHttpResponse>{};

  Future<CachedHttpResponse?> read(String key) async {
    final memoryEntry = _memory[key];
    if (memoryEntry != null) {
      return memoryEntry;
    }

    final prefs = await _instance();
    if (prefs == null) {
      return null;
    }
    final raw = prefs.getString(_entryKey(key));
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final entry = CachedHttpResponse.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      _memory[key] = entry;
      return entry;
    } catch (_) {
      _memory.remove(key);
      await prefs.remove(_entryKey(key));
      await _saveIndex(
        prefs,
        _index(prefs).where((item) => item != key).toList(growable: false),
      );
      return null;
    }
  }

  Future<void> write(String key, CachedHttpResponse entry) async {
    final prefs = await _instance();
    if (prefs == null) {
      _memory[key] = entry;
      return;
    }
    _memory[key] = entry;
    await prefs.setString(_entryKey(key), jsonEncode(entry.toJson()));

    final index = _index(prefs);
    if (!index.contains(key)) {
      index.add(key);
      await _saveIndex(prefs, index);
    }
  }

  Future<void> invalidateScope(String scopePrefix) async {
    await invalidateWhere((key) => key.startsWith(scopePrefix));
  }

  Future<void> invalidateWhere(bool Function(String key) test) async {
    final prefs = await _instance();
    if (prefs == null) {
      _memory.removeWhere((key, _) => test(key));
      return;
    }
    final index = _index(prefs);
    if (index.isEmpty) {
      return;
    }

    final remaining = <String>[];
    for (final key in index) {
      if (test(key)) {
        _memory.remove(key);
        await prefs.remove(_entryKey(key));
      } else {
        remaining.add(key);
      }
    }
    await _saveIndex(prefs, remaining);
  }

  Future<SharedPreferences?> _instance() async {
    try {
      return _prefs ??= await SharedPreferences.getInstance().timeout(
        const Duration(milliseconds: 500),
      );
    } catch (_) {
      return null;
    }
  }

  List<String> _index(SharedPreferences prefs) {
    return List<String>.from(prefs.getStringList(_indexKey) ?? const <String>[]);
  }

  Future<void> _saveIndex(SharedPreferences prefs, List<String> keys) async {
    await prefs.setStringList(_indexKey, keys);
  }

  String _entryKey(String key) => '$_entryPrefix$key';
}

class CachedHttpResponse {
  const CachedHttpResponse({
    required this.body,
    required this.headers,
    required this.cachedAt,
  });

  final String body;
  final Map<String, String> headers;
  final String cachedAt;

  Map<String, dynamic> toJson() => {
    'body': body,
    'headers': headers,
    'cachedAt': cachedAt,
  };

  factory CachedHttpResponse.fromJson(Map<String, dynamic> json) {
    final headers = json['headers'];
    return CachedHttpResponse(
      body: json['body']?.toString() ?? '',
      headers: headers is Map
          ? headers.map(
              (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
            )
          : const <String, String>{},
      cachedAt: json['cachedAt']?.toString() ?? '',
    );
  }
}
