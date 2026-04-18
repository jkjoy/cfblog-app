import 'package:cfblog_flutter/theme/app_theme.dart';
import 'package:cfblog_flutter/widgets/app_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('pagination card triggers previous and next actions', (
    tester,
  ) async {
    var previousTapped = false;
    var nextTapped = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: PaginationCard(
            currentPage: 2,
            totalPages: 3,
            onPrevious: () {
              previousTapped = true;
            },
            onNext: () {
              nextTapped = true;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('上一页'));
    await tester.tap(find.text('下一页'));
    await tester.pump();

    expect(previousTapped, isTrue);
    expect(nextTapped, isTrue);
  });

  testWidgets('pagination card disables actions at boundaries', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: PaginationCard(
            currentPage: 1,
            totalPages: 1,
            onPrevious: () {},
            onNext: () {},
          ),
        ),
      ),
    );

    final previousButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, '上一页'),
    );
    final nextButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '下一页'),
    );

    expect(previousButton.onPressed, isNull);
    expect(nextButton.onPressed, isNull);
    expect(find.text('第 1 / 1 页'), findsOneWidget);
  });
}
