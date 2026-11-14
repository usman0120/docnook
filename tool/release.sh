#!/usr/bin/env bash
# Builds every release file (BLUEPRINT 12.4, 12.5) into release/<version>/:
#   - DocNook-<v>-play.aab              upload to Play Console
#   - DocNook-<v>-arm64-v8a.apk         direct download for almost all phones
#   - DocNook-<v>-universal.apk         direct download for any phone
#   - SHA256SUMS.txt                    publish next to the APKs
#   - symbols-<v>.zip                   keep privately: decodes crash reports
# Usage: ./tool/release.sh            (refuses placeholders and a debug key)
#        ./tool/release.sh --draft    (allows both; for an internal test only)
set -euo pipefail
cd "$(dirname "$0")/.."

DRAFT=0
[[ "${1:-}" == "--draft" ]] && DRAFT=1
fail() { echo "STOP: $*"; exit 1; }

VERSION=$(sed -n 's/^version: *\([^ ]*\).*/\1/p' pubspec.yaml)
NAME=${VERSION%%+*}
OUT="release/$VERSION"

# --------------------------------------------------------- preconditions
if [[ ! -f android/key.properties ]]; then
  [[ $DRAFT -eq 1 ]] || fail "no upload key. Run ./tool/make_upload_key.sh first."
  echo "warning: no upload key, signing with the debug key (draft only)"
fi
if grep -q "publisherName = '\[" lib/app/version.dart \
   || grep -q "supportEmail = ''" lib/app/version.dart; then
  [[ $DRAFT -eq 1 ]] || fail "publisher name or support email is still a placeholder in lib/app/version.dart."
  echo "warning: legal pages still show placeholders (draft only)"
fi

[[ "${OS:-}" == "Windows_NT" && -z "${JAVA_HOME:-}" ]] \
  && export JAVA_HOME="/c/Program Files/Android/Android Studio/jbr"

./tool/check.sh
python tool/make_legal_pages.py

# ---------------------------------------------------------------- builds
rm -rf "$OUT" && mkdir -p "$OUT"
flutter build appbundle --flavor play --release \
  --obfuscate --split-debug-info=build/symbols/play
flutter build apk --flavor direct --release --split-per-abi \
  --target-platform android-arm64,android-arm \
  --obfuscate --split-debug-info=build/symbols/direct
cp build/app/outputs/flutter-apk/app-arm64-v8a-direct-release.apk \
  "$OUT/DocNook-$NAME-arm64-v8a.apk"
flutter build apk --flavor direct --release \
  --obfuscate --split-debug-info=build/symbols/direct
cp build/app/outputs/flutter-apk/app-direct-release.apk \
  "$OUT/DocNook-$NAME-universal.apk"
cp build/app/outputs/bundle/playRelease/app-play-release.aab \
  "$OUT/DocNook-$NAME-play.aab"

# ------------------------------------------------- size budget, checksums
size_mb() { echo $(( $(wc -c < "$1") / 1024 / 1024 )); }
ARM=$(size_mb "$OUT/DocNook-$NAME-arm64-v8a.apk")
UNI=$(size_mb "$OUT/DocNook-$NAME-universal.apk")
echo "arm64-v8a APK: ${ARM} MB (limit 35), universal APK: ${UNI} MB (limit 80)"
(( ARM <= 35 && UNI <= 80 )) || fail "APK size over NFR-SIZE-01."

(cd "$OUT" && sha256sum DocNook-*.apk DocNook-*.aab > SHA256SUMS.txt)
(cd build/symbols && python -c "import shutil,sys; shutil.make_archive(sys.argv[1], 'zip', '.')" \
  "../../$OUT/symbols-$NAME")

echo
echo "Release files are in $OUT:"
ls -la "$OUT"
