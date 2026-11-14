import 'dart:io';

import 'package:docnook/data/files/app_paths.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;
  setUp(() => root = Directory.systemTemp.createTempSync('docnook_paths'));
  tearDown(() => root.deleteSync(recursive: true));

  test(
    'sweep removes day-old temp and share copies, keeps fresh ones',
    () async {
      final paths = AppPaths.at(root.path);
      final now = DateTime.now();
      File touch(String dir, String name, DateTime when) =>
          File(p.join(dir, name))
            ..writeAsStringSync('x')
            ..setLastModifiedSync(when);
      final oldTmp = touch(
        paths.tmp,
        'old.pdf',
        now.subtract(const Duration(days: 2)),
      );
      final newTmp = touch(paths.tmp, 'new.pdf', now);
      final oldShare = touch(
        paths.share,
        'shared.pdf',
        now.subtract(const Duration(hours: 30)),
      );
      final scan = touch(
        paths.scans,
        'page.jpg',
        now.subtract(const Duration(days: 9)),
      );

      await paths.sweep(now: now);

      expect(oldTmp.existsSync(), isFalse);
      expect(oldShare.existsSync(), isFalse);
      expect(newTmp.existsSync(), isTrue);
      // Unfinished scans are the user's work, never swept.
      expect(scan.existsSync(), isTrue);
    },
  );
}
