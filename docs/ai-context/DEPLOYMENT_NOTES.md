# Deployment Notes & Release Procedures

## 1. Multi-Platform Targets
The DaalSetu codebase builds for:
- Android APK / AAB
- iOS IPA
- Web (HTML/WASM)
- Windows Desktop executable

---

## 2. Standard Build Commands
- **Android Release Bundle**:
  ```powershell
  flutter build appbundle --release
  ```
- **Android APK**:
  ```powershell
  flutter build apk --release
  ```
- **Web Build**:
  ```powershell
  flutter build web --release
  ```
- **Windows Release**:
  ```powershell
  flutter build windows --release
  ```

---

## 3. Environment & Configuration Security
- **Public API Host**: Defined centrally in [`lib/comman/api_url.dart`](file:///P:/DaalSetu/lib/comman/api_url.dart).
- **Secrets Management**: Never commit hardcoded tokens, passwords, keystores, or private signing keys to Git.
- **Secure Storage**: Tokens stored on client devices using platform-specific hardware/keychain encryption (`flutter_secure_storage`).
- **Release Verification**: Run `flutter analyze` and `flutter test` prior to proposing release builds.
