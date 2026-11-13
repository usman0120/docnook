import 'package:docnook/core/failures.dart';
import 'package:docnook/data/platform/platform_channel.dart';
import 'package:docnook/domain/scan/scan_models.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// On-device text recognition (BLUEPRINT 4.3, FR-SCAN-03).
///
/// ML Kit's bundled Latin model runs first; it needs no network and no
/// Google account. If it fails (some phones without Google services), the
/// direct APK falls back to Tesseract with the bundled English model.
///
/// Both engines do their work natively on background threads, so they are
/// called from the main isolate (BLUEPRINT 5.4).
class OcrService {
  OcrService(this._platform);

  final PlatformChannel _platform;
  TextRecognizer? _mlKit;
  bool _mlKitBroken = false;

  /// Reads [imagePath], an upright image of [width] × [height] pixels.
  Future<OcrPage> recognize(
    String imagePath, {
    required int width,
    required int height,
  }) async {
    if (!_mlKitBroken) {
      try {
        return await _recognizeMlKit(imagePath, width, height);
      } on Object catch (e) {
        if (kDebugMode) debugPrint('ML Kit OCR failed: ${e.runtimeType}');
        _mlKitBroken = true;
      }
    }
    final page = await _platform.ocrTesseract(imagePath);
    if (page == null) throw const DocNookFailure.unsupported();
    return page;
  }

  Future<OcrPage> _recognizeMlKit(String path, int width, int height) async {
    final recognizer = _mlKit ??= TextRecognizer();
    final result = await recognizer.processImage(InputImage.fromFilePath(path));
    return OcrPage(width.toDouble(), height.toDouble(), [
      for (final block in result.blocks)
        for (final line in block.lines)
          OcrLine(
            line.text,
            line.boundingBox.left,
            line.boundingBox.top,
            line.boundingBox.width,
            line.boundingBox.height,
          ),
    ]);
  }

  Future<void> close() async {
    await _mlKit?.close();
    _mlKit = null;
  }
}
