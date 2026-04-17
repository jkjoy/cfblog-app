import 'package:cfblog_flutter/core/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizeBaseUrl prepends https for bare domains', () {
    expect(normalizeBaseUrl('example.com'), 'https://example.com');
    expect(normalizeBaseUrl('example.com/blog/'), 'https://example.com/blog');
  });

  test('normalizeBaseUrl preserves explicit scheme', () {
    expect(normalizeBaseUrl('http://example.com/'), 'http://example.com');
    expect(
      normalizeBaseUrl('https://example.com/site/'),
      'https://example.com/site',
    );
  });
}
