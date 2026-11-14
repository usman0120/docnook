#!/usr/bin/env bash
# Creates the Play upload key once (BLUEPRINT 12.4) and android/key.properties.
# The OWNER runs this, because it asks for a password only the owner should
# know. Usage, from the project folder in Git Bash:
#     ./tool/make_upload_key.sh
# Afterwards copy android/upload-keystore.jks AND android/key.properties to
# two offline places (a USB drive and another computer). Losing the key means
# asking Google support to reset it; never commit or share it.
set -euo pipefail
cd "$(dirname "$0")/.."

KEYSTORE=android/upload-keystore.jks
PROPS=android/key.properties
if [[ -e "$KEYSTORE" || -e "$PROPS" ]]; then
  echo "An upload key already exists ($KEYSTORE / $PROPS). Nothing changed."
  exit 1
fi

KEYTOOL=keytool
for jdk in "${JAVA_HOME:-}" "/c/Program Files/Android/Android Studio/jbr"; do
  if [[ -n "$jdk" && ( -x "$jdk/bin/keytool" || -x "$jdk/bin/keytool.exe" ) ]]; then
    KEYTOOL="$jdk/bin/keytool"
    break
  fi
done

echo "Choose a strong password (at least 8 characters) and type it twice."
echo "Nothing appears while you type. Write it down and keep it safe."
read -r -s -p "Password: " PASS; echo
read -r -s -p "Same password again: " PASS2; echo
if [[ "$PASS" != "$PASS2" || ${#PASS} -lt 8 ]]; then
  echo "The passwords differ or are shorter than 8 characters. Nothing changed."
  exit 1
fi
read -r -p "Your name or company, as shown on the certificate: " OWNER_NAME
read -r -p "Two-letter country code (for example PK): " COUNTRY

"$KEYTOOL" -genkeypair -v \
  -keystore "$KEYSTORE" -storetype PKCS12 \
  -alias upload -keyalg RSA -keysize 4096 -validity 10000 \
  -storepass "$PASS" -keypass "$PASS" \
  -dname "CN=${OWNER_NAME}, C=${COUNTRY}" >/dev/null

umask 077
cat > "$PROPS" <<EOF
storeFile=../upload-keystore.jks
storePassword=$PASS
keyAlias=upload
keyPassword=$PASS
EOF
unset PASS PASS2

echo
echo "Done. Created $KEYSTORE and $PROPS (both ignored by git)."
echo "Now back up BOTH files to a USB drive and another computer."
