# DocNook — Offline Document Suite for Android: Product & Technical Blueprint (Final)

Nov 11, 2026 · @Usman Ahmad

## 1. Product summary

**DocNook** is a free, fully offline Android app that opens, scans, converts and organizes everyday documents, built in Flutter and shipped as both a Play Store app and a direct APK. The name is plain English — *Doc* (what it handles) + *Nook* (a safe little corner for your files) — easy to say, easy to spell, and it carries the search keyword "doc" in the brand itself. Store title: **DocNook: PDF Reader & Scanner** (29 of 30 characters), which puts the two highest-volume search terms, "PDF reader" and "scanner", in the title.

Package id: `app.docnook.reader`. Before the first Play upload, search Google Play for "DocNook" to confirm no app already uses the name; Play package ids are unique, so the id itself cannot clash once registered. Backup names if needed: **PaperNest**, **DocHaven**.

### Positioning

Most reader apps on Play are ad-heavy, ask for internet, upsell constantly and look identical. DocNook competes on four things they cannot easily copy:

- **Truly offline and private.** The app ships with no `INTERNET` permission at all. Users can verify this on the Play listing.
- **One place for the whole document job.** Open a file, scan a paper, convert it, combine it, find it again later.
- **Fast on cheap phones.** Designed and tested for 3 GB RAM devices common in Pakistan and similar markets.
- **Honest output.** Every tool states what it preserves. No conversion promises a quality the device cannot deliver offline.

### Target users

- Students opening lecture PDFs, slides and assignments shared on WhatsApp.
- Office and small-business staff handling invoices, spreadsheets, contracts and ID scans.
- Anyone who needs to scan a form, combine it into one PDF and send it.

### Product principles

1. **Open first, everything else second.** Any supported file opens in under 2 seconds from the Android "Open with" menu.
2. **Three taps to any tool.** Home → Tools → tool, or long-press a file → tool.
3. **Never destroy the original.** Every tool writes a new file. Edits to PDFs save as a copy unless the user chooses overwrite.
4. **No dead ends.** Every error screen says what happened and offers a next step.
5. **Earn every feature.** A module ships only if it serves the open → scan → convert → organize loop.

### Deliberately excluded (and why)

| Excluded | Reason |
| --- | --- |
| Full Word/Excel/PowerPoint editing | Months of work to do badly; users already have Office/WPS for editing. DocNook reads and converts. |
| AI chat, summaries, "ask your PDF" | Needs cloud or a large on-device model; breaks offline, size and free goals. |
| Cloud sync, accounts, login | Contradicts offline and privacy positioning. Android's share sheet already reaches Drive/WhatsApp. |
| Ads and analytics SDKs (for now) | Both require internet. Monetization (possibly ads) is a later decision if usage grows; see section 13.3. |
| eSign with legal certificates | Digital-certificate signing is a legal product. DocNook offers a drawn signature stamp only. |
| Legacy binary .doc/.xls/.ppt full rendering | No open Dart parser exists. Best-effort text extraction only, clearly labeled. |
| Home-screen widgets, wear, tablets-first layouts | Low value for v1; tablet layout simply scales. |

## 2. Feature scope

DocNook has five modules — **Read, Scan, Convert, PDF Tools, Organize** — plus a **Private Vault**, and **every feature below ships in version 1.0**. Nothing is deferred to later releases.

Fidelity labels used throughout: **Full** = looks like the original; **Good** = layout and styling mostly preserved, complex features simplified; **Basic** = text, headings, tables and images only; **Text** = plain text extraction.

### 2.1 Read (viewers)

| Format | Extensions | Fidelity | Viewer features |
| --- | --- | --- | --- |
| PDF | .pdf | Full (PDFium) | Continuous/single-page scroll, zoom, page jump, thumbnails strip, outline (TOC), text search, text select & copy, password-protected PDFs, night mode, resume position, bookmarks |
| Word | .docx, .dotx | Good | Paragraph styles, headings, bold/italic/underline, lists, tables, images, page breaks, headers/footers (simplified), search, reflow to screen width |
| Excel | .xlsx, .xlsm, .csv, .tsv | Good | Sheet tabs, frozen header row/col, column widths, cell formats (number/date/currency), merged cells, cached formula values, search, cell detail sheet |
| PowerPoint | .pptx | Basic | Slide-by-slide view: text boxes, images, simple shapes with positions; outline mode as fallback |
| OpenDocument | .odt, .ods | Basic / Good | Same renderers as Word/Excel via ODF XML mapping |
| Legacy Office | .doc, .xls, .ppt | Text | Text extraction from the old binary formats with a clear "limited preview" banner |
| Rich text | .rtf | Basic | Paragraphs, bold/italic/underline, font size |
| Text & code | .txt, .log, .json, .xml, .yaml, .ini, common code files | Full | Monospace, wrap toggle, syntax highlight for JSON/XML/code, large-file streaming (50 MB+) |
| Markdown | .md | Full | Rendered view with raw toggle |
| E-book | .epub | Good | Chapters, reflowable text, font size, themes, resume position |
| Images | .jpg, .png, .webp, .gif, .bmp, .heic (device codec) | Full | Zoom/pan, swipe through folder, rotate, convert to PDF |
| Archive | .zip | Full (browse) | List contents, open a file inside without extracting everything, extract selected |

Shared reader features: **Read Aloud** with the phone's built-in offline text-to-speech voices (play/pause, speed, highlights the sentence being read), "Open with" and share-target support, recent position memory, share/print via the Android print service, document info sheet.

### 2.2 Scan

- Camera capture with automatic edge detection, multi-page batch, retake, reorder, delete.
- Crop with 4-corner handles and perspective correction.
- Filters: Original, Document (high-contrast B/W), Grayscale, Enhanced color. Rotate.
- Modes: **Document**, **ID card** (front and back placed on one page at real card size), **Book** (splits a two-page spread into two pages).
- Export as PDF (A4/Letter/fit) or JPG set; choose quality (Small / Balanced / Best).
- **OCR** (English and other Latin-script text): on-device recognition; produces a searchable PDF (invisible text layer) or copyable text.
- Import images from the gallery into the same edit flow.

### 2.3 Convert

| From → To | Method & honest limit |
| --- | --- |
| Images → PDF | Full. Page size, margins, order, compression. |
| PDF → Images (JPG/PNG) | Full. Per page or range, chosen DPI. |
| PDF → Text (.txt) | Text layer; OCR fallback for scanned PDFs. |
| Word (.docx, .odt) → PDF | Good. Uses DocNook's own layout engine, not Word's; complex layouts may shift. |
| Excel (.xlsx, .ods, .csv) → PDF | Good. Sheet-to-pages with fit-to-width option. |
| PowerPoint (.pptx) → PDF | Basic. One slide per page. |
| Text / Markdown → PDF | Full. |
| CSV ↔ Excel | Full (data); formatting minimal. |
| PDF → Word (.docx) | Basic. Paragraphs, headings by font size, images; no complex layout. Labeled clearly. |

Batch conversion (many files in one job) for Images→PDF, PDF→Images, Word/Excel/PowerPoint→PDF. Deliberately not offered: EPUB→PDF and PDF→Excel (poor offline quality).

### 2.4 PDF Tools

| Tool | Notes |
| --- | --- |
| Merge | Any number of PDFs and images, drag to reorder |
| Split | By range, every N pages, or extract selected pages |
| Organize pages | Visual grid: reorder, rotate, delete, duplicate, insert blank or image page |
| Compress | Three honest modes: *Light* (re-save, remove unused objects), *Balanced* (recompress embedded images, text stays selectable), *Strong* (re-renders pages as JPEG; text kept selectable only if OCR is on) |
| Protect / Unlock | Add an AES-256 password; remove a password the user knows |
| Watermark | Text or image, opacity, angle, page range |
| Page numbers | Position, format "1", "Page 1 of N" |
| Sign | Draw or import a signature, save up to 3, place and resize on any page |
| Annotate | Highlight, underline, strike, freehand ink, text note; saved as standard PDF annotations |
| Fill forms | Text fields, checkboxes, radio buttons, dropdowns in existing PDF forms; save filled or flattened |
| Redact | Mark areas; the page is rebuilt so the hidden content is truly removed, not just covered by a black box |

### 2.5 Organize

- **Library** with automatic device discovery (all supported files), grouped by type.
- **Recents**, **Starred**, user **Collections** (virtual folders — a file can be in several without copying).
- **DocNook folder**: `Documents/DocNook/` for everything DocNook creates (Scans, Converted, Edited).
- Full-text **search** across file names and indexed document text (including OCR text).
- Rename, duplicate, delete (to Android trash where supported), share, open in another app, file info.
- Sort by name, date, size, type; filter by type and location.
- Launcher shortcuts (long-press the app icon): Scan, Merge PDFs, Recent.

### 2.6 Private Vault

A PIN/biometric-locked area. Files moved in are encrypted on disk with AES-256-GCM and removed from their public location. Viewers decrypt to a temporary cache that is wiped on close.

### 2.7 Language and release

The app is **English only**. Version 1.0 contains everything in this section; later versions are for fixes and user requests.

## 3. Requirements

Requirements carry IDs so Claude can reference them in commits and tests (`FR-READ-03`, `NFR-PERF-01`).

### 3.1 Functional requirements

| ID | Requirement |
| --- | --- |
| FR-CORE-01 | App appears in Android "Open with" and "Share to" for every supported MIME type and opens the file directly in the right viewer. |
| FR-CORE-02 | App works with airplane mode on for every feature. No feature may require network. |
| FR-CORE-03 | Every tool writes output to `Documents/DocNook/<Category>/` with a readable name, e.g. `Merged_2026-11-11_1432.pdf`, never overwriting silently. |
| FR-CORE-04 | Long jobs (>1 s) show determinate progress, can be cancelled, and survive screen rotation. |
| FR-CORE-05 | Results screen offers Open, Share, Rename, Show in folder, and "Do more" (chain into another tool). |
| FR-READ-01 | PDF viewer: zoom 50–800%, page jump, thumbnails, outline, search with hit highlighting, text selection. |
| FR-READ-02 | Password PDFs prompt for password; wrong password shows inline error; password is never stored. |
| FR-READ-03 | Every viewer remembers last position per document and restores it on reopen. |
| FR-READ-04 | Night mode for PDF (inverted with image protection) and themed backgrounds for text viewers. |
| FR-READ-05 | Files over a format's safe limit (section 3.2) open with a warning and a "try anyway" option instead of crashing. |
| FR-SCAN-01 | Capture up to 50 pages per session; session survives app backgrounding and process death (draft saved). |
| FR-SCAN-02 | Manual crop with magnifier loupe on corner drag. |
| FR-SCAN-03 | OCR produces a searchable PDF and stores recognized text in the search index. |
| FR-CONV-01 | Each converter shows its fidelity label and a one-line limit before the user starts. |
| FR-PDF-01 | Merge/split/organize operate on page objects without re-rendering, preserving text and quality. |
| FR-PDF-02 | Annotations and signatures are written as standard PDF annotations readable in Adobe/Chrome. |
| FR-ORG-01 | First launch (with permission) indexes all supported files; later changes picked up incrementally on app open and pull-to-refresh. |
| FR-ORG-02 | Search returns results as the user types (debounced 200 ms), matching name and indexed content. |
| FR-VAULT-01 | Vault requires PIN (4–6 digits) with optional biometric; auto-locks on app background. |
| FR-SET-01 | Settings: theme (system/light/dark), default PDF scroll mode, default output quality, output folder, clear cache, app lock, manage index, about & licenses. |

Additional v1.0 requirements:

| ID | Requirement |
| --- | --- |
| FR-READ-06 | Read Aloud in PDF, Word, text, markdown and EPUB viewers using the device TTS engine; works offline; if no TTS voice is installed, show how to install one in Android settings. |
| FR-READ-07 | Legacy .doc/.xls/.ppt and .rtf open in a text/basic preview with a banner and an "Open with another app" action. |
| FR-SCAN-04 | ID-card mode places front and back at real card size (85.6 × 54 mm) on one A4 page; Book mode splits a spread at the detected centre line, adjustable by the user. |
| FR-PDF-03 | Fill forms: edit AcroForm fields, save as editable copy or flattened copy. |
| FR-PDF-04 | Redact: content under a redaction box is removed from the output (verified by text extraction returning nothing in that area). |
| FR-PDF-05 | Protect: output opens with the password in Adobe Reader and Chrome and refuses to open without it. |
| FR-CORE-06 | No feature may require the user to create an account, register, or enter an API key. |

### 3.2 Non-functional requirements

| ID | Area | Target |
| --- | --- | --- |
| NFR-PERF-01 | Cold start to Home | < 1.5 s on a 3 GB RAM, mid-2020 phone (reference: Samsung Galaxy A12 / Redmi 9 class) |
| NFR-PERF-02 | Open a 10 MB, 100-page PDF | First page visible < 1 s |
| NFR-PERF-03 | Open a 2 MB .docx | Readable < 2 s |
| NFR-PERF-04 | Open a 5 MB .xlsx (50k cells) | First screen < 3 s; grid scroll at 60 fps |
| NFR-PERF-05 | UI thread | No frame > 32 ms during scrolling; all parsing/conversion in isolates |
| NFR-MEM-01 | Peak memory | < 350 MB for any single document operation |
| NFR-SIZE-01 | APK size | ≤ 35 MB per ABI (arm64-v8a); universal APK ≤ 80 MB |
| NFR-LIMIT-01 | Safe limits | PDF 500 MB; DOCX 50 MB; XLSX 30 MB or 1M cells; ZIP entries 10k and 2 GB uncompressed |
| NFR-COMP-01 | Android versions | minSdk 24 (Android 7.0); target the API level Google Play currently requires |
| NFR-A11Y-01 | Accessibility | TalkBack labels on every control, 48 dp touch targets, text scales to 200% without clipping, WCAG AA contrast |
| NFR-REL-01 | Stability | Crash-free sessions ≥ 99.5% in closed testing (tracked via Play Console vitals, which need no SDK) |
| NFR-I18N-01 | Localization | English only. All strings still go in ARB files so translation remains possible later |
| NFR-PRIV-01 | Privacy | No INTERNET permission, no analytics, no third-party data collection; Play Data Safety: "No data collected" |

## 4. Technology stack

One Flutter codebase in Dart, with a small, isolated Kotlin glue layer (about 150–250 lines) for the few Android jobs no maintained plugin does well. **Every component is open source and needs no account, license key, registration or API key.** Package names below are the intended choices; versions are not pinned here — Claude must check pub.dev for the current stable version, its license, its last publish date and its Android support before adding each one.

### 4.1 Core

| Concern | Choice | Why |
| --- | --- | --- |
| SDK | Flutter stable (latest), Dart 3, null safety | — |
| State management | `flutter_riverpod` (+ `riverpod_annotation`/generator) | Testable, no BuildContext coupling, good for async jobs |
| Navigation | `go_router` | Deep links from intents map cleanly to routes |
| Database | `drift` + `sqlite3_flutter_libs` | Typed SQL, migrations, FTS5 full-text search, works in isolates |
| Models | `freezed` + `json_serializable` | Immutable states, unions for job states |
| Strings | `flutter_localizations` + `intl` (English ARB file) | English only, but no hard-coded strings |
| Lints | `very_good_analysis` | Strict, catches async mistakes |

### 4.2 Document engines

| Job | Choice | Notes / risk |
| --- | --- | --- |
| PDF render, text, search | `pdfrx` (PDFium, BSD/Apache-style licenses) | Fast, handles passwords. Adds \~5 MB native per ABI. |
| PDF editing: merge, split, reorder, rotate, insert pages, watermark, page numbers, signatures, annotations, form filling, unlock | **PDFium through FFI** — the same PDFium library pdfrx already ships, called via its low-level bindings (or DocNook's own `ffigen` bindings) | PDFium has native calls for importing pages, page objects (text, image), annotations, form fill and saving copies, including saving without the password. One engine, no extra size. Wrapped in `engines/pdf/pdfium_editor.dart`. |
| PDF password protection (AES-256) | DocNook's own Dart **PDF security writer** (`engines/pdf/security/`) | PDFium cannot add encryption. Implements the PDF 2.0 standard security handler (AES-256) over a PDFium-saved copy. Highest-risk item: proven in Spike F. |
| Redaction | Rasterize the redacted page (render, paint boxes, rebuild the page as an image, optional OCR layer) | Guarantees the hidden content is gone; text on that page becomes OCR text. |
| Compression | PDFium save (Light), PDFium image re-encode (Balanced), render-to-JPEG rebuild with `pdf` (Strong) | — |
| PDF generation (convert to PDF) | `pdf` (DavBfr, Apache-2.0) | Layout widgets, font embedding |
| Print | `printing` | Android print service |
| DOCX, PPTX, ODT, ODS parsing | `archive` + `xml` (custom parsers) | No good Dart renderer exists; DocNook builds its own document model (section 5.5) |
| Legacy .doc/.xls/.ppt text | Custom Dart reader for the OLE compound-file format + text streams | Text only, by design |
| RTF | Custom Dart tokenizer → DocModel | Basic formatting |
| XLSX reading | Custom streaming parser on `xml` event API | The `excel` package loads whole workbooks into memory; too slow for large sheets |
| XLSX writing (CSV→Excel) | `excel` | Small outputs only |
| CSV | `csv` | — |
| Spreadsheet grid | `two_dimensional_scrollables` (TableView) | Official Flutter package, virtualized rows and columns |
| Markdown | `markdown_widget` | `flutter_markdown` is discontinued |
| Code highlight | `re_highlight` or `flutter_highlight` | Pick the better-maintained one at build time |
| EPUB | `epubx` + `flutter_widget_from_html_core` | Core variant only (no webview, no network) |
| ZIP | `archive` | Stream entries; enforce zip-slip and size guards |
| Read Aloud | `flutter_tts` | Uses the phone's installed offline voices |

### 4.3 Scan and OCR

| Job | Choice | Notes / risk |
| --- | --- | --- |
| Primary scanner | `google_mlkit_document_scanner` | Best UX, edge detection, small, no account or key. Needs Google Play services; the scanner module is fetched by Play services once. DocNook itself still has no INTERNET permission. |
| Fallback scanner (phones without Google services, e.g. some Huawei) | `camera` + DocNook's own crop screen + `image` (`copyRectify` for perspective) + simple edge detection in Dart | Fully supported path, tested on an emulator without Play services |
| Filters, compression | `image` (in isolates) | — |
| OCR (Play-services phones) | `google_mlkit_text_recognition`, **bundled Latin model** | Fully offline, \~4 MB, no account |
| OCR (phones without Google services) | Tesseract via `flutter_tesseract_ocr` with the English `eng` traineddata bundled (\~4 MB "fast" model) | Keeps OCR working on every phone; included only in the `direct` APK build to keep the Play build small |

### 4.4 Platform services

| Job | Choice |
| --- | --- |
| Permissions | `permission_handler` |
| Pick files / folders (SAF) | `file_picker`; folder tree grants via Kotlin glue |
| Save to public Documents (Android 10+) | `media_store_plus` or Kotlin MediaStore glue |
| Share out | `share_plus` |
| Receive "Open with" (VIEW) and "Share to" (SEND) | Kotlin glue in `MainActivity` → MethodChannel `docnook/intents` |
| Open in another app | `open_filex` |
| App lock | `local_auth` |
| Key storage | `flutter_secure_storage` (Android Keystore-backed) |
| Encryption (vault) and AES for PDF security | `cryptography` + `cryptography_flutter` (AES-256-GCM / AES-CBC, Argon2id, SHA-256/384/512) |
| Paths | `path_provider`, `path` |

### 4.5 Fonts and assets

All UI fonts are bundled; nothing is fetched at runtime (no `google_fonts` runtime fetching). Converters embed bundled Noto Sans, Noto Serif and Noto Sans Mono (Latin, Greek, Cyrillic). If a document contains other scripts, the converter loads a matching font from the phone's own `/system/fonts/` at runtime, so DocNook ships no extra font files. Register every bundled font license with `LicenseRegistry`.

### 4.6 Tooling (no online services)

`flutter_test`, `integration_test`, `mocktail`, golden tests for key screens, `build_runner` for codegen. Version control with local **git** (no hosting account needed). Instead of cloud CI, a local script **`tool/check.sh`** runs format, analyze, tests and the merged-manifest INTERNET check; Claude runs it after every task. A test-document corpus lives in `test/fixtures/` (section 12).

## 5. Architecture

DocNook uses a feature-first, layered architecture: UI talks to use cases, use cases talk to repository interfaces, and engines do all heavy parsing, rendering and conversion off the UI thread.

&#91;embedded content: Sheaf layered architecture · 4 layers, 3 infrastructure parts\]

Dependencies only point downward. The Domain layer defines interfaces; the three infrastructure parts implement them, so engines can be swapped (for example, replacing the PDF security writer) without touching screens.

### 5.1 Folder structure

```
lib/
  main.dart
  app/                 app.dart, router.dart, theme/, l10n/
  core/                result.dart, failures.dart, logging.dart, utils/
  domain/              entities/, docmodel/, sheetmodel/, repositories/ (interfaces)
  design_system/       tokens.dart, typography.dart, components/
  data/
    db/                app_database.dart, tables/, daos/, migrations/
    files/             file_ref.dart, file_type_detector.dart, file_store.dart
    platform/          intents_channel.dart, saf_channel.dart, mediastore_channel.dart
    repositories/      implementations of domain interfaces
  engines/
    jobs/              job_runner.dart, job.dart, worker_pool.dart
    pdf/               render, edit, annotate, compress
    office/            docx/, xlsx/, pptx/, odf/  (parsers -> DocModel/SheetModel)
    epub/  text/  archive/  image/
    scan/  ocr/
    convert/           docmodel_to_pdf.dart, pdf_to_docmodel.dart, docx_writer.dart, ...
  features/
    onboarding/ home/ library/ search/ tools/ convert/ scan/ vault/ settings/ monetization/ (empty seam)
    viewer/            pdf/ docx/ sheet/ slides/ text/ markdown/ epub/ image/ archive/
      <feature>/presentation/   screens, widgets
      <feature>/application/    controllers (Riverpod), use cases
android/app/src/main/kotlin/.../  MainActivity.kt, DocNookChannels.kt
tool/  check.sh
docs/  BLUEPRINT.md, decisions.md
test/  unit/ widget/ golden/ fixtures/
integration_test/
```

### 5.2 Key abstractions

- **FileRef** (sealed): `PathRef` (real file path), `ContentUriRef` (Android content URI from SAF or an intent), `VaultRef` (encrypted file id). Engines that need random access receive a local path; content URIs are streamed into the cache first, with a progress indicator for files over 20 MB.
- **FileTypeDetector**: decides format by magic bytes first, then extension, then MIME. ZIP containers are inspected: `[Content_Types].xml` distinguishes DOCX/XLSX/PPTX; the `mimetype` entry distinguishes ODT/ODS/EPUB. Renamed or extension-less files still open correctly.
- **Result\<T>** with a sealed **DocNookFailure**: `unsupported`, `corrupt`, `passwordRequired`, `wrongPassword`, `tooLarge`, `permissionDenied`, `outOfSpace`, `cancelled`, `unknown`. Every failure maps to one friendly message and one action in the UI.

### 5.3 Jobs and isolates

- Every operation that can exceed \~100 ms is a **Job** (sealed class: `RenderThumbnail`, `ParseDocx`, `ParseXlsx`, `MergePdfs`, `SplitPdf`, `CompressPdf`, `ConvertDocxToPdf`, `ScanToPdf`, `OcrPages`, `IndexText`, …).
- **JobRunner** runs jobs on a worker pool: 1 worker on devices with ≤ 3 GB RAM, 2 otherwise. Each job reports progress (0–1 plus a label) through a `SendPort`, honours a cancellation token, and writes results to a temp file first, then moves it atomically to its destination.
- Job state is persisted in the `jobs` table so an interrupted batch can show "Resume" or "Discard" on next launch.
- Plugins that call native code (ML Kit, pdfrx) are called from the main isolate; they already do their work natively and asynchronously.

### 5.4 State management

One Riverpod controller per screen (`AsyncNotifier`), holding an immutable `freezed` state. Long-lived services (database, JobRunner, settings, thumbnail cache) are providers overridden in tests. No business logic lives in widgets.

### 5.5 DocModel: one model, many outputs

Word, ODT and PowerPoint parsers all produce the same **DocModel**: `Document → Section → Block`, where a block is `Paragraph(runs, style)`, `Heading(level)`, `ListItem(level, marker)`, `Table(rows → cells → blocks)`, `ImageBlock`, `PageBreak` or `SlideFrame(positioned children)`. Two renderers consume it: **DocModel → Flutter widgets** (viewer) and **DocModel → `pdf` widgets** (Word→PDF). PDF→Word runs the other way: positioned PDF text → DocModel → DOCX writer. Spreadsheets have a parallel **SheetModel** (sparse cells, styles, merges, column widths) feeding both the grid viewer and Excel→PDF.

This is the single most important design decision: each new format or output is one parser or one renderer, not a new pipeline.

### 5.6 Caching

Thumbnails (first page, 256 px wide, WebP) and parsed DocModels for recently opened files are cached in the app cache directory, keyed by `sha1(path + size + modified time)`, with a 200 MB LRU cap. The user can clear it in Settings.

## 6. Database schema

One Drift (SQLite) database, `docnook.db`, in app-private storage, schema version 1, with a full-text index on document names and content. The database stores *metadata about* files, never the files themselves (except vault metadata). Timestamps are UTC milliseconds; enums are stored as text.

### 6.1 Tables

**documents** — every file DocNook knows about

| Column | Type | Notes |
| --- | --- | --- |
| id | INTEGER PK | autoincrement |
| uri | TEXT UNIQUE NOT NULL | absolute path or `content://` URI |
| display\_name | TEXT NOT NULL | file name shown in UI |
| extension | TEXT | lower-case, no dot |
| mime | TEXT | detected MIME |
| doc\_type | TEXT NOT NULL | `pdf`, `word`, `sheet`, `slides`, `text`, `markdown`, `epub`, `image`, `archive`, `other` |
| size\_bytes | INTEGER | — |
| modified\_at | INTEGER | file mtime |
| added\_at | INTEGER | when DocNook first saw it |
| last\_opened\_at | INTEGER NULL | drives Recents |
| open\_count | INTEGER DEFAULT 0 | — |
| is\_starred | INTEGER DEFAULT 0 | — |
| source | TEXT | `discovered`, `picked`, `intent`, `created`, `scanned` |
| page\_count | INTEGER NULL | PDF pages, sheets, slides |
| is\_encrypted | INTEGER DEFAULT 0 | password PDF |
| thumb\_key | TEXT NULL | cache key |
| is\_missing | INTEGER DEFAULT 0 | file deleted/moved outside DocNook |
| index\_state | TEXT DEFAULT `none` | `none`, `pending`, `done`, `failed`, `skipped` |
| indexed\_at | INTEGER NULL | — |

Indexes: `(doc_type, modified_at DESC)`, `(last_opened_at DESC)`, `(is_starred)`, `(is_missing)`.

**collections** and **collection\_items** — virtual folders

| Table | Columns |
| --- | --- |
| collections | id PK, name TEXT NOT NULL, color\_token TEXT, sort\_order INTEGER, created\_at INTEGER |
| collection\_items | collection\_id FK → collections ON DELETE CASCADE, document\_id FK → documents ON DELETE CASCADE, added\_at INTEGER; PK (collection\_id, document\_id) |

**reading\_state** — resume position, one row per document

| Column | Type | Notes |
| --- | --- | --- |
| document\_id | INTEGER PK FK | ON DELETE CASCADE |
| position\_json | TEXT | per viewer: `{page, offsetY, zoom}` for PDF; `{sheet, row, col}` for sheets; `{chapter, offset}` for EPUB; `{blockIndex}` for DocModel viewers |
| progress | REAL | 0–1, shown as a thin bar on cards |
| view\_prefs\_json | TEXT NULL | per-doc night mode, scroll mode |
| updated\_at | INTEGER | — |

**bookmarks** — id PK, document\_id FK (cascade), anchor\_json TEXT, label TEXT, created\_at INTEGER.

**doc\_search** — FTS5 virtual table

```sql
CREATE VIRTUAL TABLE doc_search USING fts5(
  title, body,
  document_id UNINDEXED, page UNINDEXED,
  tokenize = 'unicode61 remove_diacritics 2'
);
```

One row per page (PDF) or per \~4 KB chunk (other formats), so search results can jump to the right page. Body text is capped at 2 MB per document.

**scan\_sessions** and **scan\_pages** — scanner drafts survive process death

| Table | Columns |
| --- | --- |
| scan\_sessions | id PK, title TEXT, status TEXT (`draft`, `exported`), mode TEXT (\`document\`, \`id\_card\`, \`book\`), page\_size TEXT, quality TEXT, ocr\_enabled INTEGER, output\_document\_id INTEGER NULL FK, created\_at, updated\_at |
| scan\_pages | id PK, session\_id FK (cascade), position INTEGER, original\_path TEXT, processed\_path TEXT, corners\_json TEXT, filter TEXT, rotation INTEGER, ocr\_text TEXT NULL |

Scan images live in app-private `files/scans/<session_id>/` and are deleted when a session is exported-and-closed or discarded.

**jobs** — long operations, for progress, recovery and the "Recent activity" list

| Column | Type | Notes |
| --- | --- | --- |
| id | INTEGER PK | — |
| type | TEXT | `merge`, `split`, `compress`, `convert_docx_pdf`, … |
| status | TEXT | `queued`, `running`, `done`, `failed`, `cancelled`, `interrupted` |
| input\_json | TEXT | list of FileRefs |
| options\_json | TEXT | tool options |
| output\_json | TEXT NULL | produced URIs |
| progress | REAL | 0–1 |
| error\_code | TEXT NULL | DocNookFailure name |
| created\_at, finished\_at | INTEGER | — |

Keep the last 100 finished jobs; prune older ones on launch.

**folder\_grants** — SAF folders the user added: id PK, tree\_uri TEXT UNIQUE, display\_name TEXT, granted\_at INTEGER.

**signatures** — id PK, file\_name TEXT (PNG in app-private `files/signatures/`), created\_at INTEGER. Max 3 rows.

**vault\_items** — id PK, blob\_name TEXT UNIQUE (random UUID file name in `files/vault/`), original\_name TEXT, mime TEXT, size\_bytes INTEGER, wrapped\_key BLOB (per-file key encrypted with the vault master key), original\_location TEXT NULL (for "restore"), added\_at INTEGER.

**app\_settings** — key TEXT PK, value TEXT. Typed accessors in a `SettingsRepository`; no SharedPreferences.

### 6.2 Rules

- Foreign keys ON (`PRAGMA foreign_keys = ON`), WAL mode.
- Every schema change gets a numbered Drift migration and a migration test against a saved v1 schema dump.
- Text indexing runs as low-priority jobs only while the app is open and idle; it pauses when the user opens a document.
- Vault file names and original names never appear in `documents` or `doc_search`.

## 7. Android permissions, manifest and Play policy

DocNook asks for the fewest permissions possible, never at launch, and works fully without the optional ones. Everything except automatic library discovery works with zero storage permissions, using Android's file picker, "Open with" and "Share to".

### 7.1 Permission table

| Permission | Android versions | Required? | Asked when | Purpose |
| --- | --- | --- | --- | --- |
| `READ_EXTERNAL_STORAGE` (maxSdkVersion 32) | 7–12 | Optional | User taps "Find my documents" | Discover documents on device |
| `WRITE_EXTERNAL_STORAGE` (maxSdkVersion 28) | 7–9 | Optional | First save to `Documents/DocNook` | Save outputs on old Android; Android 10+ uses MediaStore with no permission |
| `MANAGE_EXTERNAL_STORAGE` | 11+ | Optional | User taps "Find my documents" | Discover all PDFs/Office files; Android 11+ gives no other way to list other apps' documents |
| `CAMERA` | all | Optional | Fallback scanner only | ML Kit scanner needs no camera permission in DocNook |
| `USE_BIOMETRIC` | 9+ | Normal (auto-granted) | — | App lock and vault |

**Explicitly removed:** `INTERNET` and `ACCESS_NETWORK_STATE`. Plugins sometimes merge these in; remove them with `tools:node="remove"` and add a CI step that fails the build if the merged release manifest contains either.

Images are imported with the Android Photo Picker, so `READ_MEDIA_IMAGES` is not needed and Play's photo/video permission policy does not apply.

### 7.2 Manifest essentials

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
          xmlns:tools="http://schemas.android.com/tools">

  <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
  <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28"/>
  <uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" tools:ignore="ScopedStorage"/> <!-- see flavors -->
  <uses-permission android:name="android.permission.CAMERA"/>
  <uses-permission android:name="android.permission.USE_BIOMETRIC"/>
  <uses-permission android:name="android.permission.INTERNET" tools:node="remove"/>
  <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" tools:node="remove"/>
  <uses-feature android:name="android.hardware.camera" android:required="false"/>

  <application
      android:label="DocNook"
      android:allowBackup="false"
      android:fullBackupContent="false"
      android:dataExtractionRules="@xml/data_extraction_rules"
      android:requestLegacyExternalStorage="true"
      android:usesCleartextTraffic="false"
      android:enableOnBackInvokedCallback="true">

    <activity android:name=".MainActivity" android:exported="true"
              android:launchMode="singleTask" ...>
      <intent-filter> <!-- launcher --> ... </intent-filter>

      <!-- Open with -->
      <intent-filter>
        <action android:name="android.intent.action.VIEW"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <category android:name="android.intent.category.BROWSABLE"/>
        <data android:scheme="content"/>
        <data android:scheme="file"/>
        <data android:mimeType="application/pdf"/>
        <data android:mimeType="application/vnd.openxmlformats-officedocument.wordprocessingml.document"/>
        <data android:mimeType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"/>
        <data android:mimeType="application/vnd.openxmlformats-officedocument.presentationml.presentation"/>
        <data android:mimeType="application/vnd.oasis.opendocument.text"/>
        <data android:mimeType="application/vnd.oasis.opendocument.spreadsheet"/>
        <data android:mimeType="application/epub+zip"/>
        <data android:mimeType="application/zip"/>
        <data android:mimeType="text/*"/>
        <data android:mimeType="application/msword"/>
        <data android:mimeType="application/vnd.ms-excel"/>
        <data android:mimeType="application/vnd.ms-powerpoint"/>
        <data android:mimeType="application/json"/>
      </intent-filter>

      <!-- Share to DocNook -->
      <intent-filter>
        <action android:name="android.intent.action.SEND"/>
        <action android:name="android.intent.action.SEND_MULTIPLE"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <data android:mimeType="application/*"/>
        <data android:mimeType="text/*"/>
        <data android:mimeType="image/*"/>
      </intent-filter>
    </activity>

    <provider android:name="androidx.core.content.FileProvider"
              android:authorities="${applicationId}.files"
              android:exported="false" android:grantUriPermissions="true">
      <meta-data android:name="android.support.FILE_PROVIDER_PATHS"
                 android:resource="@xml/file_paths"/>
    </provider>
  </application>

  <queries>
    <intent><action android:name="android.intent.action.VIEW"/><data android:mimeType="*/*"/></intent>
  </queries>
</manifest>
```

App shortcuts (long-press launcher icon): **Scan**, **Merge PDFs**, **Recent**. Add `application/octet-stream` handling in Dart (sniff the real type) because many file managers and WhatsApp send that MIME.

### 7.3 Build flavors

| Flavor | applicationId | All-files access | Distribution |
| --- | --- | --- | --- |
| `play` | `app.docnook.reader` | Included only if Google approves the declaration (section 7.4); otherwise removed by the flavor manifest and discovery uses SAF folder grants | Google Play (AAB) |
| `direct` | `app.docnook.reader.direct` | Always included | Split APKs shared via a Google Drive link or sent directly |

Different IDs let both installs coexist and avoid signature-mismatch update errors, because Play re-signs the Play build with Google's app-signing key.

### 7.4 Google Play policy checklist

- **All files access**: Play allows `MANAGE_EXTERNAL_STORAGE` only for listed core uses; document-management and file-search apps can qualify but approval is not guaranteed. Submit the Permissions Declaration with a short video showing "Find my documents". If rejected, ship the `play` flavor without it — the app still works fully through "Open with", the picker and folder grants.
- **Data safety form**: "No data collected, no data shared." True because there is no INTERNET permission.
- **Target API level**: target whatever level Play requires on the upload date; check the Play Console policy page at release time.
- **New personal developer accounts** must run a closed test with at least 12 opted-in testers for 14 consecutive days before production access. Plan this into the schedule (section 13).
- Privacy policy URL is still required. Host a one-page policy on Google Sites with the same Google account (free, no new signup).
- Store listing claims must match behaviour: say "works offline" only for features that do; describe Word/PowerPoint fidelity honestly.

## 8. Security and privacy design

DocNook's strongest security property is structural: with no INTERNET permission, no document or metadata can leave the device except when the user explicitly shares it. The remaining risks are a lost or borrowed phone, malicious files, and leftovers in caches.

### 8.1 Threats and controls

| Threat | Control |
| --- | --- |
| Someone else uses the unlocked phone | Optional app lock (PIN + biometric), auto-lock after 0/1/5 minutes in background; `FLAG_SECURE` hides content in the recent-apps preview while locked |
| Sensitive files visible in the library | Private Vault with encryption at rest (8.2) |
| Screenshots or screen recording of vault files | `FLAG_SECURE` on vault, lock and PIN screens; optional "Block screenshots everywhere" setting |
| Malicious or malformed files (crash, hang, memory blow-up) | All parsing in isolates with per-job timeouts (60 s parse, configurable per tool); size limits from NFR-LIMIT-01; images decoded with max 8000 px edge (downsample above) |
| ZIP bombs and zip-slip (DOCX/XLSX/EPUB are ZIPs too) | Reject entry counts > 10k, compression ratio > 100:1, total uncompressed > limit; normalise entry paths and refuse `..` or absolute paths |
| XML entity attacks | Reject any XML containing `<!DOCTYPE`; never resolve external entities |
| Leftover decrypted or copied files | Temp files live in `cache/tmp/` and `cache/vault_tmp/`; deleted when the viewer closes and swept on every app start (anything older than 24 h for `tmp`, everything for `vault_tmp`) |
| Cloud/device backups exposing data | `allowBackup=false` and data-extraction rules exclude everything; users are told the vault does not survive uninstall |
| Other apps abusing DocNook | Only `MainActivity` is exported; FileProvider not exported, URI grants are per-share and read-only; incoming URIs are read through ContentResolver only |
| PDF passwords leaking | Never stored, never logged, cleared from memory when the viewer closes |
| Logs exposing file names or text | Release builds log only error codes, no paths or content |
| Supply-chain risk in packages | Lockfile committed; each new dependency reviewed for license, maintenance and manifest permissions; tool/check.sh verifies the merged manifest (no INTERNET) |

### 8.2 Vault cryptography

1. On vault setup, generate a random 256-bit **master key**.
2. Derive a **PIN key** from the user's vault PIN with Argon2id (salt 16 bytes; parameters tuned to \~300 ms on the reference device).
3. Store the master key encrypted twice-over: wrapped with the PIN key, and that blob stored via `flutter_secure_storage` (Android Keystore). Both are needed to unlock, so a copied app-data folder alone is useless.
4. Each vault file gets its own random 256-bit **file key**, wrapped with the master key and stored in `vault_items.wrapped_key`.
5. Files are encrypted with **AES-256-GCM in 1 MB chunks**, each chunk with its own nonce and the chunk index bound as associated data (prevents reordering), behind a small versioned header. Chunking lets large PDFs stream without loading fully into memory.
6. Biometric unlock releases a Keystore key that unwraps a copy of the master key; it never replaces the PIN.
7. **There is no PIN recovery.** Forgetting the PIN means the vault cannot be opened. The setup screen says this plainly and offers "Move files out" before any reset.

App-lock PIN (separate from vault PIN, or the same if the user chooses) is stored only as an Argon2id hash. Wrong attempts back off: 5 failures → 30 s wait, doubling each further failure.

### 8.3 Release hardening

- `flutter build --release --obfuscate --split-debug-info=build/symbols`; keep symbols privately for reading stack traces.
- Upload key stored outside the repo, with two offline backups; enrol in Play App Signing.
- `android:usesCleartextTraffic="false"` even though there is no network, as a second guard.

### 8.4 Privacy promise (store listing and in-app About)

"DocNook has no internet permission. Your documents never leave your phone unless you share them. No accounts, no ads, no tracking."

## 9. Design system

DocNook's look is **"paper and ink"**: warm paper surfaces, deep ink text, one harvest-gold accent, and the user's real documents as the main visual. It should feel like a well-made stationery folder, not a template.

### 9.1 Color tokens

| Token | Light | Dark | Use |
| --- | --- | --- | --- |
| `paper` (background) | #F7F5F0 | #141413 | App background |
| `surface` | #FFFFFF | #1D1C1A | Cards, sheets |
| `surfaceSunken` | #EFECE4 | #23221F | Search field, page grid backdrop |
| `ink` (text primary) | #1C1B19 | #ECE9E2 | Body and titles |
| `inkMuted` (text secondary) | #5F5B53 | #A8A398 | Metadata, captions |
| `hairline` | #E4E0D6 | #2E2C28 | 1 px borders, dividers |
| `primary` | #1F3A4D | #9CC0D3 | Primary buttons, selection, links |
| `onPrimary` | #FFFFFF | #0E1A22 | Text on primary |
| `accent` (harvest gold) | #B57A1F | #E0A84A | Star, progress, active tab marker, highlights — never body text on white |
| `danger` | #B3261E | #F2B8B5 | Delete, errors |
| `success` | #2E6B3F | #8FD1A0 | Completed jobs |

**File-type colors** are functional, slightly muted, and appear only as small marks (badge, spine stripe, icon tint) — never as large fills: PDF #C0392B, Word #2B5797, Sheet #217346, Slides #C4532A, Text #6B6B6B, Markdown #3D5A80, EPUB #6E4C9E, Image #1F7A7A, Archive #8A6D3B.

All text/background pairs must pass WCAG AA (4.5:1 body, 3:1 large text); verify with a contrast checker before locking.

### 9.2 Typography

All fonts are bundled, all SIL Open Font License.

| Style | Font | Size / line height | Weight | Use |
| --- | --- | --- | --- | --- |
| Screen title | Source Serif 4 | 28 / 34 | 600 | Large titles on Home, Files, Tools only |
| Section title | Inter | 17 / 24 | 600 | Section headers |
| Body | Inter | 15 / 22 | 400 | Default |
| Label | Inter | 13 / 18 | 500 | Buttons, chips, metadata |
| Caption | Inter | 12 / 16 | 400 | Sizes, dates, hints |
| Mono | JetBrains Mono | 13 / 20 | 400 | Code and text viewer |

The serif appears only in a few large titles; that one touch gives the "document" character without hurting readability.

### 9.3 Shape, space, elevation, motion

- 4-point spacing grid: 4, 8, 12, 16, 24, 32, 48. Screen side padding 16 dp.
- Corner radius: 8 (chips, small tiles), 12 (cards, fields), 20 (bottom sheets, top corners only).
- Separation by 1 px hairlines and surface tone, not shadows. Elevation only on the Scan button and bottom sheets.
- Motion: 180–220 ms ease-out for most transitions; hero transition from a file's thumbnail into its viewer; respect the system "remove animations" setting.
- Haptics: light tick on drag pick-up (reorder), success tick when a job finishes.
- Icons: **Phosphor** (MIT), Regular weight everywhere, Fill weight only for active states. One icon family, no mixing.

### 9.4 Signature elements

- **Type spine**: every file row has a 3 dp vertical stripe on its left edge in the file-type color, like the tab on a binder divider. Users learn to scan by color without reading extensions.
- **Real thumbnails**: grids and Recents show the actual first page (rendered and cached), not generic icons. Office files show their rendered first page once parsed; until then, a neutral paper tile with the type badge.
- **Stacked paper** for multi-file items (merge inputs, scan sessions): 2–3 slightly offset paper edges behind the thumbnail.
- **Plain, specific copy**: "Merged 3 files · 24 pages · 2.1 MB" — never "Awesome! Your magic PDF is ready ✨".

### 9.5 Rules that keep it from looking generic or AI-made

- No gradients, glassmorphism, neon or purple-blue "AI" palettes.
- No emoji, sparkle icons or mascots anywhere in the UI.
- No stock 3D illustrations. Empty states use three in-house line drawings (paper stack, open folder, scanner frame) in `inkMuted`.
- No carousels or banner "hero cards" on Home; content is the user's documents.
- No more than one accent-colored element per screen region.
- Every screen must work in both themes and at 200% font scale before it is considered done.
- Use a 1 px hairline instead of a card wherever a card adds no grouping meaning.

### 9.6 Component library (`lib/design_system/components/`)

`DocNookScaffold`, `LargeTitleAppBar`, `FileRow`, `FileTile` (grid), `TypeBadge`, `TypeSpine`, `ToolTile`, `SectionHeader`, `SearchField`, `FilterChips`, `SegmentedChoice`, `PrimaryButton`, `SecondaryButton`, `ActionSheet`, `JobProgressSheet`, `ResultSheet`, `ConfirmDialog`, `PermissionPrimer`, `EmptyState`, `ErrorState`, `PageThumbGrid` (draggable), `ViewerToolbar`, `PinPad`, `DocNookSnackBar`.

Build these first (Phase 1) with a hidden **component gallery** screen, so every later screen is assembled from consistent parts.

## 10. Screen-by-screen UI requirements

DocNook has three bottom tabs — **Home, Files, Tools** — plus a raised **Scan** button on Home and Files, a search field at the top of Home and Files, and Settings behind an icon on Home's app bar. Every screen must define its loading, empty and error states; those are listed per screen.

### 10.1 Navigation map

| From | To |
| --- | --- |
| Launcher | Home (or App lock first, if enabled) |
| "Open with" / "Share to" | The matching viewer directly; Back returns to the calling app |
| Home, Files | Search, any viewer, Scan, Settings (Home only) |
| Tools | Tool picker → Tool options → Progress → Result |
| Viewer overflow menu | Any tool, pre-filled with the current file |
| Result | Open, Share, or "Do more" → Tools with the output pre-filled |

### 10.2 First run

**S01 Onboarding** — two pages, skippable. Page 1: real thumbnails of a PDF, a sheet and a scan, title "Every document, one place", line "Read, scan, convert and combine — all on your phone." Page 2: privacy statement "No internet. No account. Your files stay on your phone." with a small "no internet permission" badge. Buttons: Continue / Skip. Shown once.

**S02 Find-my-documents primer** — a bottom sheet (not a full screen) explaining why storage access helps: "DocNook can list the documents already on your phone." Primary: "Allow access" (opens the right system flow per Android version). Secondary: "Choose folders instead" (SAF folder picker). Tertiary: "Not now". Re-openable from Files' empty state and Settings.

### 10.3 Main tabs

**S03 Home**

- App bar: large serif title "DocNook", Settings icon right.
- Search field (tap → S06).
- **Continue reading**: horizontal row of up to 6 recent documents with a progress bar; hidden if empty.
- **Quick actions** (4 fixed tiles, one row): Scan, Open file, Merge PDF, Convert. Not configurable in v1.
- **Recent** list (FileRow with type spine, name, "PDF · 24 pages · Yesterday"), 10 items, "See all" → Files filtered by Recent.
- **Recent activity** (only if jobs exist): last 3 finished jobs with their output, e.g. "Merged 3 files · 2.1 MB".
- Raised Scan button bottom-right.
- Empty state (new user, no permission): paper-stack drawing, "Open a file or scan a page to get started", buttons "Open file" and "Find my documents".

**S04 Files (Library)**

- Large title "Files"; search field; filter chips: All, PDF, Word, Sheets, Slides, Images, Text, E-books, Archives, Starred.
- Segmented control: **Documents | Collections | Folders**. Documents = flat indexed list; Collections = user virtual folders; Folders = DocNook folder plus granted SAF folders.
- Sort menu: Recent, Name, Date modified, Size, Type. List/grid toggle.
- Long-press → multi-select mode: bottom bar with Share, Star, Add to collection, Merge (if PDFs/images), Convert, Delete.
- Row tap opens viewer; row overflow → S27 action sheet.
- Pull to refresh re-scans changes.
- States: indexing banner "Finding documents… 1,240 found" (non-blocking); empty filter "No Word files yet"; permission-missing card linking to S02.

**S05 Collection detail** — title, item count, same list behaviour as S04, "Add files" button, rename/delete collection in overflow.

**S06 Search** — autofocus field; results grouped "Names" and "Inside documents"; content hits show the file, page number and a two-line snippet with the match in bold; tap opens the viewer at that page with the term highlighted. Recent searches (last 8, clearable). Empty: "No matches for 'invoice'" plus a hint that unindexed files are only searched by name.

**S07 Tools hub** — large title "Tools"; three groups, each a 2-column grid of ToolTiles (icon, name, one-line description):

- **PDF**: Merge, Split, Organize pages, Compress, Protect, Unlock, Watermark, Page numbers, Sign, Annotate, Fill forms, Redact.
- **Convert**: Images to PDF, PDF to images, Word to PDF, Excel to PDF, PowerPoint to PDF, PDF to Word, PDF to text, Text to PDF, CSV ↔ Excel.
- **Scan**: Scan document, Scan ID card, Scan book, Scan with text (OCR), Extract text from image.

### 10.4 Tool flow (shared template for all tools)

**S08 Select files** — in-app picker showing DocNook's indexed files filtered to valid inputs, plus "Browse device" (system picker). Multi-select where the tool allows; selected count in the bottom button ("Continue with 3 files").

**S09 Tool options** — one screen per tool built from a shared template: inputs summary at the top (reorderable list for Merge), then options as simple controls, the **fidelity label** and one-line limit (for converters), and an output name field pre-filled. Primary button names the action ("Merge 3 files").

**S10 Job progress** — bottom sheet: determinate progress bar, step label ("Rendering page 12 of 40"), Cancel. The user can dismiss it; the job continues and shows as a small progress chip on the Tools tab.

**S11 Result** — bottom sheet: output thumbnail, name, "24 pages · 2.1 MB", saved location; actions Open, Share, Rename, Show in folder, Do more. For Compress: "4.8 MB → 1.3 MB (−73%)". Partial failures in batches list which files failed and why.

### 10.5 Viewers

All viewers share a **ViewerToolbar**: Back, file name (tap → S26 info), Search, overflow (Share, Open with, Print, Star, Add to collection, tool shortcuts relevant to the type, Info). The toolbar hides on scroll down and on single tap; reappears on tap or scroll up.

**S35 Read Aloud bar** — opened from the viewer overflow in PDF, Word, text, markdown and EPUB viewers: a slim bottom bar with Play/Pause, previous/next sentence, speed (0.75×–2×) and Close; the current sentence is highlighted and the view follows it. If no offline voice is installed, a sheet explains how to add one in Android's text-to-speech settings.

**S12 PDF viewer** — vertical continuous scroll (default) or single-page horizontal; page indicator "12 / 48" with draggable fast-scroll thumb; bottom bar: Thumbnails, Outline, Bookmarks, Night mode, Annotate. Double-tap to zoom; long-press to select text with Copy/Highlight/Share. Password prompt dialog for encrypted files. Search shows hit count and next/previous.

**S13 Organize pages** — grid of page thumbnails (3 columns phone): drag to reorder, tap to select, bottom bar Rotate, Delete, Duplicate, Extract, Insert (blank page or image). Save as copy (default) or overwrite.

**S14 Annotate and sign** — tool palette at bottom: Highlight, Underline, Strike, Pen (3 widths, 6 colors), Text note, Signature, Eraser, Undo/Redo. Signature: pick a saved one or "New signature" (full-screen landscape draw pad, Clear / Save). Placed items can be moved and resized until saved. Save writes a copy by default.

**S33 Fill forms** — form fields get a subtle highlight; tap a field to edit (keyboard for text, toggles for checkboxes and radios, a picker for dropdowns); Next/Previous field buttons above the keyboard. Save options: "Save copy (still editable)" or "Save flattened copy". A PDF with no form fields shows "This PDF has no fillable fields" with a link to Annotate instead.

**S34 Redact** — drag boxes over areas, or long-press text to redact the selection; a list of marked areas per page with undo. Before saving, a confirm dialog explains: "Marked content will be permanently removed. Text on redacted pages is rebuilt using OCR." Always saves a new copy.

**S15 Word viewer** — reflowed paginated-feel scroll with page-break separators, pinch to change text size (reflow, not image zoom), outline from headings, search. Banner on first open of complex files: "Simplified layout — some formatting may differ from Word."

**S16 Sheet viewer** — frozen row numbers and column letters; sheet tabs at bottom; tap a cell → bottom panel with full value, formula (read-only) and format; search jumps cell to cell; "Fit width" toggle.

**S17 Slides viewer** — one slide per screen, swipe to change, slide counter, thumbnail strip, toggle to Outline mode (titles and bullet text), banner about simplified rendering.

**S18 Text and code viewer** — monospace, line numbers toggle, wrap toggle, syntax highlight by extension, font size, streaming for large logs with "Jump to end".

**S19 Markdown viewer** — rendered by default, Raw toggle in app bar.

**S20 EPUB reader** — chapter list, font size, line spacing, themes (Paper, White, Night), progress per chapter, tap-zones for next/previous.

**S21 Image viewer** — pinch zoom, swipe through images in the same folder, Rotate, "Make PDF", "Extract text".

**S22 Archive browser** — folder tree of the ZIP with sizes; tap a supported file to open it directly; select → Extract to DocNook folder.

### 10.6 Scan

**S23 Capture** — launches the ML Kit scanner (gallery import enabled, page limit 50). A mode switch above the shutter picks Document, ID card (prompts for front, then back) or Book. On devices without it, DocNook's fallback camera screen: live preview, shutter, flash toggle, batch counter thumbnail, Done.

**S24 Review and edit** — horizontal pager of pages with a filmstrip below; per page: Crop (4-corner handles with magnifier), Rotate, Filter (Original, Document, Grayscale, Enhanced), Retake, Delete; filmstrip long-press to reorder; "Add page".

**S25 Export** — name field ("Scan 2026-11-11 14.32"), format PDF / JPG, page size (A4, Letter, Fit), quality (Small, Balanced, Best, with estimated size), OCR toggle "Make text searchable", collection picker; Save → S11.

### 10.7 Sheets, vault, settings

**S26 Document info** — bottom sheet: thumbnail, name, type, size, pages, created/modified, location path, collections, "Indexed for search: yes/no".

**S27 File action sheet** — Open with, Share, Rename, Duplicate, Star, Add to collection, Move to Vault, relevant tools (e.g., "Convert to PDF" for DOCX), Info, Delete (confirm dialog; uses system trash on Android 11+ where available).

**S28 Vault** — entered from Files (Folders segment) and Settings; PIN pad + biometric prompt; list of vault files with same FileRow (no thumbnails cached outside the vault); actions Open, Move out, Delete permanently. First-time setup explains the no-recovery rule and asks for PIN twice.

**S29 App lock** — full-screen PIN pad over a blurred-out paper background; biometric auto-prompt.

**S30 Settings** — grouped list: *Appearance* (Theme), *Reading* (PDF scroll mode, keep screen on, night-mode default), *Output* (default quality, save location, file naming), *Library* (Find my documents, folders, rebuild index, show hidden files), *Privacy & security* (App lock, Vault, Block screenshots), *Storage* (cache size + Clear), *About* (version, privacy promise, open-source licenses, rate app — Play flavor only, send feedback via email intent).

**S31 About & licenses** — version, build flavor, privacy statement, Flutter `LicensePage`.

**S32 Can't open this file** — shared error screen: plain reason ("This file is password-protected", "This looks damaged", "Old .doc files can only be previewed as text"), and actions: Try text preview, Open with another app, Share, Back.

## 11. Step-by-step implementation plan

Claude Code writes all the code in ten phases; you install each phase's build on your phone, test it against its "Done when" list, and report what you see. Never start a phase until the previous phase's "Done when" passes on the reference device. Phase 0 kills risky assumptions before any polished UI is built.

### Phase 0 — Setup and technical spikes (1.5 weeks)

- [x] Create Flutter project, package id `app.docnook.reader`, `play` and `direct` flavors, signing configs (debug + release upload key). Local git repo.
- [x] Lints (`very_good_analysis`), folder skeleton from 5.1, `tool/check.sh` (format, analyze, test, **merged-manifest check for INTERNET**).
- [ ] Spike A: open a 500-page PDF and a password PDF with pdfrx; measure first-page time.
- [ ] Spike B: through PDFium FFI, merge two PDFs, add a highlight annotation, a text watermark and an image (signature); open the result in Chrome and Adobe Reader.
- [ ] Spike C: ML Kit document scanner returns pages on the reference phone; fallback camera + crop works on an emulator without Play services; Tesseract English OCR works there too.
- [x] Spike D: parse a real 30-page DOCX into a throwaway DocModel and render paragraphs + one table.
- [x] Spike E: stream-parse a 50k-cell XLSX in an isolate under 3 s.
- [x] Spike F: Dart security writer encrypts a PDFium-saved PDF with AES-256; Chrome and Adobe Reader ask for the password and open it correctly.
- [ ] Spike G: fill one text field and one checkbox in an AcroForm PDF via PDFium and save; values show in Chrome.

**Done when:** all seven spikes pass, or an alternative is chosen and recorded in `docs/decisions.md` (never one that needs an account or key).

### Phase 1 — Foundations (2 weeks)

- [ ] Design tokens, typography, light/dark themes, all components from 9.6, hidden component gallery route.
- [x] English ARB strings setup.
- [x] `go_router` with the three-tab shell and placeholder screens.
- [x] Drift database with all v1 tables, DAOs, migration test harness.
- [ ] `FileRef`, `FileTypeDetector` (with tests on a fixture of renamed files), `Result`/`DocNookFailure`.
- [x] Kotlin `DocNookChannels`: VIEW/SEND intents → Dart stream; MediaStore save; SAF tree grant; launcher shortcuts.
- [ ] `JobRunner` with worker pool, progress, cancel, persistence in `jobs`.
- [x] `SettingsRepository`, thumbnail cache service.

**Done when:** gallery renders every component in both themes at 200% font scale; sharing a file to DocNook delivers it to a debug screen; a dummy 10 s job shows progress and cancels.

### Phase 2 — PDF viewer and "Open with" (2 weeks)

- [x] S12 PDF viewer: scroll modes, zoom, page jump, thumbnails, outline, search, text selection, night mode, bookmarks.
- [x] Password dialog; S32 error screen for every failure type.
- [x] Resume position (`reading_state`); documents row created on every open.
- [x] Home (S03) with Recents and Continue reading; S01 onboarding.

**Done when:** opening any PDF from WhatsApp/Files app lands in the viewer in < 1 s for a 10 MB file, and reopening restores the page.

### Phase 3 — Library and search (2 weeks)

- [x] S02 primer; permission flows per Android version; SAF folder grants.
- [x] Discovery scanner as a job: walks storage (or granted trees), skips `Android/`, hidden folders and caches, upserts `documents`, marks missing files.
- [x] S04 Files with filters, sort, list/grid, multi-select; S05 collections; S27 action sheet; S26 info.
- [x] Text indexing jobs (PDF text layer first) into `doc_search`; S06 search with snippets and jump-to-page.

**Done when:** a phone with 1,000+ documents finishes first discovery in < 60 s without UI jank, and searching a word inside an indexed PDF opens it on the right page.

### Phase 4 — Office and other viewers (5 weeks)

- [x] DocModel (domain) and DocModel → Flutter renderer.
- [x] DOCX parser: styles, runs, numbering/lists, tables (merged cells), images, headers/footers, page breaks; S15 Word viewer.
- [x] SheetModel, streaming XLSX parser (shared strings, styles, number formats, merges, column widths); CSV/TSV parser; S16 grid viewer.
- [x] PPTX parser (slide size, text frames, pictures, basic shapes) → S17 with outline mode.
- [x] ODT/ODS mapping; RTF tokenizer; legacy .doc/.xls/.ppt text reader (OLE compound files).
- [x] S18 text/code (streaming), S19 markdown, S20 EPUB, S21 image, S22 ZIP browser.
- [x] Indexing extended to DOCX, text, markdown, EPUB, RTF and legacy text.

**Done when:** at least 90% of the Office fixture corpus (section 12) opens without error and passes visual review; no viewer janks while scrolling on the reference device.

### Phase 5 — Scan and OCR (2.5 weeks)

- [x] S23 capture via ML Kit; fallback camera with Dart edge detection and manual crop (`copyRectify`).
- [x] S24 review/edit: crop, rotate, filters (isolate), reorder, retake, add page; drafts saved in `scan_sessions`/`scan_pages`.
- [x] Modes: Document, ID card, Book.
- [x] S25 export to PDF/JPG with size presets.
- [x] OCR (ML Kit; Tesseract on the no-Google path); searchable PDF via invisible text layer from OCR line boxes; text stored in `doc_search`.

**Done when:** a 10-page scan with OCR exports in < 20 s, its text is selectable in Chrome, an ID card prints at real size, and killing the app mid-session restores the draft.

### Phase 6 — PDF tools (4 weeks)

- [ ] Shared tool flow: S07 hub, S08 select, S09 options template, S10 progress, S11 result, "Do more" chaining.
- [ ] Merge (PDFs + images), Split, S13 Organize pages.
- [ ] Compress (Light, Balanced, Strong), Watermark, Page numbers.
- [ ] Protect (Dart security writer) and Unlock (PDFium save without security).
- [ ] S14 Annotate and Sign; saved signatures.
- [ ] S33 Fill forms; S34 Redact.

**Done when:** every tool's output opens correctly in Adobe Acrobat Reader and Chrome; redacted text cannot be found by search or copy; originals are never modified unless overwrite was chosen.

### Phase 7 — Convert (2.5 weeks)

- [ ] Images → PDF, PDF → images, PDF → text (OCR fallback).
- [ ] DocModel → `pdf` renderer: DOCX/ODT/RTF → PDF, text/markdown → PDF, with system-font fallback for non-Latin text.
- [ ] SheetModel → PDF with fit-to-width and page breaks; PPTX → PDF (one slide per page).
- [ ] PDF → DocModel (text runs grouped into lines/paragraphs by position, headings by font size) → DOCX writer.
- [ ] CSV ↔ XLSX; batch mode for the converters listed in 2.3.

**Done when:** converted fixtures pass side-by-side visual review at their stated fidelity level; a batch of 20 images → PDF completes without memory warnings.

### Phase 8 — Vault, app lock, Read Aloud, settings (2 weeks)

- [ ] Crypto service (8.2) with unit tests, including tamper and wrong-key tests.
- [ ] S28 vault, S29 app lock, `FLAG_SECURE` handling, auto-lock timer.
- [ ] Read Aloud bar (S35) in PDF, Word, text, markdown and EPUB viewers.
- [ ] S30 settings complete; S31 about/licenses; cache clearing; temp-file sweeper.

**Done when:** a vault PDF is unreadable when the app's files are copied off a rooted test emulator and opens normally in-app after PIN; Read Aloud reads a PDF page in airplane mode.

### Phase 9 — Hardening and release (2 weeks, then 14-day closed test)

- [ ] Performance pass against every NFR on the reference device; fix the top regressions.
- [ ] Accessibility pass (TalkBack walkthrough of every screen), both themes, 200% text.
- [ ] Malformed-file corpus run: no crashes, every failure lands on S32.
- [ ] Store listing (section 12.4), privacy policy page, Data safety form, All-files declaration.
- [ ] Closed test with ≥ 12 testers for 14 days; fix reported issues; then production + `direct` APK release.

**Done when:** crash-free sessions ≥ 99.5% in the closed test and no open P0/P1 bugs.

## 12. Testing, release and distribution

Quality in a document app depends on the variety of real files it has been tested against, so the fixture corpus is as important as the code. Performance targets are the NFRs in section 3.2. The only online account needed anywhere is the Google account you use for Play Console.

### 12.1 Test strategy

| Level | What | Target |
| --- | --- | --- |
| Unit | Parsers, DocModel/SheetModel, FileTypeDetector, crypto, PDF security writer, DAOs, JobRunner | ≥ 80% line coverage in `engines/` and `domain/` |
| Widget | Design-system components, tool option screens, error states | Every component; every S-screen's empty/error state |
| Golden | Components and 8 key screens in light/dark and 1.0/2.0 text scale | Run by `tool/check.sh` |
| Integration | Open-from-intent, merge flow, scan (mocked scanner), vault round-trip, migration upgrade | Run before each release |
| Corpus run | Open and convert every fixture headlessly; record time, memory, pass/fail | Before each phase gate and release |
| Manual (you) | Device walkthrough using the phase's "Done when" list | Every phase |

### 12.2 Fixture corpus (`test/fixtures/`)

About 150 files, all generated by Claude or openly licensed — **never personal or client documents**:

- **PDF**: 1-page, 500-page, password (user/owner), scanned without text, with forms, with outline, non-Latin text, corrupted header, truncated file.
- **DOCX**: as saved by MS Word, Google Docs, LibreOffice and WPS (you can create these once on any computer or phone); tables, merged cells, numbered lists, images, headers/footers, track changes present.
- **XLSX/CSV**: formulas, dates/currency formats, merged cells, multiple sheets, 50k and 1M cells, UTF-8 and ANSI CSVs.
- **PPTX, ODT, ODS, RTF, DOC, XLS, PPT, EPUB, MD, JSON, large log (100 MB)**.
- **Hostile**: zip bomb (synthetic, small), zip-slip entry, DOCTYPE XML, 20,000 × 20,000 px PNG, renamed files with wrong extensions.

### 12.3 Device matrix

| Device | Why |
| --- | --- |
| Reference low-end phone, Android 11, 3 GB RAM (Galaxy A12 / Redmi 9 class) | All performance targets measured here |
| Mid-range phone, Android 14 | Typical user |
| Emulator, latest Android | Newest permission and back-gesture behaviour |
| Emulator, Android 7.0 | minSdk 24 |
| Emulator without Google Play services (AOSP image) | Fallback scanner, Tesseract OCR and `direct` APK path |

### 12.4 Google Play release

- Build: `flutter build appbundle --flavor play --release --obfuscate --split-debug-info=build/symbols`.
- Play App Signing on; keep the upload key and two offline backups (USB drive + another computer).
- Listing: title **DocNook: PDF Reader & Scanner**; short description "PDF, Word & Excel reader with scanner, converter and PDF tools. Works offline."; category Productivity; 8 screenshots of real use (light and dark), 1024 × 500 feature graphic, no fake reviews or "#1" claims. Use the long description to name every format and tool once, in plain words (this is what Play search indexes).
- Content rating questionnaire, Data safety ("no data collected"), privacy policy URL, All-files declaration (if used).
- Privacy policy: a one-page **Google Sites** page made with the same Google account as Play Console — free, no new signup.
- Tracks: internal → closed (≥ 12 testers, 14 days; friends and family with Gmail accounts are enough) → production with staged rollout 20% → 50% → 100%.

### 12.5 Direct APK release

- Build: `flutter build apk --flavor direct --release --split-per-abi --obfuscate --split-debug-info=build/symbols-direct`, plus one universal APK.
- Share the arm64-v8a APK (works on almost all current phones) and the universal APK through a **Google Drive** folder link from the same Google account, or send them directly; publish the SHA-256 checksum next to each file.
- With no internet permission there is no in-app update check. The About screen shows the version and where to get new builds.

### 12.6 Versioning

Semantic version `1.0.0+1`; build number increases on every upload. Changelog kept in `CHANGELOG.md` and reused as Play release notes.

## 13. Budget and timeline

DocNook v1.0 needs about **US$25 in mandatory cash** (the Play Console fee) plus a test phone and your Claude plan, and about **28 calendar weeks** with Claude Code writing the code and you testing each phase, including Play's 14-day closed test. Everything else is free and needs no signup.

### 13.1 Cash budget (self-funded)

| Item | Cost | Notes |
| --- | --- | --- |
| Google Play Console registration | US$25 one-time | The only new account; personal account with identity verification |
| Reference test phone (used, 3 GB RAM, Android 11) | \~US$80–120 (approx.) | Skip if you already own a similar low-end phone |
| Claude plan for Claude Code | Your plan | Claude Code does all coding, so expect heavy use; check claude.com/pricing for the plan that fits |
| Flutter, Android Studio, git, all packages, fonts, icons | US$0 | Open source; no accounts or keys |
| Privacy-policy page, APK hosting | US$0 | Google Sites and Google Drive on the same Google account |
| **Total cash to launch** | **\~US$25 + phone** | Local-currency amounts depend on the current exchange rate |

### 13.2 Your role and schedule

You are the product owner and tester, not the programmer: about 8–12 hours a week to install builds, test the phase checklist on your phone, report problems to Claude Code in plain words, and approve the next phase. The schedule below assumes that pace; faster testing shortens it.

&#91;embedded content: Sheaf v1.0 roadmap · 10 phases, closed test, launch\]

Phase 4 (Office viewers) and Phase 6 (PDF tools, including the encryption writer) are the longest and riskiest phases; their spikes in Phase 0 exist so problems surface in week 1, not week 15.

### 13.3 Future monetization (if traffic grows)

The app launches free and offline. If usage grows and you decide to earn from it, two routes exist: a **one-time "Supporter" unlock** through Google Play Billing (keeps the no-internet promise), or **ads** (needs the INTERNET permission, an ad-network account, and a Data safety update). To keep that door open at no cost today: the store listing says "No ads" and "no internet permission" only in the current-version description (easy to change later), and the code keeps one empty `features/monetization/` seam so ads or billing can be added without restructuring.

## 14. Handover to Claude Code

All open questions are now decided (14.1). To start: set up your computer once (14.2), export this doc as Markdown into the project as `docs/BLUEPRINT.md`, save the `CLAUDE.md` from 14.3 at the project root, and paste the starter prompt from 14.4 into Claude Code.

### 14.1 Final decisions

| Topic | Decision |
| --- | --- |
| Name | **DocNook** — store title "DocNook: PDF Reader & Scanner", package `app.docnook.reader` |
| Language | English only — no Urdu UI, no Urdu OCR |
| Who codes | Claude Code writes all code; you test and approve each phase |
| Accounts and signups | None, except the Google Play Console account needed to publish. No Syncfusion, no GitHub, no API keys |
| Phones without Google services | Fully supported in the direct APK (fallback scanner + Tesseract English OCR) |
| Release scope | Every feature, including Vault, ships in v1.0 |
| Monetization | None at launch; ads or a supporter unlock may be added later if traffic grows (13.3) |
| Oldest Android | Android 7.0 (minSdk 24) |

### 14.2 One-time computer setup (about 2 hours)

1. Install **Git** from git-scm.com.
2. Install **Android Studio** from developer.android.com/studio; in its SDK Manager install the latest Android SDK, Platform-Tools and Command-line Tools; accept the licenses.
3. Install the **Flutter SDK** (stable) following docs.flutter.dev → Get started → Android; run `flutter doctor` until it shows no errors.
4. Install **Claude Code** following the official guide at docs.claude.com (Claude Code section) and sign in with your existing Claude account.
5. On your phone: Settings → About phone → tap *Build number* 7 times → Developer options → turn on **USB debugging**; connect by USB and run `flutter devices` to see it listed.
6. Create an empty folder named `docnook`, open a terminal in it, and run `git init`.
7. Export this doc as Markdown, save it as `docnook/docs/BLUEPRINT.md`, and save 14.3 as `docnook/CLAUDE.md`.

### 14.3 CLAUDE.md (save at the project root)

```markdown
# DocNook — offline document suite for Android (Flutter)

Full spec: docs/BLUEPRINT.md. Decisions log: docs/decisions.md. Read both before any task.

## About the human
The project owner is not a programmer. You (Claude Code) write all code, run all
commands, and fix all errors. Explain results in plain English, give exact steps for
anything the owner must do on the phone, and never ask them to edit code by hand.

## Non-negotiable rules
1. The app must never request INTERNET or ACCESS_NETWORK_STATE. tool/check.sh verifies
   the merged release manifest.
2. No component may require an account, registration, license key or API key
   (no Syncfusion, no cloud services). Open-source packages only.
3. Before adding a package, check pub.dev for: latest stable version, license, last
   publish date, Android support, and permissions in its manifest. Record it in
   docs/decisions.md with the reason.
4. Work that can exceed ~100 ms (parsing, rendering, converting, OCR, indexing) runs
   through JobRunner in an isolate. Never on the UI thread.
5. No business logic in widgets. Screen -> Riverpod controller -> use case -> repository.
6. domain/ is pure Dart: no Flutter, no plugin imports.
7. UI uses design_system tokens and components only: no raw colors, sizes or paddings.
8. English only, but every user-facing string lives in the ARB file.
9. Every screen implements loading, empty and error states.
10. Tools never modify the original file unless the user picked "overwrite".
11. Never log file paths, file contents or passwords in release builds.
12. Fixtures are generated or openly licensed; never real personal documents.
13. Keep features/monetization/ as an empty seam; add no ads or billing code.

## Workflow
- Work one phase at a time in the order of BLUEPRINT section 11. Do not start the next
  phase until the owner confirms the current phase's "Done when" on their phone.
- For each task: (1) state the requirement IDs it covers, (2) give a short plan and the
  files you will touch, (3) implement in small git commits citing IDs
  (e.g. "feat(pdf): resume position [FR-READ-03]"), (4) add tests, (5) run tool/check.sh.
- End each phase by installing the build on the connected phone
  (flutter run --flavor direct --release) and giving the owner a numbered test checklist.
- If a package or approach fails a spike, stop, explain in plain English, propose an
  alternative that follows rule 2, and log it.
- Ask the owner before: adding a permission, changing a shipped database schema,
  changing design tokens, or cutting scope.
- Update the checkboxes in BLUEPRINT section 11 as tasks finish.

## Commands
- Run on phone:  flutter run --flavor direct
- Codegen:       dart run build_runner build --delete-conflicting-outputs
- All checks:    ./tool/check.sh
- Release:       see BLUEPRINT sections 12.4 and 12.5

## Definition of done (every task)
- Meets its requirement IDs; works in airplane mode.
- Light + dark theme, 200% font scale, TalkBack labels.
- Tests added and passing; tool/check.sh clean.
- No jank on the reference device for scrolling screens.
```

### 14.4 Starter prompt for Claude Code

> Read `CLAUDE.md` and `docs/BLUEPRINT.md` completely. We are starting **Phase 0**. First show me, in plain English, the Phase 0 tasks, the packages you will add (after checking pub.dev for each) and the project structure you will create. Wait for my "go". Then set up the project, flavors and `tool/check.sh`, and run Spikes A–G one at a time on my connected phone, telling me after each spike what passed, what failed and what you recommend.

### 14.5 Working rhythm for each phase

1. Tell Claude Code: "Start Phase N." Approve its plan.
2. Let it build, test and commit; answer its questions.
3. When it gives you the test checklist, go through it on your phone and reply with what worked and what didn't, in your own words (screenshots help).
4. When every "Done when" item passes, say "Phase N approved" and start the next one.
5. Every few phases, export this doc again if you changed it, so `docs/BLUEPRINT.md` stays current.
