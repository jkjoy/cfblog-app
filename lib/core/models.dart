import 'package:flutter/foundation.dart';

@immutable
class AppConfig {
  const AppConfig({required this.baseUrl});

  final String baseUrl;

  Map<String, dynamic> toJson() => {'baseUrl': baseUrl};

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(baseUrl: _asString(json['baseUrl']));
  }
}

@immutable
class DiscoveryInfo {
  const DiscoveryInfo({
    required this.name,
    required this.description,
    required this.url,
    required this.home,
  });

  final String name;
  final String description;
  final String url;
  final String home;

  factory DiscoveryInfo.fromJson(Map<String, dynamic> json) {
    return DiscoveryInfo(
      name: _asString(json['name']),
      description: _asString(json['description']),
      url: _asString(json['url']),
      home: _asString(json['home']),
    );
  }
}

@immutable
class SessionUser {
  const SessionUser({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.email,
    required this.roles,
    required this.role,
    required this.registeredDate,
    required this.avatarUrls,
  });

  final int id;
  final String name;
  final String slug;
  final String description;
  final String email;
  final List<String> roles;
  final String role;
  final String registeredDate;
  final Map<String, String> avatarUrls;

  String get primaryRole => roles.isNotEmpty ? roles.first : role;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'description': description,
    'email': email,
    'roles': roles,
    'role': role,
    'registered_date': registeredDate,
    'avatar_urls': avatarUrls,
  };

  factory SessionUser.fromJson(Map<String, dynamic> json) {
    return SessionUser(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      slug: _asString(json['slug']),
      description: _asString(json['description']),
      email: _asString(json['email']),
      roles: _asStringList(json['roles']),
      role: _asString(json['role']),
      registeredDate: _asString(json['registered_date']),
      avatarUrls: _asStringMap(json['avatar_urls']),
    );
  }
}

@immutable
class SessionState {
  const SessionState({required this.token, required this.user});

  final String token;
  final SessionUser user;

  Map<String, dynamic> toJson() => {'token': token, 'user': user.toJson()};

  factory SessionState.fromJson(Map<String, dynamic> json) {
    return SessionState(
      token: _asString(json['token']),
      user: SessionUser.fromJson(_asMap(json['user'])),
    );
  }
}

@immutable
class PagedResponse<T> {
  const PagedResponse({
    required this.items,
    required this.total,
    required this.totalPages,
  });

  final List<T> items;
  final int total;
  final int totalPages;
}

@immutable
class WpPost {
  const WpPost({
    required this.id,
    required this.date,
    required this.modified,
    required this.slug,
    required this.status,
    required this.type,
    required this.title,
    required this.excerpt,
    required this.rawExcerpt,
    required this.content,
    required this.rawContent,
    required this.authorName,
    required this.featuredMedia,
    required this.featuredImageUrl,
    required this.sticky,
    required this.parent,
    required this.commentStatus,
    required this.categories,
    required this.tags,
    required this.commentCount,
    required this.viewCount,
    required this.link,
  });

  final int id;
  final String date;
  final String modified;
  final String slug;
  final String status;
  final String type;
  final String title;
  final String excerpt;
  final String rawExcerpt;
  final String content;
  final String rawContent;
  final String authorName;
  final int featuredMedia;
  final String featuredImageUrl;
  final bool sticky;
  final int parent;
  final String commentStatus;
  final List<int> categories;
  final List<int> tags;
  final int commentCount;
  final int viewCount;
  final String link;

  factory WpPost.fromJson(Map<String, dynamic> json) {
    final title = _asMap(json['title']);
    final excerpt = _asMap(json['excerpt']);
    final content = _asMap(json['content']);

    return WpPost(
      id: _asInt(json['id']),
      date: _asString(json['date']),
      modified: _asString(json['modified']),
      slug: _asString(json['slug']),
      status: _asString(json['status']),
      type: _asString(json['type']),
      title: _asString(title['rendered']),
      excerpt: _asString(excerpt['rendered']),
      rawExcerpt: _asString(excerpt['raw']),
      content: _asString(content['rendered']),
      rawContent: _asString(content['raw']),
      authorName: _asString(json['author_name']),
      featuredMedia: _asInt(json['featured_media']),
      featuredImageUrl: _asString(json['featured_image_url']),
      sticky: _asBool(json['sticky']),
      parent: _asInt(json['parent']),
      commentStatus: _asString(json['comment_status']),
      categories: _asIntList(json['categories']),
      tags: _asIntList(json['tags']),
      commentCount: _asInt(json['comment_count']),
      viewCount: _asInt(json['view_count']),
      link: _asString(json['link']),
    );
  }
}

@immutable
class WpTerm {
  const WpTerm({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.parent,
    required this.count,
  });

  final int id;
  final String name;
  final String slug;
  final String description;
  final int parent;
  final int count;

  factory WpTerm.fromJson(Map<String, dynamic> json) {
    return WpTerm(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      slug: _asString(json['slug']),
      description: _asString(json['description']),
      parent: _asInt(json['parent']),
      count: _asInt(json['count']),
    );
  }
}

@immutable
class PostReferences {
  const PostReferences({required this.categories, required this.tags});

  final List<WpTerm> categories;
  final List<WpTerm> tags;
}

@immutable
class WpLinkCategory {
  const WpLinkCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.count,
  });

  final int id;
  final String name;
  final String slug;
  final String description;
  final int count;

  factory WpLinkCategory.fromJson(Map<String, dynamic> json) {
    return WpLinkCategory(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      slug: _asString(json['slug']),
      description: _asString(json['description']),
      count: _asInt(json['count']),
    );
  }
}

@immutable
class WpLinkRef {
  const WpLinkRef({required this.id, required this.name, required this.slug});

  final int id;
  final String name;
  final String slug;

  factory WpLinkRef.fromJson(Map<String, dynamic> json) {
    return WpLinkRef(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      slug: _asString(json['slug']),
    );
  }
}

@immutable
class WpLink {
  const WpLink({
    required this.id,
    required this.name,
    required this.url,
    required this.description,
    required this.avatar,
    required this.category,
    required this.target,
    required this.visible,
    required this.rating,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final String url;
  final String description;
  final String avatar;
  final WpLinkRef? category;
  final String target;
  final String visible;
  final int rating;
  final int sortOrder;
  final String createdAt;
  final String updatedAt;

  factory WpLink.fromJson(Map<String, dynamic> json) {
    final category = _asMap(json['category']);
    return WpLink(
      id: _asInt(json['id']),
      name: _asString(json['name']),
      url: _asString(json['url']),
      description: _asString(json['description']),
      avatar: _asString(json['avatar']),
      category: category.isEmpty ? null : WpLinkRef.fromJson(category),
      target: _asString(json['target']),
      visible: _asString(json['visible']),
      rating: _asInt(json['rating']),
      sortOrder: _asInt(json['sort_order']),
      createdAt: _asString(json['created_at']),
      updatedAt: _asString(json['updated_at']),
    );
  }
}

@immutable
class WpMediaDetails {
  const WpMediaDetails({
    required this.width,
    required this.height,
    required this.file,
    required this.fileSize,
  });

  final int width;
  final int height;
  final String file;
  final int fileSize;

  factory WpMediaDetails.fromJson(Map<String, dynamic> json) {
    return WpMediaDetails(
      width: _asInt(json['width']),
      height: _asInt(json['height']),
      file: _asString(json['file']),
      fileSize: _asInt(json['filesize']),
    );
  }
}

@immutable
class WpMedia {
  const WpMedia({
    required this.id,
    required this.date,
    required this.modified,
    required this.slug,
    required this.title,
    required this.description,
    required this.caption,
    required this.altText,
    required this.mediaType,
    required this.mimeType,
    required this.mediaDetails,
    required this.sourceUrl,
  });

  final int id;
  final String date;
  final String modified;
  final String slug;
  final String title;
  final String description;
  final String caption;
  final String altText;
  final String mediaType;
  final String mimeType;
  final WpMediaDetails? mediaDetails;
  final String sourceUrl;

  bool get isImage => mimeType.startsWith('image/');

  factory WpMedia.fromJson(Map<String, dynamic> json) {
    final title = _asMap(json['title']);
    final description = _asMap(json['description']);
    final caption = _asMap(json['caption']);
    final details = _asMap(json['media_details']);

    return WpMedia(
      id: _asInt(json['id']),
      date: _asString(json['date']),
      modified: _asString(json['modified']),
      slug: _asString(json['slug']),
      title: _asString(title['rendered']),
      description: _asString(description['rendered']),
      caption: _asString(caption['rendered']),
      altText: _asString(json['alt_text']),
      mediaType: _asString(json['media_type']),
      mimeType: _asString(json['mime_type']),
      mediaDetails: details.isEmpty ? null : WpMediaDetails.fromJson(details),
      sourceUrl: _asString(json['source_url']),
    );
  }
}

@immutable
class WpComment {
  const WpComment({
    required this.id,
    required this.post,
    required this.moment,
    required this.postTitle,
    required this.parent,
    required this.author,
    required this.authorName,
    required this.authorEmail,
    required this.authorUrl,
    required this.authorIp,
    required this.date,
    required this.content,
    required this.link,
    required this.status,
    required this.type,
  });

  final int id;
  final int post;
  final int moment;
  final String postTitle;
  final int parent;
  final int author;
  final String authorName;
  final String authorEmail;
  final String authorUrl;
  final String authorIp;
  final String date;
  final String content;
  final String link;
  final String status;
  final String type;

  bool get isMomentComment => moment > 0;

  factory WpComment.fromJson(Map<String, dynamic> json) {
    final content = _asMap(json['content']);
    return WpComment(
      id: _asInt(json['id']),
      post: _asInt(json['post']),
      moment: _asInt(json['moment']),
      postTitle: _asString(json['post_title']),
      parent: _asInt(json['parent']),
      author: _asInt(json['author']),
      authorName: _asString(json['author_name']),
      authorEmail: _asString(json['author_email']),
      authorUrl: _asString(json['author_url']),
      authorIp: _asString(json['author_ip']),
      date: _asString(json['date']),
      content: _asString(content['rendered']),
      link: _asString(json['link']),
      status: _asString(json['status']),
      type: _asString(json['type']),
    );
  }
}

@immutable
class WpMoment {
  const WpMoment({
    required this.id,
    required this.content,
    required this.rawContent,
    required this.author,
    required this.authorName,
    required this.authorAvatar,
    required this.status,
    required this.mediaUrls,
    required this.viewCount,
    required this.likeCount,
    required this.commentCount,
    required this.date,
    required this.modified,
  });

  final int id;
  final String content;
  final String rawContent;
  final int author;
  final String authorName;
  final String authorAvatar;
  final String status;
  final List<String> mediaUrls;
  final int viewCount;
  final int likeCount;
  final int commentCount;
  final String date;
  final String modified;

  factory WpMoment.fromJson(Map<String, dynamic> json) {
    final content = _asMap(json['content']);
    return WpMoment(
      id: _asInt(json['id']),
      content: _asString(content['rendered']),
      rawContent: _asString(content['raw']),
      author: _asInt(json['author']),
      authorName: _asString(json['author_name']),
      authorAvatar: _asString(json['author_avatar']),
      status: _asString(json['status']),
      mediaUrls: _asStringList(json['media_urls']),
      viewCount: _asInt(json['view_count']),
      likeCount: _asInt(json['like_count']),
      commentCount: _asInt(json['comment_count']),
      date: _asString(json['date']),
      modified: _asString(json['modified']),
    );
  }
}

@immutable
class DashboardSnapshot {
  const DashboardSnapshot({
    required this.posts,
    required this.pages,
    required this.moments,
    required this.comments,
    required this.media,
    required this.users,
    required this.recentPosts,
  });

  final int posts;
  final int pages;
  final int moments;
  final int comments;
  final int media;
  final int users;
  final List<WpPost> recentPosts;
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

Map<String, String> _asStringMap(Object? value) {
  return _asMap(
    value,
  ).map((key, entry) => MapEntry(key, entry?.toString() ?? ''));
}

List<String> _asStringList(Object? value) {
  if (value is List) {
    return value.map((entry) => entry.toString()).toList();
  }
  return const <String>[];
}

String _asString(Object? value) => value?.toString() ?? '';

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

bool _asBool(Object? value) {
  if (value is bool) {
    return value;
  }
  final raw = value?.toString().toLowerCase() ?? '';
  return raw == 'true' || raw == '1';
}

List<int> _asIntList(Object? value) {
  if (value is List) {
    return value
        .map((entry) => _asInt(entry))
        .where((entry) => entry > 0)
        .toList();
  }
  return const <int>[];
}
