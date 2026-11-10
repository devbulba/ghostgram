#!/usr/bin/env bash
set -euo pipefail

CERTS=build-system/fake-codesigning/certs
PROFILES=build-system/fake-codesigning/profiles
P12="$CERTS/SelfSigned.p12"

KC=gg-genprofiles.keychain
KCP=gg-genprofiles

security delete-keychain "$KC" 2>/dev/null || true
security create-keychain -p "$KCP" "$KC"
security set-keychain-settings "$KC"
security unlock-keychain -p "$KCP" "$KC"
security import "$P12" -k "$KC" -P "" -T /usr/bin/codesign -T /usr/bin/security
security set-key-partition-list -S apple-tool:,apple: -k "$KCP" "$KC" >/dev/null

SIGN_ID=$(security find-identity -v -p codesigning "$KC" | sed -n 's/.*"\(.*\)".*/\1/p' | head -n1)
echo "Signing identity: $SIGN_ID"

for f in "$PROFILES"/*.mobileprovision; do
  echo "Patching $(basename "$f")"
  tmp=$(mktemp)
  security cms -D -i "$f" > "$tmp"
  plutil -remove DER-Encoded-Profile "$tmp" 2>/dev/null || true
  if ! plutil -replace ExpirationDate -date "2035-01-01T00:00:00Z" "$tmp" 2>/dev/null; then
    plutil -insert ExpirationDate -date "2035-01-01T00:00:00Z" "$tmp"
  fi
  plutil -replace TimeToLive -integer 315360000 "$tmp" 2>/dev/null || true
  security cms -S -k "$KC" -N "$SIGN_ID" -i "$tmp" -o "$f"
  rm -f "$tmp"
done

security delete-keychain "$KC" 2>/dev/null || true