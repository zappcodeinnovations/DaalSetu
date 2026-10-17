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

## Bug 16: Side Panel Navigation — Crash & Black Screen Fix
- **Symptom**:
  1. Opening "Buyer Requirements" from side panel crashed with `No Material widget found` and `RenderFlex overflowed by 99280 pixels on the bottom`.
  2. Opening "My Interests", "Today's Offers", and "Settings" from side panel displayed pitch black backgrounds with unreadable dark text.
- **Root Cause**:
  1. `BuyerRequestManagementView` returned a bare `Column` with a `TextField` and `Expanded` with no `Scaffold` ancestor when navigated to via `Get.to(...)`.
  2. `BuyerMyInterestsView`, `BuyerTodayOffersView`, and `SettingsScreen` used `backgroundColor: Colors.transparent` on their `Scaffold`s, which exposed the unpainted Android activity surface.
- **Fix**:
  1. Added `wrapInScaffold: true` option in `BuyerRequestManagementView` to dynamically wrap in a `Scaffold` with `AppBar` and back button when accessed standalone.
  2. Replaced `Colors.transparent` with `theme.scaffoldBackgroundColor` on `Scaffold` and `AppBar` across `BuyerMyInterestsView`, `BuyerTodayOffersView`, and `SettingsScreen`.
  3. Added `Navigator.canPop(context)` back button navigation for seamless return to previous screen.
- **Files Changed**:
  - `lib/modules/buyer/offers/view/buyer_request_management_view.dart`
  - `lib/modules/admin_catalog/view/admin_drawer.dart`
  - `lib/modules/buyer/offers/view/buyer_my_interests_view.dart`
  - `lib/modules/buyer/offers/view/buyer_today_offers_view.dart`
  - `lib/modules/settings/view/settings_page.dart`
  - `lib/modules/buyer/offers/view/buyer_negotiation_view.dart`
- **Verification**: `flutter test test/negotiation_timestamp_test.dart` (PASSED), `flutter analyze` (0 errors).
