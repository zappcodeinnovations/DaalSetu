---
name: deployment-verification
description: >-
  Use this skill to verify release builds, deployment configurations, environment consistency, and build artifact readiness.
---

# Deployment Verification Skill

## Purpose
Validates that deployment artifacts, release configurations, and platform builds compile cleanly without errors or broken dependencies.

## Procedure
1. **Pre-Build Verification**:
   - Run `flutter analyze` across all project modules.
   - Run all automated unit and integration tests with `flutter test`.
2. **Build Execution**:
   - For Android: Test APK build (`flutter build apk --release`).
   - For Web: Test web release bundle (`flutter build web --release`).
   - For Desktop: Test target platform build (`flutter build windows --release`).
3. **Artifact & Manifest Checks**:
   - Check `pubspec.yaml` versioning and build numbers.
   - Verify that all assets referenced in `pubspec.yaml` exist on disk.
4. **Log Analysis**:
   - Inspect build logs for warnings, deprecated APIs, or resource missing errors.
