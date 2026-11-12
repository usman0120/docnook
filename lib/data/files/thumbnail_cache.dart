import 'dart:io';
import 'dart:ui' as ui;

import 'package:docnook/data/files/app_paths.dart';
import 'package:flutter/painting.dart';
import 'package:path/path.dart' as p;
import 'package:pdfrx/pdfrx.dart';

/// First-page thumbnails, 256 px wide, kept in the app cache
/// (BLUEPRINT 5.6, 9.4). PNG because Flutter can encode it without a plugin.
class ThumbnailCache {
  ThumbnailCache(this._paths);

  final AppPaths _paths;
  static const width = 256;

  String pathFor(String key) => p.join(_paths.thumbs, '$key.png');

  ImageProvider? imageFor(String? key) {
    if (key == null) return null;
    final file = File(pathFor(key));
    return file.existsSync() ? FileImage(file) : null;
  }

  /// Renders page 1 of an open PDF and stores it under [key]. Returns false
  /// when rendering fails (the UI then keeps the neutral paper tile).
  Future<bool> savePdfThumbnail(PdfDocument document, String key) async {
    if (document.pages.isEmpty) return false;
    final page = document.pages.first;
    final scale = width / page.width;
    final height = (page.height * scale).round().clamp(1, width * 3);
    final rendered = await page.render(
      fullWidth: width.toDouble(),
      fullHeight: height.toDouble(),
      width: width,
      height: height,
      backgroundColor: 0xFFFFFFFF,
    );
    if (rendered == null) return false;
    try {
      final image = await rendered.createImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) return false;
      final file = File(pathFor(key));
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      // A new file under the same key must not show the old cached bitmap.
      await FileImage(file).evict();
      return true;
    } finally {
      rendered.dispose();
    }
  }

  Future<void> clear() async {
    final dir = Directory(_paths.thumbs);
    if (dir.existsSync()) await dir.delete(recursive: true);
    PaintingBinding.instance.imageCache.clear();
  }
}
