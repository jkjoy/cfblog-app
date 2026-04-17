import 'dart:math' as math;
import 'dart:typed_data';

import 'package:mime/mime.dart';

String? detectUploadMimeType({
  required String fileName,
  Uint8List? bytes,
}) {
  final headerBytes = bytes == null || bytes.isEmpty
      ? null
      : bytes.sublist(0, math.min(bytes.length, 16));
  return lookupMimeType(fileName, headerBytes: headerBytes);
}
