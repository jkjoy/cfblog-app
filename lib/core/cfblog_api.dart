import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import 'formatters.dart';
import 'media_upload.dart';
import 'models.dart';

enum ApiRoot { root, v2 }

class CfblogApi {
  CfblogApi(this.baseUrl, {this.token, http.Client? client})
    : _client = client ?? http.Client();

  final String baseUrl;
  final String? token;
  final http.Client _client;

  String get normalizedBaseUrl => normalizeBaseUrl(baseUrl);

  Uri _buildUri(
    String path, {
    Map<String, dynamic>? query,
    ApiRoot root = ApiRoot.v2,
  }) {
    final prefix = root == ApiRoot.root
        ? '$normalizedBaseUrl/wp-json'
        : '$normalizedBaseUrl/wp-json/wp/v2';
    final resolvedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$prefix$resolvedPath');
    if (query == null || query.isEmpty) {
      return uri;
    }

    return uri.replace(
      queryParameters: {
        for (final entry in query.entries)
          if (entry.value != null && entry.value.toString().trim().isNotEmpty)
            entry.key: entry.value.toString(),
      },
    );
  }

  Future<_ApiResponse<T>> _request<T>(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
    ApiRoot root = ApiRoot.v2,
    required T Function(Object? json) decoder,
  }) async {
    final request = http.Request(
      method,
      _buildUri(path, query: query, root: root),
    )..headers['accept'] = 'application/json';

    if (token != null && token!.isNotEmpty) {
      request.headers['authorization'] = 'Bearer $token';
    }

    if (body != null) {
      request.headers['content-type'] = 'application/json';
      request.body = jsonEncode(body);
    }

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    Object? payload;

    if (response.body.isNotEmpty) {
      try {
        payload = jsonDecode(response.body);
      } catch (_) {
        payload = response.body;
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = switch (payload) {
        {'message': final String message} => message,
        {'error': final String error} => error,
        _ => 'Request failed with status ${response.statusCode}',
      };
      throw Exception(message);
    }

    return _ApiResponse(data: decoder(payload), headers: response.headers);
  }

  Future<DiscoveryInfo> getDiscovery() async {
    final result = await _request(
      '/',
      root: ApiRoot.root,
      decoder: (json) => DiscoveryInfo.fromJson(_asMap(json)),
    );
    return result.data;
  }

  Future<SessionState> login({
    required String username,
    required String password,
  }) async {
    final result = await _request(
      '/users/login',
      method: 'POST',
      body: {'username': username, 'password': password},
      decoder: (json) {
        final map = _asMap(json);
        return SessionState(
          token: map['token']?.toString() ?? '',
          user: SessionUser.fromJson(_asMap(map['user'])),
        );
      },
    );
    return result.data;
  }

  Future<SessionUser> getCurrentUser() async {
    final result = await _request(
      '/users/me',
      decoder: (json) => SessionUser.fromJson(_asMap(json)),
    );
    return result.data;
  }

  Future<PagedResponse<WpPost>> listPosts({
    int page = 1,
    int perPage = 12,
    String search = '',
    String status = 'publish',
  }) async {
    final result = await _request<List<WpPost>>(
      '/posts',
      query: {
        'page': page,
        'per_page': perPage,
        'search': search,
        'status': status,
      },
      decoder: (json) =>
          _asList(json).map((entry) => WpPost.fromJson(_asMap(entry))).toList(),
    );
    return PagedResponse<WpPost>(
      items: result.data,
      total:
          int.tryParse(result.headers['x-wp-total'] ?? '') ??
          result.data.length,
      totalPages: int.tryParse(result.headers['x-wp-totalpages'] ?? '') ?? 1,
    );
  }

  Future<PagedResponse<WpPost>> listPages({
    int page = 1,
    int perPage = 12,
    String status = 'all',
  }) async {
    final result = await _request<List<WpPost>>(
      '/pages',
      query: {'page': page, 'per_page': perPage, 'status': status},
      decoder: (json) =>
          _asList(json).map((entry) => WpPost.fromJson(_asMap(entry))).toList(),
    );
    return PagedResponse<WpPost>(
      items: result.data,
      total:
          int.tryParse(result.headers['x-wp-total'] ?? '') ??
          result.data.length,
      totalPages: int.tryParse(result.headers['x-wp-totalpages'] ?? '') ?? 1,
    );
  }

  Future<WpPost> getPost(int id) async {
    final result = await _request(
      '/posts/$id',
      decoder: (json) => WpPost.fromJson(_asMap(json)),
    );
    return result.data;
  }

  Future<WpPost> getPage(int id) async {
    final result = await _request(
      '/pages/$id',
      decoder: (json) => WpPost.fromJson(_asMap(json)),
    );
    return result.data;
  }

  Future<PagedResponse<WpTerm>> listCategories({
    int page = 1,
    int perPage = 100,
    String search = '',
  }) async {
    final result = await _request<List<WpTerm>>(
      '/categories',
      query: {'page': page, 'per_page': perPage, 'search': search},
      decoder: (json) =>
          _asList(json).map((entry) => WpTerm.fromJson(_asMap(entry))).toList(),
    );
    return PagedResponse<WpTerm>(
      items: result.data,
      total:
          int.tryParse(result.headers['x-wp-total'] ?? '') ??
          result.data.length,
      totalPages: int.tryParse(result.headers['x-wp-totalpages'] ?? '') ?? 1,
    );
  }

  Future<PagedResponse<WpTerm>> listTags({
    int page = 1,
    int perPage = 100,
    String search = '',
  }) async {
    final result = await _request<List<WpTerm>>(
      '/tags',
      query: {'page': page, 'per_page': perPage, 'search': search},
      decoder: (json) =>
          _asList(json).map((entry) => WpTerm.fromJson(_asMap(entry))).toList(),
    );
    return PagedResponse<WpTerm>(
      items: result.data,
      total:
          int.tryParse(result.headers['x-wp-total'] ?? '') ??
          result.data.length,
      totalPages: int.tryParse(result.headers['x-wp-totalpages'] ?? '') ?? 1,
    );
  }

  Future<PostReferences> getPostReferences() async {
    final results = await Future.wait<PagedResponse<WpTerm>>([
      listCategories(),
      listTags(),
    ]);
    return PostReferences(categories: results[0].items, tags: results[1].items);
  }

  Future<WpTerm> createCategory(Map<String, dynamic> payload) async {
    final result = await _request(
      '/categories',
      method: 'POST',
      body: payload,
      decoder: (json) => WpTerm.fromJson(_asMap(json)),
    );
    return result.data;
  }

  Future<WpTerm> updateCategory(int id, Map<String, dynamic> payload) async {
    final result = await _request(
      '/categories/$id',
      method: 'PUT',
      body: payload,
      decoder: (json) => WpTerm.fromJson(_asMap(json)),
    );
    return result.data;
  }

  Future<void> deleteCategory(int id) async {
    await _request(
      '/categories/$id',
      method: 'DELETE',
      query: {'force': true},
      decoder: (json) => json,
    );
  }

  Future<WpTerm> createTag(Map<String, dynamic> payload) async {
    final result = await _request(
      '/tags',
      method: 'POST',
      body: payload,
      decoder: (json) => WpTerm.fromJson(_asMap(json)),
    );
    return result.data;
  }

  Future<WpTerm> updateTag(int id, Map<String, dynamic> payload) async {
    final result = await _request(
      '/tags/$id',
      method: 'PUT',
      body: payload,
      decoder: (json) => WpTerm.fromJson(_asMap(json)),
    );
    return result.data;
  }

  Future<void> deleteTag(int id) async {
    await _request(
      '/tags/$id',
      method: 'DELETE',
      query: {'force': true},
      decoder: (json) => json,
    );
  }

  Future<PagedResponse<WpLink>> listLinks({
    int page = 1,
    int perPage = 12,
    String visible = 'yes',
  }) async {
    final result = await _request<List<WpLink>>(
      '/links',
      query: {'page': page, 'per_page': perPage, 'visible': visible},
      decoder: (json) =>
          _asList(json).map((entry) => WpLink.fromJson(_asMap(entry))).toList(),
    );
    return PagedResponse<WpLink>(
      items: result.data,
      total:
          int.tryParse(result.headers['x-wp-total'] ?? '') ??
          result.data.length,
      totalPages: int.tryParse(result.headers['x-wp-totalpages'] ?? '') ?? 1,
    );
  }

  Future<List<WpLinkCategory>> listLinkCategories() async {
    final result = await _request<List<WpLinkCategory>>(
      '/link-categories',
      decoder: (json) => _asList(
        json,
      ).map((entry) => WpLinkCategory.fromJson(_asMap(entry))).toList(),
    );
    return result.data;
  }

  Future<WpLink> createLink(Map<String, dynamic> payload) async {
    final result = await _request(
      '/links',
      method: 'POST',
      body: payload,
      decoder: (json) => WpLink.fromJson(_asMap(json)),
    );
    return result.data;
  }

  Future<WpLink> updateLink(int id, Map<String, dynamic> payload) async {
    final result = await _request(
      '/links/$id',
      method: 'PUT',
      body: payload,
      decoder: (json) => WpLink.fromJson(_asMap(json)),
    );
    return result.data;
  }

  Future<void> deleteLink(int id) async {
    await _request('/links/$id', method: 'DELETE', decoder: (json) => json);
  }

  Future<WpLinkCategory> createLinkCategory(
    Map<String, dynamic> payload,
  ) async {
    final result = await _request(
      '/link-categories',
      method: 'POST',
      body: payload,
      decoder: (json) => WpLinkCategory.fromJson(_asMap(json)),
    );
    return result.data;
  }

  Future<WpLinkCategory> updateLinkCategory(
    int id,
    Map<String, dynamic> payload,
  ) async {
    final result = await _request(
      '/link-categories/$id',
      method: 'PUT',
      body: payload,
      decoder: (json) => WpLinkCategory.fromJson(_asMap(json)),
    );
    return result.data;
  }

  Future<void> deleteLinkCategory(int id) async {
    await _request(
      '/link-categories/$id',
      method: 'DELETE',
      decoder: (json) => json,
    );
  }

  Future<PagedResponse<SessionUser>> listUsers({
    int page = 1,
    int perPage = 12,
    String search = '',
    String role = '',
  }) async {
    final result = await _request<List<SessionUser>>(
      '/users',
      query: {
        'page': page,
        'per_page': perPage,
        'search': search,
        'role': role,
      },
      decoder: (json) => _asList(
        json,
      ).map((entry) => SessionUser.fromJson(_asMap(entry))).toList(),
    );
    return PagedResponse<SessionUser>(
      items: result.data,
      total:
          int.tryParse(result.headers['x-wp-total'] ?? '') ??
          result.data.length,
      totalPages: int.tryParse(result.headers['x-wp-totalpages'] ?? '') ?? 1,
    );
  }

  Future<Map<String, String>> getSettings({bool admin = true}) async {
    final result = await _request(
      admin ? '/settings/admin' : '/settings',
      decoder: (json) => _asMap(
        json,
      ).map((key, value) => MapEntry(key, value?.toString() ?? '')),
    );
    return result.data;
  }

  Future<void> updateSettings(Map<String, String> payload) async {
    await _request(
      '/settings',
      method: 'PUT',
      body: payload,
      decoder: (json) => json,
    );
  }

  Future<SessionUser> createUser(Map<String, dynamic> payload) async {
    final result = await _request(
      '/users',
      method: 'POST',
      body: payload,
      decoder: (json) => SessionUser.fromJson(_asMap(json)),
    );
    return result.data;
  }

  Future<SessionUser> updateUser(int id, Map<String, dynamic> payload) async {
    final result = await _request(
      '/users/$id',
      method: 'PUT',
      body: payload,
      decoder: (json) => SessionUser.fromJson(_asMap(json)),
    );
    return result.data;
  }

  Future<void> deleteUser(int id) async {
    await _request('/users/$id', method: 'DELETE', decoder: (json) => json);
  }

  Future<WpPost> createPost(Map<String, dynamic> payload) async {
    final result = await _request(
      '/posts',
      method: 'POST',
      body: payload,
      decoder: (json) => WpPost.fromJson(_asMap(json)),
    );
    return result.data;
  }

  Future<WpPost> updatePost(int id, Map<String, dynamic> payload) async {
    final result = await _request(
      '/posts/$id',
      method: 'PUT',
      body: payload,
      decoder: (json) => WpPost.fromJson(_asMap(json)),
    );
    return result.data;
  }

  Future<WpPost> createPage(Map<String, dynamic> payload) async {
    final result = await _request(
      '/pages',
      method: 'POST',
      body: payload,
      decoder: (json) => WpPost.fromJson(_asMap(json)),
    );
    return result.data;
  }

  Future<WpPost> updatePage(int id, Map<String, dynamic> payload) async {
    final result = await _request(
      '/pages/$id',
      method: 'PUT',
      body: payload,
      decoder: (json) => WpPost.fromJson(_asMap(json)),
    );
    return result.data;
  }

  Future<void> deletePage(int id) async {
    await _request('/pages/$id', method: 'DELETE', decoder: (json) => json);
  }

  Future<PagedResponse<WpMedia>> listMedia({
    int page = 1,
    int perPage = 12,
  }) async {
    final result = await _request<List<WpMedia>>(
      '/media',
      query: {'page': page, 'per_page': perPage},
      decoder: (json) => _asList(
        json,
      ).map((entry) => WpMedia.fromJson(_asMap(entry))).toList(),
    );
    return PagedResponse<WpMedia>(
      items: result.data,
      total:
          int.tryParse(result.headers['x-wp-total'] ?? '') ??
          result.data.length,
      totalPages: int.tryParse(result.headers['x-wp-totalpages'] ?? '') ?? 1,
    );
  }

  Future<WpMedia> updateMedia(int id, Map<String, dynamic> payload) async {
    final result = await _request(
      '/media/$id',
      method: 'PUT',
      body: payload,
      decoder: (json) => WpMedia.fromJson(_asMap(json)),
    );
    return result.data;
  }

  Future<void> deleteMedia(int id) async {
    await _request(
      '/media/$id',
      method: 'DELETE',
      query: {'force': true},
      decoder: (json) => json,
    );
  }

  Future<WpMedia> uploadMedia({
    required String fileName,
    required Map<String, String> fields,
    String? filePath,
    Uint8List? bytes,
    String? mimeType,
  }) async {
    final request = http.MultipartRequest('POST', _buildUri('/media'))
      ..headers['accept'] = 'application/json';

    if (token != null && token!.isNotEmpty) {
      request.headers['authorization'] = 'Bearer $token';
    }

    request.fields.addAll(fields);
    final resolvedMimeType =
        mimeType ?? detectUploadMimeType(fileName: fileName, bytes: bytes);
    final mediaType = _parseMediaType(resolvedMimeType);

    if (bytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
          contentType: mediaType,
        ),
      );
    } else if (filePath != null && filePath.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          filePath,
          filename: fileName,
          contentType: mediaType,
        ),
      );
    } else {
      throw Exception('未找到可上传的文件内容');
    }

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    Object? payload;

    if (response.body.isNotEmpty) {
      try {
        payload = jsonDecode(response.body);
      } catch (_) {
        payload = response.body;
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = switch (payload) {
        {'message': final String message} => message,
        {'error': final String error} => error,
        _ => 'Request failed with status ${response.statusCode}',
      };
      throw Exception(message);
    }

    return WpMedia.fromJson(_asMap(payload));
  }

  MediaType? _parseMediaType(String? mimeType) {
    if (mimeType == null || mimeType.trim().isEmpty) {
      return null;
    }

    try {
      return MediaType.parse(mimeType);
    } catch (_) {
      return null;
    }
  }

  Future<PagedResponse<WpMoment>> listMoments({
    int page = 1,
    int perPage = 12,
    String status = 'all',
  }) async {
    final result = await _request<List<WpMoment>>(
      '/moments',
      query: {'page': page, 'per_page': perPage, 'status': status},
      decoder: (json) => _asList(
        json,
      ).map((entry) => WpMoment.fromJson(_asMap(entry))).toList(),
    );
    return PagedResponse<WpMoment>(
      items: result.data,
      total:
          int.tryParse(result.headers['x-wp-total'] ?? '') ??
          result.data.length,
      totalPages: int.tryParse(result.headers['x-wp-totalpages'] ?? '') ?? 1,
    );
  }

  Future<WpMoment> createMoment(Map<String, dynamic> payload) async {
    final result = await _request(
      '/moments',
      method: 'POST',
      body: payload,
      decoder: (json) => WpMoment.fromJson(_asMap(json)),
    );
    return result.data;
  }

  Future<WpMoment> updateMoment(int id, Map<String, dynamic> payload) async {
    final result = await _request(
      '/moments/$id',
      method: 'PUT',
      body: payload,
      decoder: (json) => WpMoment.fromJson(_asMap(json)),
    );
    return result.data;
  }

  Future<void> deleteMoment(int id) async {
    await _request('/moments/$id', method: 'DELETE', decoder: (json) => json);
  }

  Future<PagedResponse<WpComment>> listComments({
    int page = 1,
    int perPage = 12,
    String status = 'all',
  }) async {
    final result = await _request<List<WpComment>>(
      '/comments',
      query: {'page': page, 'per_page': perPage, 'status': status},
      decoder: (json) => _asList(
        json,
      ).map((entry) => WpComment.fromJson(_asMap(entry))).toList(),
    );
    return PagedResponse<WpComment>(
      items: result.data,
      total:
          int.tryParse(result.headers['x-wp-total'] ?? '') ??
          result.data.length,
      totalPages: int.tryParse(result.headers['x-wp-totalpages'] ?? '') ?? 1,
    );
  }

  Future<PagedResponse<WpComment>> listMomentComments({
    int page = 1,
    int perPage = 12,
    String status = 'all',
  }) async {
    final result = await _request<List<WpComment>>(
      '/moments/comments/all',
      query: {'page': page, 'per_page': perPage, 'status': status},
      decoder: (json) => _asList(
        json,
      ).map((entry) => WpComment.fromJson(_asMap(entry))).toList(),
    );
    return PagedResponse<WpComment>(
      items: result.data,
      total:
          int.tryParse(result.headers['x-wp-total'] ?? '') ??
          result.data.length,
      totalPages: int.tryParse(result.headers['x-wp-totalpages'] ?? '') ?? 1,
    );
  }

  Future<WpComment> createComment(Map<String, dynamic> payload) async {
    final result = await _request(
      '/comments',
      method: 'POST',
      body: payload,
      decoder: (json) => WpComment.fromJson(_asMap(json)),
    );
    return result.data;
  }

  Future<WpComment> updateComment(int id, Map<String, dynamic> payload) async {
    final result = await _request(
      '/comments/$id',
      method: 'PUT',
      body: payload,
      decoder: (json) => WpComment.fromJson(_asMap(json)),
    );
    return result.data;
  }

  Future<void> deleteComment(int id) async {
    await _request('/comments/$id', method: 'DELETE', decoder: (json) => json);
  }

  Future<WpComment> createMomentComment(
    int momentId,
    Map<String, dynamic> payload,
  ) async {
    final result = await _request(
      '/moments/$momentId/comments',
      method: 'POST',
      body: payload,
      decoder: (json) => WpComment.fromJson(_asMap(json)),
    );
    return result.data;
  }

  Future<WpComment> updateMomentComment(
    int momentId,
    int id,
    Map<String, dynamic> payload,
  ) async {
    final result = await _request(
      '/moments/$momentId/comments/$id',
      method: 'PUT',
      body: payload,
      decoder: (json) => WpComment.fromJson(_asMap(json)),
    );
    return result.data;
  }

  Future<void> deleteMomentComment(int momentId, int id) async {
    await _request(
      '/moments/$momentId/comments/$id',
      method: 'DELETE',
      decoder: (json) => json,
    );
  }

  Future<DashboardSnapshot> getDashboardSnapshot() async {
    final totals = await Future.wait<int>([
      _fetchTotal(
        '/posts',
        query: {'page': 1, 'per_page': 1, 'status': 'publish'},
      ),
      _fetchTotal('/pages', query: {'page': 1, 'per_page': 1, 'status': 'all'}),
      _fetchTotal(
        '/moments',
        query: {'page': 1, 'per_page': 1, 'status': 'all'},
      ),
      _fetchTotal(
        '/comments',
        query: {'page': 1, 'per_page': 1, 'status': 'all'},
      ),
      _fetchTotal('/media', query: {'page': 1, 'per_page': 1}),
      _fetchTotal('/users', query: {'page': 1, 'per_page': 1}),
    ]);

    final recentPosts = await listPosts(page: 1, perPage: 4, status: 'publish');

    return DashboardSnapshot(
      posts: totals[0],
      pages: totals[1],
      moments: totals[2],
      comments: totals[3],
      media: totals[4],
      users: totals[5],
      recentPosts: recentPosts.items,
    );
  }

  Future<int> _fetchTotal(String path, {Map<String, dynamic>? query}) async {
    final result = await _request<List<Object?>>(
      path,
      query: query,
      decoder: (json) => _asList(json),
    );
    return int.tryParse(result.headers['x-wp-total'] ?? '') ??
        result.data.length;
  }
}

class _ApiResponse<T> {
  const _ApiResponse({required this.data, required this.headers});

  final T data;
  final Map<String, String> headers;
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, entry) => MapEntry(key.toString(), entry));
  }
  return const <String, dynamic>{};
}

List<Object?> _asList(Object? value) {
  if (value is List) {
    return value.cast<Object?>();
  }
  return const <Object?>[];
}
