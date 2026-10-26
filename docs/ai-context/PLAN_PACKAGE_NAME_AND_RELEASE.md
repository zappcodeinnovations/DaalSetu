# Implementation Plan: Package Name Change (`com.zappkode.daalsetu`) & Play Store Release Setup

**Author**: Senior Software Engineering Partner  
**Target Application**: DaalSetu Mobile App  
**Date**: October 26, 2026  
**Status**: Pending User Confirmation / Execution  

---

## 1. Executive Summary & Objective

- **Current Application ID / Package**: `com.zappcode.daalsetu`
- **Target Application ID / Package**: `com.zappkode.daalsetu` (Company name spelling corrected: `zappcode` ➔ `zappkode`)
- **Keystore Credentials Provided**:
  - `storePassword`: `daalsetu@12`
  - `keyPassword`: `daalsetu@12`
  - `keyAlias`: `upload`
  - `storeFile`: `upload-keystore.jks`
- **Goal**:
  1. Complete package/namespace rename across Android native layer and Flutter Dart MethodChannels with zero breaking changes.
  2. Configure and verify release signing setup.
  3. Ensure project passes `flutter analyze` and all automated tests.
  4. Provide exact steps for generating the signed Android App Bundle (`.aab`) and publishing on the Google Play Store.

---

## 2. Impact Analysis & Affected Files

| # | File / Directory | Change Description | Downstream Impact / Risk |
|---|---|---|---|
| 1 | `android/app/build.gradle.kts` | Update `namespace = "com.zappkode.daalsetu"` and `defaultConfig { applicationId = "com.zappkode.daalsetu" }` | Defines the Android app ID on Play Store and R class namespace |
| 2 | `android/app/src/main/kotlin/com/zappcode/daalsetu/MainActivity.kt` ➔ `.../com/zappkode/daalsetu/MainActivity.kt` | Move directory path from `com/zappcode/daalsetu` to `com/zappkode/daalsetu`, update `package com.zappkode.daalsetu` and `downloadsChannel = "com.zappkode.daalsetu/downloads"` | Native entrypoint must match namespace |
| 3 | `lib/modules/downloads/service/downloads_service.dart` | Update MethodChannel identifier to `'com.zappkode.daalsetu/downloads'` | Must match `MainActivity.kt` exactly |
| 4 | `lib/modules/admin_dc/service/admin_challan_pdf_service.dart` | Update MethodChannel identifier to `'com.zappkode.daalsetu/downloads'` | Must match `MainActivity.kt` exactly |
| 5 | `android/key.properties` | Verify keystore configuration and keystore file placement in `android/app/upload-keystore.jks` | Keystore file required for signing release builds |

---

## 3. Safe Implementation Strategy (Step-by-Step)

### Step 1: Update Android Gradle Configuration
In `android/app/build.gradle.kts`:
- Line 18:
  ```kotlin
  -    namespace = "com.zappcode.daalsetu"
  +    namespace = "com.zappkode.daalsetu"
  ```
- Line 32:
  ```kotlin
  -        applicationId = "com.zappcode.daalsetu"
  +        applicationId = "com.zappkode.daalsetu"
  ```

### Step 2: Relocate Kotlin MainActivity
1. Create new folder structure: `android/app/src/main/kotlin/com/zappkode/daalsetu/`
2. Create `MainActivity.kt` in the new folder with:
   - Package: `package com.zappkode.daalsetu`
   - Downloads MethodChannel: `private val downloadsChannel = "com.zappkode.daalsetu/downloads"`
   - Keep all existing download, open, list, and delete implementations 100% intact.
3. Remove old folder `android/app/src/main/kotlin/com/zappcode/` to prevent duplicate package definitions.

### Step 3: Synchronize Flutter Dart MethodChannels
1. `lib/modules/downloads/service/downloads_service.dart`:
   ```dart
   -    'com.zappcode.daalsetu/downloads',
   +    'com.zappkode.daalsetu/downloads',
   ```
2. `lib/modules/admin_dc/service/admin_challan_pdf_service.dart`:
   ```dart
   -    'com.zappcode.daalsetu/downloads',
   +    'com.zappkode.daalsetu/downloads',
   ```

### Step 4: Keystore Placement Verification
In `android/app/build.gradle.kts`, the release signing block is:
```kotlin
storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
```
Because `file(it)` resolves relative to the `android/app` directory:
- The keystore file `upload-keystore.jks` must reside at:
  📁 `android/app/upload-keystore.jks`
- Ensure `android/.gitignore` contains:
  ```
  key.properties
  **/*.keystore
  **/*.jks
  ```
  *(Confirmed: already present in `android/.gitignore`, keeping your keys safe from accidental git commits).*

### Step 5: Verification & Testing
1. Run `flutter analyze` to ensure 0 syntax or channel errors.
2. Run automated test suite: `flutter test`.
3. Verify Android Gradle project sync cleanly.

---

## 4. Google Play Store Release Preparation Guide

Once the code changes are completed, follow these steps to build and publish:

### A. Place the Keystore File
Copy your created `upload-keystore.jks` into:
```
d:\Flutter_project\DaalSetu\android\app\upload-keystore.jks
```

### B. Versioning (`pubspec.yaml`)
In `pubspec.yaml`:
```yaml
version: 1.0.0+1
```
- Format: `version_name+version_code`
- For initial release: `1.0.0+1` (Version Code = 1).
- For future updates: increment the build number (e.g. `1.0.1+2`, `1.0.2+3`). Google Play Console requires a strictly higher version code for every new release.

### C. Build the Android App Bundle (AAB)
Run the release build command in terminal:
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```
- Output location:
  `build/app/outputs/bundle/release/app-release.aab`
- This `.aab` file will be signed using your `upload-keystore.jks` and ready for upload to Google Play Console.

### D. Play Console Registration Checklist
1. **Google Play Console Account**: Log in to https://play.google.com/console
2. **Create App**:
   - App Name: `Daal Setu` (or preferred title)
   - Default language: English (United States or India)
   - App or Game: App
   - Free or Paid: Free
3. **App Content & Policies**:
   - Privacy Policy URL (Required)
   - App Access / Login Credentials for Google Reviewers (Provide demo user/password)
   - Target Audience & Content Rating questionnaire
   - Data Safety Section (Disclose data collection: name, mobile, storage/downloads, etc.)
4. **Store Listing**:
   - Short Description (up to 80 chars)
   - Full Description (up to 4000 chars)
   - App Icon: 512 x 512 px (PNG 32-bit with alpha)
   - Feature Graphic: 1024 x 500 px (PNG or JPEG)
   - Phone Screenshots: Minimum 2 screenshots (16:9 or 9:16 aspect ratio, min 1080px)
5. **Create Release**:
   - Go to **Production** (or **Closed Testing** / Internal Testing)
   - Create new release
   - Upload `app-release.aab`
   - Enter Release Notes
   - Save and Submit for Review!

---

## 5. Rollback Plan

If needed, git state can be restored instantly via:
```bash
git checkout android/app/build.gradle.kts lib/modules/downloads/service/downloads_service.dart lib/modules/admin_dc/service/admin_challan_pdf_service.dart
```
and reverting the moved `MainActivity.kt`.

---

## 6. Ready for Execution?
Please review this plan. Upon your confirmation, we will execute the package rename, verify the changes, and confirm readiness for `flutter build appbundle --release`.
