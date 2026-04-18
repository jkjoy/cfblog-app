import 'dart:convert';

import 'package:cfblog_flutter/app.dart';
import 'package:cfblog_flutter/core/models.dart';
import 'package:cfblog_flutter/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('mobile workspace navigation uses bottom bar and workspace sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final client = MockClient((request) async {
      final path = request.url.path;
      return switch (path) {
        String p when p.endsWith('/comments') => http.Response(
          '[]',
          200,
          headers: const {'x-wp-total': '6', 'x-wp-totalpages': '1'},
        ),
        String p when p.endsWith('/posts') => http.Response(
          '[]',
          200,
          headers: const {'x-wp-total': '8', 'x-wp-totalpages': '1'},
        ),
        String p when p.endsWith('/media') => http.Response(
          '[]',
          200,
          headers: const {'x-wp-total': '12', 'x-wp-totalpages': '1'},
        ),
        String p when p.endsWith('/pages') => http.Response(
          '[]',
          200,
          headers: const {'x-wp-total': '4', 'x-wp-totalpages': '1'},
        ),
        String p when p.endsWith('/moments') => http.Response(
          '[]',
          200,
          headers: const {'x-wp-total': '3', 'x-wp-totalpages': '1'},
        ),
        String p when p.endsWith('/users') => http.Response(
          '[]',
          200,
          headers: const {'x-wp-total': '2', 'x-wp-totalpages': '1'},
        ),
        _ => http.Response(jsonEncode([]), 200),
      };
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: WorkspaceShell(
          config: const AppConfig(baseUrl: 'https://example.com'),
          discovery: const DiscoveryInfo(
            name: 'CFBlog Site',
            description: '',
            url: 'https://example.com',
            home: 'https://example.com',
          ),
          session: const SessionState(
            token: 'token',
            user: SessionUser(
              id: 1,
              name: 'LT',
              slug: 'lt',
              description: '',
              email: 'lt@example.com',
              roles: ['administrator'],
              role: 'administrator',
              registeredDate: '2026-04-16T10:00:00',
              avatarUrls: {},
            ),
          ),
          client: client,
          initialTab: WorkspaceTab.comments,
          onLogout: () async {},
          onResetSite: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CFBlog Site'), findsOneWidget);
    expect(find.text('评论'), findsWidgets);
    expect(find.text('撰写'), findsOneWidget);

    await tester.tap(find.byTooltip('站点信息'));
    await tester.pumpAndSettle();

    expect(find.text('站点信息'), findsOneWidget);
    expect(find.text('切换站点'), findsOneWidget);

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('全部工作区'));
    await tester.pumpAndSettle();

    expect(find.text('全部工作区'), findsOneWidget);
    expect(find.text('常用入口'), findsOneWidget);
    expect(find.text('内容发布'), findsOneWidget);
    expect(find.text('互动运营'), findsOneWidget);
    expect(find.text('系统设置'), findsOneWidget);
    expect(find.text('分类标签'), findsOneWidget);
    expect(find.text('系统'), findsOneWidget);
  });
}
