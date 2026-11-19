#!/usr/bin/env bash
# Build the GitHub (non-App Store) release of Telik: archive with the
# CHECK_FOR_UPDATES compilation condition, export with Developer ID signing,
# notarize, staple and zip as build/github-release/Telik.zip.
#
# The App Store build is archived from Xcode as usual, without the flag, so it
# never contains the GitHub update checker.
#
# One-time setup: store notarization credentials in the keychain:
#   xcrun notarytool store-credentials telik-notary \
#     --apple-id <apple-id> --team-id 297CWMJG7A --password <app-specific-password>
#
# Usage: scripts/release-github.sh
#   NOTARY_PROFILE  keychain profile for notarytool (default: telik-notary)
#   SKIP_NOTARIZE=1 build and sign only, e.g. to test the script
set -euo pipefail

cd "$(dirname "$0")/.."

TEAM_ID=297CWMJG7A
NOTARY_PROFILE=${NOTARY_PROFILE:-telik-notary}
OUT=build/github-release
ARCHIVE=$OUT/Telik.xcarchive
EXPORT=$OUT/export
APP=$EXPORT/Telik.app
ZIP=$OUT/Telik.zip

if [[ -n $(git status --porcelain) ]]; then
  echo "warning: working tree has uncommitted changes" >&2
fi

VERSION=$(xcodebuild -project Telik.xcodeproj -scheme Telik -configuration Release \
  -showBuildSettings 2>/dev/null | awk '$1 == "MARKETING_VERSION" { print $3; exit }')
echo "==> Telik $VERSION"

rm -rf "$OUT"
mkdir -p "$OUT"

echo "==> Archiving with CHECK_FOR_UPDATES"
xcodebuild archive \
  -project Telik.xcodeproj \
  -scheme Telik \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -archivePath "$ARCHIVE" \
  -quiet \
  SWIFT_ACTIVE_COMPILATION_CONDITIONS='$(inherited) CHECK_FOR_UPDATES'

cat > "$OUT/ExportOptions.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>developer-id</string>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>teamID</key>
  <string>$TEAM_ID</string>
</dict>
</plist>
EOF

echo "==> Exporting with Developer ID"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath "$EXPORT" \
  -exportOptionsPlist "$OUT/ExportOptions.plist" \
  -allowProvisioningUpdates \
  -quiet

codesign --verify --strict --deep "$APP"

if [[ ${SKIP_NOTARIZE:-} == 1 ]]; then
  echo "==> Skipping notarization"
else
  echo "==> Notarizing"
  ditto -c -k --keepParent "$APP" "$OUT/notarize.zip"
  xcrun notarytool submit "$OUT/notarize.zip" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$APP"
  spctl --assess --type execute "$APP"
  rm "$OUT/notarize.zip"
fi

ditto -c -k --keepParent "$APP" "$ZIP"

cat <<EOF

Built $ZIP

Create a GitHub release with tag and title exactly "$VERSION" (the in-app
update check compares the release title with the app version) and attach
Telik.zip, e.g.:

  gh release create $VERSION $ZIP --title $VERSION
EOF
