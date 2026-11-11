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
