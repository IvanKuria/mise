#!/usr/bin/env bash
#
# notarize.sh — submit a DMG (or .app/.zip) to Apple's notary service, wait
# for the result, then staple the ticket so it validates offline.
#
# This is a REFERENCE script. It is correct and runnable once you have stored
# notarization credentials in a keychain profile (see NOTARIZE.md).
#
# Pipeline:
#   xcrun notarytool submit --wait   -> Apple notarizes the artifact
#   xcrun stapler staple             -> attaches the ticket to the artifact
#   spctl / stapler validate         -> verifies Gatekeeper acceptance
#
# Usage:
#   ./Scripts/notarize.sh path/to/Mise-0.1.0.dmg
#
# Env vars:
#   NOTARY_PROFILE   (optional) Name of the keychain profile created with
#                    `xcrun notarytool store-credentials`.
#                    Default: "mise-notary"
#
#   -- OR, instead of a profile, supply these three directly --
#   APPLE_ID         Apple ID email used for notarization.
#   TEAM_ID          10-char Apple Developer Team ID.
#   APP_PASSWORD     App-specific password (appleid.apple.com -> Sign-In & Security).
#
set -euo pipefail

ARTIFACT="${1:-}"
if [[ -z "$ARTIFACT" || ! -e "$ARTIFACT" ]]; then
  echo "usage: $0 <path-to-dmg-or-zip-or-app>" >&2
  exit 1
fi

NOTARY_PROFILE="${NOTARY_PROFILE:-mise-notary}"

# Choose auth: keychain profile (preferred) or explicit Apple ID creds.
auth_args=()
if [[ -n "${APPLE_ID:-}" && -n "${TEAM_ID:-}" && -n "${APP_PASSWORD:-}" ]]; then
  echo "==> Authenticating with explicit Apple ID credentials"
  auth_args=(--apple-id "$APPLE_ID" --team-id "$TEAM_ID" --password "$APP_PASSWORD")
else
  echo "==> Authenticating with keychain profile: $NOTARY_PROFILE"
  echo "    (create it once with: xcrun notarytool store-credentials \"$NOTARY_PROFILE\" ...)"
  auth_args=(--keychain-profile "$NOTARY_PROFILE")
fi

echo "==> Submitting to Apple notary service (this can take a few minutes)"
# --wait blocks until Apple finishes; nonzero exit if it is rejected.
xcrun notarytool submit "$ARTIFACT" "${auth_args[@]}" --wait

echo "==> Stapling the notarization ticket to $ARTIFACT"
# A DMG (and a .app) can be stapled directly; a .zip cannot — staple the
# .app inside it and re-zip if you distribute a zip.
xcrun stapler staple "$ARTIFACT"

echo "==> Verifying"
xcrun stapler validate "$ARTIFACT"

# Gatekeeper assessment. For a .dmg the relevant check is on the .app it
# contains, but spctl on the dmg confirms the disk image is accepted.
case "$ARTIFACT" in
  *.app)
    spctl -a -vvv --type execute "$ARTIFACT" ;;
  *.dmg)
    spctl -a -vvv --type open --context context:primary-signature "$ARTIFACT" || true ;;
esac

echo
echo "Notarized and stapled: $ARTIFACT"
echo "Ship it. Users can now open it without Gatekeeper warnings."
