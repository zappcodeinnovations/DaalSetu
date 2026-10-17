# Test Strategy & Quality Assurance Framework

## 1. Automated Testing Architecture
Testing is mandatory for every bug fix and feature implementation under the Euroside AI development rules.

```text
       ┌────────────────────────┐
       │   Integration Tests    │  (Full page flows, GetX bindings)
       ├────────────────────────┤
       │   Widget / UI Tests    │  (Stateful widgets, input behaviors)
       ├────────────────────────┤
       │   Unit / Model Tests   │  (JSON parsing, calculations, dates)
       └────────────────────────┘
```

---

## 2. Standard Test Execution Commands
- **Run all tests**:
  ```powershell
  flutter test
  ```
- **Run a single test file**:
  ```powershell
  flutter test test/<test_file_name>.dart
  ```
- **Static code analysis**:
  ```powershell
  flutter analyze <path>
  ```

---

## 3. Mocking & Harness Guidelines
1. **SharedPreferences**: Always initialize in `setUp()` when tests touch persistent settings:
   ```dart
   SharedPreferences.setMockInitialValues({});
   ```
2. **Platform Channels / Secure Storage**: In unit tests, avoid invoking real secure storage methods without stubbing the method channel or testing through isolated controllers/repositories.
3. **Repository Mocks**: Subclass `AdminCatalogRepository` (e.g. `FakeAdminCatalogRepository`) to return deterministic `AdminPageResult` fixtures without external HTTP calls.
4. **GetX State Reset**: Always invoke `Get.reset()` in `setUp()` and `tearDown()` to prevent controller leaks across test suites.

---

## 4. Continuous Loop Testing Protocol
1. **Inspect**: Read failing code, stack trace, and error logs.
2. **Reproduce**: Write a test verifying the exact failure or symptom.
3. **Diagnose**: Identify the true root cause rather than patching superficial symptoms.
4. **Implement**: Make the minimal surgical fix.
5. **Run Tests**: Execute `flutter test test/<test_file>.dart`.
6. **Analyze**: If tests fail, inspect full trace and refine fix (up to 5 bounded iterations).
7. **Regression Check**: Run existing related test suites.
8. **Static Analysis**: Verify zero errors or warnings via `flutter analyze`.
