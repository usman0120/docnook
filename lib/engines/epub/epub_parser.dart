import 'package:docnook/core/failures.dart';
import 'package:docnook/domain/docmodel/doc_model.dart';
import 'package:docnook/engines/archive/safe_zip.dart';
import 'package:docnook/engines/office/html/html_to_docmodel.dart';
import 'package:docnook/engines/office/xml_events.dart';

/// One chapter of an EPUB: its title and blocks.
final class EpubChapter {
  const EpubChapter(this.title, this.blocks);
  final String title;
  final List<Block> blocks;
}

/// A parsed EPUB: chapters in reading order sharing one image table.
final class EpubBook {
  const EpubBook({
    required this.title,
    required this.chapters,
    required this.images,
    this.author,
  });

  final String title;
  final String? author;
  final List<EpubChapter> chapters;
  final Map<String, DocImage> images;

  DocModel toDocModel() => DocModel(
    title: title,
    images: images,
    sections: [for (final c in chapters) DocSection(blocks: c.blocks)],
  );
}

/// Reads EPUB 2/3 (container → OPF → spine → XHTML) without a webview or
/// network (Good fidelity). DRM-protected books are reported unsupported.
abstract final class EpubParser {
  static const _maxImageBytes = 64 * 1024 * 1024;

  static EpubBook parseFile(String path) {
    final zip = SafeZip.open(path);
    try {
      return _read(zip);
    } finally {
      zip.close();
    }
  }

  static EpubBook _read(SafeZip zip) {
    if (zip.has('META-INF/encryption.xml')) {
      final enc = zip.text('META-INF/encryption.xml') ?? '';
      // Font obfuscation is harmless; anything else is DRM.
      if (RegExp('EncryptedData').allMatches(enc).length >
          RegExp(
            'obfuscation|font',
            caseSensitive: false,
          ).allMatches(enc).length) {
        throw const DocNookFailure.unsupported(detail: 'epub: drm');
      }
    }
    final container = zip.text('META-INF/container.xml');
    if (container == null) {
      throw const DocNookFailure.corrupt(detail: 'epub: container');
    }
    final rootfile = XmlPull(container).find('rootfile')?.attr('full-path');
    if (rootfile == null) {
      throw const DocNookFailure.corrupt(detail: 'epub: rootfile');
    }
    final opf = zip.text(rootfile);
    if (opf == null) throw const DocNookFailure.corrupt(detail: 'epub: opf');
    final base = rootfile.contains('/')
        ? rootfile.substring(0, rootfile.lastIndexOf('/') + 1)
        : '';

    final manifest = <String, ({String href, String type, String props})>{};
    final spine = <String>[];
    var title = '';
    String? author;
    String? navHref;
    String? ncxId;
    final pull = XmlPull(opf);
    final package = pull.find('package');
    if (package == null) {
      throw const DocNookFailure.corrupt(detail: 'epub: package');
    }
    pull.children(package, (section) {
      switch (section.localName) {
        case 'metadata':
          pull.children(section, (m) {
            if (m.localName == 'title' && title.isEmpty) {
              title = pull.text(m).trim();
            }
            if (m.localName == 'creator' && author == null) {
              author = pull.text(m).trim();
            }
          });
        case 'manifest':
          pull.children(section, (item) {
            final id = item.attr('id');
            final href = item.attr('href');
            if (id == null || href == null) return;
            final props = item.attr('properties') ?? '';
            manifest[id] = (
              href: _resolve(base, Uri.decodeFull(href)),
              type: item.attr('media-type') ?? '',
              props: props,
            );
            if (props.contains('nav')) navHref = manifest[id]!.href;
          });
        case 'spine':
          ncxId = section.attr('toc');
          pull.children(section, (ref) {
            final id = ref.attr('idref');
            if (id != null && ref.attr('linear') != 'no') spine.add(id);
          });
      }
    });

    final titles = _tocTitles(
      zip,
      navHref,
      ncxId == null ? null : manifest[ncxId]?.href,
    );
    final images = <String, DocImage>{};
    var imageBytes = 0;

    final chapters = <EpubChapter>[];
    for (final id in spine) {
      final item = manifest[id];
      if (item == null ||
          !(item.type.contains('html') ||
              item.href.endsWith('.xhtml') ||
              item.href.endsWith('.html'))) {
        continue;
      }
      final xhtml = zip.text(item.href);
      if (xhtml == null) continue;
      final dir = item.href.contains('/')
          ? item.href.substring(0, item.href.lastIndexOf('/') + 1)
          : '';
      List<HtmlNode> nodes;
      try {
        nodes = parseXhtmlBody(xhtml);
      } on DocNookFailure {
        continue; // one malformed chapter should not lose the book
      }
      final blocks = HtmlToDocModel(
        resolveImage: (src) {
          final path = _resolve(dir, Uri.decodeFull(src.split('#').first));
          if (images.containsKey(path)) return path;
          final size = zip.sizeOf(path);
          if (size == 0 || imageBytes + size > _maxImageBytes) return null;
          final bytes = zip.bytes(path);
          if (bytes == null) return null;
          imageBytes += bytes.length;
          images[path] = DocImage(bytes);
          return path;
        },
      ).convert(nodes);
      if (blocks.isEmpty) continue;
      final heading = blocks
          .whereType<Paragraph>()
          .where((p) => p.headingLevel > 0)
          .map((p) => p.plainText.trim())
          .firstOrNull;
      chapters.add(
        EpubChapter(
          titles[item.href] ?? heading ?? 'Section ${chapters.length + 1}',
          blocks,
        ),
      );
    }
    if (chapters.isEmpty) {
      throw const DocNookFailure.corrupt(detail: 'epub: no chapters');
    }
    return EpubBook(
      title: title.isEmpty ? 'Book' : title,
      author: author,
      chapters: chapters,
      images: images,
    );
  }

  /// Chapter titles by file, from the EPUB 3 nav or the EPUB 2 NCX.
  static Map<String, String> _tocTitles(SafeZip zip, String? nav, String? ncx) {
    final titles = <String, String>{};
    if (nav != null) {
      final xml = zip.text(nav);
      final dir = nav.contains('/')
          ? nav.substring(0, nav.lastIndexOf('/') + 1)
          : '';
      if (xml != null) {
        try {
          for (final m in RegExp(
            '<a[^>]*href="([^"#]+)[^"]*"[^>]*>(.*?)</a>',
            dotAll: true,
          ).allMatches(xml)) {
            final file = _resolve(dir, Uri.decodeFull(m.group(1)!));
            final text = m.group(2)!.replaceAll(RegExp('<[^>]+>'), '').trim();
            if (text.isNotEmpty) titles.putIfAbsent(file, () => text);
          }
        } on FormatException {
          // Keep headings as titles.
        }
      }
    }
    if (titles.isEmpty && ncx != null) {
      final xml = zip.text(ncx);
      final dir = ncx.contains('/')
          ? ncx.substring(0, ncx.lastIndexOf('/') + 1)
          : '';
      if (xml != null) {
        for (final m in RegExp(
          r'<navLabel>\s*<text>(.*?)</text>\s*</navLabel>\s*<content src="([^"#]+)',
          dotAll: true,
        ).allMatches(xml)) {
          titles.putIfAbsent(
            _resolve(dir, Uri.decodeFull(m.group(2)!)),
            () => m.group(1)!.trim(),
          );
        }
      }
    }
    return titles;
  }

  static String _resolve(String dir, String href) {
    final parts = <String>[];
    for (final p in '$dir$href'.split('/')) {
      if (p == '..') {
        if (parts.isNotEmpty) parts.removeLast();
      } else if (p.isNotEmpty && p != '.') {
        parts.add(p);
      }
    }
    return parts.join('/');
  }
}
