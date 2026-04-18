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

  test('formatCompactDate returns month-day time by default', () {
    expect(
      formatCompactDate('2026-04-18T09:07:00Z'),
      matches(RegExp(r'^\d{2}-\d{2} \d{2}:\d{2}$')),
    );
  });

  test('formatCompactDate can include year', () {
    expect(
      formatCompactDate('2026-04-18T09:07:00Z', withYear: true),
      matches(RegExp(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}$')),
    );
  });
}
