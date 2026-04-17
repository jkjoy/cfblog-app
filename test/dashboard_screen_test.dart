import 'dart:convert';

import 'package:cfblog_flutter/core/cfblog_api.dart';
import 'package:cfblog_flutter/core/models.dart';
import 'package:cfblog_flutter/features/dashboard/dashboard_screen.dart';
import 'package:cfblog_flutter/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('dashboard exposes workspace launch cards and actions', (
    tester,
  ) async {
    var openedSystem = false;

    final api = CfblogApi(
      'https://example.com',
      token: 'token',
      client: MockClient((request) async {
        final path = request.url.path;
        final perPage = request.url.queryParameters['per_page'];

        if (path.endsWith('/posts')) {
          if (perPage == '4') {
            return http.Response(
              jsonEncode([
                {
                  'id': 7,
                  'date': '2026-04-17T12:00:00',
                  'modified': '2026-04-17T13:00:00',
                  'slug': 'hello-flutter',
                  'status': 'publish',
                  'type': 'post',
                  'title': {'rendered': 'Hello Flutter'},
                  'excerpt': {'rendered': 'A dashboard test post.'},
                  'content': {'rendered': '<p>Body</p>'},
                  'author_name': 'LT',
                  'featured_media': 0,
                  'featured_image_url': '',
                  'sticky': false,
                  'parent': 0,
                  'comment_status': 'open',
                  'categories': [1],
                  'tags': [2],
                  'comment_count': 3,
                  'view_count': 99,
                  'link': 'https://example.com/hello-flutter',
                },
              ]),
              200,
              headers: const {'x-wp-total': '8', 'x-wp-totalpages': '1'},
            );
          }
          return http.Response(
            '[]',
            200,
            headers: const {'x-wp-total': '8', 'x-wp-totalpages': '1'},
          );
        }

        if (path.endsWith('/pages')) {
          return http.Response(
            '[]',
            200,
            headers: const {'x-wp-total': '3', 'x-wp-totalpages': '1'},
          );
        }

        if (path.endsWith('/moments')) {
          return http.Response(
            '[]',
            200,
            headers: const {'x-wp-total': '5', 'x-wp-totalpages': '1'},
          );
        }

        if (path.endsWith('/comments')) {
          return http.Response(
            '[]',
            200,
            headers: const {'x-wp-total': '11', 'x-wp-totalpages': '1'},
          );
        }

        if (path.endsWith('/media')) {
          return http.Response(
            '[]',
            200,
            headers: const {'x-wp-total': '14', 'x-wp-totalpages': '2'},
          );
        }

        if (path.endsWith('/users')) {
          return http.Response(
            '[]',
            200,
            headers: const {'x-wp-total': '4', 'x-wp-totalpages': '1'},
          );
        }

        throw Exception('Unhandled request: ${request.url}');
      }),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: DashboardScreen(
            api: api,
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
            onOpenPosts: () {},
            onOpenTaxonomies: () {},
            onOpenLinks: () {},
            onOpenSystem: () {
              openedSystem = true;
            },
            onOpenPages: () {},
            onOpenMoments: () {},
            onOpenMedia: () {},
            onOpenComments: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('工作区入口'), findsOneWidget);
    final openSystemButton = find.widgetWithText(OutlinedButton, '打开系统');

    expect(openSystemButton, findsOneWidget);
    expect(find.text('Hello Flutter'), findsOneWidget);

    await tester.ensureVisible(openSystemButton);
    await tester.pumpAndSettle();
    await tester.tap(openSystemButton);
    await tester.pumpAndSettle();

    expect(openedSystem, isTrue);
  });
}
