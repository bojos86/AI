# BBK OCR — Flutter WebView (Strict UAT)

This project wraps the Strict UAT HTML into a Flutter Android app with camera permission, so you can install an APK on your S25 Ultra and test OCR offline.

## Quick Start (Debug APK via GitHub Actions)
1. Create a new GitHub repository and push this project.
2. Go to **Actions** → run **Build Flutter APK (Debug)**.
3. Download `BBK-OCR-UAT-debug-apk` artifact → `app-debug.apk` and install on your phone.

## Signed Release APK (for direct share/install)
1. Generate a keystore on your machine:
   ```bash
   keytool -genkey -v -keystore release.keystore -alias bbkocr -keyalg RSA -keysize 2048 -validity 10000
   ```
2. Base64-encode the keystore:
   ```bash
   base64 -w0 release.keystore > keystore.base64
   ```
3. In your GitHub repo, set the following **Secrets** (Settings → Secrets → Actions):
   - `ANDROID_KEYSTORE_BASE64` = content of `keystore.base64`
   - `ANDROID_KEYSTORE_PASSWORD` = the keystore password
   - `ANDROID_KEY_ALIAS` = `bbkocr` (or your alias)
   - `ANDROID_KEY_ALIAS_PASSWORD` = the key password
4. Run **Actions → Release Signed APK** and enter a tag (e.g. `v0.1.0`).
5. After it finishes, the **Release** page will contain a downloadable `app-release.apk` (signed).

## Notes
- App shows local `assets/bbk_ocr_strict_uat.html` in a WebView (camera enabled).
- AndroidManifest is patched to include `CAMERA` and `INTERNET` automatically during CI.
- If you update the HTML, just replace `assets/bbk_ocr_strict_uat.html` and re-run the build.
