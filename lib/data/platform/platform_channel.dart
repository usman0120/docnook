import 'dart:async';

import 'package:docnook/core/failures.dart';
import 'package:docnook/core/result.dart';
import 'package:docnook/domain/scan/scan_models.dart';
import 'package:flutter/services.dart';

/// A file handed to DocNook by another app ("Open with" / "Share to").
final class IncomingFile {
  const IncomingFile({required this.uri, this.name, this.size, this.mime});

  factory IncomingFile.fromMap(Map<Object?, Object?> map) => IncomingFile(
    uri: map['uri']! as String,
    name: map['name'] as String?,
    size: (map['size'] as num?)?.toInt(),
    mime: map['mime'] as String?,
  );

  /// `content://` or `file://` URI.
  final String uri;
  final String? name;
  final int? size;
  final String? mime;
}

sealed class IncomingEvent {
  const IncomingEvent({required this.initial});

  /// True when this intent launched the app (Back should return to the
  /// calling app).
  final bool initial;
}

final class ViewEvent extends IncomingEvent {
  const ViewEvent(this.file, {required super.initial});
  final IncomingFile file;
}

final class ShareEvent extends IncomingEvent {
  const ShareEvent(this.files, {required super.initial});
  final List<IncomingFile> files;
}

final class SharedTextEvent extends IncomingEvent {
  const SharedTextEvent(this.text, {required super.initial});
  final String text;
}

final class ShortcutEvent extends IncomingEvent {
  const ShortcutEvent(this.id, {required super.initial});

  /// `scan`, `merge` or `recent`.
  final String id;
}

/// Where a saved output landed.
final class SavedFile {
  const SavedFile({required this.uri, required this.path, required this.name});
  final String uri;
  final String? path;
  final String name;
}

/// Dart face of `DocNookChannels.kt`.
class PlatformChannel {
  PlatformChannel({MethodChannel? methods, EventChannel? intents})
    : _methods = methods ?? const MethodChannel('docnook/platform'),
      _intents = intents ?? const EventChannel('docnook/intents');

  final MethodChannel _methods;
  final EventChannel _intents;
  Stream<IncomingEvent>? _events;

  /// Incoming intents, including the one that launched the app.
  Stream<IncomingEvent> get incoming => _events ??= _intents
      .receiveBroadcastStream()
      .map((raw) => _parse(raw as Map<Object?, Object?>))
      .where((e) => e != null)
      .cast<IncomingEvent>();

  static IncomingEvent? _parse(Map<Object?, Object?> map) {
    final initial = map['initial'] == true;
    switch (map['kind']) {
      case 'view':
        final files = map['files']! as List<Object?>;
        if (files.isEmpty) return null;
        return ViewEvent(
          IncomingFile.fromMap(files.first! as Map<Object?, Object?>),
          initial: initial,
        );
      case 'share':
        final files = [
          for (final f in map['files']! as List<Object?>)
            IncomingFile.fromMap(f! as Map<Object?, Object?>),
        ];
        return files.isEmpty ? null : ShareEvent(files, initial: initial);
      case 'text':
        return SharedTextEvent(map['text']! as String, initial: initial);
      case 'shortcut':
        return ShortcutEvent(map['id']! as String, initial: initial);
    }
    return null;
  }

  Future<Result<T>> _call<T>(
    String method, [
    Map<String, Object?>? args,
  ]) async {
    try {
      return Ok(await _methods.invokeMethod<T>(method, args) as T);
    } on PlatformException catch (e) {
      return Err(switch (e.code) {
        'permissionDenied' => const DocNookFailure.permissionDenied(),
        'notFound' => const DocNookFailure.corrupt(detail: 'not found'),
        'outOfSpace' => const DocNookFailure.outOfSpace(),
        _ => DocNookFailure.unknown(detail: e.code),
      });
    } on MissingPluginException {
      return const Err(DocNookFailure.unsupported(detail: 'no platform'));
    }
  }

  /// Streams a content URI into [dest] (app-private). Returns bytes copied.
  Future<Result<int>> copyToCache(String uri, String dest) async =>
      await _call<int>('copyToCache', {'uri': uri, 'dest': dest});

  /// Publishes a finished file in `Documents/DocNook/<subdir>/`.
  Future<Result<SavedFile>> saveToDocuments({
    required String source,
    required String subdir,
    required String name,
    required String mime,
  }) async {
    final result = await _call<Map<Object?, Object?>>('saveToDocuments', {
      'source': source,
      'subdir': subdir,
      'name': name,
      'mime': mime,
    });
    return result.map(
      (m) => SavedFile(
        uri: m['uri']! as String,
        path: m['path'] as String?,
        name: m['name']! as String,
      ),
    );
  }

  Future<bool> openWith(String pathOrUri, {String? mime}) async =>
      (await _call<bool>('openWith', {
        'path': pathOrUri,
        'mime': mime,
      })).valueOrNull ??
      false;

  Future<bool> share(List<String> pathsOrUris, {String? mime}) async =>
      (await _call<bool>('share', {
        'paths': pathsOrUris,
        'mime': mime,
      })).valueOrNull ??
      false;

  /// Opens the system document picker. Returns the chosen files, or an empty
  /// list when the user backs out.
  Future<List<IncomingFile>> pickFiles({
    List<String> mimes = const ['*/*'],
    bool multiple = false,
  }) async {
    final result = await _call<List<Object?>?>('pickFiles', {
      'mimes': mimes,
      'multiple': multiple,
    });
    return [
      for (final f in result.valueOrNull ?? const <Object?>[])
        IncomingFile.fromMap(f! as Map<Object?, Object?>),
    ];
  }

  /// Opens the system folder picker; returns the granted tree URI or null.
  Future<String?> pickTree() async =>
      (await _call<String?>('pickTree')).valueOrNull;

  Future<List<String>> persistedTrees() async =>
      ((await _call<List<Object?>>('persistedTrees')).valueOrNull ?? const [])
          .cast<String>();

  /// Whether DocNook may list documents across shared storage.
  Future<bool> hasStorageAccess() async =>
      (await _call<bool>('hasStorageAccess')).valueOrNull ?? false;

  /// Android 7–10 runtime prompt. Returns whether it was granted.
  Future<bool> requestLegacyStorage() async =>
      (await _call<bool>('requestLegacyStorage')).valueOrNull ?? false;

  /// Absolute path of shared storage, e.g. /storage/emulated/0.
  Future<String?> storageRoot() async =>
      (await _call<String?>('storageRoot')).valueOrNull;

  /// Every file under a granted folder tree.
  Future<Result<List<TreeEntry>>> listTree(String treeUri) async {
    final result = await _call<List<Object?>>('listTree', {'uri': treeUri});
    return result.map(
      (list) => [
        for (final e in list) TreeEntry.fromMap(e! as Map<Object?, Object?>),
      ],
    );
  }

  Future<String?> treeName(String treeUri) async =>
      (await _call<String?>('treeName', {'uri': treeUri})).valueOrNull;

  Future<void> releaseTree(String treeUri) =>
      _call<void>('releaseTree', {'uri': treeUri});

  Future<bool> deleteDocument(String pathOrUri) async =>
      (await _call<bool>('deleteDocument', {'uri': pathOrUri})).valueOrNull ??
      false;

  /// Returns the new path or URI, or null when renaming failed.
  Future<String?> renameDocument(String pathOrUri, String name) async =>
      (await _call<String?>('renameDocument', {
        'uri': pathOrUri,
        'name': name,
      })).valueOrNull;

  /// For each content URI, whether it still points at a document. Unknown
  /// (for example, a revoked permission) counts as present.
  Future<List<bool>> urisExist(List<String> uris) async {
    if (uris.isEmpty) return const [];
    final result = await _call<List<Object?>>('urisExist', {'uris': uris});
    final list = result.valueOrNull;
    if (list == null || list.length != uris.length) {
      return List<bool>.filled(uris.length, true);
    }
    return [for (final v in list) v != false];
  }

  Future<bool> hasAllFilesAccess() async =>
      (await _call<bool>('hasAllFilesAccess')).valueOrNull ?? false;

  Future<bool> requestAllFilesAccess() async =>
      (await _call<bool>('requestAllFilesAccess')).valueOrNull ?? false;

  Future<void> setSecure({required bool on}) =>
      _call<void>('setSecure', {'on': on});

  /// Tesseract OCR (direct APK only). Null when unavailable or failed.
  Future<OcrPage?> ocrTesseract(String path) async {
    final result = await _call<Map<Object?, Object?>>('ocrTesseract', {
      'path': path,
    });
    final m = result.valueOrNull;
    if (m == null) return null;
    return OcrPage(
      (m['width']! as num).toDouble(),
      (m['height']! as num).toDouble(),
      [
        for (final raw in m['lines']! as List<Object?>)
          if (raw case final Map<Object?, Object?> l)
            OcrLine(
              l['text']! as String,
              (l['left']! as num).toDouble(),
              (l['top']! as num).toDouble(),
              (l['width']! as num).toDouble(),
              (l['height']! as num).toDouble(),
            ),
      ],
    );
  }

  Future<int> sdkInt() async => (await _call<int>('sdkInt')).valueOrNull ?? 0;

  Future<int> totalMemoryMb() async =>
      (await _call<int>('totalMemoryMb')).valueOrNull ?? 0;

  Future<bool> openTtsSettings() async =>
      (await _call<bool>('openTtsSettings')).valueOrNull ?? false;
}

/// A file inside a granted folder tree.
final class TreeEntry {
  const TreeEntry({
    required this.uri,
    required this.name,
    this.mime,
    this.size,
    this.modified,
  });

  factory TreeEntry.fromMap(Map<Object?, Object?> map) => TreeEntry(
    uri: map['uri']! as String,
    name: map['name']! as String,
    mime: map['mime'] as String?,
    size: (map['size'] as num?)?.toInt(),
    modified: (map['modified'] as num?)?.toInt(),
  );

  final String uri;
  final String name;
  final String? mime;
  final int? size;

  /// Milliseconds since epoch.
  final int? modified;
}
