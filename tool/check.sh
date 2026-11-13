#!/usr/bin/env bash
# DocNook local checks: format, analyze, tests, and the offline guarantee.
# Usage: ./tool/check.sh            run everything
#        ./tool/check.sh --fast     skip the merged-manifest check (no Gradle)
set -euo pipefail

cd "$(dirname "$0")/.."

FAST=0
[[ "${1:-}" == "--fast" ]] && FAST=1

step() { printf '\n== %s ==\n' "$1"; }

step "Format"
dart format --output=none --set-exit-if-changed lib test tool integration_test 2>/dev/null \
  || dart format --output=none --set-exit-if-changed lib test

step "Analyze"
flutter analyze --no-pub

step "Tests"
flutter test --no-pub

if [[ $FAST -eq 1 ]]; then
  printf '\nSkipped merged-manifest check (--fast).\n'
  exit 0
fi

# NFR-PRIV-01 / CLAUDE.md rule 1: the merged release manifest of every flavor
# must not contain INTERNET or ACCESS_NETWORK_STATE, whatever plugins merge in.
step "Merged manifest: no network permissions"
GRADLEW=./gradlew
[[ "${OS:-}" == "Windows_NT" ]] && GRADLEW=./gradlew.bat
# Use the JDK Flutter builds with; a newer system JDK can be too new for
# Gradle ("What went wrong: 27").
FLUTTER_JAVA=$(flutter doctor -v 2>/dev/null | sed -n 's/.*Java binary at: \(.*\)[\/]bin[\/]java.*/\1/p' | head -n 1)
[[ -n "$FLUTTER_JAVA" ]] && export JAVA_HOME="$FLUTTER_JAVA"
(cd android && "$GRADLEW" -q :app:processPlayReleaseManifest :app:processDirectReleaseManifest)

FAILED=0
for flavor in playRelease directRelease; do
  manifest=$(find build/app/intermediates/merged_manifests/"$flavor" -name AndroidManifest.xml 2>/dev/null | head -n 1)
  if [[ -z "$manifest" ]]; then
    manifest=$(find build/app/intermediates -path "*${flavor}*" -name AndroidManifest.xml 2>/dev/null | grep -i merged | head -n 1 || true)
  fi
  if [[ -z "$manifest" ]]; then
    echo "FAIL: merged manifest for $flavor not found"
    FAILED=1
    continue
  fi
  if grep -E 'uses-permission[^>]*android\.permission\.(INTERNET|ACCESS_NETWORK_STATE)"' "$manifest"; then
    echo "FAIL: $flavor merged manifest requests a network permission"
    FAILED=1
  else
    echo "ok: $flavor has no network permission"
  fi
done
[[ $FAILED -eq 0 ]] || exit 1

printf '\nAll checks passed.\n'
