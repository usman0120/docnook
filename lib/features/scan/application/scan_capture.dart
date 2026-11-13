import 'package:flutter/services.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';

/// Result of asking the ML Kit scanner for pages.
sealed class CaptureOutcome {
  const CaptureOutcome();
}

/// Pages came back, as local file paths.
final class Captured extends CaptureOutcome {
  const Captured(this.paths);
  final List<String> paths;
}

/// The user backed out of the scanner.
final class CaptureCancelled extends CaptureOutcome {
  const CaptureCancelled();
}

/// The ML Kit scanner can't run here (no Google Play services, or its
/// module isn't installed); use DocNook's own camera screen instead.
final class CaptureUnavailable extends CaptureOutcome {
  const CaptureUnavailable();
}

/// Starts Google's document scanner (BLUEPRINT 4.3, S23). It runs in Google
/// Play services, finds page edges itself and returns cropped JPEGs. DocNook
/// needs no camera permission for it.
abstract final class MlKitCapture {
  static Future<CaptureOutcome> scan({required int pageLimit}) async {
    final scanner = DocumentScanner(
      options: DocumentScannerOptions(
        pageLimit: pageLimit.clamp(1, 50),
        isGalleryImport: true,
      ),
    );
    try {
      final result = await scanner.scanDocument();
      final images = result.images ?? const <String>[];
      return images.isEmpty
          ? const CaptureCancelled()
          : Captured(List.of(images));
    } on PlatformException catch (e) {
      final message = e.message ?? '';
      if (message.contains('cancel')) return const CaptureCancelled();
      return const CaptureUnavailable();
    } on MissingPluginException {
      return const CaptureUnavailable();
    } finally {
      await scanner.close();
    }
  }
}
