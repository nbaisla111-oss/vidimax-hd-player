#!/usr/bin/env bash
set -euo pipefail

# Generates a fresh Google Play Upload Keystore (PKCS12, RSA 2048, valid 10,000 days)
OUT_DIR="$(cd "$(dirname "$0")" && pwd)"
JKS_PATH="${OUT_DIR}/app/upload-keystore.jks"

echo "Generating upload-keystore.jks at: ${JKS_PATH}"
keytool -genkey -v \
  -keystore "${JKS_PATH}" \
  -storetype PKCS12 \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload

echo ""
echo "✅ Done! Keep ${JKS_PATH} and your passwords backed up safely."
echo "Base64 value for GitHub Secret KEYSTORE_BASE64:"
base64 -w 0 "${JKS_PATH}" 2>/dev/null || base64 -i "${JKS_PATH}" | tr -d '\n'
echo ""
