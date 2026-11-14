# DocNook decisions log

Each entry: date, decision, reason. Package entries also record version, license,
last publish date and manifest permissions (CLAUDE.md rule 3).

## 2026-11-11 — Project created

- Flutter project `docnook` created in this folder with Android as the only platform.
- Toolchain found on the build machine: Flutter 3.41.7 (stable, Dart 3.11.5),
  Android SDK 36.1.0, platforms 34–36.1, JDK 27.
- Local git repository on branch `main`; no hosting account.

## 2026-11-11 — Decisions from the owner

- **Pacing:** keep building through the phases; at the end of each phase install the
  build on the phone and hand over a test checklist, then continue while the owner
  tests. (Replaces the strict "wait for approval" gate in CLAUDE.md's workflow.)
- **Flutter:** upgrade to the latest stable (3.47.9).
- **Test phone:** Samsung Galaxy A06 (SM-A065F), Android 16, 4 GB RAM, 720×1600,
  arm64, Google Play services present. Close to the blueprint's low-end reference
  class, so performance targets are measured on it.

## 2026-11-11 — UI fonts

- Inter (400/500/600), Source Serif 4 (600), JetBrains Mono (400/700), static TTFs,
  Latin subset from the Fontsource distribution, SIL OFL 1.1. Bundled in
  `assets/fonts/`; license text in `assets/licenses/fonts-OFL.txt`.
- Latin subset keeps the six files at ~370 KB total. Characters outside it (file
  names in other scripts) fall back to the phone's system font automatically.

## 2026-11-11 — Spike F: AES-256 PDF protection — PASSED (desktop)

- `lib/engines/pdf/security/` implements the PDF 2.0 standard security handler
  (V5 / R6, AESV3) in pure Dart: object reader, writer, algorithm 2.B hash, /U /UE
  /O /OE /Perms.
- Verified with an independent implementation (pypdf + cryptography): the wrong
  password is rejected, the user and owner passwords both open the file, and page
  text and metadata decrypt correctly. 13 unit tests.
- **Package:** `pointycastle` (MIT, pure Dart, no manifest permissions) for
  AES/SHA primitives. Chosen over `cryptography` for this writer because algorithm
  2.B needs synchronous, unpadded AES-CBC in a tight loop, which `cryptography`'s
  async, always-padded API does not offer. `cryptography` is still planned for the
  vault.
- Still to confirm on the phone: the output opens in Chrome and Adobe Reader, and a
  real PDFium-saved file (not just a hand-built one) round-trips.
- Limitation recorded: input must use a classic cross-reference table (what PDFium
  writes on a full save). Cross-reference streams are rejected as `unsupported`.

## 2026-11-11 — Spike E: streaming XLSX parse — PASSED (desktop)

- `lib/engines/office/xlsx/xlsx_parser.dart` walks each part with the `xml` event
  API into `SheetModel` (typed, sparse rows; no XML tree, no per-cell objects).
- AOT-compiled on the build PC: 50,000 cells in ~0.15 s; 1,000,000 cells in ~4–6 s.
  The phone is expected to be 5–8× slower, inside the 3 s target for 50k cells.
  To be re-measured on the Galaxy A06.
- **Packages:** `archive` 4.6.0 (MIT) for ZIP, `xml` 7.x (MIT) for events. Both pure
  Dart, no manifest permissions.
- All ZIP access goes through `SafeZip` (entry count, total size, compression-ratio
  and zip-slip guards). All XML goes through `xmlEvents`, which rejects any DOCTYPE.
- Excel's built-in date format (id 14) is locale-dependent; DocNook shows it
  day-first (`dd/mm/yyyy`) to match the target market.

## 2026-11-12 — Toolchain and core packages

- Flutter upgraded to **3.47.9** (Dart 3.13.7).
- Each package below was checked for licence and manifest permissions. None of the
  plugin libraries declares a permission; only their example apps request INTERNET,
  which does not reach DocNook. `tool/check.sh` still verifies the merged manifest.

| Package | Version | Licence | Why |
| --- | --- | --- | --- |
| flutter_riverpod | 3.5.0 | MIT | State management (BLUEPRINT 4.1) |
| go_router | 18.1.4 | BSD-3 | Routing, deep links from intents |
| drift / drift_dev | 2.35.x | MIT | Typed SQLite, migrations, FTS5 |
| sqlite3 (via drift) | 3.x | MIT | Native SQLite now ships through Dart build hooks. `sqlite3_flutter_libs` is end-of-life (`0.6.0+eol`) and was **not** added. |
| path_provider, path | 2.1.x, 1.9.x | BSD-3 | App directories |
| pdfrx | 2.12.0 | MIT (PDFium: BSD/Apache) | PDF render, text, search (BLUEPRINT 4.2) |
| pointycastle | 4.0.0 | MIT | AES/SHA for the PDF security writer |
| archive | 4.6.0 | MIT | ZIP for every Office/EPUB format |
| xml | 7.1.x | MIT | Event-based XML parsing |
| phosphor_flutter | 2.1.0 | MIT | The single icon family (BLUEPRINT 9.3) |
| intl, flutter_localizations | SDK | BSD-3 | English ARB strings |
| meta | 1.x | BSD-3 | `@immutable` in pure-Dart domain code |
| very_good_analysis (dev) | 11.0.0 | MIT | Strict lints; a few purely stylistic rules relaxed in `analysis_options.yaml` |
| build_runner, mocktail (dev) | — | BSD-3 / MIT | Codegen, test doubles |

## 2026-11-12 — Spike D: DOCX → DocModel — PASSED (desktop)

- `lib/engines/office/docx/` parses styles (with `basedOn` inheritance and document
  defaults), numbering (bullets, nested decimal/letter/roman, restarts), tables (grid
  widths, horizontal spans, vertical merges, shading, nesting), pictures (PNG/JPEG/GIF/
  BMP/WebP; EMF/WMF dropped), hyperlinks, page breaks, sections with page size,
  headers/footers (simplified to text), footnotes (listed at the end), tracked
  changes (insertions kept, deletions dropped), text boxes (flattened, flagged
  "simplified").
- A 30-page Word file made with python-docx (`test/fixtures/handbook_30p.docx`,
  generated, not personal) parses in ~45 ms on the build PC (warm), ~200 ms cold.
- Not yet done: the Flutter renderer for DocModel (Phase 4).

## 2026-11-12 — Icons: Phosphor bundled directly

- `phosphor_flutter` 2.1.0 (last release May 2024) does not compile on Flutter
  3.47: it extends `IconData`, which is now a final class. Replaced by the Phosphor
  icon fonts themselves (MIT, `assets/fonts/Phosphor-*.ttf`) plus a generated
  `lib/design_system/icons.dart` holding only the icons in use
  (`python tool/gen_icons.py`). Same look; release builds tree-shake the fonts.

## 2026-11-12 — First device build (Galaxy A06, Android 16)

- Release APK (arm64, direct flavor): 28.2 MB, under the 35 MB target (NFR-SIZE-01).
- Built APK requests no INTERNET / ACCESS_NETWORK_STATE (checked with aapt2).
- "Open with" a 120-page PDF from cold start: ~1.1 s to the first page.
- **Spike F confirmed on device:** a PDF encrypted by DocNook's AES-256 writer is
  recognised by PDFium, a wrong password is rejected, the right one opens it.
- **Spike A partly confirmed:** password PDFs and fast first page work; the 500-page
  timing is still to measure.
- Flutter's built-in deep linking is disabled in the manifest
  (`flutter_deeplinking_enabled=false`): DocNook routes VIEW/SEND intents itself,
  and the engine was also pushing file URIs as routes.
- Viewer toolbars sit above and below the document (not floating over it), so the
  first and last page are never hidden under a bar.

## 2026-11-12 — Phase 3: library and search

- Discovery walks shared storage in an isolate (skips `Android/`, hidden folders,
  caches, trash, empty files; code files other than JSON/XML are not listed) and
  any SAF folders the user adds (walked in Kotlin through DocumentsContract).
  Results are saved in 500-row batches with `INSERT … ON CONFLICT(uri)`; files that
  disappear are marked missing, never deleted from the database.
- Indexing runs on the main isolate for PDFs (PDFium is already native and async)
  and in an isolate for text files; it pauses while any document is open, and a
  document interrupted mid-way is not saved half-indexed. Password PDFs are never
  indexed (no password is stored). Files reached only through a content URI are
  indexed from their opened copy when the viewer closes.
- Search input is turned into quoted FTS5 prefix terms, so punctuation can never
  break the query.
- Deleting uses a plain delete after a confirm dialog. The Android 11+ system trash
  needs a per-file system confirmation through MediaStore; deferred to Phase 9.
- All bottom sheets open on the root navigator so they cover the tab bar and Scan.
- DocNook launcher icon: paper sheet with folded corner, ink lines, one gold line,
  on the primary ink-blue (adaptive + legacy PNGs).

## 2026-11-12 — Phase 4: Office and other viewers

- **Packages added:** `two_dimensional_scrollables` 0.5.6 (Flutter team, BSD-3; the
  sheet grid with pinned headers and merged cells) and `markdown` 7.3.1 (Dart team,
  BSD-3; parsing only). No manifest permissions.
- **Not added (unmaintained):** `re_highlight`/`flutter_highlight` (last releases
  2024/2021) and `epubx` (2023). Replaced with small in-house code: a line-based
  highlighter (`engines/text/highlighter.dart`) and an EPUB reader that goes
  container → OPF → spine → XHTML → DocModel. `markdown_widget` and
  `flutter_widget_from_html_core` are not needed: Markdown and EPUB go through one
  HTML→DocModel converter and the same renderer as Word.
- XHTML from EPUBs: a plain `<!DOCTYPE html>` is stripped and HTML named entities
  become numeric before parsing; any DOCTYPE with an internal subset is still
  rejected (no entity expansion).
- Legacy .doc/.xls/.ppt: own compound-file reader; .doc text via the piece table,
  .xls via BIFF8 records (SST, LABELSST, NUMBER, RK, MULRK, cached formula numbers),
  .ppt via TextChars/TextBytes atoms. Shown with a "limited preview" banner.
  Encrypted .doc files report "password-protected".
- Fixtures (`tool/make_fixtures.py`, independent libraries: python-pptx, openpyxl,
  odfpy, xlwt): PPTX, XLSX, XLS, ODT, ODS, RTF, MD, CSV, EPUB. **Still needed:** real
  .doc and .ppt files saved by Microsoft Office (no generator on this PC).
- Slide text that overflows its box shrinks to fit (as PowerPoint's autofit),
  found by the new render test (`test/widget/docmodel_render_test.dart`), which
  lays out every fixture at phone width in both themes at 1× and 2× text.
- Large text files are indexed by line offset in an isolate and read 200 lines at a
  time; a 20 MB log indexes in well under 8 s on the build PC.

## 2026-11-12 — Phase 4 device check (Galaxy A06)

- Every viewer opened from "Open with" in 0.6–0.9 s: Word, ODT, RTF, Markdown,
  XLSX, ODS, CSV, old XLS, PPTX, EPUB, a 200,000-line log, JSON, ZIP.
- Fixed after the check: spreadsheet column width unit (8.4 px per digit) so
  formatted numbers and dates fit; CSV/ODS columns without stored widths size to
  their content (first 300 rows, max 40 characters); EPUB images without a stated
  size show at natural size; old .xls shows one table per sheet; Markdown task
  boxes are drawn as icons (Samsung's font turned ☑ into a colour emoji).
- Known limit: a merged range that crosses a frozen pane edge is shown unmerged
  (the grid cannot draw one cell across pinned and scrolling columns).
- One black screen on the very first launch after install; not reproduced in later
  launches (graphics warm-up on this Mali GPU). Watch for it in testing.

## 2026-11-13 — Phase 5: scanning and OCR

Owner decisions (asked 2026-11-13):
- Backup scanner for phones without Google services: **DocNook's own camera
  screen** (live preview, flash, mode switch). Adds the `CAMERA` permission, which
  the blueprint already listed as optional; it is asked only when that screen opens.
- **Tesseract included** in the direct APK only.

Packages (checked on pub.dev 2026-11-13; none needs an account or key):

| Package | Version | Licence | Published | Manifest | Why |
| --- | --- | --- | --- | --- | --- |
| google_mlkit_document_scanner | 0.7.2 | MIT (plugin); ML Kit terms (SDK, free, no key) | 2026-11-10 | nothing extra; scanner runs in Play services | S23 primary capture: edge detection, crop, gallery import |
| google_mlkit_text_recognition | 1.0.3 | MIT (plugin); ML Kit terms | 2026-11-13 | nothing extra | OCR with the bundled Latin model (works offline) |
| camera | 0.12.2 (camera_android_camerax 0.7.6+1) | BSD-3-Clause | 2026-10-27 | CAMERA, RECORD_AUDIO, WRITE_EXTERNAL_STORAGE ≤28, camera.any feature | fallback camera screen |
| image | 4.12.0 (was transitive) | MIT | 2026-10-11 | none (pure Dart) | crop/perspective, filters, JPEG in isolates |
| Tesseract4Android (Gradle, direct flavor only) | 4.9.0 from JitPack | Apache-2.0 | — | none | OCR when ML Kit can't run |
| tessdata_fast `eng.traineddata` | main | Apache-2.0 | — | — | English model, 4.1 MB, in `android/app/src/direct/assets` |

Manifest handling (CLAUDE.md rule 1 still holds; `tool/check.sh` verifies it):
- `RECORD_AUDIO` from the camera plugin is removed (`tools:node="remove"`); video is
  never recorded. `android.hardware.camera.any` is marked not required, so phones
  without a camera can still install DocNook.
- ML Kit brings Google's usage-statistics uploader (datatransport). The app has no
  network permission, so nothing can be sent. Its upload backend registration is
  removed as well, so it never schedules upload jobs (Android 14+ refuses network
  jobs from apps without network-state permission, which could otherwise crash).
- JitPack is added as a Maven repository restricted to the
  `cz.adaptech.tesseract4android` group.
- R8 rules: `-dontwarn` for ML Kit's optional Chinese/Devanagari/Japanese/Korean
  models (not bundled), `-keep` for Tesseract's JNI classes.
- ML Kit and Tesseract ask for uncompressed native libraries, which made the APK
  139 MB. `useLegacyPackaging = true` plus `extractNativeLibs="true"` compresses
  them: the universal direct APK is 67.6 MB and the arm64 part about 28 MB
  (was about 13 MB). The direct APK should be published per ABI
  (`--split-per-abi`); Play splits the AAB itself.

Design:
- Capture: ML Kit scanner first; if it can't start (no Google Play services), DocNook's
  camera screen. Mode (Document, ID card, Book) is chosen before capture (Tools tiles;
  the Scan button means Document) because ML Kit's own screen can't host a switch;
  the fallback camera shows the switch above the shutter as in S23.
- Drafts (FR-SCAN-01): each page is written to `scan_sessions`/`scan_pages` and to
  `files/scans/<id>/` as soon as it is captured. Home lists unfinished scans. The
  page's crop corners and the Book-mode split point share `corners_json`
  (`{"corners":[…8 numbers…],"split":0.52}`), so the shipped schema is unchanged.
- Image work (`engines/scan/scan_image.dart`, pure Dart in JobRunner isolates):
  EXIF upright, perspective crop with `copyRectify`, quarter-turn rotation, then
  Book split, then filter. Document/Enhanced filters divide out uneven lighting
  (a coarse grid of local paper brightness), so paper turns white.
- Fallback edge detection: Otsu threshold, largest bright region, extreme corners;
  falls back to the whole photo when the region is implausible. Book gutter: darkest
  column band in the middle third, else the centre.
- PDF (`engines/scan/scan_pdf_writer.dart`): pure-Dart writer that embeds each JPEG
  as-is (DCTDecode) and adds an invisible text layer (render mode 3, Helvetica,
  WinAnsi, per-line size and horizontal scale from the OCR box). Checked with pypdf:
  text extracts in reading order at the right positions, including "café €5".
- ID card: one page (A4, or Letter if chosen) with front and back at exactly
  85.6 × 54 mm, centred, 40 mm from the top with a 20 mm gap; JPG export composes the
  same sheet at 200 dpi.
- OCR runs on the exported images (so boxes match), ML Kit first, Tesseract when ML
  Kit fails. Text goes into `doc_search` per page (FR-SCAN-03).
- Outputs go to `Documents/DocNook/Scans/` through MediaStore; the draft and its
  photos are deleted after a successful save.

Spike C status: ML Kit path builds; device test pending (owner's phone is shared;
ask first). Fallback path still needs an emulator without Play services.

## 2026-11-13 — Phase 5 device check (Galaxy A06)

- Spike C, ML Kit half: Google's document scanner opens from DocNook (Scan button and
  Tools tiles), imports from the gallery, finds and straightens pages, and hands
  JPEGs back. Cancelling returns to Home with no draft.
- 10-page scan with OCR saved in 8.4 s (target < 20 s); every page's text extracts
  with pypdf, and DocNook's search finds a word on page 2. 2.3 MB at Balanced.
- ID card: one A4 page, both sides exactly 85.6 × 54 mm, centred, 40 mm from the top.
- Book: the fold was found exactly; one spread saved as two pages.
- Killing the app during review keeps the draft; Home shows "Unfinished scan".
- Fixed after the check: Document filter turned pages red (one-channel JPEG
  encoding; now three channels, test checks all channels); review opened on the last
  page; crop handles at the screen edge were swallowed by Android's back gesture
  (48 dp side margin now), and the outer half of each handle sat outside the
  editor box, where Flutter ignores touches (the editor now has a half-handle margin
  all round); the dragged handle hid the corner in the magnifier (it
  now hides itself); size estimate used the quality's maximum instead of each page's
  real size (now within ~3 %); the export screen briefly said "saved or discarded"
  behind the result sheet; the ID card back sits 20 mm below the front.
- Not yet tested: the fallback camera and Tesseract on a phone without Google
  services (needs an emulator without Play services).
- Privacy note: with Auto capture on, the scanner took a photo of whatever was in
  front of the camera during testing; it was discarded unsaved. Tests then used
  Manual mode and generated pages only.
- Re-rendering a page preview after a crop took about 4 s on the A06; previews are
  now 1280 px on the long edge (was 1600), still sharper than the 720 px screen.

## 2026-11-13 — Files deleted outside DocNook

- Found during cleanup: deleting files in another app left them in DocNook's
  library, because missing files were only detected by a full discovery run, which
  needs all-files access.
- Now a presence check runs at start and whenever the app returns to the foreground.
  File paths are checked with `stat` in a JobRunner isolate; content URIs are queried
  through the Kotlin glue (`urisExist`). A deleted MediaStore item queries empty and a
  deleted SAF document throws FileNotFound/IllegalArgument: both count as gone.
  Anything uncertain (revoked grant, no permission) counts as present, so DocNook
  never hides a file it merely can't see.
- Without storage access Android reports other apps' files as absent, so file paths
  are checked then only inside Documents/DocNook and DocNook's private folders.
- Gone documents are marked `is_missing` (schema unchanged): hidden from Files and
  search, shown greyed in Recents and collections, and restored if found again.

## 2026-11-13 — Phase 6: PDF tools

- **Engine:** PDFium through FFI, as BLUEPRINT 4.2 planned: `engines/pdf/pdfium_editor.dart`
  calls the PDFium library pdfrx already ships. No new native code, no size increase.
  Each edit runs in short steps on pdfrx's own PDFium worker isolate
  (`PdfrxEntryFunctions.compute`), because PDFium is single-threaded and pdfrx
  queues every call there; running it from a JobRunner isolate would race the
  viewer. Between steps the job reports progress and checks for Cancel. Pure-Dart
  work (AES encryption, JPEG encoding, image decoding, the scan PDF writer) runs in
  JobRunner isolates as before.
- **Packages** (both already in the app through pdfrx; now direct dependencies
  because DocNook imports them):
  | Package | Version | License | Published | Manifest permissions | Why |
  | --- | --- | --- | --- | --- | --- |
  | pdfium_dart | 0.4.1 | MIT (PDFium BSD-3/Apache-2.0) | 2026, pdfrx monorepo | none (pure Dart bindings) | PDFium FFI bindings for editing |
  | ffi | 2.2.0 | BSD-3 (Dart team) | 2026 | none | native memory helpers for those bindings |
- **What each tool does underneath:**
  - Merge, Split, Organize, Extract: `FPDF_ImportPagesByIndex` into a new document,
    one import per run of pages from the same file, so shared fonts and images are
    copied once. Pages are copied, never re-rendered (FR-PDF-01). Pictures become
    pages through the Phase 5 scan PDF writer first. Bookmarks are not carried over.
  - Watermark and page numbers: text objects in a standard font (Helvetica), with
    opacity written as an ExtGState; image watermarks are one shared form XObject,
    so a 300-page watermark stores the picture once. Placement accounts for /Rotate,
    so stamps read upright. Limit: the standard font covers Latin text only; other
    characters are replaced by "?". Logged for Phase 7, when system fonts arrive.
  - Annotate and Sign: standard Highlight / Underline / StrikeOut / Ink / Text
    (note) annotations (FR-PDF-02). Signatures are Ink annotations (vector strokes),
    so they stay sharp at any zoom. After adding them DocNook renders the page once
    with annotations on, which makes PDFium write appearance streams (/AP) into the
    file, so readers that don't draw annotations themselves still show them.
    Saved signatures (max 3) are JSON stroke files in app-private storage.
  - Fill forms: PDFium's form filler (`FORM_*`): text by focus + replace, checkboxes
    and radios by a simulated tap, lists by `FORM_SetIndexSelected`. PDFium redraws
    each field. "Flattened copy" runs `FPDFPage_Flatten` on every page.
  - Compress: Light keeps the smaller of a full re-save and a page-by-page rebuild
    (which drops unused objects). Balanced re-encodes photos over 64 KB as JPEG
    (max 1600 px, quality 70), skipping images with transparency, 1-bit masks and
    any image used on more than one page (replacing it per page would store copies).
    Strong renders pages at ~115 dpi to JPEG, with an OCR text layer if chosen.
  - Protect: a full PDFium save (classic xref, any old security removed), then the
    Spike F AES-256 writer. Unlock: a PDFium save with `FPDF_REMOVE_SECURITY`.
  - Redact: pages with marks are rendered at 200 dpi, the boxes are painted black
    into the pixels, the page is rebuilt as a picture with an OCR text layer; pages
    without marks are copied unchanged (FR-PDF-04).
- Outputs go to `Documents/DocNook/Edited/` named like `Merged_2026-11-11_1432.pdf`
  or `<name>_compressed.pdf` (FR-CORE-03). Only Organize can replace the original,
  and only when the user picks "Replace the original" (CLAUDE.md rule 10).
- One tool job at a time. Closing the progress sheet leaves it running behind a chip
  on the Tools tab.
- **Spikes B and G, desktop:** passed in `test/unit/pdfium_editor_test.dart` against
  the real PDFium library (merge, highlight with /AP, text and image watermark,
  page numbers on rotated pages, form text + checkbox fill and flatten, unlock,
  balanced compression). Still to confirm on the phone and in Chrome / Adobe Reader.
- Found while testing: on Windows the PDFium error code was overwritten before it
  was read (a password-protected file looked damaged); the code is now read right
  after the failed call, with a retry, as pdfrx does. `FPDFImageObj_GetImageMetadata`
  needs the page handle to report colour depth.
- **Device check, Galaxy A06 (2026-11-13):** every PDF tool ran on the phone with
  generated files: merge (PDF + photo + form, drag to reorder), split into ranges,
  organize (rotate, delete, drag to move, blank page, save as copy), Balanced
  compression (332 KB → 160 KB), protect (wrong password refused, right one opens),
  unlock, red 45° watermark, "Page 1 of 12", highlight / strike / pen / note,
  signature (drawn, moved, resized, saved for reuse, deleted), form fill (text,
  checkbox, radio, dropdown, flattened) and redact. Pulled back to the PC and read
  with PDFium: annotations carry appearance streams; the protected copy is
  encrypted; on the redacted page the title and the marked line are gone from the
  text while the rest came back through OCR.
- Fixed during that check: Open / Do more on the result sheet landed under the
  closing tool screen (tool screens now close first); a new PDF reference on every
  rebuild made pdfrx reload and cancel drawing gestures (one reference per screen);
  drags started where they were recognised, cutting off the first letters (now
  where the finger touched down); the palette changed height when a tool was
  picked, so the page jumped; Discard left the editor open; scrolled tabs showed
  through the status bar; segmented controls had double margins; chained tools
  stacked name suffixes; underline and strike now default to red.
- Still open for Phase 6 "Done when": opening the outputs in Adobe Acrobat Reader
  and Chrome (no Chrome or Adobe Reader check was done on this shared phone).

## 2026-11-14 — Phase 7: Convert

- **Packages** (rule 3):
  | Package | Version | License | Manifest permissions | Why |
  | --- | --- | --- | --- | --- |
  | pdf (DavBfr) | 3.13.1 | Apache-2.0 | none (pure Dart) | PDF layout for every "→ PDF" converter, as BLUEPRINT 4.2 planned. Embeds only the glyphs a document uses. |
  | barcode, bidi, path_parsing, qr | transitive of `pdf` | Apache-2.0 / BSD | none | pulled in by `pdf`; DocNook does not use them directly |
- **Fonts:** Noto Sans, Noto Serif (regular, bold, italic, bold italic) and Noto Sans
  Mono (regular, bold), SIL OFL 1.1, from the Noto project, cut with fontTools to
  Latin, Latin Extended, Greek, Cyrillic and common symbols: 1.9 MB raw, about
  1 MB in the APK. Licence in `assets/licenses/fonts-Noto-OFL.txt`, registered with
  LicenseRegistry. Other scripts (Arabic, Hebrew, Devanagari, Thai…) use the
  phone's own `/system/fonts/*.ttf` at conversion time (BLUEPRINT 4.5). Limit: only
  TrueType files are usable by the PDF writer, so scripts Android ships only as
  `.otf`/`.ttc` (Chinese, Japanese, Korean on most phones) are not drawn.
- **XLSX and DOCX writers are DocNook's own** (`archive` + string XML) instead of
  the `excel` package: smaller, no extra dependency, and they only need values
  (CSV → Excel) and paragraphs/tables/pictures (PDF → Word).
- **How each converter works:**
  - Word / ODT / RTF / Markdown / text → PDF: parse to DocModel and render with
    `pdf` widgets (the second DocModel renderer, BLUEPRINT 5.5) in one JobRunner
    isolate. Tables lose column spans (pdf tables have none); EMF/WMF pictures
    are left out.
  - PowerPoint → PDF: one page per slide at the slide's own size.
  - Excel / ODS / CSV → PDF: each visible sheet on A4, landscape when wide;
    "fit to width" scales down to 40 %, beyond that column blocks continue on
    extra pages; frozen header rows repeat; capped at 20,000 rows per sheet.
  - PDF → Word: text positions from PDFium grouped into lines and paragraphs,
    larger lines become headings, pictures extracted through PDFium, a page
    break per PDF page.
  - PDF → images: pdfrx renders at 96 / 150 / 300 dpi (capped at 6000 px), JPG or
    PNG, one file per page. PDF → text: the text layer, OCR for pages without one.
  - Images → PDF: A4 / Letter (landscape pictures on landscape pages) or the
    picture's own shape; three margins; three quality steps.
  - CSV ↔ Excel: CSV/TSV → XLSX with a bold header row; XLSX/ODS → one UTF-8 CSV
    (with BOM, for Excel) per visible sheet.
  - Extract text from image: OCR to a .txt, with "Copy text" on the result.
- Batch mode for Images → PDF (combined), PDF → images, Word / Excel / PowerPoint →
  PDF: a failed file is listed on the result screen; the others still convert.
- Every converter shows its fidelity label and one-line limit before it starts
  (FR-CONV-01). Outputs go to `Documents/DocNook/Converted/`.
- Checked on desktop: the 30-page handbook, ODT, RTF, Markdown, the slide deck and
  the budget workbook convert; rendered pages were inspected by eye; CSV → XLSX →
  CSV and DocModel → DOCX → DocModel round trips are unit-tested.

## 2026-11-14 — Owner scope changes before Phase 8

- **Vault and app lock removed.** DocNook is a simple document app: no Private
  Vault, no app lock, no PIN or biometric, no "Block screenshots" setting. FR-VAULT-01,
  S28 and S29 are dropped. The unused `vault_items` table stays in the schema (removing
  it would be a schema change with nothing to gain); nothing writes to it.
- **Internet rule relaxed to "offline first".** The app stays without INTERNET; a
  feature may add it only if it truly needs it and the owner approves. No current
  feature does, so tool/check.sh still fails on INTERNET.
- **No licences page in Settings.** Open-source licences (Apache-2.0, BSD, MIT, OFL)
  require their notices to ship with the app, so the notices stay reachable through a
  small "Open-source notices" link at the end of the Terms page (owner's choice).
- **Privacy policy and Terms pages added** to Settings → About, bundled in the app so
  they work offline. Publisher name and contact email are placeholders until the owner
  provides them before release.

## 2026-11-14 — Phase 8: Read Aloud and settings

| Package | Version | License | Published | Manifest | Why |
| --- | --- | --- | --- | --- | --- |
| flutter_tts | 4.2.5 | MIT | ~10 months before (pub.dev) | no permissions; needs the `TTS_SERVICE` query DocNook already declares | Read Aloud with the phone's own voices (FR-READ-06) |

- **Read Aloud** speaks one sentence at a time with the device's text-to-speech
  engine, choosing only voices that work offline (an English one; the engine's
  default when it qualifies). With no offline voice, the bar says so and a sheet
  explains how to add one in Android's voice settings.
- Sentences are found by DocNook's own splitter (`domain/read_aloud`): `.`, `!`, `?`,
  `…`, blank lines and list items end a sentence; abbreviations, initials and
  decimals don't; pieces over 320 characters are cut at a comma or space.
- Each viewer reads in its own units and highlights the sentence with the same
  mechanism as in-document search: PDF pages (highlight drawn from PDFium character
  boxes), document blocks (Word, ODT, RTF, rendered Markdown), text lines, EPUB
  paragraphs across chapters. The view scrolls only when the sentence leaves the
  screen. Reading starts at the page or paragraph on screen. Speed 0.75×–2× is
  remembered.
- Pause stops the voice and replays the current sentence on Play (Android's engine
  can't resume mid-sentence).
- **Settings** gained Keep screen on (window flag while a document is open), Read
  Aloud voice (opens Android's voice settings), File naming (name_action or
  name_action_date), and a Library group: Find my documents, Folders, Look for new
  documents, Show hidden files, Rebuild search index. About has Privacy policy and
  Terms; Rate DocNook shows only in the Play build; Send feedback appears once a
  support address is set in `lib/app/version.dart`.
- The temp-file sweeper now also clears share copies older than a day; vault folders
  and the "Block screenshots" setting were removed with the vault (owner decision).
- `USE_BIOMETRIC` removed from the manifest (only the app lock used it).

## 2026-11-14 — Phase 9: hardening and release preparation

- **Malformed-file corpus** (`test/corpus/malformed_corpus_test.dart`, plus the PDF
  cases in `pdfium_editor_test.dart`): empty, random, truncated and wrong-magic files
  for every format; broken XML and DOCTYPE entity bombs inside DOCX/XLSX/PPTX/ODF/
  EPUB; ZIPs claiming 3 GB entries; zip-slip names; renamed files; a PNG claiming
  20,000 × 20,000 pixels; deeply nested RTF and Markdown. Each runs in its own
  isolate like JobRunner and must succeed or fail with a recognised failure within
  30 s. Two real problems found and fixed:
  - Images were decoded in full whatever their declared size, so a tiny hostile
    PNG could exhaust memory and kill the app. `engines/image/safe_decode.dart` now
    reads the header first and refuses pictures over **52 megapixels** (`tooLarge`),
    covering 50 MP phone photos within NFR-MEM-01. Used by image→PDF, signatures,
    logos and the scanner.
  - Markdown nested thousands of levels deep overflowed the parser's stack or took
    minutes. Quote and indent nesting beyond **16 levels** is flattened before
    parsing; the text is kept.
- **Accessibility** (`test/widget/accessibility_test.dart`): every design-system
  component is checked with Flutter's labelled-tap-target, 48 dp tap-target and
  text-contrast guidelines, in light and dark themes at 1× and 2× text, and for
  overflow. One fix: segmented-choice segments were 42 dp tall; now 48 dp
  (`Sizes.touch`; no token changed).
- **Performance marks** (`lib/app/perf.dart`): profile builds print
  `DocNookPerf open <kind> <ms>` when a viewer shows its content. Release builds
  print nothing; lines never include names or paths (rule 11).
- **Release tooling**: `tool/make_upload_key.sh` (the owner creates the Play upload
  key; its password is never seen by Claude Code), `tool/release.sh` (checks, refuses
  placeholders or a debug key unless `--draft`, builds the obfuscated AAB and APKs,
  checks NFR-SIZE-01, writes SHA-256 sums and zips symbols), `tool/check.sh` now also
  verifies `appVersion` matches `pubspec.yaml`. `tool/make_legal_pages.py` writes the
  web privacy policy and terms from the same ARB strings as the in-app pages;
  `tool/make_store_graphics.py` draws the 512 px icon and feature graphic from the
  launcher artwork. Store text and Play Console answers are in `docs/release/`.
- **Performance pass on the Galaxy A06** (Android 14, the owner's phone; generated
  files only). Obfuscated release build:
  | Target | Measured | Limit |
  | --- | --- | --- |
  | NFR-PERF-01 cold start to Home | 0.6–0.7 s (1.1–1.6 s on the first launch after an install) | 1.5 s |
  | NFR-PERF-02 first page, 7.5 MB 100-page PDF | 0.34 s typical, one 1.6 s outlier | 1 s |
  | NFR-PERF-03 readable, Word file of ~150 pages | 0.63 s (1.8 s the first time: copying from another app) | 2 s |
  | NFR-PERF-04 first screen, 50k-cell XLSX | 2.5–2.7 s | 3 s |
  | NFR-SIZE-01 APK size | 27 MB arm64, 68 MB universal | 35 / 80 MB |
  Open times come from the profile build's marks. The spreadsheet has the least
  margin; worth watching on slower phones in the closed test.
- **TalkBack check on the phone** (accessibility tree, without changing the phone's
  settings): every control on Home, Files, Tools, Settings and the sheet viewer has
  a spoken label, but labelled controls did not report their tap action, so
  TalkBack's double-tap could fail. Fixed in all 13 wrappers (the label now carries
  the tap and long-press actions) and the accessibility test now fails if any
  enabled button lacks a tap action. Confirmed on the phone afterwards.
