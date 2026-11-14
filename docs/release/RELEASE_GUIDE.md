# DocNook release guide (for the owner)

Plain steps for Phase 9. Claude Code runs the commands; the steps marked
**You** need your own accounts, passwords or phone.

## 1. One-time preparation

1. **You:** tell Claude Code the publisher name (your name or company) and the
   support email for the privacy policy, terms and store listing. Claude
   puts them in `lib/app/version.dart` and regenerates the web pages.
2. **You:** create the upload key. In the Terminal panel run:

   ```bash
   ./tool/make_upload_key.sh
   ```

   Type a password you will not forget (twice), your name and country.
   Then copy `android/upload-keystore.jks` and `android/key.properties` to a
   USB drive and to another computer. Never email or upload them.
3. **You:** make the privacy policy page. In Google Sites (same Google account
   as Play Console) create a site named "DocNook privacy", paste the text of
   `docs/release/privacy_policy.html` (open it in a browser and copy), and
   publish. Copy the page address. Do the same for `terms.html` if you like.

## 2. Build the release files

Ask Claude Code: "Build the release". It runs `./tool/release.sh`, which runs
every check and then writes into `release/<version>/`:

| File | What it is for |
| --- | --- |
| `DocNook-1.0.0-play.aab` | Upload to Play Console |
| `DocNook-1.0.0-arm64-v8a.apk` | Direct download, almost all phones |
| `DocNook-1.0.0-universal.apk` | Direct download, any phone |
| `SHA256SUMS.txt` | Put next to the APKs so people can check them |
| `symbols-1.0.0.zip` | Keep privately; needed to read crash reports |

## 3. Play Console (you)

1. Create app → name "DocNook: PDF Reader & Scanner", App, Free.
2. Fill the store listing from `docs/release/store_listing.md` and upload
   `graphics/icon_512.png`, `graphics/feature_graphic.png` and 8 screenshots.
3. Answer every App content form with `docs/release/play_console_forms.md`.
4. Testing → Internal testing → create a release → upload the `.aab` →
   accept **Play App Signing** → roll out. Install it from the internal link
   on your phone and open a few files.
5. Testing → Closed testing → create a track, add at least **12 testers**
   (Gmail addresses of friends and family) → upload the same `.aab` → roll
   out. Each tester must accept the invite link and **keep the app installed
   for 14 days**. Ask them to open a few of their documents each day.
6. While the test runs, send Claude Code any problem testers report (what
   they did, what happened, a screenshot). Each fix becomes a new build with
   a higher build number (`1.0.0+2`, `+3`, …).
7. After 14 days: Play Console → Quality → Android vitals. Crash-free
   sessions must be at least 99.5% and no serious bug may be open.
8. Apply for production access when Play offers it, then release to
   production with a staged rollout: 20% → 50% → 100% a few days apart.

## 4. Direct APK (you)

1. Create a Google Drive folder "DocNook", upload the two APKs and
   `SHA256SUMS.txt`, and share it as "Anyone with the link: Viewer".
2. On a phone, installing needs "Install unknown apps" allowed for the browser
   or Files app; Android asks the first time.

## 5. Every later update

1. Tell Claude Code what changed; it raises the version in `pubspec.yaml`
   and `lib/app/version.dart` and adds a `CHANGELOG.md` entry.
2. "Build the release", then upload the new `.aab` and APKs as above.
