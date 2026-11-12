---
name: regression-testing
description: >-
  Use this skill to run automated regression test suites, verify existing functionality remains intact, and detect unintended side-effects.
---

# Regression Testing Skill

## Purpose
Ensures new code changes, bug fixes, and feature updates do not break previously working features or alter existing API contracts.

## Procedure
1. **Identify Affected Modules**:
   - Determine which sibling views, models, and controllers interact with modified code.
2. **Execute Targeted Test Suites**:
   - Run existing tests for related modules:
     ```powershell
     flutter test test/<related_test>.dart
     ```
3. **Run Static Code Analysis**:
   - Verify no new compiler or linter errors/warnings were introduced:
     ```powershell
     flutter analyze <target_directories>
     ```
4. **Inspect Git Diff**:
   - Run `git diff` and ensure only the intended lines were modified. Check for accidental whitespace, generated artifacts, or removed logic.
5. **Report Status**:
   - Clearly report which tests passed, which were not run, and any observed edge cases.
