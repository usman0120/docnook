import 'dart:io';

import 'package:docnook/engines/jobs/job_runner.dart';
import 'package:docnook/engines/library/discovery.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory root;

  setUp(() => root = Directory.systemTemp.createTempSync('discovery'));
  tearDown(() => root.deleteSync(recursive: true));

  void file(String path, [String content = 'x']) {
    final f = File(p.join(root.path, path));
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(content);
  }

  test(
    'finds supported documents and skips system, hidden and empty files',
    () {
      file('Download/report.pdf');
      file('Download/budget.XLSX');
      file('Documents/notes.txt');
      file('Documents/sub/deep/slides.pptx');
      file('Documents/readme.md');
      file('Documents/data.json');
      file('Documents/script.dart');
      file('Documents/photo.mp4');
      file('Documents/empty.pdf', '');
      file('.hidden/secret.pdf');
      file('Documents/.private.pdf');
      file('Android/data/app/file.pdf');
      file('Pictures/.thumbnails/t.pdf');

      final found = discoverFiles(
        DiscoveryRequest(root: root.path),
        JobContext.detached(),
      );
      final names = found.map((f) => f.name).toSet();
      expect(names, {
        'report.pdf',
        'budget.XLSX',
        'notes.txt',
        'slides.pptx',
        'readme.md',
        'data.json',
      });
      final report = found.firstWhere((f) => f.name == 'report.pdf');
      expect(report.size, 1);
      expect(report.uri, p.join(root.path, 'Download', 'report.pdf'));
    },
  );

  test('hidden folders are included on request', () {
    file('.hidden/secret.pdf');
    final found = discoverFiles(
      DiscoveryRequest(root: root.path, includeHidden: true),
      JobContext.detached(),
    );
    expect(found.single.name, 'secret.pdf');
  });

  test('stops at the file cap', () {
    for (var i = 0; i < 30; i++) {
      file('Docs/f$i.pdf');
    }
    final found = discoverFiles(
      DiscoveryRequest(root: root.path, maxFiles: 10),
      JobContext.detached(),
    );
    expect(found.length, lessThanOrEqualTo(30));
    expect(found.length, greaterThanOrEqualTo(10));
  });

  test('a missing root yields nothing instead of failing', () {
    final found = discoverFiles(
      DiscoveryRequest(root: p.join(root.path, 'nope')),
      JobContext.detached(),
    );
    expect(found, isEmpty);
  });
}
