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
