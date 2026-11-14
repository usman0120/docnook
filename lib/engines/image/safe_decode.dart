import 'dart:typed_data';

import 'package:docnook/core/failures.dart';
import 'package:image/image.dart' as img;

/// Largest picture decoded in full: 52 megapixels covers 50 MP phone photos
/// while keeping one decoded copy near 200 MB (NFR-MEM-01). A file that
/// claims more pixels is refused before any memory is allocated, so a tiny
/// hostile PNG declaring 20,000 × 20,000 pixels cannot exhaust memory
/// (BLUEPRINT 8.1, 12.2 "Hostile").
const maxDecodePixels = 52 * 1000 * 1000;

/// Decodes [bytes] after checking the size the header declares.
///
/// Throws [DocNookFailure] `corrupt` for unreadable data and `tooLarge` for
/// pictures over [maxPixels].
img.Image decodeImageSafe(Uint8List bytes, {int maxPixels = maxDecodePixels}) {
  final decoder = img.findDecoderForData(bytes);
  if (decoder == null) throw const DocNookFailure.corrupt(detail: 'image');
  final img.DecodeInfo? info;
  try {
    info = decoder.startDecode(bytes);
  } on Object {
    throw const DocNookFailure.corrupt(detail: 'image header');
  }
  if (info == null || info.width <= 0 || info.height <= 0) {
    throw const DocNookFailure.corrupt(detail: 'image header');
  }
  if (info.width * info.height > maxPixels) {
    throw const DocNookFailure.tooLarge(detail: 'image pixels');
  }
  final img.Image? decoded;
  try {
    decoded = decoder.decode(bytes);
  } on Object {
    throw const DocNookFailure.corrupt(detail: 'image data');
  }
  if (decoded == null) throw const DocNookFailure.corrupt(detail: 'image');
  return decoded;
}
