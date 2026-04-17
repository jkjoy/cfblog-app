String normalizeBaseUrl(String value) {
  return value.trim().replaceFirst(RegExp(r'/+$'), '');
}

String stripHtml(String input) {
  return input
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String formatDate(String? raw) {
  if (raw == null || raw.isEmpty) {
    return '未设置';
  }
  final date = DateTime.tryParse(raw)?.toLocal();
  if (date == null) {
    return raw;
  }
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:$minute';
}

String formatBytes(int? bytes) {
  final value = bytes ?? 0;
  if (value <= 0) {
    return '未知大小';
  }
  const units = ['B', 'KB', 'MB', 'GB'];
  double size = value.toDouble();
  var index = 0;
  while (size >= 1024 && index < units.length - 1) {
    size /= 1024;
    index += 1;
  }
  final formatted = size >= 100 || index == 0
      ? size.toStringAsFixed(0)
      : size.toStringAsFixed(1);
  return '$formatted ${units[index]}';
}

String roleLabel(String role) {
  return switch (role) {
    'administrator' => '管理员',
    'editor' => '编辑',
    'author' => '作者',
    'contributor' => '投稿者',
    'subscriber' => '订阅者',
    _ => role.isEmpty ? '成员' : role,
  };
}

String statusLabel(String status) {
  return switch (status) {
    'publish' => '已发布',
    'draft' => '草稿',
    'pending' => '待审核',
    'private' => '私密',
    'trash' => '回收站',
    _ => status.isEmpty ? '未知' : status,
  };
}

String commentStatusLabel(String status) {
  return switch (status) {
    'approved' => '已通过',
    'pending' => '待审核',
    'spam' => '垃圾',
    'trash' => '回收站',
    _ => status.isEmpty ? '未知' : status,
  };
}

String visibleLabel(String visible) {
  return switch (visible) {
    'yes' => '展示中',
    'no' => '已隐藏',
    _ => visible.isEmpty ? '未知' : visible,
  };
}

String linkTargetLabel(String target) {
  return switch (target) {
    '_blank' => '新窗口',
    '_self' => '当前窗口',
    _ => target.isEmpty ? '默认打开' : target,
  };
}
