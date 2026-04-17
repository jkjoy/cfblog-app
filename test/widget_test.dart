import 'package:cfblog_flutter/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders the connection screen when no session is stored', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const CfblogApp());
    await tester.pumpAndSettle();

    expect(find.text('连接你的 CFBlog 站点'), findsOneWidget);
  });
}
