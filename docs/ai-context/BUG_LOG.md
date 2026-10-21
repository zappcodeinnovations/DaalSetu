# Bug Log & Historical Fixes

## Bug 37: Buyer Dashboard Active Requirements Missing Data & Multi-Offer Carousel Parity
- **Symptom**: Buyer Dashboard's "Active Requirement" banner was missing/hidden whenever a buyer had no open RFQs, did not display available active marketplace offers, did not filter out out-of-stock or expired deals, and only rendered a single static card instead of a carousel slider.
- **Root Cause**:
  1. `_buildBannerSlider` strictly pulled from `data.recentRfqs` (the buyer's personal negotiations/RFQs) and returned `const SizedBox()` if no item had `status == 'open'`.
  2. `BuyerDashboardController` had no active offers loader or reactive list for marketplace products.
  3. No stock or expiry filter was applied to the banner item.
  4. No slider/PageView was implemented for multiple offers.
- **Fix**:
  1. Added `BuyerOffersLoader` and `activeOffers` reactive list to `BuyerDashboardController`, loading from `BuyerServices.getAllOffers()`, `BuyerServices.getTodayOffers()`, and `recentRfqs`.
  2. Implemented `BuyerDashboardController.filterValidOffers` excluding out-of-stock, expired, inactive, and closed/rejected items.
  3. Replaced static card with `BuyerOffersCarouselSlider`:
     - Built with Flutter native `PageView.builder` and smooth animated page indicator dots.
     - Single-card display when only 1 valid offer exists.
     - Elegant empty-state CTA card when 0 offers exist, inviting buyers to post requirements or browse catalog.
     - Preserved clean typography, badges ("ACTIVE REQUIREMENT" vs "ACTIVE OFFER"), price/quantity display, and navigation.
- **Files Changed**:
  - `lib/modules/buyer/dashboard/controller/buyer_dashboard_controller.dart`
  - `lib/modules/buyer/dashboard/view/buyer_dashboard_view.dart`
  - `test/buyer_dashboard_offers_slider_test.dart`
- **Verification**: 10 tests in `test/buyer_dashboard_offers_slider_test.dart` passed; regression tests in `test/buyer_dashboard_kpi_navigation_test.dart` and `test/buyer_dashboard_view_all_navigation_test.dart` passed; static analysis in `lib/modules/buyer/dashboard/` is 100% clean.

---

## Bug 36: Register Company GST Input Appeared Capped at 12 Characters
- **Symptom**: Users could not finish entering a 15-character GST number; an invalid positional character after the PAN segment was silently rejected, making the field appear capped at 12 characters.
- **Root Cause**: The GST formatter enforced every positional rule while typing instead of allowing the complete value and reporting validation feedback.
- **Fix**: GST fields now accept and uppercase up to 15 alphanumeric characters across Seller, Transporter, and Admin company forms. The existing validator still enforces the official GST structure before submission.
- **Files Changed**: `lib/utils/tax_id_formatters.dart`, company form views, admin record form, and `test/tax_id_formatters_test.dart`.
- **Verification**: Formatter regression tests pass and targeted Flutter analysis reports no issues.

---

## Bug 35: Transporter Contract Details Missing Deal and Party Data
- **Symptom**: Transporter My Deals could show only the logistics route while deal dates, price/quantity, buyer, and seller details remained blank.
- **Root Cause**: `/api/transport-bids/?view=mine` returned only a partial nested contract. When optional detail enrichment was unavailable, the screen had no fallback values for the missing fields.
- **Fix**: The backend My Deals payload now includes web-parity deal, packing, dates, remarks, buyer/seller company/contact, GST/address, product category/brand, and route data.
- **Files Changed**: `P:/Daal_Broker/Api/web_parity_views.py`, `P:/Daal_Broker/brokers_app/test_web_parity_api.py`.
- **Verification**: Transport bid flow and transporter contract authorization tests pass; navigation confirms the complete nested contract is supplied as initial detail data.

---

## Bug 34: Shared Contract Detail Called Inaccessible Consignment Endpoint
- **Symptom**: Opening contract details could log `Consignment not found` from `/api/consignments/<id>/` followed by a permission-scoped response from `/api/mobile/contracts/<id>/`.
- **Root Cause**: The shared Seller contract detail view always requested both APIs in parallel. Transporters cannot access consignment-management details, and the consignment API only includes active/received workflow contracts.
- **Fix**:
  1. Added role-aware consignment loading; transporter details no longer call the seller/buyer/admin consignment endpoint.
  2. Skip consignment lookup for statuses excluded by the backend consignment queryset.
  3. Made detail enrichment requests silent because list/notification data remains a valid fallback for permission-scoped 403/404 responses.
  4. Preserved the authenticated mobile contract-detail request for transporters with a bid.
- **Files Changed**:
  - `lib/modules/seller/contracts/view/seller_contract_detail_view.dart`
  - `lib/services/seller_services.dart`
  - `test/seller_contract_detail_request_scope_test.dart`
- **Verification**: Flutter request-scope regression test passed; targeted analyzer reports no errors. Django tests confirm bidders can view contract details and transporters without a bid remain denied.

---

## Bug 33: Stale Flutter Build Reported Missing Existing Members
- **Symptom**: Flutter compilation reported missing `BuyerOfferModel.isInterested`, branch names, offer-interest update URL, and `ProfileModel.copyWith`.
- **Root Cause**: All reported members already existed in the checked-out source and were visible to the Dart analyzer. The errors came from stale incremental Flutter artifacts rather than missing implementation.
- **Fix**: Cleared generated Flutter artifacts and regenerated package metadata without changing the pinned dependency lockfile.
- **Verification**: Fresh targeted analysis resolved all five reported compiler errors. Existing unrelated warnings in `buyer_services.dart` remain.

---

## Bug 32: Admin Offer Video Preview Clipped and Unplayable
- **Symptom**: Offer Videos Details displayed only a cropped/blank-looking video frame; playback controls were not visible and the video could not be played from the screen.
- **Root Cause**: The detail screen forced the complete video player column into a fixed 150px container. The video consumed that height and clipped the progress and play controls below it.
- **Fix**:
  1. Removed the fixed-height wrapper and render the preview in a stable 16:9 surface with `BoxFit.contain` behavior.
  2. Added a full-surface play/pause target, visible play indicator, seekable progress bar, and fullscreen playback.
  3. Added a user-friendly failure state with Retry and retained authenticated header/query-token media access.
  4. Added regression coverage preventing the fixed-height clipping and checking the required playback controls.
- **Files Changed**:
  - `lib/modules/admin_catalog/view/admin_record_detail_screen.dart`
  - `lib/widgets/authenticated_video_player.dart`
  - `test/admin_offer_video_preview_test.dart`
- **Verification**: Flutter preview regression test passed; targeted analyzer is clean. Existing Django bearer-token, query-token, and byte-range video preview tests pass.

---

## Bug 31: Sub Admin Email Validation Missing
- **Symptom**: Seller Sub Admin create/edit accepted incomplete email addresses such as `rest@gmail.c`.
- **Root Cause**:
  1. The shared Flutter admin form only checked whether Email was present.
  2. The backend Sub Admin flow checked required fields and uniqueness but never validated email format; Django's base email validator alone also permits one-character top-level domains.
- **Fix**:
  1. Added reusable client-side email validation requiring a complete domain and a 2-63 character alphabetic top-level domain.
  2. Applied email keyboard configuration and inline validation to the shared admin form used by Sub Admin create/edit.
  3. Added matching server-side validation before both create and update persistence, returning a user-friendly API message.
  4. Added Flutter and Django regression coverage for invalid create, invalid update, valid email, and required email behavior.
- **Files Changed**:
  - `lib/utils/input_validators.dart`
  - `lib/modules/admin_catalog/view/admin_record_form_screen.dart`
  - `test/admin_sub_admin_email_validation_test.dart`
  - `P:\Daal_Broker\brokers_app\permissions_views.py`
  - `P:\Daal_Broker\brokers_app\test_web_parity_api.py`
- **Verification**: Flutter validator tests passed (2/2); Django Sub Admin API test passed, covering client-independent create and update rejection.

---

## Bug 30: Seller Offers Excel Export Formatting
- **Symptom**: Seller offer exports opened as an unformatted worksheet with cramped columns, plain title/timestamp rows, and no visual separation for table headers.
- **Root Cause**: The mobile app exported CSV data. CSV cannot store Excel styles, merged cells, row heights, text wrapping, or column widths.
- **Fix**:
  1. Replaced the CSV export with a native `.xlsx` workbook using the project's existing Excel dependency.
  2. Added merged and styled title/timestamp banners, a contrasting orange header row, readable column widths, wrapped text, numeric alignment, and alternating data-row fills.
  3. Preserved the existing native share/save flow with the correct Excel MIME type and a descriptive filename.
- **Files Changed**:
  - `lib/modules/seller/products/controller/seller_product_controller.dart`
  - `lib/modules/seller/products/service/seller_offer_export_service.dart`
  - `test/seller_offer_excel_export_test.dart`
- **Verification**: Focused workbook test validates sheet structure, values, widths, styles, and generated XLSX bytes.

---

## Bug 22: Buyer Dashboard Chart Type, Range Filtering, and KPI Data Parity
- **Symptom**: Buyer mobile dashboard range buttons did not refresh subordinate analytics, chart visuals differed from web, some x-axis labels were omitted, and Average Purchase Price could display a stale alias value.
- **Root Cause**:
  1. Mobile sent `range`, but `buyer_dashboard_api` ignored it and always calculated Supplier Spend, Commodity Mix, Order Status, and Transport Status from unfiltered querysets.
  2. The KPI mapper preferred legacy `avg_purchase_price` over the web dashboard's authoritative `avg_price` field.
  3. Chart parity had no regression coverage, allowing incorrect chart types/orientations and skipped interval labels to return unnoticed.
- **Fix**:
  1. Added normalized `7D`, `1M`, `3M`, and `1Y` API range handling and range-scoped subordinate chart querysets.
  2. Kept Spend & Orders as web-style Orders bars plus Spend line, Supplier Spend horizontal with scale, and Commodity Mix as a polar-area visualization; all x-axis intervals render.
  3. Average Purchase Price now prioritizes `avg_price`, matching the web panel payload.
  4. Added controller dependency injection and regression tests proving range changes reload all chart datasets.
- **Files Changed**:
  - `P:\Daal_Broker\Api\views.py`
  - `P:\Daal_Broker\test_buyer_dashboard_ranges.py`
  - `lib/modules/buyer/dashboard/controller/buyer_dashboard_controller.dart`
  - `lib/modules/buyer/dashboard/view/buyer_dashboard_view.dart`
  - `lib/modules/buyer/dashboard/view/buyer_dashboard_analytics.dart`
  - `test/buyer_dashboard_analytics_parity_test.dart`
  - `test/buyer_dashboard_kpi_navigation_test.dart`
- **Verification**: Flutter dashboard tests passed (5/5) and Django range-contract tests passed (3/3).

---

## Bug 21: Background API Failures Display Intrusive Error Toasts
- **Symptom**: Buyer screens with successfully loaded content, including Categories, could be covered by a red generic server-error toast from an unrelated background request.
- **Root Cause**:
  1. Buyer Dashboard initializes `ProfileController`; its non-critical profile hydration performed two GET requests without `suppressErrorDialog`, then displayed the caught raw exception through `Get.snackbar`.
  2. Buyer branch background refresh accepted a `silent` flag, but did not forward it through `SellerServices.getSellerBranches`, allowing the API client to display global error UI.
- **Fix**:
  1. Profile background hydration now suppresses global network/server dialogs, retains existing profile data on failure, and records an internal load error without showing a raw toast.
  2. Explicit profile refresh can show a short user-friendly retry message without exposing the server exception.
  3. Buyer branch silent refresh now propagates through the service to `ApiClient.get`.
- **Files Changed**:
  - `lib/services/profile_services.dart`
  - `lib/modules/profile/controller/profile_controller.dart`
  - `lib/services/seller_services.dart`
  - `lib/modules/buyer/branch/controller/buyer_branch_controller.dart`
  - `test/background_api_error_policy_test.dart`
- **Verification**: Background API error policy tests passed (2/2). Targeted analyzer reported no errors; existing warnings in `seller_services.dart` remain.

---

## Bug 20: Sub-Category Master Details Image Display Failure ("Not Available")
- **Symptom**: On the mobile app's Sub-Category Master Details screen (`ID: 117`, `Name: sub`), even though an image was uploaded during creation, the Image field displayed `"Not Available"` (in grey italics) instead of rendering the uploaded image preview and download option.
- **Root Cause**:
  1. During creation, multipart upload sends the file with parameter key `'image'`. The backend Django Category model saves it in field `image`, and the detail endpoint `/api/categories/$id/` returns it under key `'image'`.
  2. In `admin_module_config.dart`, the `sub_categories` detailSection field was strictly defined as `'image_url'`. When `_resolveValue(data, 'image_url')` ran, `data['image_url']` evaluated to null.
  3. `_resolveValue` lacked an automatic fallback for image fields (unlike `first_name` and `last_name`).
- **Fix**:
  1. Updated detail field key in `admin_module_config.dart` for `'sub_categories'`, `'categories'`, and `'offer_images'` to `'image_url|image|category_image|image_path'`.
  2. Enhanced `_resolveValue` in `admin_record_detail_screen.dart` with smart fallback for image fields (`image_url`, `image`, `category_image`, `image_path`, `thumbnail`, `file`, etc.).
  3. Refined `isNullOrEmpty` in `_buildField` to treat string `'null'` as empty, and ensured `_absoluteUrl` prepends `/` cleanly when needed.
  4. Added `test/admin_subcategory_image_test.dart` covering field configuration and detail screen rendering for absolute URLs, relative URLs, and legitimate null states.
- **Files Changed**:
  - `lib/modules/admin_catalog/config/admin_module_config.dart`
  - `lib/modules/admin_catalog/view/admin_record_detail_screen.dart`
  - `test/admin_subcategory_image_test.dart`
- **Verification**: `flutter test test/admin_subcategory_image_test.dart` (6/6 tests PASSED) & `flutter analyze` (No issues found).

---

## Bug 19: Delivery Challan PDF Issuing Company PAN Number Disparity
- **Symptom**: On the mobile app generated Delivery Challan PDF, the PAN number in both the header (`GST: 23ABVSC1223F1Z4 PAN: ...`) and the bottom remark/signatory box (`PAN No. : ...`) displayed `ABCDE1234E`, whereas the web panel source PDF displayed `ABVSC1223F`.
- **Root Cause**: `BuyerChallanPdfService` evaluated `companyPan` as `(challan.sellerPan ?? 'ABVSC1223F').toUpperCase()`, erroneously pulling the seller's PAN (`ABCDE1234E`) instead of the issuing company's (`FARMLAND`) PAN (`company?.panNumber` or derived 10-char PAN from `companyGst.substring(2, 12)`: `ABVSC1223F`).
- **Fix**: Updated `companyPan` resolution in `buyer_challan_pdf_service.dart` to prioritize `company?.panNumber`, derive from `companyGst` substring (chars 2-12) if empty, and fall back safely to `'ABVSC1223F'`, completely removing conflation with `sellerPan`.
- **Files Changed**:
  - `lib/modules/buyer/delivery_challan/service/buyer_challan_pdf_service.dart`
  - `test/buyer_challan_pdf_test.dart`
- **Verification**: `flutter test --no-pub test/buyer_challan_pdf_test.dart` (4/4 tests PASSED).

---

## Bug 18: Pending Offers API (`/api/offers/pending/`) Omits Quantity & Inventory Parameters
- **Symptom**: On the Buyer mobile app under "Offers & Requirements" > "Pending", offers "toor angar" and "dal" displayed a red "OUT OF STOCK" status pill badge, `Available Quantity: 0.000 QTL`, and a disabled "Out of Stock" button. On the Buyer web panel dashboard, both offers displayed as "Active".
- **Root Cause**:
  1. Backend endpoint `/api/offers/pending/` only outputs `['id', 'title', 'image', 'price', 'offer_price', 'discount_percentage', 'created_at', 'status_code', 'status_label', 'status_tone']` and completely omits quantity fields (`available_quantity`, `remaining_quantity`, `quantity_qtl`, `quantity_unit`, `remaining_bag_count`, `packing_weight_kg`).
  2. The underlying products in the database (`/api/products/146/` and `/api/products/141/`) are confirmed active with full stock (`20.100 QTL` and `660.000 QTL`).
  3. The web dashboard card only renders `status_label` ("Active") and does not render `available_quantity`.
  4. On mobile, the absent quantity falls back to `'0.000 QTL'`, which causes client-side stock calculation in `BuyerOfferModel.fromJson` to falsely infer `detectedOutOfStock = true`, overriding the backend's `status_label: "Active"` into `OUT OF STOCK` and disabling the CTA button.
- **Fix**:
  1. Updated the backend pending/today/previous offer list serializer to include `available_quantity`, `remaining_quantity`, `original_quantity`, `quantity_qtl`, quantity/amount units, bag counts, packing weight, and `is_active`.
  2. Added a mobile compatibility fallback that hydrates active pending offers from `/api/products/<id>/` when an older list response omits stock values, while keeping the list endpoint's status and price authoritative.
  3. Preserved a real zero `remaining_quantity` instead of incorrectly falling back to the original quantity.
- **Files Changed**:
  - `P:\Daal_Broker\Api\views.py`
  - `P:\Daal_Broker\test_pending_offers.py`
  - `lib/services/buyer_services.dart`
  - `test/buyer_pending_offer_enrichment_test.dart`
- **Verification**: Backend tests passed (2/2); Flutter pending-offer enrichment and quantity calculation tests passed (5/5).

---

## Bug 15: Buyer Branches Network Filter Consolidation & Branch Type Badges
- **Symptom**: On the Buyer "Branches Network" screen, the Search card contained both a redundant "Clear" text link and a "Reset" button. Additionally, branch cards (e.g., "Test Branch") lacked a type/status badge (e.g. green "Additional" badge), making it impossible to distinguish between primary and additional branches.
- **Root Cause**:
  1. Header row inside the Search filter card rendered a redundant `Clear` text button when filters were active in addition to the standard `Reset` button.
  2. The branch card item builder conditionally rendered `isPrimary ? Container(PRIMARY) : OutlinedButton(LEAVE)`, meaning non-primary branches showed only the LEAVE button and never displayed their status badge.
- **Fix**:
  1. Removed the redundant `Clear` text link, consolidating on standard `Apply` and `Reset` buttons matching the web panel.
  2. Implemented `_buildBranchTypeBadge` rendering blue `Primary` and green `Additional` pill badges matching the Buyer web panel.
  3. Embedded the type badge inside the header Wrap of every branch card and maintained the LEAVE button for non-primary branches.
- **Files Changed**:
  - `lib/modules/buyer/branch/view/buyer_branch_view.dart`
  - `test/buyer_branch_view_badge_test.dart`
- **Verification**: `flutter test test/buyer_branch_view_badge_test.dart test/buyer_branch_search_filter_test.dart` (8/8 tests PASSED).

---

## Bug 14: Buyer Action Button Text Clipping & Artificial Category Filtering
- **Symptom**: In the Live Negotiation / Requirement Details screen, the text label on the green 'Accept' button was vertically cut off along the bottom. In the Categories screen and offer creation dropdown, categories containing 'test', 'xyz', 'sub', etc. were artificially filtered out and hidden.
- **Root Cause**:
  1. `ElevatedButton.icon` inside a tight `SizedBox(height: 46)` inherited the global `elevatedButtonTheme` vertical padding of 16px top and 16px bottom, leaving only 14px for a 16px font and icon, causing bottom vertical clipping.
  2. Client-side methods `isDummyCategory` and `_isDummyOrTestCategory` removed valid categories containing test/dummy names.
- **Fix**:
  1. Added explicit `padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0)`, explicit `fontSize: 14`, and 48px height on Accept and Reject action buttons.
  2. Removed artificial dummy/test category filters across `CategoryService`, `CategoryPageView`, and `AddBuyerOfferView`.
- **Files Changed**:
  - `lib/modules/buyer/offers/view/buyer_offer_details_view.dart`
  - `lib/services/category_services.dart`
  - `lib/modules/category/view/category_page.dart`
  - `lib/modules/buyer/offers/view/add_buyer_offer_view.dart`
  - `test/buyer_category_screen_test.dart`
  - `test/buyer_negotiation_accept_button_test.dart`
- **Verification**: `flutter test test/buyer_category_screen_test.dart test/buyer_negotiation_accept_button_test.dart` (5/5 tests PASSED).

---

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

---

## Bug 21: Transporter Dashboard — 3M Trend Chart Distorted Scaling & Missing Web Analytical Charts
- **Symptom**:
  1. Under the 3M filter, the "Earnings & Shipments Trend" chart displayed severe scaling distortion: Catmull-Rom spline line sagged into negative values below the baseline between Aug and Sep, left and right dual axes had mismatched tick intervals (3 vs 6 vs 4) with 3-decimal formatting (`0.050`), and the October line dot and shipment bar were misaligned.
  2. Analytical charts present on the Transporter web panel ("Top Routes (Trips)", "Transport Types" visual distribution, and "SLA: On-time % (Drivers)") were missing or misnamed.
- **Root Cause**:
  1. In `TransporterDashboardView`, `LineChartBarData` omitted `preventCurveOverShooting: true` and `preventCurveOvershootingThreshold: 0.0`. Dual axis scaling used arbitrary multipliers (`* 1.25` and `.ceilToDouble()`) that inflated maxShip from 2.0 to 3.0 and maxEarn from 0.12 to 0.150, creating mismatched gridlines.
  2. `TransporterDashboardController` never parsed `slaDrivers` from `/api/transporter/dashboard/overview/`.
  3. `TransporterDashboardView` omitted `_buildSlaDriversCard` and titled top routes as just "Top Routes" rather than "Top Routes (Trips)".
- **Fix**:
  1. Added `_calculateScale` algorithm synchronizing dual-axis divisions (6 intervals: 0.02 step for Earnings up to 0.12, 0.4 step for Shipments up to 2.4).
  2. Configured `preventCurveOverShooting: true`, `preventCurveOvershootingThreshold: 0.0`, and `curveSmoothness: 0.25` to eliminate curve sagging below Y=0.
  3. Dynamic bar width (42px on 3M) for balanced visual weight.
  4. Added `slaDrivers` reactive series and fallback parser in `TransporterDashboardController`.
  5. Built `_buildSlaDriversCard`, `_buildTopRoutesCard` ("Top Routes (Trips)"), and `_buildTransportTypesCard`.
- **Files Changed**:
  - `lib/modules/transporter/dashboard/controller/transporter_dashboard_controller.dart`
  - `lib/modules/transporter/dashboard/view/transporter_dashboard_view.dart`
  - `test/transporter_trend_chart_test.dart`
- **Verification**: `flutter test test/transporter_trend_chart_test.dart` (4 tests PASSED), `flutter test test/transporter_api_models_test.dart` (PASSED), `flutter analyze lib/modules/transporter/dashboard/` (0 issues).

## Bug 22: Buyer Delivery Challan — Missing Driver License Number in Transport Details Card
- **Symptom**: Under the Transport Details card on mobile, only Truck No, Driver Name, Driver Mobile, and Transporter were displayed. The driver's License Number was omitted entirely, unlike the Buyer web panel which displays "License Number: VSJSNSJSJ".
- **Root Cause**: `BuyerDeliveryChallanModel` did not map or sanitize driver license number keys from the API (`driver_license_number`, `license_number`), and `buyer_delivery_challan_detail_view.dart` omitted the row in `_buildTransportDetails`.
- **Fix**:
  1. Updated `BuyerDeliveryChallanModel` with robust `driverLicenseNumber` parsing supporting `driver_license_number`, `license_number`, `driver_license`, and nested `driver['license_number']` mappings, with `cleanStr` sanitizing out `"null"` and empty strings.
  2. Added `_buildInfoRow(context, "License Number", challan.driverLicenseNumber ?? "N/A", IconlyLight.paper)` placed directly under "Driver Name" to achieve 1:1 parity with the web panel.
- **Files Changed**:
  - `lib/modules/buyer/delivery_challan/model/buyer_delivery_challan_model.dart`
  - `lib/modules/buyer/delivery_challan/view/buyer_delivery_challan_detail_view.dart`
  - `test/buyer_challan_transport_details_test.dart`
- **Verification**: `flutter test test/buyer_challan_transport_details_test.dart` (2 tests PASSED), regression test suite (9 tests PASSED).
## Bug 23: Buyer Delivery Challan PDF — Consignee Telephone Bound to Driver Mobile & Erroneous "DEL AT" Binding
- **Symptom**:
  1. The generated delivery challan PDF on mobile displayed the driver's contact number (`TEL : 3546464944`) under the consignee box (`M/S. Test Buyer`) instead of the buyer's registered mobile number (`TEL : 1234567891`).
  2. "DEL AT" field was erroneously populated with the buyer's billing address (`gopal nagar, gopal nagar, Nagpur, Maharashtra, 440022, India`) rather than remaining blank when no separate delivery address was designated.
- **Root Cause**:
  1. `buyer_challan_pdf_service.dart` hardcoded `'TEL : ${challan.driverMobile ?? '-'}'` under consignee info.
  2. `_metaRow('DEL AT', ': ${challan.buyerAddress ?? ''}')` passed `challan.buyerAddress` rather than checking a dedicated delivery destination address on the challan record.
  3. `BuyerDeliveryChallanModel` lacked `buyerMobile` and `deliveryAddress` fields and fallback parsing.
- **Fix**:
  1. Added `buyerMobile` and `deliveryAddress` to `BuyerDeliveryChallanModel` with comprehensive fallback extraction across API payload schemas.
  2. In `BuyerChallanPdfService`, resolved buyer contact telephone with fallback to `ProfileController` and `AppPreferences.getUsername()` when empty on model, binding `'TEL : ${buyerPhone.isNotEmpty ? buyerPhone : '-'}'`.
  3. Updated `DEL AT` binding to `_metaRow('DEL AT', ': ${challan.deliveryAddress ?? ''}')`, leaving the field blank (`: `) when no separate delivery address is designated.
- **Files Changed**:
  - `lib/modules/buyer/delivery_challan/model/buyer_delivery_challan_model.dart`
  - `lib/modules/buyer/delivery_challan/service/buyer_challan_pdf_service.dart`
  - `test/buyer_challan_pdf_test.dart`
- **Verification**: `flutter test --no-pub test/buyer_challan_pdf_test.dart` (3 tests PASSED), full regression suite (13 tests PASSED).

## Bug 24: Buyer Offer Negotiation Summary — Seller Price and Available Qty Rendered as Dashes
- **Symptom**: Under the Negotiation Summary card in `BuyerOfferDetailsView`, Seller Price rendered as `₹-/ton` without a numeric price value, and Available Qty rendered as `- qtl` without any operational quantity value.
- **Root Cause**:
  1. `_buildNegotiationSection` in `buyer_offer_details_view.dart` strictly checked `thread['seller_price'] ?? thread['seller_amount'] ?? thread['amount']` and `thread['available_quantity'] ?? thread['available_stock'] ?? thread['quantity']`. The API payload returns operational numbers in `seller_snapshot_amount`, `seller_snapshot_quantity`, nested `product`/`offer` objects, or parent `offerDetails.value` (`target_price`, `available_quantity`, etc.).
  2. `loadNegotiationThread` in `BuyerOfferDetailController` did not unpack nested product maps (`product`, `offer`, `product_detail`), operational snapshot keys (`seller_snapshot_amount`, `seller_snapshot_quantity`), or fall back to `offerDetails.value` and `ProductService.getProductDetail`.
- **Fix**:
  1. Updated `loadNegotiationThread` in `BuyerOfferDetailController` to unpack `productMap` (`amount`, `seller_price`, `available_quantity`, etc.), map operational snapshot fields, fall back to `offerDetails.value`, and query `ProductService.getProductDetail` if price or quantity are still missing.
  2. Updated `_buildNegotiationSection` in `buyer_offer_details_view.dart` to accept parent `data` (`offerDetails.value`) and implement robust candidate resolution (`resolveVal` and `resolveQty`) checking snapshot fields, nested product maps, and parent data for seller price, operational available quantity, price unit, and quantity unit.
- **Files Changed**:
  - `lib/modules/buyer/offers/controller/buyer_offer_detail_controller.dart`
  - `lib/modules/buyer/offers/view/buyer_offer_details_view.dart`
  - `test/buyer_negotiation_summary_card_test.dart`
- **Verification**: `flutter test --no-pub test/buyer_negotiation_summary_card_test.dart` (3 tests PASSED), full regression test suite (16 tests PASSED), `flutter analyze --no-pub` (0 issues).

---

## Bug 25: Create Brokerage Bill — Overlapping Floating Label & Unnecessary 1/10 Counter
- **Symptom**: On the Create Brokerage Bill screen under "Eligible Delivery Challans", the input field for "Line brokerage rate (optional)" had an overlapping float-label artifact on the top border, an unnecessary `1/10` counter crowding the bottom inside the card, and tight asymmetric container padding.
- **Root Cause**:
  1. `_input` utilized `maxLength: numeric ? 10 : null`, which prompted Flutter's `TextFormField` to automatically render the `1/10` character counter.
  2. The input field in `_challanTile` used an `OutlineInputBorder` with `labelText`, causing the floating text to collide with the outline border inside the colored card container.
  3. Padding in `_challanTile` was `const EdgeInsets.only(left: 10, top: 4)` with no right or bottom padding, causing the field to touch the card boundaries.
- **Fix**:
  1. Realigned the label cleanly above the border using an explicit `Text('Line brokerage rate (optional)', ...)` widget with `hintText: 'Enter line rate'` inside `_challanTile`.
  2. Balanced container padding to `const EdgeInsets.fromLTRB(14, 6, 14, 12)` inside the card.
  3. Replaced `maxLength: numeric ? 10 : null` in `_input` with `inputFormatters: [LengthLimitingTextInputFormatter(10), FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]` and `counter: const SizedBox.shrink()`, eliminating the `1/10` counter.
- **Files Changed**:
  - `lib/modules/admin_catalog/view/admin_brokerage_bills_screen.dart`
  - `test/brokerage_bill_line_rate_test.dart`
- **Verification**: `flutter test test/brokerage_bill_line_rate_test.dart` (1 test PASSED), `flutter analyze lib/modules/admin_catalog/view/admin_brokerage_bills_screen.dart` (0 issues).

---

## Bug 26: Admin Parity & UI Bug Fixes (Transporter Bids, Dashboard Donut Palettes, Complaints Redirect, Brokerage Filters, KYC Search)
- **Symptom**:
  1. Contract Details screen had no way to view, accept, or reject transporter bids (feature parity gap with Web admin modal).
  2. Dashboard donut charts ("Pipeline by Stage" & "Commodity Mix") used identical hardcoded color palettes for completely different metrics.
  3. Clicking "Complaints" KPI metric card on Admin Dashboard redirected to `Notifications` view instead of complaints/issues overview.
  4. Pull-to-refresh and AppBar refresh in Brokerage Bills did not reset date or search filters.
  6. KYC Users screen card action buttons row (`[View] [Approve] [Reject] [History]`) overflowed by 3.6px on compact devices.
- **Root Cause & Fix**:
  1. Added `_transporterSection` to `lib/modules/contracts/view/contract_details_view.dart` linking to `TransportBidsSheet`, and updated `TransportBidsSheet._bidCard` to permit accept/reject for all pending/reserved bids.
  2. Extended `_buildDonutCard` in `lib/modules/dashboard/view/dashboard_page.dart` with custom color palette support; assigned distinct palettes to Pipeline (stage status) and Commodity (agro crop palette).
  3. Re-pointed Complaints KPI card `onTap` to `AdminOverviewKpisView(initialCategory: 'Logistics')` which displays open complaints and active tickets.
  4. Updated `_loadInitial` in `lib/modules/admin_catalog/view/admin_brokerage_bills_screen.dart` with `clearFilters: true` on refresh.
  5. Updated `KycUserModel.fromJson` with nested and fallback resolution for name, mobile, email, and role, added PAN/GST search matching in `KycController`, and added `searchParameter: 'search'` to `'kyc'` in `admin_module_config.dart`.
  6. Made KYC Users screen action buttons, status tabs, and summary cards responsive using `FittedBox(fit: BoxFit.scaleDown)` and adjusted spacing to completely eliminate the 3.6px overflow on all devices.
- **Files Changed**:
  - `lib/modules/contracts/view/contract_details_view.dart`
  - `lib/modules/admin_catalog/view/transport_bids_sheet.dart`
  - `lib/modules/dashboard/view/dashboard_page.dart`
  - `lib/modules/admin_catalog/view/admin_brokerage_bills_screen.dart`
  - `lib/modules/kyc_users/model/kyc_user_model.dart`
  - `lib/modules/kyc_users/controller/kyc_user_controller.dart`
  - `lib/modules/kyc_users/view/kyc_user_view.dart`
  - `lib/modules/admin_catalog/config/admin_module_config.dart`
  - `test/admin_feedback_fixes_test.dart`
- **Verification**: `flutter test test/admin_feedback_fixes_test.dart` (3 tests PASSED), `flutter analyze` on all modified files (0 errors).


## Bug 25: Contract Details — Missing Offer ID (e.g., "50 (ID: 152)") in Mobile Contract Details View
- **Symptom**: On the mobile Contract Details screen (`ContractDetailScreen`), the product item rendered only `Product: 50`, omitting the offer/product ID `(ID: 152)`, whereas the web Contract Details modal renders `Offer: 50 (ID: 152)`.
- **Root Cause**:
  1. `ContractDetailModel.fromJson` parsed `productId: number('product')`. The backend endpoint `/api/mobile/contracts/<id>/` returns `"product_id": 152` (and `"buyer_id"`, `"seller_id"`, `"interest_id"`), causing `productId` to evaluate to `null`.
  2. `ContractModel` lacked `productId` and `interestId` properties and parser mappings, so `ContractDetailModel.fromContractModel` hardcoded `productId: null`.
  3. `ContractDetailScreen` labeled the row as `'Product'` instead of `'Offer'` and only conditionally printed a separate redundant `'Product ID'` row which never rendered due to `productId == null`.
- **Fix**:
  1. Updated `ContractModel` to declare and parse `productId` (`product_id` ?? `product` ?? `offer_id` ?? `offer`) and `interestId` (`interest_id` ?? `interest`).
  2. Updated `ContractDetailModel.fromJson` to check `*_id` variants first (`product_id`, `interest_id`, `buyer_id`, `seller_id`, etc.) and wired `productId` and `interestId` from `ContractModel` in `fromContractModel`.
  3. Formatted the row in `contract_details_view.dart` as `'Offer'` displaying `${contract.productTitle} (ID: ${contract.productId})` matching 1:1 with the web panel and `seller_contract_detail_view.dart`.
- **Files Changed**:
  - `lib/modules/contracts/model/contract_model.dart`
  - `lib/modules/contracts/model/contract_details_model.dart`
  - `lib/modules/contracts/view/contract_details_view.dart`
  - `test/contract_detail_model_test.dart`
  - `test/buyer_contract_details_offer_id_test.dart`
- **Verification**: `flutter test test/buyer_contract_details_offer_id_test.dart --no-pub` (3 tests PASSED), `flutter test test/contract_detail_model_test.dart --no-pub` (1 test PASSED).

## Bug 26: Buyer Categories — Omitted Request Timestamps on Category Cards & Missing Approval Requests List
- **Symptom**: On the mobile Buyer Categories screen (`CategoryPageView`), category cards labeled timestamps as "Created on" with raw UTC hours (e.g. `12:51 AM` instead of local `06:21 AM`), and the entire approval requests ("Recent Requests") section tracking timestamps and approval statuses from the Buyer web panel was completely omitted.
- **Root Cause**:
  1. `CategoryModel` lacked a `requestedAt` property, and `category_page.dart` called `_formatDateTime` without `.toLocal()` timezone conversion.
  2. `CategoryService.fetchBuyerCategoryData` parsed `data["requests"]` to extract IDs into `requestedAtMap`, but never preserved the full `requests` list in `BuyerCategoriesResult` for controller/UI consumption.
  3. `CategoryPageView` lacked a "Recent Requests" tab or section to view submitted category approval requests.
- **Fix**:
  1. Created `CategoryRequestModel` in `lib/modules/category/model/category_request_model.dart` parsing `id`, `status`, `categoryNames`, `requestedAt`, `reviewedAt`, `requestNote`, `adminComment`, and `reviewerName`.
  2. Added `requestedAt` to `CategoryModel` and passed `requested_at: reqCreatedAt` in `CategoryService.fetchBuyerCategoryData()`.
  3. Added `requests: parsedRequests` to `BuyerCategoriesResult` and exposed `recentRequests` observable in `CategoryController`.
  4. Enhanced `CategoryPageView` with `DefaultTabController` (Tabs: "My Categories" and "Recent Requests"), showing the count badge for recent requests.
  5. Corrected `_formatDateTime` to apply `.toLocal()` and formatted timestamps as `dd MMM yyyy, hh:mm a` (e.g., `16 Oct 2026, 06:21 AM`, `17 Oct 2026, 10:54 AM`) matching the web panel 1:1.
  6. Built `_buildRecentRequestsTab` and `_buildRequestCard` with status badges, category names, request timestamp, review info, and admin notes.
- **Files Changed**:
  - `lib/modules/category/model/category_model.dart`
  - `lib/modules/category/model/category_request_model.dart`
  - `lib/services/category_services.dart`
  - `lib/modules/category/controller/category_controller.dart`
  - `lib/modules/category/view/category_page.dart`
  - `test/buyer_category_requests_test.dart`
- **Verification**: `flutter test test/buyer_category_requests_test.dart --no-pub` (3 tests PASSED), regression suite (11 tests PASSED).

## Bug 27: Buyer Dashboard — TOP SUPPLIER (MTD) & AVG PURCHASE PRICE KPI Cards Navigated to Contracts Screen
- **Symptom**: Tapping on either the "TOP SUPPLIER (MTD)" card or the "AVG PURCHASE PRICE" card on the Buyer Dashboard navigated to `ContractsScreen` instead of the "Offers & Requirements" screen (`BuyerOffersView`).
- **Root Cause**: In `BuyerDashboardView._buildKPIGrid` (`lib/modules/buyer/dashboard/view/buyer_dashboard_view.dart`), `onTap` for both "TOP SUPPLIER (MTD)" and "AVG PURCHASE PRICE" was hardcoded as `Get.to(() => const ContractsScreen())`.
- **Fix**:
  1. Updated the `onTap` handler on the "TOP SUPPLIER (MTD)" `_buildKPICard` to `Get.to(() => const BuyerOffersView(initialIndex: 0))`.
  2. Updated the `onTap` handler on the "AVG PURCHASE PRICE" `_buildKPICard` to `Get.to(() => const BuyerOffersView(initialIndex: 0))`.
  3. Added `@visibleForTesting buildKPIGrid` helper to facilitate clean, isolated widget testing without unneeded tree side-effects.
  4. Added automated widget tests in `test/buyer_dashboard_kpi_navigation_test.dart` verifying tapping each card navigates to `BuyerOffersView`.
- **Files Changed**:
  - `lib/modules/buyer/dashboard/view/buyer_dashboard_view.dart`
  - `test/buyer_dashboard_kpi_navigation_test.dart`
- **Verification**: `flutter test test/buyer_dashboard_kpi_navigation_test.dart --no-pub` (2 tests PASSED), full regression suite (11 tests PASSED).
