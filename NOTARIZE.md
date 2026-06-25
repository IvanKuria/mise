# Distributing mise (Developer ID + Notarization)

`mise` is a macOS menu-bar agent app (`LSUIElement`, no Dock icon) distributed
**directly** as a notarized **Developer ID** build inside a `.dmg` — *not* via
the Mac App Store. This guide is the full path from a clean checkout to a
signed, notarized, stapled disk image that opens on any Mac without a
Gatekeeper warning.

Everything below is runnable once you supply your own Apple Developer
credentials. Nothing here requires the Mac App Store.

---

## 0. Prerequisites

- An **Apple Developer Program** membership (paid).
- Xcode + command-line tools (`xcode-select --install`).
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`) —
  the Xcode project is generated from `App/project.yml`.
- *(optional, nicer DMG)* `brew install create-dmg`.

Find your **Team ID** (10 characters, e.g. `ABCDE12345`) at
<https://developer.apple.com/account> → Membership.

---

## 1. Fill in your Team ID

Open `App/project.yml` and set your Team ID:

```yaml
settings:
  base:
    DEVELOPMENT_TEAM: "ABCDE12345"   # <-- your 10-char Apple Team ID
```

Then regenerate the Xcode project:

```bash
cd App
xcodegen generate
```

> The Release configuration already sets
> `CODE_SIGN_IDENTITY: "Developer ID Application"`, keeps
> `ENABLE_HARDENED_RUNTIME: YES`, wires `CODE_SIGN_ENTITLEMENTS:
> Mise.entitlements`, and sets `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon`.
> Signing style is left as **Automatic** for convenience; flip it to **Manual**
> (`CODE_SIGN_STYLE: Manual`) if you want fully reproducible CI signing with an
> explicitly chosen certificate.

---

## 2. Get a Developer ID Application certificate

You sign with a **"Developer ID Application"** certificate (distinct from the
"Apple Distribution" cert used for the App Store).

- Easiest: Xcode → **Settings → Accounts → Manage Certificates → +
  → Developer ID Application**.
- Or create it on the developer portal and download/install it into your
  login keychain.

Verify it is present:

```bash
security find-identity -p codesigning -v | grep "Developer ID Application"
```

---

## 3. Store notarization credentials (once)

Create an **app-specific password** at <https://appleid.apple.com> →
*Sign-In & Security → App-Specific Passwords*. Then save a reusable keychain
profile so you never type the password again:

```bash
xcrun notarytool store-credentials "mise-notary" \
  --apple-id "you@example.com" \
  --team-id "ABCDE12345" \
  --password "abcd-efgh-ijkl-mnop"   # the app-specific password
```

`notarize.sh` defaults to the profile name `mise-notary` (override with
`NOTARY_PROFILE`). Alternatively, pass `APPLE_ID` / `TEAM_ID` / `APP_PASSWORD`
as env vars instead of using a profile.

---

## 4. Archive → export → DMG

```bash
cd App
DEVELOPMENT_TEAM=ABCDE12345 ./Scripts/package-dmg.sh
```

This does:

1. `xcodegen generate` (keeps the project in sync with `project.yml`),
2. `xcodebuild archive` (Release) → `build/Mise.xcarchive`,
3. `xcodebuild -exportArchive` with a **`developer-id`** ExportOptions →
   `build/export/Mise.app` (signed, hardened runtime),
4. verifies the signature and the hardened-runtime flag,
5. builds `build/Mise-<version>.dmg` (via `create-dmg` if installed, else
   `hdiutil` with an `/Applications` drop link).

The DMG version comes from `CFBundleShortVersionString` (driven by
`MARKETING_VERSION` in `project.yml`).

---

## 5. Notarize → staple

```bash
cd App
./Scripts/notarize.sh build/Mise-0.1.0.dmg
```

This runs:

1. `xcrun notarytool submit --wait` — uploads to Apple's notary service and
   blocks until a verdict (a few minutes). Nonzero exit on rejection; inspect
   the log with `xcrun notarytool log <submission-id> --keychain-profile mise-notary`.
2. `xcrun stapler staple` — attaches the notarization ticket to the DMG so it
   validates **offline**.
3. `xcrun stapler validate` + `spctl -a -vvv`.

---

## 6. Verify (Gatekeeper) manually

After stapling you can independently confirm acceptance:

```bash
# The disk image:
spctl -a -t open --context context:primary-signature -vvv build/Mise-0.1.0.dmg
stapler validate build/Mise-0.1.0.dmg

# The app inside it (mount the dmg first, or check build/export/Mise.app):
spctl -a -t execute -vvv build/export/Mise.app
codesign -dvv build/export/Mise.app 2>&1 | grep -i runtime   # expect "runtime" flag
stapler validate build/export/Mise.app
```

A healthy result shows `accepted` and `source=Notarized Developer ID`.

---

## Entitlements rationale (non-sandboxed)

`App/Mise.entitlements` is intentionally an **empty entitlements dictionary**:

- **App Sandbox is OFF.** Because mise ships via Developer ID (not the MAS),
  the sandbox is not required. Leaving it off gives the app unrestricted
  filesystem and network access (reading user-chosen library exports, talking
  to TMDB / the network) without enumerating sandbox temporary-exception
  entitlements.
- **Hardened Runtime is ON** (`ENABLE_HARDENED_RUNTIME: YES`), which Apple
  *requires* for notarization. The entitlements file deliberately enables none
  of the hardened-runtime exceptions (JIT, disable-library-validation, dyld
  env vars, etc.) because mise needs none of them. Add one only if a future
  dependency genuinely requires it — each extra exception weakens the runtime
  protections.

**If you ever move to the Mac App Store** (and therefore must sandbox), add to
`Mise.entitlements`:

```xml
<key>com.apple.security.app-sandbox</key>                    <true/>
<key>com.apple.security.network.client</key>                 <true/>   <!-- outbound TMDB / network -->
<key>com.apple.security.files.user-selected.read-only</key>  <true/>   <!-- importing a Letterboxd export -->
```

…then re-test, since the sandbox will start restricting filesystem access.

---

## App icon — PLACEHOLDER

The current app icon in
`App/Resources/Assets.xcassets/AppIcon.appiconset/` is a **generated
placeholder**: a charcoal-gradient rounded square with a notch silhouette and a
minimal film-strip / play mark. **Replace it before any public release** with
the final brand asset.

To regenerate the full icon set from a new 1024×1024 master PNG, resize into
the ten required slots with `sips` (the `Contents.json` already references these
filenames):

```bash
ICONSET=App/Resources/Assets.xcassets/AppIcon.appiconset
for spec in "16:icon_16x16" "32:icon_16x16@2x" "32:icon_32x32" "64:icon_32x32@2x" \
            "128:icon_128x128" "256:icon_128x128@2x" "256:icon_256x256" \
            "512:icon_256x256@2x" "512:icon_512x512"; do
  px="${spec%%:*}"; name="${spec##*:}"
  sips -s format png -z "$px" "$px" master_1024.png --out "$ICONSET/$name.png"
done
cp master_1024.png "$ICONSET/icon_512x512@2x.png"
```

**Menu-bar icon:** the `MenuBarExtra` uses a built-in **SF Symbol**, so no
template image asset is needed in the catalog. If you later want a custom
menu-bar glyph, add a *template* PDF/PNG (single-color, transparent, with
"Render As: Template Image" in the asset) so macOS tints it for light/dark menu
bars automatically.
