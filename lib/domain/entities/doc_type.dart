/// The viewer family a file belongs to. Stored as text in `documents.doc_type`.
enum DocType {
  pdf,
  word,
  sheet,
  slides,
  text,
  markdown,
  epub,
  image,
  archive,
  other,
}

/// How faithfully DocNook shows or converts a format (BLUEPRINT section 2).
enum Fidelity { full, good, basic, text }

/// The concrete file format, decided by content first and name second.
enum DocFormat {
  pdf(DocType.pdf, 'application/pdf', Fidelity.full),
  docx(
    DocType.word,
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    Fidelity.good,
  ),
  dotx(
    DocType.word,
    'application/vnd.openxmlformats-officedocument.wordprocessingml.template',
    Fidelity.good,
  ),
  odt(DocType.word, 'application/vnd.oasis.opendocument.text', Fidelity.basic),
  doc(DocType.word, 'application/msword', Fidelity.text),
  rtf(DocType.word, 'application/rtf', Fidelity.basic),
  xlsx(
    DocType.sheet,
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    Fidelity.good,
  ),
  xlsm(
    DocType.sheet,
    'application/vnd.ms-excel.sheet.macroenabled.12',
    Fidelity.good,
  ),
  ods(
    DocType.sheet,
    'application/vnd.oasis.opendocument.spreadsheet',
    Fidelity.good,
  ),
  xls(DocType.sheet, 'application/vnd.ms-excel', Fidelity.text),
  csv(DocType.sheet, 'text/csv', Fidelity.good),
  tsv(DocType.sheet, 'text/tab-separated-values', Fidelity.good),
  pptx(
    DocType.slides,
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    Fidelity.basic,
  ),
  ppt(DocType.slides, 'application/vnd.ms-powerpoint', Fidelity.text),
  plainText(DocType.text, 'text/plain', Fidelity.full),
  code(DocType.text, 'text/plain', Fidelity.full),
  markdown(DocType.markdown, 'text/markdown', Fidelity.full),
  epub(DocType.epub, 'application/epub+zip', Fidelity.good),
  jpeg(DocType.image, 'image/jpeg', Fidelity.full),
  png(DocType.image, 'image/png', Fidelity.full),
  webp(DocType.image, 'image/webp', Fidelity.full),
  gif(DocType.image, 'image/gif', Fidelity.full),
  bmp(DocType.image, 'image/bmp', Fidelity.full),
  heic(DocType.image, 'image/heic', Fidelity.full),
  zip(DocType.archive, 'application/zip', Fidelity.full),
  unknown(DocType.other, 'application/octet-stream', Fidelity.text);

  const DocFormat(this.docType, this.mime, this.fidelity);

  final DocType docType;
  final String mime;
  final Fidelity fidelity;

  /// Old binary Office formats: text preview only, with a banner (FR-READ-07).
  bool get isLegacyOffice =>
      this == DocFormat.doc || this == DocFormat.xls || this == DocFormat.ppt;

  bool get isSupported => this != DocFormat.unknown;
}
