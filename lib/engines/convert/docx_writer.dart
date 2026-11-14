import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:docnook/domain/docmodel/doc_model.dart';
import 'package:docnook/engines/convert/sheet_export.dart';
import 'package:docnook/engines/jobs/job_runner.dart';

/// DocModel → DOCX (WordprocessingML): paragraphs and runs with basic
/// formatting, headings as Word's Heading 1–3 styles, lists with their
/// markers as text, tables, pictures and page breaks. Opens in Word,
/// LibreOffice and Google Docs. Runs in a JobRunner isolate.
int writeDocxJob((DocModel, String) args, JobContext context) {
  final (model, output) = args;
  final bytes = buildDocx(model);
  File(output).writeAsBytesSync(bytes, flush: true);
  context.progress(1);
  return bytes.length;
}

Uint8List buildDocx(DocModel model) {
  final media =
      <String, (String, Uint8List, String)>{}; // id → (file, bytes, rel)
  var rel = 1;
  String relFor(String imageId) {
    final existing = media[imageId];
    if (existing != null) return existing.$3;
    final image = model.images[imageId]!;
    final png =
        image.mime == 'image/png' ||
        (image.bytes.length > 4 &&
            image.bytes[0] == 0x89 &&
            image.bytes[1] == 0x50);
    final file = 'image${media.length + 1}.${png ? 'png' : 'jpeg'}';
    final id = 'rIdImg${rel++}';
    media[imageId] = (file, image.bytes, id);
    return id;
  }

  var drawingId = 1;
  String picture(String imageId, double width, double height) {
    if (!model.images.containsKey(imageId)) return '';
    final r = relFor(imageId);
    // Fit inside the text width (6.27 in at A4 with 1 in margins).
    var w = width;
    var h = height;
    const maxW = 451.0;
    if (w > maxW) {
      h = h * maxW / w;
      w = maxW;
    }
    final cx = (w * 12700).round();
    final cy = (h * 12700).round();
    final n = drawingId++;
    return '<w:r><w:drawing><wp:inline distT="0" distB="0" distL="0" distR="0">'
        '<wp:extent cx="$cx" cy="$cy"/><wp:docPr id="$n" name="Picture $n"/>'
        '<a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">'
        '<a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">'
        '<pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">'
        '<pic:nvPicPr><pic:cNvPr id="$n" name="Picture $n"/><pic:cNvPicPr/></pic:nvPicPr>'
        '<pic:blipFill><a:blip r:embed="$r"/><a:stretch><a:fillRect/></a:stretch></pic:blipFill>'
        '<pic:spPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="$cx" cy="$cy"/></a:xfrm>'
        '<a:prstGeom prst="rect"><a:avLst/></a:prstGeom></pic:spPr></pic:pic>'
        '</a:graphicData></a:graphic></wp:inline></w:drawing></w:r>';
  }

  String run(TextRun r) {
    final s = r.style;
    final props = StringBuffer();
    if (s.bold) props.write('<w:b/>');
    if (s.italic) props.write('<w:i/>');
    if (s.underline) props.write('<w:u w:val="single"/>');
    if (s.strike) props.write('<w:strike/>');
    if (s.color != null) {
      final hex = (s.color! & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
      props.write('<w:color w:val="$hex"/>');
    }
    if (s.fontSize != null) {
      props.write('<w:sz w:val="${(s.fontSize! * 2).round()}"/>');
    }
    if (s.position == VerticalPosition.superscript) {
      props.write('<w:vertAlign w:val="superscript"/>');
    } else if (s.position == VerticalPosition.subscript) {
      props.write('<w:vertAlign w:val="subscript"/>');
    }
    final out = StringBuffer('<w:r>');
    if (props.isNotEmpty) out.write('<w:rPr>$props</w:rPr>');
    final parts = r.text.split('\n');
    for (var i = 0; i < parts.length; i++) {
      if (i > 0) out.write('<w:br/>');
      final tabs = parts[i].split('\t');
      for (var k = 0; k < tabs.length; k++) {
        if (k > 0) out.write('<w:tab/>');
        if (tabs[k].isNotEmpty) {
          out.write('<w:t xml:space="preserve">${xmlEscape(tabs[k])}</w:t>');
        }
      }
    }
    out.write('</w:r>');
    return out.toString();
  }

  String paragraph(Paragraph p) {
    final ps = p.style;
    final props = StringBuffer();
    if (p.headingLevel > 0) {
      props.write('<w:pStyle w:val="Heading${p.headingLevel.clamp(1, 3)}"/>');
    }
    final align = switch (ps.align) {
      TextAlignment.center => 'center',
      TextAlignment.end => 'right',
      TextAlignment.justify => 'both',
      TextAlignment.start => null,
    };
    if (ps.spaceBefore > 0 || ps.spaceAfter > 0) {
      props.write(
        '<w:spacing w:before="${(ps.spaceBefore * 20).round()}" '
        'w:after="${(ps.spaceAfter * 20).round()}"/>',
      );
    }
    final list = p.list;
    final indent = list != null ? (list.level + 1) * 18.0 : ps.indentStart;
    if (indent > 0) {
      props.write(
        '<w:ind w:left="${(indent * 20).round()}"'
        '${list != null ? ' w:hanging="360"' : ''}/>',
      );
    }
    if (align != null) props.write('<w:jc w:val="$align"/>');
    if (ps.rtl) props.write('<w:bidi/>');
    final out = StringBuffer('<w:p>');
    if (props.isNotEmpty) out.write('<w:pPr>$props</w:pPr>');
    if (list != null && list.marker.isNotEmpty) {
      out.write(run(TextRun('${list.marker}\t')));
    }
    for (final inline in p.inlines) {
      switch (inline) {
        case TextRun():
          out.write(run(inline));
        case InlineImage(:final imageId, :final width, :final height):
          out.write(picture(imageId, width, height));
      }
    }
    out.write('</w:p>');
    return out.toString();
  }

  String blocks(List<Block> list) {
    final out = StringBuffer();
    for (final block in list) {
      switch (block) {
        case Paragraph():
          out.write(paragraph(block));
        case ImageBlock(:final imageId, :final width, :final height):
          out.write('<w:p>${picture(imageId, width, height)}</w:p>');
        case PageBreak():
          out.write('<w:p><w:r><w:br w:type="page"/></w:r></w:p>');
        case TableBlock(:final rows):
          final cols = block.columnCount;
          if (cols == 0) continue;
          out.write(
            '<w:tbl><w:tblPr><w:tblW w:w="0" w:type="auto"/><w:tblBorders>'
            '<w:top w:val="single" w:sz="4"/><w:left w:val="single" w:sz="4"/>'
            '<w:bottom w:val="single" w:sz="4"/><w:right w:val="single" w:sz="4"/>'
            '<w:insideH w:val="single" w:sz="4"/><w:insideV w:val="single" w:sz="4"/>'
            '</w:tblBorders></w:tblPr><w:tblGrid>',
          );
          for (var c = 0; c < cols; c++) {
            out.write('<w:gridCol/>');
          }
          out.write('</w:tblGrid>');
          for (final row in rows) {
            out.write('<w:tr>');
            for (final cell in row.cells) {
              out.write('<w:tc><w:tcPr>');
              if (cell.colSpan > 1) {
                out.write('<w:gridSpan w:val="${cell.colSpan}"/>');
              }
              if (cell.covered) {
                out.write('<w:vMerge/>');
              } else if (cell.rowSpan > 1) {
                out.write('<w:vMerge w:val="restart"/>');
              }
              out.write('</w:tcPr>');
              final inner = cell.covered ? '' : blocks(cell.blocks);
              out.write(inner.isEmpty ? '<w:p/>' : inner);
              out.write('</w:tc>');
            }
            out.write('</w:tr>');
          }
          out.write('</w:tbl>');
        case SlideFrame(:final items, :final title):
          if (title != null) {
            out.write(paragraph(Paragraph([TextRun(title)], headingLevel: 2)));
          }
          for (final item in items) {
            if (item is SlideText && !item.isTitle) {
              out.write(blocks(item.paragraphs));
            }
          }
      }
    }
    return out.toString();
  }

  final body = StringBuffer();
  for (final section in model.sections) {
    body.write(blocks(section.blocks));
  }

  final archive = Archive();
  void add(String path, List<int> data) =>
      archive.addFile(ArchiveFile(path, data.length, data));
  void addText(String path, String text) => add(path, utf8.encode(text));

  addText(
    'word/document.xml',
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" '
        'xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing">'
        '<w:body>$body<w:sectPr><w:pgSz w:w="11906" w:h="16838"/>'
        '<w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" '
        'w:header="708" w:footer="708" w:gutter="0"/></w:sectPr></w:body></w:document>',
  );
  addText('word/styles.xml', _styles);
  addText(
    'word/_rels/document.xml.rels',
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rIdStyles" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
        '${[for (final m in media.values) '<Relationship Id="${m.$3}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/image" Target="media/${m.$1}"/>'].join()}'
        '</Relationships>',
  );
  for (final m in media.values) {
    add('word/media/${m.$1}', m.$2);
  }
  addText(
    '[Content_Types].xml',
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Default Extension="jpeg" ContentType="image/jpeg"/>'
        '<Default Extension="png" ContentType="image/png"/>'
        '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
        '<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>'
        '</Types>',
  );
  addText(
    '_rels/.rels',
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>'
        '</Relationships>',
  );
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

const _styles =
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
    '<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
    '<w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:cs="Calibri"/>'
    '<w:sz w:val="22"/></w:rPr></w:rPrDefault>'
    '<w:pPrDefault><w:pPr><w:spacing w:after="120" w:line="264" w:lineRule="auto"/></w:pPr></w:pPrDefault></w:docDefaults>'
    '<w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/></w:style>'
    '<w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/><w:basedOn w:val="Normal"/>'
    '<w:pPr><w:keepNext/><w:spacing w:before="240" w:after="120"/><w:outlineLvl w:val="0"/></w:pPr>'
    '<w:rPr><w:b/><w:sz w:val="36"/></w:rPr></w:style>'
    '<w:style w:type="paragraph" w:styleId="Heading2"><w:name w:val="heading 2"/><w:basedOn w:val="Normal"/>'
    '<w:pPr><w:keepNext/><w:spacing w:before="200" w:after="100"/><w:outlineLvl w:val="1"/></w:pPr>'
    '<w:rPr><w:b/><w:sz w:val="30"/></w:rPr></w:style>'
    '<w:style w:type="paragraph" w:styleId="Heading3"><w:name w:val="heading 3"/><w:basedOn w:val="Normal"/>'
    '<w:pPr><w:keepNext/><w:spacing w:before="160" w:after="80"/><w:outlineLvl w:val="2"/></w:pPr>'
    '<w:rPr><w:b/><w:sz w:val="26"/></w:rPr></w:style>'
    '</w:styles>';
