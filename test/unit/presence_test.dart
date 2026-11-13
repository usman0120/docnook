import 'dart:io';

import 'package:docnook/data/db/app_database.dart';
import 'package:docnook/data/repositories/library_repository.dart';
import 'package:docnook/engines/jobs/job_runner.dart';
import 'package:docnook/engines/library/discovery.dart';
import 'package:docnook/engines/library/presence.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('tells file paths from content URIs', () {
    expect(isFilePath('/storage/emulated/0/Documents/a.pdf'), isTrue);
    expect(isFilePath('file:///storage/emulated/0/a.pdf'), isTrue);
    expect(isFilePath('content://media/external/file/12'), isFalse);
    expect(
      filePathOf('file:///storage/emulated/0/a%20b.pdf'),
      '/storage/emulated/0/a b.pdf',
    );
  });

  test('reports which files still exist', () {
    final dir = Directory.systemTemp.createTempSync('docnook_presence');
    addTearDown(() => dir.deleteSync(recursive: true));
    final kept = File(p.join(dir.path, 'kept.pdf'))..writeAsStringSync('x');
    final gone = p.join(dir.path, 'gone.pdf');
    expect(filesExist([kept.path, gone], JobContext.detached()), [true, false]);
  });

  test(
    'missing documents leave the library and stay out of the check',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final library = LibraryRepository(db);
      await library.applyDiscovery([
        for (final name in ['a.pdf', 'b.pdf'])
          FoundFile(uri: '/s/$name', name: name, size: 1, modifiedMs: 1),
      ], scopes: const []);
      final before = await library.presentLocations();
      expect(before.map((r) => r.$2), containsAll(['/s/a.pdf', '/s/b.pdf']));

      final a = before.firstWhere((r) => r.$2 == '/s/a.pdf').$1;
      await library.markMissing([a]);

      final shown = await library.watchLibrary().first;
      expect(shown.map((d) => d.name), ['b.pdf']);
      final after = await library.presentLocations();
      expect(after.map((r) => r.$2), ['/s/b.pdf']);

      // Found again later: it comes back.
      await library.applyDiscovery([
        const FoundFile(uri: '/s/a.pdf', name: 'a.pdf', size: 1, modifiedMs: 1),
      ], scopes: const []);
      expect(await library.presentLocations(), hasLength(2));
    },
  );
}
