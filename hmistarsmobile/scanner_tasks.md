# HMI Stars Mobile — Feature Handbook

> Last updated: 2026-06-09
> Covers: Messaging / Scanner / PDF preview / Camera / Build

---

## ✅ Notifications

- [x] Simplified push notification banner — shows only `"Sender : message"` content, no extra metadata.

---

## ✅ Scanner Feature (`document_scanner_view.dart`)

### Image Capture & Flow
- [x] Opening "Scan a document" shows a **selection screen first** (camera + gallery buttons) — does NOT auto-launch camera.
- [x] Cache original image bytes in memory to avoid redundant re-reads on filter changes.
- [x] Selecting a filter option does **not** re-trigger image capturing/picking — uses in-memory cache.

### Filters
- [x] Implement CamScanner-style **B&W Scan** filter: soft-thresholding background removal (background → pure white, text → black).
- [x] Implement **Enhanced** filter: contrast + saturation boost for vivid clarity.
- [x] **Original** filter: unmodified image.
- [x] All filters are cached — switching between them is instant (no reprocessing).

### Rotation
- [x] **Rotate Left** and **Rotate Right** buttons work instantly using `RotatedBox` (zero reprocessing delay).
- [x] Final rotation is applied to image bytes only at PDF save time via a background isolate.

### OCR-based Real PDF Generation
- [x] Added `google_mlkit_text_recognition ^0.13.1` for on-device OCR (free, offline, no API key).
- [x] When saving: Google ML Kit extracts all text blocks with their **bounding box positions**.
- [x] Each text block is repositioned inside the PDF at its relative location (scaled to A4).
- [x] Result is a **searchable, selectable text-based PDF** — not just a photo inside a PDF.
- [x] **Automatic fallback**: if OCR yields no text, falls back to high-quality image PDF.
- [x] OCR info badge shown to user: *"PDF will be generated with OCR-extracted text"*.

### Bug Fixes
- [x] Fixed navigation race condition in `_handleSave()` — `Navigator.pop` called before `onScanCompleted`.
- [x] Fixed `pw.Positioned` compilation error — `width` moved into `pw.SizedBox` wrapper (pdf 3.12.0 incompatibility).
- [x] Fixed Dart string interpolation syntax error on line 234 (`'...\\'...\\'...'` → `"...'...'..."`).

### i18n
- [x] All strings in scanner view support bilingual **French / English** translation.

---

## ✅ Camera Photo Feature (`messagerie_page.dart` + `photo_enhance_view.dart`)

- [x] After taking a regular camera photo, app routes to new **`PhotoEnhanceView`** screen before sending.
- [x] `PhotoEnhanceView` offers the same three filters: **Original**, **B&W**, **Enhanced**.
- [x] Filters are cached — switching is instant.
- [x] Confirming from the enhance screen saves the filtered image and then triggers the document type prompt.
- [x] All strings bilingual FR/EN.

---

## ✅ Web Platform — PDF Previewer (`file_previewer.dart`)

- [x] Removed **Print** and **Share** buttons from PDF preview on web platform.
- [x] Kept only the **Download** button (the one next to the ✕ button).
- [x] Unused print/share action code removed entirely.

---

## ✅ Android Build & ProGuard

- [x] Created `android/app/proguard-rules.pro` with keep/dontwarn rules for:
  - `com.google.mlkit.**`
  - `com.google.android.gms.**`
  - Flutter embedding classes
- [x] `build.gradle.kts` updated to reference `proguard-rules.pro` (minification kept OFF for dev builds).
- [x] Resolved Gradle `Address already in use: bind` error by stopping lingering daemons (`gradlew --stop`).
- [x] Build produces `app-release.apk` successfully (135.4 MB).

---

## ⚠️ Known Device Issue (Not a Code Problem)

- [ ] `INSTALL_FAILED_USER_RESTRICTED` on device `22120RN86G`:
  - **Fix**: On phone → Settings → Developer Options → Enable **"Install via USB"** → tap **Allow** when prompted.
  - Alternative: Copy APK from `build\app\outputs\flutter-apk\app-release.apk` to phone and install manually.

---

## 📁 Key Files Modified

| File | Change |
|------|--------|
| `widgets/document_scanner_view.dart` | Full rewrite: OCR PDF, filters, rotation, selection screen |
| `widgets/photo_enhance_view.dart` | **NEW** — filter screen for regular camera photos |
| `messagerie_page.dart` | Camera flow routed through `PhotoEnhanceView` |
| `Platforme/.../file_previewer.dart` | Removed print/share buttons from PDF preview |
| `pubspec.yaml` | Added `google_mlkit_text_recognition`, `image` |
| `android/app/build.gradle.kts` | ProGuard config |
| `android/app/proguard-rules.pro` | **NEW** — ML Kit keep/dontwarn rules |
