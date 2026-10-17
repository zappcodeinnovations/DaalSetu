# Bug Log & Historical Fixes

## Bug 9: Negotiation Submission Fails — Seller/Admin Panel
- **Symptom**: Submitting a negotiation counter-offer displayed "Failed to submit: The server is temporarily unavailable" or "Exception: Something went wrong".
- **Root Cause**: `NegotiationPage` payload was missing expected field formats (e.g., price per quintal conversions and required integer parsing), and exceptions from `ApiClient` surfaced generic connection error dialogs.
- **Fix**: Corrected payload structure, validated values prior to submission, surfaced actionable backend validation responses, and guarded against duplicate submissions.
- **Files Changed**: `lib/modules/admin_catalog/view/negotiation_page.dart`
- **Verification**: `test/negotiation_submission_test.dart` (PASSED).

---

## Bug 10: Admin Panel — Incorrect Negotiation Timestamp
- **Symptom**: Negotiation log timestamps displayed incorrect date/time compared to backend database creation time.
- **Root Cause**: Backend timestamp was returned in UTC ISO 8601 without explicit `.toLocal()` conversion on mobile, or was treated as local time.
- **Fix**: Explicitly converted parsed ISO 8601 timestamps to device local time (`DateTime.parse(ts).toLocal()`) with standard AM/PM 12-hour format.
- **Files Changed**: `lib/modules/admin_catalog/view/negotiation_page.dart`
- **Verification**: `test/negotiation_timestamp_test.dart` (PASSED).

---

## Bug 11: Admin Panel — User List Not Refreshing After Adding a User
- **Symptom**: After successfully creating a new user via `AddUserScreen`, the user list did not update and the new user was missing unless pulled to refresh manually.
- **Root Cause**: `UserManagementScreen` FAB invoked `Get.to(() => AddUserScreen())` un-awaited, discarding `Get.back(result: true)`. Also, `UserController` lacked an `ever(users)` listener and an `isLoading` re-entrancy guard.
- **Fix**: Made FAB `onPressed` an `async` callback awaiting navigation and calling `fetchUsers()`. Added concurrent fetch hook in `AddUserController` on success. Added `ever(users, (_) => _applyFilter())` and re-entrancy guard.
- **Files Changed**:
  - `lib/modules/users/view/user_view.dart`
  - `lib/modules/users/controller/user_controller.dart`
  - `lib/modules/users/controller/add_user_controller.dart`
- **Verification**: `test/user_list_refresh_test.dart` (9 tests PASSED).

---

## Bug 12: Admin Panel — Brand Master Search Not Clearing on Refresh
- **Symptom**: In Admin Panel → Brand Master, the search field retained previously entered text and the list retained the search filter after refreshing the page.
- **Root Cause**: `AdminSearchBar` lacked an external `TextEditingController`. Refresh button and `RefreshIndicator` invoked `controller.load(refresh: true)` without clearing `controller.search.value` or cancelling pending debounce timers.
- **Fix**: Added `controller` and `onClear` to `AdminSearchBar`. Instantiated `_searchController` in `_AdminModuleListScreenState`. Created unified `_refresh()` that cancels debounce, clears `_searchController`, calls `controller.resetSearch()`, and reloads page 1 with `controller.load(refresh: true)`.
- **Files Changed**:
  - `lib/modules/admin_catalog/controller/admin_catalog_controller.dart`
  - `lib/widgets/admin_common_widgets.dart`
  - `lib/modules/admin_catalog/view/admin_module_list_screen.dart`
- **Verification**: `test/brand_master_search_refresh_test.dart` (7 tests PASSED).
