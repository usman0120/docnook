import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:docnook/core/failures.dart';
import 'package:docnook/data/repositories/search_repository.dart';
import 'package:docnook/domain/docmodel/doc_model.dart';
import 'package:docnook/domain/entities/doc_type.dart';
import 'package:docnook/engines/epub/epub_parser.dart';
import 'package:docnook/engines/jobs/job_runner.dart';
import 'package:docnook/engines/office/docx/docx_parser.dart';
import 'package:docnook/engines/office/html/html_to_docmodel.dart';
import 'package:docnook/engines/office/legacy/ole_file.dart';
import 'package:docnook/engines/office/odf/odt_parser.dart';
import 'package:docnook/engines/office/rtf/rtf_parser.dart';
import 'package:markdown/markdown.dart' as md;

/// What to parse: a readable local file and its detected format.
final class ParseRequest {
  const ParseRequest(this.path, this.format);
  final String path;
  final DocFormat format;
}

/// Parses any flowing document into a [DocModel]. A [JobBody]: runs in an
/// isolate (CLAUDE.md rule 4).
DocModel parseToDocModel(ParseRequest request, JobContext context) {
  context.progress(0.05);
  final model = switch (request.format) {
    DocFormat.docx || DocFormat.dotx => DocxParser.parseFile(request.path),
    DocFormat.odt => OdtParser.parseFile(request.path),
    DocFormat.rtf => RtfParser.parse(File(request.path).readAsBytesSync()),
    DocFormat.doc => _paragraphs(
      LegacyText.doc(File(request.path).readAsBytesSync()),
    ),
    DocFormat.ppt => _paragraphs(
      LegacyText.ppt(File(request.path).readAsBytesSync()),
      gap: true,
    ),
    DocFormat.xls => _paragraphs(
      LegacyText.xls(File(request.path).readAsBytesSync()),
    ),
    DocFormat.markdown => markdownToDocModel(
      decodeText(File(request.path).readAsBytesSync()),
    ),
    DocFormat.epub => EpubParser.parseFile(request.path).toDocModel(),
    _ => throw const DocNookFailure.unsupported(),
  };
  context.progress(1);
  return model;
}

DocModel _paragraphs(List<String> lines, {bool gap = false}) => DocModel(
  sections: [
    DocSection(
      blocks: [
        for (final line in lines)
          Paragraph([
            TextRun(line),
          ], style: ParagraphStyle(spaceAfter: gap ? 10 : 4)),
      ],
    ),
  ],
);

/// Decodes text files: UTF-8 (with or without BOM), UTF-16 with a BOM, and
/// Windows-1252 when the bytes are not valid UTF-8.
String decodeText(Uint8List bytes) {
  if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
    return String.fromCharCodes(
      Uint16List.sublistView(
        Uint8List.fromList(bytes.sublist(2, bytes.length - bytes.length % 2)),
      ),
    );
  }
  if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
    final units = <int>[
      for (var i = 2; i + 1 < bytes.length; i += 2)
        bytes[i] << 8 | bytes[i + 1],
    ];
    return String.fromCharCodes(units);
  }
  final start =
      bytes.length >= 3 &&
          bytes[0] == 0xEF &&
          bytes[1] == 0xBB &&
          bytes[2] == 0xBF
      ? 3
      : 0;
  try {
    return utf8.decode(Uint8List.sublistView(bytes, start));
  } on FormatException {
    return latin1.decode(Uint8List.sublistView(bytes, start));
  }
}

/// GitHub-flavoured Markdown → DocModel through the shared HTML converter.
DocModel markdownToDocModel(String source) {
  final document = md.Document(
    extensionSet: md.ExtensionSet.gitHubFlavored,
    encodeHtml: false,
  );
  final nodes = document.parse(source.replaceAll('\r\n', '\n'));
  HtmlNode convert(md.Node node) => switch (node) {
    md.Element(:final tag, :final attributes, :final children) => HtmlElement(
      tag,
      Map.of(attributes),
      [for (final c in children ?? const <md.Node>[]) convert(c)],
    ),
    md.Text(:final text) => HtmlText(text),
    _ => HtmlText(node.textContent),
  };
  final blocks = HtmlToDocModel().convert([for (final n in nodes) convert(n)]);
  return DocModel(sections: [DocSection(blocks: blocks)]);
}

/// Splits a DocModel's text into index chunks (~4 KB each, BLUEPRINT 6.1).
List<IndexChunk> docModelChunks(DocModel model) {
  final text = model.plainText();
  final chunks = <IndexChunk>[];
  var start = 0;
  while (start < text.length && start < SearchRepository.maxBodyChars) {
    var end = start + 4096;
    if (end >= text.length) {
      end = text.length;
    } else {
      final nl = text.lastIndexOf('\n', end);
      if (nl > start + 2048) end = nl + 1;
    }
    chunks.add(IndexChunk(chunks.length + 1, text.substring(start, end)));
    start = end;
  }
  return chunks;
}

/// Same as [parseToDocModel] without a job context (tests, quick reads).
DocModel parseToDocModelSync(String path) {
  final name = path.replaceAll(String.fromCharCode(92), '/').split('/').last;
  final ext = name.contains('.')
      ? name.substring(name.lastIndexOf('.') + 1).toLowerCase()
      : '';
  final format = switch (ext) {
    'docx' => DocFormat.docx,
    'odt' => DocFormat.odt,
    'rtf' => DocFormat.rtf,
    'doc' => DocFormat.doc,
    'ppt' => DocFormat.ppt,
    'xls' => DocFormat.xls,
    'md' || 'markdown' => DocFormat.markdown,
    'epub' => DocFormat.epub,
    _ => DocFormat.unknown,
  };
  return parseToDocModel(ParseRequest(path, format), JobContext.detached());
}
