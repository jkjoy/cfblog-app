import 'package:cfblog_flutter/theme/app_theme.dart';
import 'package:cfblog_flutter/widgets/app_chrome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('selection chip bar reflects current value and changes it', (
    tester,
  ) async {
    var current = 'draft';

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: SelectionChipBar<String>(
                items: const ['publish', 'draft', 'private'],
                value: current,
                labelBuilder: (item) => item,
                onSelected: (value) {
                  setState(() {
                    current = value;
                  });
                },
              ),
            );
          },
        ),
      ),
    );

    ChoiceChip draftChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'draft'),
    );
    expect(draftChip.selected, isTrue);

    await tester.tap(find.widgetWithText(ChoiceChip, 'private'));
    await tester.pumpAndSettle();

    draftChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'draft'),
    );
    final privateChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'private'),
    );

    expect(draftChip.selected, isFalse);
    expect(privateChip.selected, isTrue);
  });
}
