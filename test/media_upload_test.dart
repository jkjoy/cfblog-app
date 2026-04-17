import 'dart:convert';
import 'dart:typed_data';

import 'package:cfblog_flutter/core/media_upload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detectUploadMimeType resolves common image types from filename', () {
    expect(detectUploadMimeType(fileName: 'cover.png'), 'image/png');
    expect(detectUploadMimeType(fileName: 'hero.jpg'), 'image/jpeg');
    expect(detectUploadMimeType(fileName: 'doc.pdf'), 'application/pdf');
  });

  test('detectUploadMimeType can use header bytes when available', () {
    final bytes = Uint8List.fromList(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO7Z0ioAAAAASUVORK5CYII=',
      ),
    );

    expect(detectUploadMimeType(fileName: 'upload.bin', bytes: bytes), 'image/png');
  });
}
