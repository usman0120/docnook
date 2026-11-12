import 'dart:convert';
import 'dart:io';

import 'package:docnook/engines/jobs/job_runner.dart';
import 'package:docnook/engines/text/highlighter.dart';
import 'package:docnook/engines/text/text_file.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('text'));
  tearDown(() => dir.deleteSync(recursive: true));

  File write(String name, List<int> bytes) =>
      File('${dir.path}/$name')..writeAsBytesSync(bytes);

  test('indexes lines and reads them back in blocks', () {
    final lines = List.generate(1234, (i) => 'line $i ${'x' * (i % 50)}');
    final f = write('a.log', utf8.encode('${lines.join('\n')}\n'));
    final index = indexLines(f.path, JobContext.detached());
    expect(index.lineCount, 1234);
    expect(index.encoding, 'utf8');
    final reader = LineReader(f.path, index);
    expect(reader.line(0), 'line 0 ');
    expect(reader.line(599), lines[599]);
    expect(reader.line(1233), lines[1233]);
    reader.close();
  });

  test('CRLF, no trailing newline, tabs, BOM', () {
    final f = write('b.txt', [
      0xEF,
      0xBB,
      0xBF,
      ...utf8.encode('one\r\ntwo\tx\r\nthree'),
    ]);
    final index = indexLines(f.path, JobContext.detached());
    final reader = LineReader(f.path, index);
    expect(index.lineCount, 3);
    expect(
      [reader.line(0), reader.line(1), reader.line(2)],
      ['one', 'two    x', 'three'],
    );
    reader.close();
  });

  test('UTF-16 LE and Windows-1252 files', () {
    final utf16 = [0xFF, 0xFE];
    for (final u in 'héllo\nwörld'.codeUnits) {
      utf16
        ..add(u & 0xFF)
        ..add(u >> 8);
    }
    final a = write('c.txt', utf16);
    final ia = indexLines(a.path, JobContext.detached());
    final ra = LineReader(a.path, ia);
    expect(ia.encoding, 'utf16le');
    expect([ra.line(0), ra.line(1)], ['héllo', 'wörld']);
    ra.close();

    final b = write('d.txt', [0x63, 0x61, 0x66, 0xE9, 0x0A, 0x6F, 0x6B]);
    final ib = indexLines(b.path, JobContext.detached());
    final rb = LineReader(b.path, ib);
    expect(ib.encoding, 'latin1');
    expect(rb.line(0), 'café');
    rb.close();
  });

  test('search finds matching lines case-insensitively', () {
    final f = write(
      'e.log',
      utf8.encode(['ok', 'ERROR disk', 'ok', 'error net'].join('\n')),
    );
    final index = indexLines(f.path, JobContext.detached());
    expect(
      searchLines(LineSearch(f.path, index, 'error'), JobContext.detached()),
      [1, 3],
    );
  });

  test('a 20 MB log indexes quickly', () {
    final line = utf8.encode(
      '2026-11-12 10:00:00 INFO request served in 12 ms by worker-7\n',
    );
    final sink = File('${dir.path}/big.log').openSync(mode: FileMode.write);
    for (var i = 0; i < 20 * 1024 * 1024 ~/ line.length; i++) {
      sink.writeFromSync(line);
    }
    sink.closeSync();
    final sw = Stopwatch()..start();
    final index = indexLines('${dir.path}/big.log', JobContext.detached());
    expect(index.lineCount, greaterThan(300000));
    expect(sw.elapsedMilliseconds, lessThan(8000));
  });

  test('highlighter tokens', () {
    final json = highlightLine(
      '  "name": "Ali", "age": 42, "ok": true',
      Syntax.json,
    );
    expect(
      json.firstWhere((t) => t.text == '"name"').kind,
      TokenKind.attribute,
    );
    expect(json.firstWhere((t) => t.text == '"Ali"').kind, TokenKind.string);
    expect(json.firstWhere((t) => t.text == '42').kind, TokenKind.number);
    expect(json.firstWhere((t) => t.text == 'true').kind, TokenKind.keyword);

    final code = highlightLine('final x = "a"; // note', Syntax.code);
    expect(code.first.kind, TokenKind.keyword);
    expect(code.last.kind, TokenKind.comment);
    expect(code.map((t) => t.text).join(), 'final x = "a"; // note');

    final xml = highlightLine('<item id="7">text</item>', Syntax.xml);
    expect(xml.map((t) => t.text).join(), '<item id="7">text</item>');
    expect(xml.firstWhere((t) => t.text == 'id').kind, TokenKind.attribute);
    expect(
      highlightLine('# comment', Syntax.hash).single.kind,
      TokenKind.comment,
    );
    expect(syntaxFor('kt'), Syntax.code);
    expect(syntaxFor('txt'), Syntax.none);
  });
}
