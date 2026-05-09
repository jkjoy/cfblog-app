/// Internal helpers for decoding loosely-typed JSON payloads returned from the
/// CFBlog REST API. The backend occasionally stringifies numbers or returns
/// empty objects for optional fields, so these helpers absorb that noise.
Map<String, dynamic> asJsonMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, entry) => MapEntry(key.toString(), entry));
  }
  return const <String, dynamic>{};
}

List<Object?> asJsonList(Object? value) {
  if (value is List) {
    return value.cast<Object?>();
  }
  return const <Object?>[];
}

String asJsonString(Object? value) => value?.toString() ?? '';

int asJsonInt(Object? value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool asJsonBool(Object? value) {
  if (value is bool) {
    return value;
  }
  final raw = value?.toString().toLowerCase() ?? '';
  return raw == 'true' || raw == '1';
}

List<String> asJsonStringList(Object? value) {
  if (value is List) {
    return value.map((entry) => entry.toString()).toList();
  }
  return const <String>[];
}

Map<String, String> asJsonStringMap(Object? value) {
  return asJsonMap(
    value,
  ).map((key, entry) => MapEntry(key, entry?.toString() ?? ''));
}

List<int> asJsonIntList(Object? value) {
  if (value is List) {
    return value
        .map(asJsonInt)
        .where((entry) => entry > 0)
        .toList();
  }
  return const <int>[];
}
