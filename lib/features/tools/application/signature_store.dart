import 'dart:convert';
import 'dart:io';

import 'package:docnook/app/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;

/// A drawn signature: strokes as flat x, y lists in 0–1 of its own box,
/// and the box's width / height.
@immutable
final class Signature {
  const Signature({
    required this.id,
    required this.aspect,
    required this.strokes,
  });

  factory Signature.fromJson(String id, Map<String, Object?> json) => Signature(
    id: id,
    aspect: (json['aspect']! as num).toDouble(),
    strokes: [
      for (final s in json['strokes']! as List<Object?>)
        [for (final v in s! as List<Object?>) (v! as num).toDouble()],
    ],
  );

  final String id;
  final double aspect;
  final List<List<double>> strokes;

  Map<String, Object?> toJson() => {'aspect': aspect, 'strokes': strokes};

  /// Fits raw strokes (any units) into a 0–1 box, keeping their shape.
  static Signature? normalize(String id, List<List<double>> raw) {
    var (l, t, r, b) = (double.infinity, double.infinity, -1e12, -1e12);
    for (final s in raw) {
      for (var i = 0; i + 1 < s.length; i += 2) {
        if (s[i] < l) l = s[i];
        if (s[i] > r) r = s[i];
        if (s[i + 1] < t) t = s[i + 1];
        if (s[i + 1] > b) b = s[i + 1];
      }
    }
    final w = r - l;
    final h = b - t;
    if (!w.isFinite || !h.isFinite || w < 4 || h < 4) return null;
    return Signature(
      id: id,
      aspect: w / h,
      strokes: [
        for (final s in raw)
          [
            for (var i = 0; i + 1 < s.length; i += 2) ...[
              (s[i] - l) / w,
              (s[i + 1] - t) / h,
            ],
          ],
      ],
    );
  }
}

final signatureStoreProvider = Provider<SignatureStore>(
  (ref) => SignatureStore(ref.watch(appPathsProvider).signatures),
);

final signaturesProvider = FutureProvider.autoDispose<List<Signature>>(
  (ref) => ref.watch(signatureStoreProvider).list(),
);

/// Up to [max] saved signatures, as small JSON files in app-private
/// storage (never in the shared Documents folder).
class SignatureStore {
  SignatureStore(this._dir);

  final String _dir;
  static const max = 3;

  Future<List<Signature>> list() async {
    final dir = Directory(_dir);
    if (!dir.existsSync()) return const [];
    final files =
        dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.json'))
            .toList()
          ..sort(
            (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
          );
    final out = <Signature>[];
    for (final f in files) {
      try {
        final json = jsonDecode(await f.readAsString()) as Map<String, Object?>;
        out.add(Signature.fromJson(p.basenameWithoutExtension(f.path), json));
      } on Object {
        // A damaged file is skipped, not fatal.
      }
    }
    return out;
  }

  /// Saves [signature]; the oldest goes when there are already [max].
  Future<void> save(Signature signature) async {
    final existing = await list();
    for (final old in existing.skip(max - 1)) {
      await delete(old.id);
    }
    await File(
      p.join(_dir, '${signature.id}.json'),
    ).writeAsString(jsonEncode(signature.toJson()), flush: true);
  }

  Future<void> delete(String id) async {
    final f = File(p.join(_dir, '$id.json'));
    if (f.existsSync()) await f.delete();
  }
}
