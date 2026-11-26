# Current Task State

## Current Task
- **Goal**: Batch 23 App-Side Fixes — (1) Dismiss active snackbars/toasts on logout; (2) Add `Reserved` filter tab and `RESERVED` badge parity for active contracts with incoming bids; (3) Fix Contract PDF `Buyer ID` and `Seller ID` priority to show alphanumeric IDs (`buyerUniqueId`, `sellerMappedId`) before farm/display names.
- **Status**: **100% Implemented & Verified (No Backend API Changes)**
  - **Changes Made**:
    1. `lib/utils/app_snackbar.dart` & `lib/utils/app_preferences.dart`: Added `AppSnackbar.dismissAll()` and called it in `AppPreferences.logout()`.
    2. `lib/modules/contracts/view/contract_view.dart`: Added `'Reserved'` to `filters`, added `_effectiveStatus(contract)` mapping `active` + `activeBidCount > 0` to `'reserved'`, and styled `'reserved'` badge with `Colors.amber.shade700`.
    3. `lib/modules/contracts/services/contract_pdf.dart`: Prioritized `contract.buyerUniqueId` and `contract.sellerMappedId` ahead of `displayBuyerId`/`displaySellerId`.
    4. `test/batch_23_logout_toast_reserved_pdf_id_test.dart`: Added automated tests covering all 3 fixes.
  - **Verification**:
    - `test/batch_23_logout_toast_reserved_pdf_id_test.dart`, `test/batch_21_admin_and_contract_fixes_test.dart`, `test/batch_20_pdf_and_vehicles_test.dart`: **11/11 Passed (100% Pass Rate)**.
    - Static analysis: **0 Errors / 0 Warnings** across all modified files.

---

## Current Task
- **Goal**: Bug 73 — (1) Fix `visibleLabelIndices` error in `dashboard_page.dart`; (2) Make PDF download bulletproof with Android Scoped Storage auto-fallback in `DownloadsService.saveBytes`; (3) Protect PDF generator against Helvetica Unicode glyph crashes using comprehensive `pdfSafeText()` mapping; (4) Validate backend PDF download response header (`%PDF-` magic bytes).
- **Status**: **100% Implemented & Verified**
  - **Changes Made**:
    1. `lib/modules/dashboard/view/dashboard_page.dart`: Cleaned up any remaining compiler references to `visibleLabelIndices`.
    2. `lib/utils/pdf_text.dart`: Sanitized em-dash (`—`), en-dash (`–`), curly quotes (`“ ”`, `’`), and rupee symbols (`₹`) into safe ASCII equivalents.
    3. `lib/modules/contracts/services/contract_pdf.dart`: Protected all section text cells with `pdfSafeText()`, sanitized `tradeValue` and `money()`.
    4. `lib/modules/downloads/service/downloads_service.dart`: Guaranteed internal documents storage write first (guaranteeing downloads appear in DownloadsView) and safely caught native Android `saveFileToDownloads` `PlatformException`.
    5. `lib/modules/contracts/view/contract_details_view.dart`: Verified `%PDF-` magic bytes before accepting backend response, falling back reliably to client generator.
    6. `test/batch_20_pdf_and_vehicles_test.dart`: Added test for special characters / em-dash in PDF generator.
  - **Verification**:
    - Cumulative regression suite (batches 20, 21, 22): **12/12 Passed (100% Pass Rate)**
    - Static analysis: **0 Errors / 0 Warnings / 0 Issues**.

---

## Previous Tasks (Batch 22)
- **Goal**: Batch 20 Fixes — (1) Admin Registered Vehicles RC number placeholder (`e.g., MH31 AB 1234`), 10-character limit, and 10-character format validation; (2) Downloaded Contract PDF `Administration` section `Admin Remark` field parity; (3) Admin Registered Vehicles RC document clear/remove (`×`) cross icon; (4) Downloaded Contract PDF `Buyer` and `Seller` sections `GST No.` parity.
- **Status**: **100% Implemented & Verified**
  - **Files Updated / Created**:
    1. `lib/modules/admin_catalog/view/admin_record_form_screen.dart`:
       - Added `maxLength: 10` for vehicle number fields (`vehicle_number`, `rc_number`).
       - Added `hintText: 'e.g., MH31 AB 1234'` for vehicle number fields.
       - Added validation enforcing 10 alphanumeric characters when non-empty.
       - Updated `_fileField`: when `name != null`, wrapped in a `Row` with `Expanded(child: button)` and a trailing red remove `IconButton(icon: Icon(Icons.close_rounded, color: Colors.redAccent))` that clears `filePaths[field.key]` upon tap.
    2. `lib/modules/contracts/services/contract_pdf.dart`:
       - Added `['Admin Remark', dash(contract.adminRemark)]` as the top row under `section('Administration', ...)`.
       - Updated `isAdminView` check to also inspect `contract.adminRemark.isNotEmpty`.
       - Added `['GST No.', dash(contract.buyerGst)]` to `section('Buyer')`.
       - Added `['GST No.', dash(contract.sellerGst)]` to `section('Seller')`.
       - Added `DeflateCallback? deflate` parameter to `buildContractPdf` for uncompressed stream testing.
    3. `test/batch_20_pdf_and_vehicles_test.dart`:
       - Automated test suite verifying all 4 fixes (RC format placeholder & length validator, RC document remove button & state clearance, and Contract PDF Administration & GST numbers generation).
  - **Verification**:
    - `test/batch_20_pdf_and_vehicles_test.dart`: **3/3 Passed**
    - Full regression suite (`test/batch_19_bug1_and_bug2_test.dart`, `test/batch_19_bug3_and_bug4_test.dart`, `test/batch_19_bug5_gtv_deals_chart_test.dart`, `test/batch_20_pdf_and_vehicles_test.dart`): **12/12 Passed (100% Pass Rate)**
    - Static analysis: **0 Errors / 0 Warnings** across all modified files.

---

## Previous Tasks (Batch 19)
- **Goal**: Reopened Bug Fixes — (1) Out of Stock product card badge clean title-case formatting; (2) Manage Categories modal root commodities filtering & web parity; (3) Reset Password screen top-anchored back button; (4) Admin Dashboard Deals in Negotiation route mapping to Buyer Offers; (5) Dashboard Gross Trade Value & Deals chart x-axis date overlap and right-edge separation.
- **Status**: **100% Implemented & Verified**
  - **Files Updated / Created**:
    1. `lib/modules/products/view/product_view.dart`: Replaced raw `product.status.toUpperCase()` with `_formatStatus(product.status)`, rendering clean "Out of Stock" / "Available" copy.
    2. `lib/modules/admin_catalog/view/admin_module_list_screen.dart`: Updated `_showManageCategoriesModal` to fetch system categories from `CategoryService.fetchBuyerCategoryData()` / `/api/categories/`, strictly filter for root categories (`parent == null`, `level == 0`, `status != 'pending'`), deduplicate, sort alphabetically, and match web layout (subtitle, sprout icon, `Cancel` and `Save Changes` buttons).
    3. `lib/modules/Auth/forgot_password/view/forgot_password_page.dart`: Anchored back button to the top-left of the viewport using `Positioned` + `SafeArea`, removing it from the vertically-centered form.
    4. `lib/modules/dashboard/view/dashboard_page.dart`: Updated "Deals in Negotiation" card `onTap` to `AppRoutes.adminModule('buyer_offers')`.
    5. `lib/modules/dashboard/view/dashboard_page.dart`: Implemented dynamic downsampling `_computeVisibleLabelIndices` for GTV & Deals chart when `count > 7` (e.g. 1Y: shows 4-5 well-spaced milestones with start and end dates and $\ge 2$ step spacing to prevent label overlap) and expanded rightTitles reservedSize to 38 with left padding to give the green deals bar breathing space away from the right axis.
    6. `test/batch_19_bug1_and_bug2_test.dart`, `test/batch_19_bug3_and_bug4_test.dart`, & `test/batch_19_bug5_gtv_deals_chart_test.dart`: Automated test suites covering all five fixes.
  - **Verification**:
    - `test/batch_19_bug1_and_bug2_test.dart`: **3/3 Passed**
    - `test/batch_19_bug3_and_bug4_test.dart`: **2/2 Passed**
    - `test/batch_19_bug5_gtv_deals_chart_test.dart`: **3/3 Passed**
    - Total Batch 19 suite: **8/8 Passed (100% Pass Rate)**
    - Static analysis: **0 Errors / Clean**

---
  - **Merge Commits**:
    - `d640b41`: `feat: batch 18 fixes - dynamic resubmit button, negotiation status banners, email lowercase normalization`
    - `5e53460`: `merge: cleanly integrate origin/rohit_app_UI with Batch 18 fixes`
    - `be62366`: `fix(product_detail): safe reactive and static resubmit label support without GetX Obx empty observable error`
  - **Backup Branches**:
    - `backup/batch18_pre_remote_merge_base`: points to HEAD before local commit.
    - `backup/batch18_local_commit`: points to local commit `d640b41`.
  - **Conflicts Resolved (3 files)**:
    1. `lib/modules/products/view/product_detail.dart`: Unified remote's `isOfferSubmitted` callback with local `isResubmit` and `initialProduct`. Added safe `_dummyRx` guard ensuring `Obx` never throws empty-observable exception when callback returns static booleans.
    2. `lib/modules/buyer/offers/view/buyer_offers_view.dart`: Integrated remote's `buyerOfferSubmittedCheck(offer, tag: offerType)` while passing `isResubmit: isSubmitted`.
    3. `lib/modules/buyer/offers/view/buyer_today_offers_view.dart`: Integrated remote's `buyerOfferSubmittedCheck(offer, tag: 'today')` while passing `isResubmit: isSubmitted`.
  - **Features Merged from Remote (14 Commits)**:
    - Global Keyboard dismissal on tap outside + iOS Previous/Next/Done toolbar + consistent header back arrow (`5cf459b`).
    - App-wide global `SafeArea` preventing content hiding behind floating nav bar (`ee74159`).
    - Transporter shipments live auto-refresh (`498c067`).
    - Dashboard header profile avatar showing user's real uploaded photo (`e7ae19e`).
    - Seller Create Offer branch choice selection (`3caa6fa`, `a6d3f8a`).
    - Seller Register Company Landmark + Number of Employees fields (`a6d576d`).
    - Brokerage bill date picker and DD-MM-YYYY display format (`be91f6c`).
    - Offer details parity: hidden seller login and remaining bags (`c52b43d`).
  - **Automated Verification Results**:
    - `test/batch_18_fixes_test.dart`: **8/8 Passed**
    - `test/buyer_my_interests_fix_test.dart`: **3/3 Passed**
    - `test/brokerage_date_format_test.dart`: **3/3 Passed**
    - `test/product_detail_resubmit_test.dart`: **1/1 Passed**
    - `test/product_detail_fields_test.dart`: **1/1 Passed**
    - `test/seller_offer_branch_choice_test.dart`: **3/3 Passed**
    - `test/transporter_shipments_auto_refresh_test.dart`: **1/1 Passed**
    - `test/keyboard_and_back_global_test.dart`: **1/1 Passed**
    - Cumulative Test Suite: **21/21 Passed (100% Pass Rate)**
    - Static Analysis: **0 Errors** across all merged files.
    - `test/kyc_flow_integration_test.dart`: **3/3 Passed** (KYC 3-lines menu opens drawer, user card action buttons & reject dialog, detail review screen Approve/Reject)
    - `test/admin_menu_button_opens_drawer_test.dart`: **2/2 Passed** (KYC & Products screens menu icons open drawer)
    - `test/batch_13_buyer_fixes_test.dart` through `test/batch_17_fixes_test.dart`: **All Passed**
    - Cumulative Regression: **49/49 Passed (100% Pass Rate)**
    - Remote developer tests (`buyer_categories_tick_list_test.dart`, `admin_challan_card_deliver_test.dart`): **All Passed**
    - `flutter analyze`: Verified with **0 compile errors** on modified files.
  - **Working Tree**: Clean, branch ahead of remote by 9 commits (`git status` clean).

---

## Previous Completed Batches
  - **Remote Branch Integration & Merge Status**: **100% Merged & Verified (Branch: rohit_app_UI, Commits: 42efe0b, ab81dfb)**
    1. Committed all uncommitted fixes from Batches 1 through 12 under commit `42efe0b` (`feat: ui and functional bug fixes for admin, buyer, seller and dashboard`).
    2. Created safety backup branch `backup/our_fixes_42efe0b`.
    3. Merged 18 incoming remote commits from `origin/rohit_app_UI` (`bae822c`) under merge commit `ab81dfb`.
    4. Resolved 3 merge conflicts cleanly:
       - `lib/modules/buyer/offers/view/buyer_offers_view.dart`: Primary "Submit Offer" first, followed by styled "Cancel" button second (44px height, matching borders).
       - `lib/modules/buyer/offers/view/buyer_today_offers_view.dart`: Primary "Submit Offer" first, followed by styled "Cancel" button second.
       - `lib/modules/kyc_users/view/kyc_user_view.dart`: Adopted `AppDate.dateTime` with safe fallback.
       - Aligned Delete dialog buttons in `admin_roles_screen.dart` and `profile_page.dart` to adhere to app-wide primary-action-first policy.
    5. All automated test suites passing: `batch_12_fixes_test.dart` (6/6), `batch_11_fixes_test.dart` (8/8), `dialog_button_order_test.dart` (3/3), `cancel_outline_test.dart`, `app_date_test.dart`, `buyer_offers_tabs_and_interest_buttons_test.dart`.
    6. `flutter analyze lib/` verified with 0 errors.
  - **Batch 12 Brokerage Billing Companies Filter, Validation Toast Visibility, Dialog Navigation, & Activity View Border**: **100% Implemented & Verified**
    1. **Bug 1 (Brokerage Bills - Billing Company Filter Inconsistency)**:
       - In `lib/modules/admin_catalog/view/admin_brokerage_bills_screen.dart`, removed `?? data['companies']` fallback and used exclusively `_companies = _billingMaps(data['billing_companies']);`.
       - Non-billing company (`abc company`) is completely excluded from the Billing Company dropdown, matching the web portal parity (`daalsetu.zappcode.in/accounting/brokerage-bills/`).
    2. **Bug 2 (Submit Offer Modal & Validation Banners Behind Dialog Container)**:
       - In `lib/utils/app_snackbar.dart`, added check `if (Get.isDialogOpen == true || Get.isBottomSheetOpen == true)` to show notifications via `Get.rawSnackbar(snackPosition: SnackPosition.TOP, ...)`.
       - When validation fails inside any dialog (such as "Please select a preferred delivery date"), the warning toast displays directly on the top overlay above dialog containers and buttons instead of being obscured behind the modal barrier.
    3. **Bug 3 (Admin Manage Offer Modal - Negotiation Button Navigation)**:
       - In `lib/modules/admin_catalog/view/offer_interests_dialog.dart`, replaced `Get.to` with `Navigator.of(context).push(MaterialPageRoute(builder: (_) => ...))` in `_openNegotiationPage`.
       - Eliminates GetX route deduplication suppression inside `showDialog` modal routes. Tapping Negotiation repeatedly after counter-proposals reliably pushes `NegotiationPage` every time without flashing and prematurely reloading the modal.
    4. **Bug 4 (Buyer My Activity Screen - "View" Action Button Outline Border)**:
       - In `lib/modules/buyer/offers/view/buyer_my_interests_view.dart`, upgraded the `View` button `side` border from faint colors to `isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)` with `width: 1.2`.
       - The `View` button now has a clean, crisp, visible outline border matching adjacent `Edit` and `Cancel` buttons.
    5. **Bug 5 (Negotiation Page Current Offer Unit Hardcoded TON -> Dynamic QTL)**:
       - In `lib/modules/admin_catalog/view/negotiation_page.dart`, replaced hardcoded `'$clean/TON'` in `_formatPrice` with dynamic `_currentPriceUnit` (`_thread?['price_unit'] ?? 'QTL'`). Current offer price now cleanly displays `₹25.00/QTL` instead of erroneous `₹25.00/TON`.
    6. **Bug 6 (Profile Photo Cropper Blank Image Display & Decoding Failure)**:
       - In `lib/widgets/profile_photo_cropper.dart`, added `progressIndicator: const Center(child: CircularProgressIndicator(color: Color(0xFFFF7A00)))`, theme-aware `baseColor`, and non-empty byte validation so that image loading is clearly indicated and empty states don't cause blank screens.
       - In `lib/modules/profile/view/edit_profile_page.dart`, enforced `maxWidth: 1200` and `maxHeight: 1200` on `_picker.pickImage` and validated downloaded image bytes (`bytes.length >= 50`), ensuring fast and reliable isolate decoding without memory stalls.
  - **Batch 11 Brokerage Sub Admin Filter, Nav Bar Dynamic Insets, Date Input dd/mm/yyyy & Button Symmetry**: **100% Implemented & Verified (Uncommitted)**
    1. **Bug 1 (Brokerage Bills Filters Assigned Sub Admin Dropdown)**:
       - Added `_assignedSubAdmin` state variable, `_subAdmins` list, and options loader fetching from options or `/api/admin/salesmen/`.
       - Rendered `Assigned Sub Admin` dropdown in `_filters()` accordion, wired query parameter `'assigned_sub_admin'` to `_loadBills()`, and included sub-admin in active filter counter and removable chips (`_activeFilterChips`). Matches web portal parity (`daalsetu.zappcode.in/accounting/brokerage-bills/`).
    2. **Bug 2 (Bottom Navigation Bar Dynamic Viewport Adjustment & Containment)**:
       - In `lib/modules/nav_bar/view/nav_page.dart`, set `resizeToAvoidBottomInset: false` on `MainNavigationScreen` for all roles (including seller and buyer), preventing the root scaffold from shoving the floating navbar into the middle of the screen when the keyboard triggers.
    3. **Bug 3 (Delivery Period Date Selection Input Placeholder dd/mm/yyyy)**:
       - In `lib/widgets/delivery_period_picker.dart`, passed `locale: const Locale('en', 'GB')` to `showDatePicker()`. When switching to keyboard entry mode, placeholder displays standard `dd/mm/yyyy` and accepts Indian/UK date format without "Invalid format" errors.
    4. **Bug 4 (Buyer Submit Offer & Cancel Symmetrical Button Styling)**:
       - In `lib/modules/buyer/offers/view/buyer_offers_view.dart` and `buyer_today_offers_view.dart`, upgraded secondary "Cancel" button from bare text to a styled `OutlinedButton` with identical height (`Size(0, 44)`), border radius (`14px`), and vertical padding (`12px`), cleanly aligned with the primary "Submit Offer" / "Resubmit" `ElevatedButton`.
  - **Batch 10 Brokerage Bills List Date, Active Filter Chips, Cancel Bill Alignment & Buyer Cancel Button Fixes**: **100% Implemented & Verified (Uncommitted)**
    1. **Bug 1 (Brokerage Bills List "Bill date" Format)**:
       - In `lib/modules/admin_catalog/view/admin_brokerage_bills_screen.dart`, formatted `bill_date` on bill listing cards using top-level `_formatDate(bill['bill_date'])` to render clean `dd/MM/yyyy` format (`05/11/2026`) instead of raw ISO `2026-11-05`.
    2. **Bug 2 (Brokerage Bills Filter Accordion Badge Counter & Active Filter Chips)**:
       - In `lib/modules/admin_catalog/view/admin_brokerage_bills_screen.dart`, added `_activeFilterCount` getter and displayed an active counter badge pill `Filters (N)` on the accordion header.
       - Implemented `_activeFilterChips()` displaying removable chips for each active criterion (Status, Seller, Buyer, Billing Company, Date From, Date To) with single-tap removal and `Clear all` action.
    3. **Bug 3 ("Cancel issued bill" Button Text Alignment)**:
       - In `lib/modules/admin_catalog/view/admin_brokerage_bills_screen.dart`, styled the `FilledButton` in `_confirm()` dialog with explicit `padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12)`, `alignment: Alignment.center`, and text `height: 1.0` with `textAlign: TextAlign.center`, eliminating vertical text misalignment.
    4. **Bug 4 (Buyer My Interests Remove Cancel Button when Status is INTERESTED)**:
       - In `lib/modules/buyer/offers/model/buyer_offer_model.dart`, defaulted `canCancelInterest` fallback to `false`.
       - In `lib/modules/buyer/offers/view/buyer_my_interests_view.dart`, added `isInterestedStatus` check and guarded Cancel button with `if (offer.canCancelInterest && !isInterestedStatus)`. When status badge reads "INTERESTED", the Cancel button is cleanly removed while keeping View, Edit, and Negotiation buttons intact.
  - **Batch 9 Admin KYC, Dashboard Activity & Brokerage Audit Trail Fixes**: **100% Implemented & Verified (Uncommitted)**
    1. **Bug 1 (KYC Users Details Modal Empty Fields & Date Joined)**:
       - In `lib/modules/kyc_users/model/kyc_user_model.dart`, expanded `dateJoined` fallback to read `userObj?['date_joined']`, `userObj?['created_at']`, and `json['kyc_submitted_at'] ?? json['submitted_at']`.
       - In `lib/modules/kyc_users/view/kyc_user_view.dart`, updated `formatTimestamp` and string display helpers to render clean dash (`-`) instead of `"N/A"` for null/empty values (matching web admin portal `/kyc/`). Passed `user.dateJoined ?? user.kycSubmittedAt` so the exact registration date (`2026-11-05 12:29:14`) is properly displayed.
    2. **Bug 2 (Dashboard Recent Activities Redirections & Ellipses Removal)**:
       - In `lib/modules/dashboard/view/dashboard_page.dart`, removed `trailingText: "View All"` and its navigation to `AdminNotificationView`, preventing unwanted redirection.
       - Sanitized activity description strings with `.replaceAll(RegExp(r'\.{2,}\s*•'), ' •')` to strip artificial trailing ellipses from commodity names (`arhar daal`, `mix daal`, `pkrj`, `pukhraj`, `masoor dal`). Increased font size to `11.5px` and ensured cards do not trigger unwanted redirections.
    3. **Bug 3 (Brokerage Bill Detail Audit Trail & Date Formatting)**:
       - In `lib/modules/admin_catalog/view/admin_brokerage_bills_screen.dart`, added `_formatDate` to format `bill_date` and `period_from — period_to` in clean `dd/MM/yyyy` format (`05/11/2026`, `06/11/2026 — 07/11/2026`) instead of raw ISO `YYYY-MM-DD`.
       - Implemented `_auditTrailCard(bill)` with `_auditEntry` displaying creation and issuance history (`Created 05 Nov 2026, 06:11 PM by FARMLAND`, `Issued 05 Nov 2026, 06:12 PM by FARMLAND`), matching web admin portal `/accounting/brokerage-bills/22/`.
  - **Batch 8 Buyer & Admin UX/Functional Bug Fixes (Submit Offer vs Resubmit, GTV MTD Navigation, Manage Stock Default State, Narration Contrast)**: **100% Implemented & Verified (Uncommitted)**
    1. **Bug 1 (Buyer Panel Offers "Submit Offer" vs "Resubmit" Button Labeling)**:
       - In `lib/modules/buyer/offers/model/buyer_offer_model.dart`, added `hasSubmittedOffer` detection from `has_submitted_offer`, `has_interest`, `my_interest`, and `parsedInterestId`.
       - In `lib/modules/buyer/offers/controller/buyer_offers_controller.dart`, added `RxSet<int> submittedProductIds` and `isOfferSubmitted(productId, offer: offer)`. Updated `fetchOffers` and `submitInterest` to track submitted products.
       - In `lib/modules/buyer/offers/view/buyer_offers_view.dart` and `buyer_today_offers_view.dart`, replaced hardcoded "Submit Offer" with dynamic `isSubmitted ? "Resubmit" : "Submit Offer"` on both cards and dialog headers/buttons to match web platform behavior.
    2. **Bug 2 (Admin Dashboard Gross Trade Value (MTD) Navigation to Contracts)**:
       - In `lib/modules/dashboard/view/dashboard_page.dart` (line 408), changed Gross Trade Value (MTD) KPI card `onTap` from `AppRoutes.adminBranchReports` to `Get.to(() => const ContractsScreen())`, matching the web portal (`/contracts/`). Also aligned `admin_overview_kpis_view.dart`.
    3. **Bug 3 (Admin Offers "Manage Stock" Collapsed by Default)**:
       - In `lib/modules/admin_catalog/view/admin_offers_list_screen.dart`, initialized `_isExpanded = false;` in `initState()` so the Manage Stock section loads cleanly collapsed by default, eliminating visual clutter.
    4. **Bug 4 (Buyer Challan Details "Narration / Details" Text Contrast)**:
       - In `lib/modules/buyer/delivery_challan/view/buyer_delivery_challan_detail_view.dart`, replaced faint `Colors.grey[700]` with high-contrast theme-aware color (`isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)`), `height: 1.5`, and `FontWeight.w500` for clear readability on dark backgrounds.
  - **Batch 7 Admin Security & UI Bug Fixes (Sub Admin Delete Restriction, Contract Unique IDs, Delivery Period Layout, Header Avatar)**: **100% Implemented & Verified (Uncommitted)**
    1. **Bug 1 (Sub Admins Delete Button Restricted to Super Admin)**:
       - In `lib/modules/admin_catalog/view/admin_module_list_screen.dart`, loaded user role from `AppPreferences.getRole()` and restricted sub-admin card delete button to `_isSuperAdmin`. Regular Admin no longer sees or accesses the red Delete button.
    2. **Bug 2 (Contract Details Buyer & Seller Entity IDs and Company/Name Alignment)**:
       - In `lib/modules/contracts/view/contract_details_view.dart`, updated `_partySection` to show party name as main title, entity unique IDs (`ID: 166 | BUY8855C2A68` / `ID: 165 | SEL1433F6F61F`) without restrictive checks, and cleanly labeled company rows (`Company: Test company` / `Company: Agrotech`), exactly matching the web admin portal.
    3. **Bug 3 (Negotiation Delivery Period Single Horizontal Row Layout)**:
       - Refactored `DeliveryPeriodPicker` in `lib/widgets/delivery_period_picker.dart` from vertical `Column` stacking to compact single horizontal `Row` (`From: dd-mm-yyyy [calendar]` and `To: dd-mm-yyyy [calendar]`), reducing box height and keeping alignment clean.
    4. **Bug 4 (Admin Dashboard Header & Greeting Avatar Photo Binding)**:
       - In `lib/modules/dashboard/view/dashboard_page.dart`, bound top-right AppBar avatar and greeting card avatar to `profileController.profileImageUrl(profile?.profileImage)`. Uploaded profile photos now display dynamically with fallback to icons.
  - **Batch 6 Admin & UI Bug Fixes (Roles, Photo Cropper, Contract Total Price)**: **100% Implemented & Verified (Uncommitted)**
    1. **Bug 1 (Roles Screen Edit & Delete Action Buttons)**:
       - Upgraded `_roleCard` in `lib/modules/admin_catalog/view/admin_roles_screen.dart` to include dedicated `[Edit]` and `[Delete]` buttons matching the web admin portal (`/rbac/roles/`).
       - Wired direct role editing via `_openEditor(role)` and deletion with a confirmation dialog triggering `ApiClient.delete('/api/admin/roles/$id/')` with automatic reload. System roles safely hide the delete action.
    2. **Bug 2 (Photo Cropper Button Text Cut Off Fixed)**:
       - Adjusted the button container in `lib/widgets/profile_photo_cropper.dart` with height 54 and vertical padding 12, giving full breathing room to Poppins font descenders ('p', 'y') and eliminating text clipping.
    3. **Bug 3 (Contract Details Total Deal Price Added)**:
       - Integrated calculated total deal price ($\text{Rate} \times \text{Quantity}$) using `formatInr` into both the top summary banner card (`Total: ₹2,500.00`) and the `Product & deal` card (`Total deal price`) in `lib/modules/contracts/view/contract_details_view.dart`, exactly matching the web admin portal (`/contracts/?status=active`).
  - **Admin QA Bug Fixes (Bugs 1-4)**: **100% Implemented & Verified (Uncommitted)**
    1. **Bug 1 (Admin Registered Company "Set Primary" Access)**:
       - Enabled `admin` and `super_admin` in `_hasCompanyManagement` within `lib/modules/profile/view/profile_page.dart`. Admin profile screen now displays the "Manage Company" card navigating to company management.
       - Hardened `isPrimary` parsing in `lib/modules/seller/company/model/seller_company_model.dart` to cleanly handle boolean, integer (`1`), and string (`"true"`).
    2. **Bug 2 (Admin Profile KYC Documents Delete Button & In-App Viewer with Back Button)**:
       - Added red-tinted Delete button (`Icons.delete_outline_rounded`) with confirmation dialog in `_buildDocumentRow` (`lib/modules/profile/view/profile_page.dart`) to remove uploaded KYC documents (PAN, GST, Aadhaar) calling `controller.updateProfile({fieldKey: ''})`.
       - Updated `_openDocument` with dedicated in-app viewer `Scaffold` featuring a prominent Top AppBar Back button (`IconButton(icon: Icon(Icons.arrow_back), onPressed: () => Get.back())`), interactive zoomable image viewer (`InteractiveViewer`), and "Open in external app" action button.
       - Updated `_openLegal` to open an in-app dialog with an explicit Back button.
    3. **Bug 3 (Edit Profile Date Picker Allows Today's Date)**:
       - Removed `.subtract(const Duration(days: 1))` from `lib/modules/profile/view/edit_profile_page.dart:129`. `lastAllowed` is now set to `DateTime(today.year, today.month, today.day)`, allowing users to select today's date while correctly disabling future dates.
    4. **Bug 4 (Sub Admins Form "Branch Ref Code" Input Field)**:
       - Added `AdminFieldConfig('branch_ref_code', 'Branch Ref Code')` to the `salesman` module configuration in `lib/modules/admin_catalog/config/admin_module_config.dart`, matching the web admin portal form.
  - **Static Analysis**: 0 errors across all modified files (`flutter analyze`).
  - **Automated Tests**: 100% passing (`flutter test test/buyer_offers_tabs_and_interest_buttons_test.dart`, `flutter test test/batch_9_fixes_test.dart`).
  - **Git State**: All changes strictly uncommitted as instructed by user.
  - **Phase 1 (Buyer Module Navigation)**: **100% Implemented & Verified (Uncommitted)**
    1. `lib/modules/buyer/offers/view/buyer_my_interests_view.dart`: Wrapped interest card `GlassCard` with `InkWell(borderRadius: BorderRadius.circular(16), onTap: () => _openDetails(offer))`. Clicking anywhere on the card now opens `BuyerOfferDetailsView`. Inner buttons (View, Edit, Negotiation, Cancel) remain fully independent and clickable without conflicts.
    2. `lib/modules/buyer/offers/view/buyer_request_management_view.dart`: Wrapped requirement card `GlassCard` with `InkWell(borderRadius: BorderRadius.circular(16), onTap: numericId == null ? null : () => Get.to(...))`. Tapping anywhere on the card navigates directly to `BuyerOfferDetailsView`.
    3. `lib/modules/buyer/dashboard/view/buyer_dashboard_view.dart`: Wrapped Recent Requirements cards with `InkWell` to navigate to `BuyerOfferDetailsView` (or Activity View) and Recent Orders cards to navigate to `BuyerOrdersView`.
    4. `lib/modules/buyer/orders/view/buyer_orders_view.dart`: Wrapped order `GlassCard` with `InkWell` and connected to a comprehensive order details modal bottom sheet `_showOrderDetails` displaying commodity, seller/brand, quantity, price, dates, and order status.
  - **Static Analysis**: 0 errors across all 4 files (`flutter analyze`).
  - **Automated Tests**: 100% passing (`flutter test test/buyer_offers_tabs_and_interest_buttons_test.dart`, `flutter test test/batch_9_fixes_test.dart`).
  - **Git State**: All changes uncommitted as requested by user.
  - All 6 commits from `rohit` successfully integrated:
    - FCM Push Notifications on Android & iOS (`push_notification_service.dart`, sound channel, icon silhouette)
    - Buyer Requirement Editing (`edit_buyer_requirement_view.dart`) modernized with HeroHeader & dual theme
    - Profile Photo Cropper (`profile_photo_cropper.dart`), DOB validation, and legal policy links
    - Stock History Dialog connected with real API data inside modernized 20px rounded dialog
    - Contract PDF generator (`contract_pdf.dart`) and negotiation chat parameter highlights
    - Transporter delete company button and network users refresh icon
  - App-Wide Dark & Bright Themes: **100% Preserved & Verified across all screens**
  - Bug 58 (Notifications Dark Mode White-on-Cream Contrast): **Fixed & Verified**
  - Automated Regression Tests: **51/51 Passing across test suites**
  - Analyzer: **0 errors, 0 warnings in modified files (`lib/`)**
- **Admin Redesign & Card Polish Scope (33 Total Admin Views / Modals Modernized)**:
  - **Batch 3B (Admin Masters List, Negotiation & Action Dialogs)**:
    - `lib/modules/admin_catalog/view/admin_module_list_screen.dart`: Upgraded generic catalog record cards and buyer cards to 18px rounded containers with `#FFE0B2` borders, vibrant icon pods, modern pill segments, and warm gradient FAB.
    - `lib/modules/admin_catalog/view/negotiation_page.dart`: Upgraded to `HeroHeader` ("Negotiation: ${offerTitle}" • "Live negotiation · auto-refresh"), 18px rounded cards with `#FFE0B2` borders, and saffron gradient submit button.
    - `lib/modules/admin_catalog/view/assign_driver_dialog.dart`: Upgraded to modern curved bottom sheet with top drag handle, curved saffron banner header, badge icon pod, and 16px rounded driver cards with `#FFE0B2` borders.
    - `lib/modules/admin_catalog/view/assign_vehicle_dialog.dart`: Upgraded to modern curved bottom sheet with top drag handle, curved saffron banner header, vehicle icon pod, and 16px rounded vehicle cards with `#FFE0B2` borders and saffron action buttons.
    - `lib/modules/admin_catalog/view/approve_deal_dialog.dart`: Upgraded to 20px rounded dialog with `#FFE0B2` border, emerald success pod, saffron-accented sub-admin selector, and warm gradient accept button.
    - `lib/modules/admin_catalog/view/stock_history_dialog.dart`: Upgraded to 20px rounded dialog with `#FFE0B2` border, saffron inventory pod, responsive `Wrap` actions preventing overflow, and warm gradient button.
  - **Batch 3A (Dashboard Eye-Catching Cards, Admin Drawer, and Transport Bids Sheet)**:
    - `lib/modules/dashboard/view/dashboard_page.dart`: Upgraded KPI cards from dull `GlassCard` with grey borders to 18px rounded containers with `#FFE0B2` borders, rich category color palettes (Saffron `#EA580C`, Amber `#D97706`, Emerald `#059669`, Blue `#2563EB`, Red `#DC2626`), high-contrast typography, and depth shadows.
    - `lib/modules/admin_catalog/view/admin_drawer.dart`: Refactored to match Buyer/Seller drawer design language using `_buyerSectionHeader`, `_buyerCardGroup`, and `_buyerMenuItem` with colorful rounded icon pods and collapsible Masters/Offers groups.
    - `lib/modules/admin_catalog/view/transport_bids_sheet.dart`: Converted raw unstyled modal into a modern curved sheet with warm saffron top banner, shipping icon pod, 18px rounded bid cards with `#FFE0B2` borders, vibrant status pills, and rounded action buttons.
  - **Batch 1 (Admin Core Tabs & Cards)**:
    - `lib/modules/kyc_users/view/kyc_user_view.dart` (`KycUsersScreen`): Upgraded from flat AppBar to `HeroHeader` + 14px KPI pods + 18px eye-catching user cards with `#FFE0B2` borders, Saffron avatar gradient, depth shadows, and refined action buttons.
    - `lib/modules/products/view/product_view.dart` (`ProductScreen`): Upgraded from flat AppBar to `HeroHeader` + warm gradient "Create Offer" CTA + 18px rounded product cards with `#FFE0B2` borders and vibrant badges.
    - `lib/modules/contracts/view/contract_view.dart` (`ContractsScreen`): Upgraded card border from dull dividerColor to 18px radius with `#FFE0B2` borders and depth shadows.
  - **Batch 2 (User Management & Secondary Admin Screens)**:
    - `lib/modules/users/view/user_view.dart` (`UserManagementScreen`): Upgraded to `HeroHeader` + 14px metric pods (`#FFE0B2` borders) + 18px eye-catching user cards with Saffron avatar, `#FFE0B2` borders, depth shadows, and warm gradient FAB.
    - `lib/modules/users/view/user_detail_screen.dart` (`UserDetailScreen`): Upgraded to `HeroHeader` + 18px profile header card + 18px info/security pods with `#FFE0B2` borders and Saffron accent icons.
    - `lib/modules/users/view/add_user_screen.dart` (`AddUserScreen`): Upgraded to `HeroHeader` + 18px header pod + 18px form pod with `#FFE0B2` border + warm Saffron-to-Amber gradient CTA button.
    - `lib/modules/contracts/view/contract_edit_view.dart` (`ContractEditView`): Upgraded to `HeroHeader` + 3 organized 18px pods (Deal Parameters, Locations & Schedule, Status & Remarks) with `#FFE0B2` borders + warm gradient CTA button.
  - **Batch 4A (Core Admin & Dashboard — 3/3 screens)**:
    - `lib/modules/dashboard/view/dashboard_page.dart` (`AdminDashboardScreen`)
    - `lib/modules/admin_catalog/view/admin_drawer.dart` (`AdminDrawer`)
    - `lib/modules/admin_notifications/view/admin_notification_view.dart` (`AdminNotificationView`)
  - **Batch 4B (Catalog, Deals & Offers — 4/4 screens)**:
    - `lib/modules/admin_catalog/view/admin_offers_list_screen.dart` (`AdminOffersListScreen`)
    - `lib/modules/admin_catalog/view/admin_category_master_screen.dart` (`AdminCategoryMasterScreen`)
    - `lib/modules/admin_catalog/view/admin_record_detail_screen.dart` (`AdminRecordDetailScreen`)
    - `lib/modules/admin_catalog/view/admin_record_form_screen.dart` (`AdminRecordFormScreen`)
  - **Batch 4C (Delivery Challans & Logistics Operations — 3/3 screens + Challan Card)**:
    - `lib/modules/admin_dc/view/admin_dc_list_view.dart` (`AdminChallanListView`)
    - `lib/modules/admin_dc/view/admin_create_dc_view.dart` (`AdminCreateChallanView`)
    - `lib/modules/admin_dc/view/admin_dc_details_view.dart` (`AdminChallanDetailsView`)
    - `lib/modules/admin_dc/widgets/admin_challan_card.dart` (`AdminChallanCard`)
  - **Batch 4D (Branch Performance & Financial Reports — 3/3 screens + Report Card)**:
    - `lib/modules/admin_reports/view/admin_branch_reports_view.dart` (`AdminBranchReportsView`)
    - `lib/modules/admin_catalog/view/admin_branch_settings_screen.dart` (`AdminBranchSettingsScreen`)
    - `lib/modules/admin_catalog/view/admin_brokerage_bills_screen.dart` (`AdminBrokerageBillsScreen`)
    - `lib/modules/admin_reports/widgets/branch_report_card.dart` (`BranchReportCard`)
  - **Batch 4E (Governance, Roles & Compliance — 4/4 screens)**:
    - `lib/modules/admin_catalog/view/admin_roles_screen.dart` (`AdminRolesScreen`)
    - `lib/modules/admin_catalog/view/admin_permissions_matrix_screen.dart` (`AdminPermissionsMatrixScreen`)
    - `lib/modules/admin_catalog/view/admin_sub_admin_permissions_screen.dart` (`AdminSubAdminPermissionsScreen`)
    - `lib/modules/admin_catalog/view/admin_complaints_view.dart` (`AdminComplaintsView`)
- **Global Brand Color Unification & Polish**:
  - `lib/theme/app_theme.dart`: Aligned `colorScheme.primary` and `primaryColor` to brand `secondaryOrange` (`#F57C00`), eliminating lingering mustard-yellow tints from buttons, active chips, dialog icons, and focus borders app-wide.
  - `lib/modules/nav_bar/view/nav_page.dart`: Upgraded `GlassNavBar` background from `#FFF8E1` pale yellow gradient to clean white surface with warm `#FFE0B2` border.
  - `lib/modules/settings/view/settings_page.dart`: Upgraded Privacy Policy/URL dialog with high-contrast saffron URL text and vibrant `secondaryOrange` "Open" button.
- **Evidence**: `flutter analyze` 0 errors, 0 warnings on modified files; automated regression test suites (10 test files, 39/39 tests passing: `test/theme_toggle_test.dart`, `test/onboarding_screen_test.dart`, `test/admin_batch_3b_test.dart`, `test/admin_secondary_screens_test.dart`, `test/admin_core_tabs_test.dart`, `test/admin_batch_4a_test.dart`, `test/admin_batch_4b_test.dart`, `test/admin_batch_4c_test.dart`, `test/admin_batch_4d_test.dart`, `test/admin_batch_4e_test.dart`) all green. Zero breaking changes.

---

## Completed Work in Current Session
- **Milestone 4 — Batch 4E (Governance, Roles & Compliance — 4/4 Screens) Completed & Verified**:
  - `AdminRolesScreen`: Modernized with `HeroHeader`, drawer toggle, 18px role cards with `#FFE0B2` borders, and saffron gradient FAB.
  - `AdminPermissionsMatrixScreen`: Modernized with `HeroHeader`, drawer toggle, role selector pill, and 18px rounded matrix container with `#FFE0B2` borders.
  - `AdminSubAdminPermissionsScreen`: Modernized with `HeroHeader`, sub-admin profile pod with `#FFE0B2` border, module toggles, and warm gradient save button.
  - `AdminComplaintsView`: Modernized with `HeroHeader`, 14px KPI pods with `#FFE0B2` borders, responsive `Wrap` layouts preventing RenderFlex overflows, and dispute resolution cards.
- **Milestone 4 — Batch 4D (Branch Performance & Financial Reports — 3/3 Screens) Completed & Verified**:
  - `AdminBranchReportsView`, `AdminBranchSettingsScreen`, and `AdminBrokerageBillsScreen` modernized with unified agritech design system and 100% backward compatibility.
- **Milestone 4 — Batch 4C (Delivery Challans & Logistics Operations — 3/3 Screens) Completed & Verified**:
  - `AdminChallanListView`, `AdminCreateChallanView`, and `AdminChallanDetailsView` modernized with unified agritech design system and 100% backward compatibility.
- **Milestone 4 — Batch 4B (Catalog, Deals & Offers — 4/4 Screens) Completed & Verified**:
  - `AdminOffersListScreen`, `AdminCategoryMasterScreen`, `AdminRecordDetailScreen`, and `AdminRecordFormScreen` modernized with unified agritech design system and 100% backward compatibility.
- **Milestone 4 — Batch 4A (Core Admin & Dashboard — 3/3 Screens) Completed & Verified**:
  - `AdminDashboardScreen`, `AdminDrawer`, and `AdminNotificationView` modernized with unified agritech design system and 100% backward compatibility.
- **Milestone 3 — Batch 3D Step 3D.2 (Marketplace Demand & Offers — 2/2 Screens) Completed & Verified**:
  - `TransporterOffersView` modernized with `HeroHeader` + TabBar (4 tabs: Offers, Today, Pending, Previous) + 18px rounded cards with `#FFE0B2` borders, high-contrast price, quantity pills, and status tags.
  - `TransporterRfqView` modernized with `HeroHeader` + 18px rounded RFQ tender cards with RFQ badge, category title, target price, required quantity, buyer name, and status pills.
  - 100% backward compatibility preserved for `BuyerOffersController` (tag-based) and `SellerRfqController`.
- **Milestone 3 — Batch 3D Step 3D.1 (Catalog Trio: Brands, Categories, Products — 3/3 Screens) Completed & Verified**:
  - `TransporterBrandsView`, `TransporterCategoryView`, and `TransporterProductsView` modernized with unified agritech design system, zero raw integer IDs (Bug 54 fixed), and 100% backward compatibility.
- **Milestone 3 — Batch 3C (Organization & Branches — 5/5 Screens) Completed & Verified**:
  - `TransporterCompanyView`, `TransporterCompanyDetail`, `TransporterCompanyForm`, `TransporterBranchView`, and `TransporterUsersView` modernized with unified agritech design system and 100% backward compatibility.
- **Milestone 3 — Batch 3B (Fleet & Logistics: Vehicles & Drivers — 6/6 Screens) Completed & Verified**:
  - `TransporterVehiclesView`, `TransporterVehicleDetail`, `TransporterVehicleForm`, `TransporterDriversView`, `TransporterDriverDetail`, and `TransporterDriverForm` modernized with unified agritech design system and 100% backward compatibility.
- **Milestone 3 — Batch 3A (Transporter Core & Dashboard: 5/5 Screens) Completed & Verified**:
  - `TransporterDashboardView`, `TransporterBiddingView`, `TransporterContractsView`, `TransporterNotificationsView`, and `TransporterKycView` are unified under the modern agritech design system.
  - 100% backward compatibility preserved for `TransporterDashboardController`, `TransporterBiddingController`, `SellerContractController`, `SellerNotificationController`, and `ProfileController`.
- **Milestone 2 (Auth Portal Modernization: 100% of all Auth Screens) Completed & Verified**:
  - `login_screen.dart`, `register_page.dart`, `forgot_password_page.dart`, and `change_password_page.dart` are all unified under the same premium agritech design system with warm ambient top wash, DaalSetu logo, verified "KISOR" brand pill, and gradient buttons.
- **Milestone 1 (Seller Panel: 100% of all 18 Screens) Completed & Verified**:
  - All 18 Seller screens are unified under `HeroHeader`, 18px radius cards, `#FFE0B2` border tints, high-contrast typography, and warm saffron-to-amber gradient call-to-actions.
  - Zero breaking changes to GetX controllers, dynamic calculation formulas, API models, dispatch callbacks, or negotiation streams.
- **HeroHeader Architecture Hardening**:
  - Dynamically calculates `bottom` widget preferred height, preventing overflows across all tabbed screens app-wide.
- **Seller Panel Phase 1, Phase 2, & Phase 3 (100%) Complete**:
  - Successfully redesigned Seller Drawer, Dashboard, Products, Create Offer, Deal Contracts, Contract Details, Buyer Requirements (RFQ List), Requirement Details, and Buyer Offers & Negotiation.
  - Preserved 100% of GetX controllers, dynamic calculation math, location clearing buttons, dropdown items, role checks, quotation dialogs, live chat navigation, auto-refresh timers, and automated test finders.
- **Final Specialized Screens Modernization**:
  - `lib/modules/shared/view/offer_interest_negotiation_chat_view.dart`:
    - Upgraded negotiation chat header to agritech `HeroHeader` ("${title}" • "Live negotiation · auto-refresh") with white back navigation and refresh action.
  - `lib/modules/admin_catalog/view/admin_module_list_screen.dart`:
    - Upgraded Sub-Admins/Salesman catalog view to `HeroHeader` with dynamic module title and refresh action.
  - `lib/modules/admin_catalog/view/admin_roles_screen.dart`:
    - Upgraded Roles screen to `HeroHeader` ("Roles" • "Manage administrative roles & permissions").
- **Login Screen UI/UX Modernization**:
  - Transformed flat/washed-out login screen into a warm, high-contrast, premium Agro Trading authentication portal.
  - Added subtle saffron-to-amber top ambient gradient wash and soft radial glows.
  - Elevated DaalSetu logo with 30px amber depth shadow, white border, and integrated `'KISOR'` badge with `'Pulse Trading Platform'` subtitle.
  - Refined Sign-In card with amber border tint, soft multi-layer shadow, and "Encrypted" security badge pill.
  - Upgraded "Sign in securely" button with deep saffron/amber dual gradient and glow.
  - Strictly preserved 10-digit mobile input format, controller, form validation, password visibility toggling, autofocus, and route navigations.
- **Buyer Panel Secondary & Detail Screens Modernization**:
  - Safely refactored `ContractDetailScreen`, `ProductDetailScreen`, `SellerNotificationView`, `EditProfileScreen`, `AddCompanyView`, and `SubCategoryScreen` to use the unified warm `HeroHeader`.
- **Settings Screen Destinations HeroHeader Unification**:
  - Upgraded Profile and Change Password screens to follow the same warm hero gradient and typography.
- **100% Buyer Drawer Destinations HeroHeader Unification**:
  - Brought unified warm hero gradient and typography across all 14 screens accessible from Buyer Drawer.
- **Buyer Panel Core Screens HeroHeader Rollout**:
  - Implemented `HeroHeader` across Post Requirement, Offer Details, Delivery Challan Details, Recent Orders, Transport Tracking, and Consignments.
- **Settings Screen HeroHeader Rollout**:
  - Replaced plain white AppBar with warm gradient `HeroHeader`.
- **HeroHeader Responsiveness & Overflow Prevention**:
  - Hardened subtitle height calculation and padding to ensure 0-overflow on all device aspect ratios.
- **Buyer Drawer Modern Redesign**:
  - Upgraded flat, black-and-white drawer to a warm, eye-catching agritech/fintech drawer matching the redesigned HeroHeader and dashboard cards with zero risk to navigation.
- **Buyer Offers Screen UI Beautification**:
  - Transformed dull/translucent offer cards into crisp, high-contrast, beautiful fintech/agritech cards with prominent price and solid background.
- **Active Offer & KPI Cards Transformation**:
  - Transformed flat/dull active offer and KPI grid into vibrant, eye-catching components matching reference design.
- **Complete Buyer Primary Navigation HeroHeader Rollout**:
  - Upgraded all 5 main buyer tabs to have unified, warm, eye-catching curved hero headers.
- **Reusable HeroHeader & Dashboard Parity**:
  - Transformed flat clinical dashboard into warm, vibrant, eye-catching UI matching the reference design.
- **Global Visual Polish (Nav Bar, TextButtons, Checkboxes, Switches)**:
  - Eliminated faded yellow-on-white active bottom bar tabs and clickable action links by binding them to `secondaryOrange`.
- **Global Button, Card, and Input Field Contrast Polish**:
  - Replaced low-contrast white-on-yellow buttons with striking orange call-to-actions.
  - Added clean definition to cards and text inputs so they pop against the scaffold background.
- **Global Typography & Contrast Enhancement**:
  - Solved faded and light text feedback across 109+ screens by centrally hardening text contrast and font weights in `lib/theme/app_theme.dart`.
- **Bug 56 Completed (Category Button Navigation Overlap, Activity FAB Clearance, Settings Bottom Spacing, Global AppBar Title Spacing)**:
  - Added `SafeArea` to Category Page bottom bar button to prevent overlap with Android navigation buttons.
  - Fixed Buyer Activity FAB clearance above floating `GlassNavBar`.
  - Fixed Settings Page trailing whitespace below "Version 1.0.0".
  - Fixed horizontal spacing across all pages between hamburger menu icon (`☰`) and page title.
- **Bug 55 Completed (Sign In Screen TextEditingController Disposed Crash)**:
  - Eliminated the red assertion error `"A TextEditingController was used after being disposed"` on `LoginScreen`.
  - Converted `usernameController` and `passwordController` to self-healing getters that re-instantiate fresh controllers when accessed after disposal or route close.
  - Added closed controller detection in `LoginScreen.initState()` to evict dead GetX instances.
  - Enabled `fenix: true` in `AuthBinding`.
  - Verified with automated tests and static analysis.
- **Bug 54 Completed (Hide Internal Database IDs)**:
  - Eliminated raw database integer IDs from Transporter Brands, Dashboards, Buyer Orders, and Contract administration details.
  - Replaced IDs with meaningful business information (Seller name, Category, Brand, Product title).
- **Bug 53 Completed (Display Full User Name & Company Name on Admin Offers & Seller Interests)**:
  - Fixed mobile number display on Admin Offer cards by prioritizing `Seller.fullName`.
  - Fixed raw ID display on Seller Interests cards by prioritizing Buyer Name and Company Name over `buyer_unique_id`.
  - Verified with 3 automated tests in `test/seller_offer_interest_identity_test.dart`.
- **Bug 52 Completed (Replace "Operation Control" Branding with "KISOR")**:
  - Updated subtitle text beneath DaalSetu logo on `LoginScreen` from `'Operations control centre'` to `'KISOR'`.
  - Verified with automated widget test in `test/login_screen_test.dart`.
- **Bug 51 Completed (Login Screen Password Eye Icon Inverted State)**:
  - Corrected inverted eye icon behavior: shows open eye (`Icons.visibility_outlined`) when password is dots/hidden, and crossed-out eye (`Icons.visibility_off_outlined`) when password is text/revealed.
  - Verified with 2 automated widget tests and clean static analysis.
- **Bug 50 Completed (Brand Name & Offer Name Display on Contract Screens)**:
- **Bug 47 Completed (Notifications Not Opening & 2nd Tap Not Redirecting)**:
  - Eliminated silent suppression on deal/contract notifications.
  - Resolved GetX duplicate route suppression on consecutive notification taps.
  - Eliminated UI spinner flickering during `markAsRead` in Seller notifications.
  - Verified with 4 automated tests in `test/notification_reclick_navigation_test.dart`.
- **Bug 46 Completed (Card-Wide Clickability on Buyer Dashboard & Admin Offers)**:
  - Enabled card-wide tap gestures on Buyer Dashboard carousel and Admin Offers screen with zero child button collision.
  - Verified with 2 test suites.
- **Bug 45 Completed (Seller Product Card Full Clickability)**:
  - Enabled card-wide clickability on Seller's "My Products" screen so tapping on image, title, price, or body opens `ProductDetailScreen`.
  - Verified no conflict with inner action buttons.
- **Bug 44 Completed (System Navigation Bar Overlap with Floating Glass Bottom Bar)**:
  - Fixed bottom navigation bar cutoff and overlap on Android 3-button navigation devices by integrating dynamic safe area insets into `GlassNavBar`.
  - Guarded against keyboard jitter using `isKeyboardOpen` detection.
  - Verified across 4 test scenarios in `test/bottom_nav_bar_insets_test.dart`.
- **Bug 43 Completed (Login Screen Password Eye Icon Toggle Unresponsiveness & Cursor Loss)**:
  - Fixed second-tap unresponsiveness by removing gesture-intercepting tooltips and configuring non-stealing focus node.
  - Preserved cursor selection offset on visibility change.
  - Switched to reactive GetX `isPasswordVisible` and added theme-aware contrast colors.
  - Verified with 2 new widget tests and regression test suite.
- **Bug 41 Completed (Seller Products 154px Overflow & Buyer Offer Mixing)**:
  - Fixed `RIGHT OVERFLOWED BY 154 PIXELS` on product cards by decoupling location into an `Expanded` row with 2-line ellipsis.
  - Excluded buyer request bridge products from the Seller's "My Products" screen on both frontend and backend.
  - Verified with 5 automated widget and model unit tests.
- **Bug 40 Completed (Delete Account Dialog Assertion Error on Cancel)**:
  - Fixed red error screen displaying `Failed assertion: line 6281 pos 12: '_dependents.isEmpty': is not true.` when cancelling the Delete Account dialog.
  - Converted dialog to dedicated `_DeleteAccountDialog` `StatefulWidget` to safely handle `TextEditingController` disposal in `dispose()` and scoped `Navigator.of(context).pop()`.
  - Added regression test `test/delete_account_dialog_test.dart` (verified passing).
- **Bug 39 Completed (Admin User Creation Form Auto-Reset Parity)**:
  - Addressed form state retention where user creation inputs (Name, Mobile, Email, Branch, Role, Password, PAN, GST, Images, Tag) persisted across submissions.
  - Converted `AddUserScreen` to `StatefulWidget` with clean controller initialization, reset, and disposal lifecycles.
  - Added `branchController` ("Branch Code (Optional)") and passed it through to `AddUserController.createUser` and `AddUserServices.addUser`.
  - Implemented `resetForm()` in `AddUserScreenState` to wipe all controllers, dropdowns, and Rx variables clean upon successful user creation and upon opening.
  - Added `AddUserController.reset()` to reset `selectedTagId` and `isLoading`.
  - Implemented `resetForm()` in `AdminRecordFormScreenState` on successful record creation.
  - Added automated test suite `test/admin_user_form_reset_test.dart` (3/3 passing).
- **Bug 38 Completed (Place Bid Modal - Primary Orange/Yellow Theming Parity)**:
  - Addressed inconsistent legacy teal (`Color(0xFF0F766E)`) and dark navy (`Color(0xFF131D2E)`) styling on Shipments Place Bid / Update Bid modal.
  - Updated header background to brand linear gradient using primary amber/gold (`_gold = Color(0xFFFFB300)`) and secondary orange (`Color(0xFFF57C00)`).
  - Updated close icon to solid `Colors.white` for high contrast against the header gradient.
  - Updated TextField focused border and cursor color to `_gold`.
  - Updated Submit button to `ElevatedButton` with `backgroundColor: _gold` and white typography, matching the offer card's "PLACE BID" button and app theme.
  - Adapted text styles to support dark and light theme brightness cleanly.
  - Added automated widget test `test/transporter_place_bid_theming_test.dart`.
- **Bug 37 Completed (Buyer Dashboard Active Requirements & Offers Carousel Slider)**:
  - Addressed missing data in Buyer Dashboard "Active Requirement" banner when buyers had no open RFQs.
  - Integrated active marketplace offers loader in `BuyerDashboardController` with automatic fallback to active dashboard items.
  - Implemented strict filtering (`BuyerDashboardController.filterValidOffers`) excluding out-of-stock, expired, inactive, and closed/rejected deals.
  - Replaced single static card with `BuyerOffersCarouselSlider`:
    - Multi-offer carousel with smooth horizontal swipe `PageView` and animated dot indicators.
    - Single offer card display without superfluous indicators.
    - Friendly empty-state CTA card ("Looking for Bulk Commodities?") with direct actions to post requirement or browse offers.
    - Clean typography, currency/quantity formatting, and one-tap navigation to `ProductDetailScreen` or `BuyerOfferDetailsView`.
  - Added automated test suite `test/buyer_dashboard_offers_slider_test.dart` (10 tests passing).
- **Bug 36 Completed (GST Entry Length)**: Seller, Transporter, and Admin company forms accept all 15 GST alphanumeric characters while preserving official-format validation on submit.
- **Bug 35 Completed (Transporter Contract Detail Data)**: My Deals now carries complete deal, product, date, buyer/seller company/contact, GST/address, remarks, and route fields so details remain populated even when optional enrichment is unavailable.
- **Bug 34 Completed (Contract Detail Request Scope)**: Transporter detail no longer calls inaccessible consignment management, non-consignment statuses skip the lookup, and optional detail enrichment failures remain silent while initial list data renders.
- **Bug 33 Completed (Stale Flutter Compilation State)**: Confirmed all reported model/API members are present in tracked source, cleared generated artifacts, regenerated package metadata, and verified the missing-member errors no longer reproduce.
- **Bug 32 Completed (Admin Offer Video Playback)**: Removed the fixed-height player clipping, added visible inline playback controls, fullscreen viewing, progress seeking, and a retry state. Backend authenticated video streaming and byte ranges were verified.
- **Bug 31 Completed (Sub Admin Email Validation)**: Added shared Flutter form validation and matching Django validation for Sub Admin create/edit. Incomplete domains such as `rest@gmail.c` are rejected before persistence, while the API returns a clean validation message.
- **Bug 30 Completed (Seller Offers Excel Formatting)**: Replaced the formatting-limited CSV export with a native XLSX workbook and added professional title/timestamp banners, colored headers, readable widths, wrapping, numeric alignment, zebra rows, and correct Excel sharing metadata.
- **Bug 22 Completed (Buyer Dashboard Analytics Parity)**: `1M`, `3M`, and `1Y` now refresh all dashboard chart datasets. Spend/Orders, Supplier Spend, and Commodity Mix render with web-equivalent chart types, and Average Purchase Price uses the web-authoritative API field.
- **Bug 21 Completed (Background API Error Toasts)**: Non-critical Buyer profile and branch synchronization failures now retain functional screen content without opening generic server-error UI. User-triggered refresh errors remain concise and actionable.
- **Bug 18 Completed (Buyer Pending Offers False Out-of-Stock)**: Added complete inventory fields to the backend offer-list payload and mobile fallback hydration for older API responses. Active offers now retain `Active` status, real available quantity, and an enabled CTA; genuine zero-stock offers remain unavailable.
- **Repository Sync**: Fast-forwarded `rohit` from `0add5ff` to `a5f3ae2`; preserved local documentation while resolving the `TASK_STATE.md` stash conflict.
- **Weekly Report**: Documented mobile and web/backend delivery, QA evidence, repository status, risks, and next-week priorities in `docs/reports/WEEKLY_REPORT_2026-10-12_TO_2026-10-17.md`.
- **Bug 29 (Buyer Dashboard — TOP SUPPLIER & AVG PURCHASE PRICE Navigation Parity)**:
  - Addressed issue where tapping on either the "TOP SUPPLIER (MTD)" card or the "AVG PURCHASE PRICE" card on the Buyer Dashboard navigated to `ContractsScreen` instead of the "Offers & Requirements" screen (`BuyerOffersView`).
  - Updated both `onTap` handlers in `BuyerDashboardView._buildKPIGrid` (`lib/modules/buyer/dashboard/view/buyer_dashboard_view.dart`) to `Get.to(() => const BuyerOffersView(initialIndex: 0))`.
  - Exposed `@visibleForTesting buildKPIGrid` in `BuyerDashboardView` for isolated widget testability.
  - Added automated widget tests in `test/buyer_dashboard_kpi_navigation_test.dart` verifying tapping each card navigates to `BuyerOffersView`.
  - Verified with `flutter test test/buyer_dashboard_kpi_navigation_test.dart --no-pub` (2 tests PASSED) and full regression suite (11 tests PASSED).
- **Bug 28 (Buyer Categories — Request Timestamps & Recent Requests Parity)**:
  - Addressed missing request dates/timestamps on category cards and omitted approval requests list.
  - Confirmed `/api/buyer-categories/` already returns `data["requests"]` with `requested_at`, `status`, `categories`, `reviewed_at`, and `reviewed_by`.
  - Added `CategoryRequestModel` parsing all request fields and preserved `requests` in `BuyerCategoriesResult` and `CategoryController.recentRequests`.
  - Added `requestedAt` to `CategoryModel` with `requested_at` mapping from `requests`.
  - Fixed timezone conversion in `CategoryPageView._formatDateTime` (`.toLocal()`), formatting as `dd MMM yyyy, hh:mm a` (e.g. `16 Oct 2026, 06:21 AM`, `17 Oct 2026, 10:54 AM`) matching the web panel 1:1.
  - Added `DefaultTabController` with "My Categories" and "Recent Requests" tabs with count badge, rendering the full approval requests list matching web panel parity.
  - Verified with `test/buyer_category_requests_test.dart` (3 tests PASSED) and full regression suite (11 tests PASSED).
- **Bug 27 (Contract Details — Offer ID Display & Model Parsing Parity)**:
  - Fixed missing offer/product ID on mobile Contract Details screen (`contract_details_view.dart`).
  - Diagnosed live contract API: backend returns `"product_id": 152` while `ContractDetailModel.fromJson` parsed `number('product')`, causing `productId` to be `null`.
  - Added `productId` and `interestId` to `ContractModel` with fallback parser (`product_id` ?? `product` ?? `offer_id` ?? `offer`).
  - Updated `ContractDetailModel.fromJson` to prioritize `*_id` variants (`product_id`, `interest_id`, `buyer_id`, `seller_id`) and wired `c.productId` and `c.interestId` in `fromContractModel`.
  - Formatted the row in `contract_details_view.dart` as `'Offer'` displaying `${contract.productTitle} (ID: ${contract.productId})` matching 1:1 with the web panel and seller contract view.
  - Verified with `test/buyer_contract_details_offer_id_test.dart` (3 tests PASSED) and `test/contract_detail_model_test.dart` (1 test PASSED).
- **Bug 26 (Delivery Challan PDF Issuing Company PAN Number Parity)**:
  - Fixed PAN number disparity between Android app PDF (`ABCDE1234E`) and website PDF (`ABVSC1223F`).
  - Resolved root cause where `companyPan` was pulling `challan.sellerPan` (seller's PAN) instead of the issuing company (`FARMLAND`) PAN.
  - Implemented prioritized resolution in `buyer_challan_pdf_service.dart`: checks `company?.panNumber`, derives from `companyGst.substring(2, 12)` if present, and falls back cleanly to `'ABVSC1223F'`.
  - Both places in the generated PDF (top header `GST: ... PAN: ...` and bottom signatory box `PAN No. : ...`) now display `ABVSC1223F`, matching the web panel 1:1.
  - Created automated test in `test/buyer_challan_pdf_test.dart` and verified all tests pass.

- **Bug 25 (Pending Offers API `/api/offers/pending/` Missing Quantity Analysis)**:
  - Investigated issue where offers "toor angar" and "dal" display red "OUT OF STOCK" status badge and disabled "Out of Stock" button on mobile, but display as "Active" on the web dashboard.
  - Authenticated and queried live backend endpoints `GET /api/offers/pending/` and `GET /api/products/<id>/`.
  - Discovered that `/api/offers/pending/` returns only 10 fields (`id`, `title`, `image`, `price`, `offer_price`, `discount_percentage`, `created_at`, `status_code`, `status_label`, `status_tone`) and completely omits quantity/inventory fields.
  - Confirmed via `GET /api/products/146/` (20.100 QTL available) and `GET /api/products/141/` (660.000 QTL available) that both products have full operational stock in the database.
  - Identified that web panel shows "Active" because it only renders `status_label`, while mobile parses `Available Quantity` which defaults to `0.000 QTL` and triggers client-side out-of-stock logic.
  - Documented exact findings and recommended payload additions for the backend developer.

- **Bug 24 (Buyer Offer Negotiation Summary — Seller Price & Available Qty Data Binding)**:
  - Fixed data binding in `buyer_offer_details_view.dart` and `buyer_offer_detail_controller.dart` where Seller Price rendered as `₹-/ton` and Available Qty rendered as `- qtl`.
  - Unpacked `productMap` and mapped operational snapshot fields (`seller_snapshot_amount`, `seller_snapshot_quantity`) in `loadNegotiationThread`.
  - Added multi-candidate resolution checking `seller_snapshot_amount`, `seller_snapshot_quantity`, nested product maps, parent offer details (`target_price`, `available_quantity`), and fallback to `ProductService.getProductDetail`.
  - Verified with `test/buyer_negotiation_summary_card_test.dart` (3 tests PASSED), full regression suite (16 tests PASSED), and clean `flutter analyze --no-pub`.

- **Bug 23 (Buyer Delivery Challan PDF — Consignee Telephone & DEL AT Address Parity)**:
  - Corrected consignee contact mapping in `buyer_challan_pdf_service.dart`: replaced erroneous `challan.driverMobile` with buyer registered mobile number resolution (checks `challan.buyerMobile`, `ProfileController.profile.value.mobile`, and `AppPreferences.getUsername()`).
  - Corrected delivery destination mapping: bound `DEL AT` to `challan.deliveryAddress` instead of copying `challan.buyerAddress`, ensuring `DEL AT` remains blank when no separate delivery address is designated.
  - Added `buyerMobile` and `deliveryAddress` fields to `BuyerDeliveryChallanModel` with comprehensive key fallback parsing and sanitization.
  - Verified with `test/buyer_challan_pdf_test.dart` (3 tests PASSED) and full regression suite (13 tests PASSED).

- **Bug 22 (Buyer Delivery Challan — Driver License Number Field)**:
  - Added "License Number" field to Transport Details card in `buyer_delivery_challan_detail_view.dart`, positioned directly below "Driver Name" and above "Driver Mobile" to achieve 1:1 parity with the Buyer web panel.
  - Enhanced `BuyerDeliveryChallanModel.fromJson` with robust parsing for `driver_license_number`, `license_number`, `driver_license`, and nested `driver['license_number']` keys.
  - Implemented string sanitization (`cleanStr`) ensuring `"null"` strings, empty strings, and whitespace fall back cleanly to `"N/A"`, preventing broken/null UI display.
  - Created automated test `test/buyer_challan_transport_details_test.dart` (2 tests PASSED) and verified zero regressions across 9 existing tests.

- **Bug 9**: Resolved negotiation submission error in `negotiation_page.dart`.
- **Bug 10**: Resolved negotiation timestamp discrepancy in `negotiation_page.dart`.
- **Bug 11**: Resolved user list refresh defect in `user_view.dart`, `user_controller.dart`, and `add_user_controller.dart`.
- **Bug 12**: Resolved Brand Master search persistence defect in `admin_catalog_controller.dart`, `admin_common_widgets.dart`, and `admin_module_list_screen.dart`.
- **Bug 13 (Buyer Drawer)**: Fixed Buyer Drawer navigation and permission checks for buyer roles in `admin_drawer.dart`.
- **Bug 17 (Buyer Branches Filter Consolidation & Type Badges)**:
  - Removed duplicate "Clear" text link from Search filter card in `buyer_branch_view.dart`, standardizing on single "Reset" and "Apply" buttons matching the Buyer web panel.
  - Added `_buildBranchTypeBadge` to render blue "Primary" and green "Additional" pill badges on mobile branch cards.
  - Kept the "LEAVE" button visible alongside the "Additional" badge on non-primary branches.
  - Verified with `test/buyer_branch_view_badge_test.dart` and `test/buyer_branch_search_filter_test.dart` (8/8 tests PASSED).
- **Bug 16 (Buyer Dashboard Routing to My Interests)**:
  - Updated "View All" on Recent Requirements & Negotiations section in `buyer_dashboard_view.dart` to open `BuyerActivityView(initialIndex: 0)` ("My Interests" tab) instead of index 1 ("My Requirements").
  - Verified with `test/buyer_dashboard_view_all_navigation_test.dart` (PASSED).
- **Bug 15 (Buyer Action Button Text Clipping & Category Filter Removal)**:
  - Fixed vertical clipping of the green "Accept" text label in `buyer_offer_details_view.dart` by removing vertical padding conflicts (`padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0)`), setting font size 14, and height 48.
  - Removed artificial category filtering (`isDummyCategory` / `_isDummyOrTestCategory`) across `category_services.dart`, `category_page.dart`, and `add_buyer_offer_view.dart` so all categories (including test/dummy names) are displayed without restriction.
  - Added tests in `buyer_category_screen_test.dart` and `buyer_negotiation_accept_button_test.dart`.
- **Bug 14 (Delivery Challan PDF Formatting & Typos)**:
  - Corrected label typo "PAYMENT SCHEDULS :" -> "PAYMENT SCHEDULE :".
  - Professionalized salutation text to formal business standard.
  - Corrected charge breakdown label typo "LORRY FRIGHT" -> "LORRY FREIGHT".
  - Fixed vertical empty stretch by replacing `pw.Expanded` / `pw.Spacer()` with compact `pw.Table` (flex 4, 3, 3) and top-aligned container.
  - Formatted all monetary totals, rates, and charges with consistent vector Rupee (₹) prefixes via `_currencyWidget`.
  - Resolved `color: highlightYellow` and `decoration: BoxDecoration` container assertion collision.
- **Bug 15 (Broadcast Expiry in Requirement Details)**:
  - Added "Broadcast Expiry" field in mobile "Requirement Details" view (`buyer_offer_details_view.dart` and `seller_rfq_detail_view.dart`).
  - Added comprehensive fallback extraction (`broadcast_expiry`, `broadcast_expiry_datetime`, `expiry_datetime`, `deal_expiry_datetime`, `expiry_date`, `expires_at`, nested RFQ/Offer/Product maps).
  - Formatted into web panel format `dd MMM yyyy, hh:mm a` (e.g. `22 Oct 2026, 01:52 PM`) with timezone localization.
  - Verified with unit and widget test `test/requirement_details_broadcast_expiry_test.dart` and clean `flutter analyze`.
- **Task 16 (Rename 'All' Category to 'Offers')**:
  - Confirmed and updated primary tab in "Offers & Requirements" page (`buyer_offers_view.dart`) to `'Offers'`.
  - Cleaned empty state text interpolation for `offerType == 'all'` to display "No offers are available at the moment." instead of "No all offers...".
  - Renamed "All Offers" tab in `transporter_offers_view.dart` to "Offers" with clean empty state phrasing.
  - Removed unused import in `transporter_offers_view.dart`.
- **Task 17 (Buyer Submit Offer dd-mm-yyyy Date Format)**:
  - Formatted delivery date strictly as `dd-mm-yyyy` (e.g. `18-10-2026`) upon date selection across Buyer Panel modals (`buyer_offers_view.dart`, `buyer_today_offers_view.dart`, `buyer_my_interests_view.dart`).
  - Added automatic ISO date normalizer in `BuyerServices.showInterest` to ensure full backend compatibility with `yyyy-MM-dd`.
  - Verified with automated test `test/buyer_submit_offer_date_format_test.dart` and 0-issue `flutter analyze`.
- **Task 18 (Negotiation Summary Data, Standardized Timestamps & Composer Layout)**:
  - Fixed unbound summary data in `OfferInterestNegotiationChatView` (`seller_price` and `available_quantity` now populate via product fallback and format as `₹10,000.00 / TON` and `5000.100 QTL`).
  - Standardized date/time parsing and formatting in negotiation log to `dd/MM/yyyy hh:mm a` across mobile (`offer_interest_negotiation_chat_view.dart`) and web (`negotiation_page.dart`), removing hardcoded `"13 Oct 12:22"` and converting UTC naive timestamps to local IST.
  - Resolved input placeholder truncation ("Counter qua...") by separating inputs and send action into a balanced layout with full labels `Counter Price (₹)` and `Counter Qty`.
  - Added unit suffixes/affordances (`/$priceUnit` and `quantityUnit`) directly inside the text fields.
  - Replaced cramped circular send icon with a prominent, full-width `Submit Negotiation` button with proper 46px touch target and loading state.
  - Added helper note matching Buyer web panel specifications.
- **Task 21 (Transporter Dashboard — 3M Trend Chart Scaling & Missing Web Analytical Charts)**:
  - Synchronized dual-axis gridlines and scaling via `_calculateScale` algorithm with 6 equal divisions (0.02 step for Earnings up to 0.12, 0.4 step for Shipments up to 2.4).
  - Resolved negative curve sagging below Y=0 by enabling `preventCurveOverShooting: true`, `preventCurveOvershootingThreshold: 0.0`, and `curveSmoothness: 0.25` on `LineChartBarData`.
  - Added dynamic proportional bar width (42px on 3M) matching web styling.
  - Added `slaDrivers` reactive series and fallback parser to `TransporterDashboardController`.
  - Added missing `"SLA: On-time % (Drivers)"` card (`_buildSlaDriversCard`) with driver breakdown, SLA target badge (90%), progress bars, and fleet on-time fallback.
  - Renamed "Top Routes" to `"Top Routes (Trips)"` with route corridor badge styling.
  - Enhanced `"Transport Types"` card with proportional progress indicators.
- **Verification**: Created `test/transporter_trend_chart_test.dart` (4 tests passing), verified `test/transporter_api_models_test.dart` (passing), and confirmed 0 issues with `flutter analyze lib/modules/transporter/dashboard/`.


