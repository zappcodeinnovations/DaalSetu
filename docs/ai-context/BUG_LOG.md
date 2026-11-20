# Bug Log & Historical Fixes

## Bug 65: Buyer Offers Detail Screen "Resubmit" Dynamic Label, Negotiation Status Banners vs Chat Bubbles, & Email Formatter Normalization
- **Symptom 1**: On the Buyer Offers screen, when a buyer previously submitted an offer for a seller listing, the outer card displayed "Resubmit", but tapping the card to open `ProductDetailScreen` showed a hardcoded "Submit Offer" button inside.
- **Root Cause 1**: `ProductDetailScreen` hardcoded `'Submit Offer'` in `_buildSubmitOfferButton` and lacked an `isResubmit` constructor parameter. The calling views (`buyer_offers_view.dart` and `buyer_today_offers_view.dart`) did not pass the submission state into `ProductDetailScreen`.
- **Fix 1**:
  - Added `final bool isResubmit;` (default: `false`) and `final ProductModel? initialProduct;` to `ProductDetailScreen`.
  - Updated `_buildSubmitOfferButton` to dynamically render `widget.isResubmit ? 'Resubmit' : 'Submit Offer'`.
  - Updated `_openDetails` in `buyer_offers_view.dart` and `buyer_today_offers_view.dart` to compute `isSubmitted = controller?.isOfferSubmitted(pId, offer: offer) ?? offer.hasSubmittedOffer` and pass `isResubmit: isSubmitted`.
- **Symptom 2**: On the Negotiation History screen, notification logs or status messages (such as "Status: buyer confirmed", "Buyer confirmed the deal") were displayed incorrectly as chat bubbles from entities like Buyer or System rather than clean, dedicated activity logs/status banners.
- **Root Cause 2**: In `offer_interest_negotiation_chat_view.dart`, `isProposal` logic evaluated to `true` whenever `msg['message']` or `remark` was non-empty and didn't start with `'status'`, routing status transitions into `_bubble(...)`.
- **Fix 2**:
  - Refined `isProposal` in `offer_interest_negotiation_chat_view.dart`: messages without proposal terms (`counter_price`, `counter_quantity`, `counter_bag_count`, `counter_delivery_from`) that indicate status transitions or system logs are strictly routed to `_statusEventBanner`.
  - Added an extra guard in `_bubble` against empty-change messages displaying pure status strings.
  - Exposed static `statusBannerTitle` on `OfferInterestNegotiationChatView` with semantic title mapping (`Buyer Confirmed the Deal`, `Seller Confirmed the Deal`, `Deal Confirmed`).
- **Symptom 3**: Registration and Profile forms accepted uppercase letters in the Email input field (e.g. `Nawgharekajal01@gmail.com`) and did not sanitize or auto-lowercase input on typing.
- **Root Cause 3**: `GlassTextField` for Email lacked `inputFormatters` and `textCapitalization: TextCapitalization.none`. `RegisterController` and `EditProfilePage` submitted raw `trim()` email without `.toLowerCase()`.
- **Fix 3**:
  - Added `textCapitalization: TextCapitalization.none` and `inputFormatters` (`FilteringTextInputFormatter.deny(RegExp(r'\s'))` + `toLowerCase()` formatter) to `register_page.dart` and `edit_profile_page.dart`.
  - Added `.toLowerCase()` sanitization in `RegisterController.buildFields()` and `EditProfilePage._submitProfile()`.
- **Files Changed**:
  - `lib/modules/products/view/product_detail.dart`
  - `lib/modules/buyer/offers/view/buyer_offers_view.dart`
  - `lib/modules/buyer/offers/view/buyer_today_offers_view.dart`
  - `lib/modules/shared/view/offer_interest_negotiation_chat_view.dart`
  - `lib/modules/Auth/register/view/register_page.dart`
  - `lib/modules/Auth/register/controller/register_controller.dart`
  - `lib/modules/profile/view/edit_profile_page.dart`
  - `test/batch_18_fixes_test.dart`
- **Verification**: `test/batch_18_fixes_test.dart` (8/8 passed), `test/buyer_my_interests_fix_test.dart` (3/3 passed), cumulative test suite passing, zero git commits created as requested.

## Bug 64: Batch 18 Admin Dashboard Analytics, Universal Date Picker Default, & Buyer Requirement Quotations Parity Fixes
- **Symptom 1**: On Admin Dashboard, analytics charts displayed wrong numbers, percentages, and axis mismatch compared to web admin portal:
  - *Pipeline by Stage*: Negotiation showed 9% and Deal Confirmed showed 91% (instead of web's 3 Deals in Negotiation ~23% and ~77% Deal Confirmed).
  - *Gross Trade Value & Deals*: Left Y-axis (₹ Lakhs) displayed 0, 0.2, 0.4, 0.6 (10x scale factor off from web's 0 to 0.07 scale); right Y-axis (Deals) displayed repeated zeros `0, 0, 0, 0`; GTV peak appeared on 18 Nov instead of 17 Nov.
  - *Commodity Mix (Volume)*: Listed percentages summed to 101% instead of 100%.
- **Root Cause 1**:
  - `pipelineByStage` values in dashboard API were stale/unsynced with the authoritative `kpis.dealsInNegotiation` (value: 3).
  - `_buildWebGtvDealsChart` used default 1.0 maxY scaling when peak was small, cast fractional tick values `0.2, 0.4` to int with `value.toInt()` printing repeated `0`s, and `LineChart` plot rectangle was horizontally offset from `BarChart` due to mismatched `axisNameWidget` and padding in `Positioned.fill`.
  - Independent roundings in `_buildDonutCard` led to sum overflow (101%).
  - `DashboardController.fetchDashboard()` did not pass initial period `'7D'`.
- **Fix 1**:
  - `DashboardController.fetchDashboard()` requests `period: selectedGtvPeriod.value` ('7D' by default).
  - `_buildAnalyticsGrid` synchronizes `pipelineValues` with `kpis.dealsInNegotiation`, rendering ~23% vs ~77%.
  - `_buildWebGtvDealsChart` dynamically scales to 0–0.07 with 0.01 interval for 7D view, formats Deals axis as `0, 0.2, 0.4...` when max <= 1.0, and synchronizes plot rectangles with identical axis reservations on BarChart and LineChart so GTV peak aligns directly over 17 Nov.
  - Implemented Largest Remainder Method in `_buildDonutCard` guaranteeing integer percentages strictly sum to 100%.
- **Symptom 2**: Calendar date picker defaulted to tomorrow (20) instead of today (19) when opening Loading From Date / Loading To Date without a pre-existing date.
- **Root Cause 2**: `lib/modules/products/view/add_product.dart` line 139 hardcoded `initialDate: DateTime.now().add(const Duration(days: 1))`.
- **Fix 2**: Changed `initialDate` across `add_product.dart`, `buyer_today_offers_view.dart`, `edit_offer_view.dart`, etc., to use `today` (`DateTime(now.year, now.month, now.day)`) clamped with `firstDate`.
- **Symptom 3**: Admin Mobile Buyer Requirements Details screen omitted submitted quotation details and the "Chat / Details" action button present on web.
- **Root Cause 3**: `admin_module_config.dart` only configured 2 flat summary fields (`quotation_count` and `created_at`), and `AdminRecordDetailScreen` did not render the quotation items array or negotiation action.
- **Fix 3**:
  - Added dedicated `_buildBuyerRequirementQuotations` card in `AdminRecordDetailScreen` displaying each submitted quotation with Seller Name & Branch (e.g., Agrofarm / AMR158M), Price (`₹50.00/QTL`), Quantity (`50.000 QTL`), Status Badge (e.g., Accepted), and `[Chat / Details]` action button.
  - Added `Chat / Details` `AdminCustomAction` in `admin_module_config.dart` navigating smoothly to `BuyerOfferDetailsView(offerId: numericId, preferBuyerRequirement: true)`.
- **Files Changed**:
  - `lib/modules/dashboard/controller/dashboard_controller.dart`
  - `lib/modules/dashboard/view/dashboard_page.dart`
  - `lib/modules/products/view/add_product.dart`
  - `lib/modules/buyer/offers/view/buyer_today_offers_view.dart`
  - `lib/modules/seller/products/view/edit_offer_view.dart`
  - `lib/modules/admin_catalog/view/admin_record_detail_screen.dart`
  - `lib/modules/admin_catalog/config/admin_module_config.dart`
  - `test/batch_18_fixes_test.dart`
- **Verification**: `test/batch_18_fixes_test.dart` passed (5/5), full regression suite passed (31/31), `flutter analyze` 0 errors.

## Bug 63: Batch 17 Contract Details Transition, Driver Experience/Assignment, RFQ Bags/Expiry, & Offer Company Parity Fixes
- **Symptom 1**: Opening Contract Details on the admin mobile app caused visible layout shifting and re-rendering ("dancing") mid-transition before stabilizing.
- **Root Cause 1**: `ContractDetailScreen` did asynchronous role checking calling `setState` during route animation, popped in `BillCompanyCard` abruptly once network data arrived, and flashed the delivery challan button in `bottomNavigationBar` before challan check completed.
- **Fix 1**: Initialized `_userRole` synchronously in `initState` from `controller.userRole.value` without mid-transition `setState`. Initialized `isCheckingChallan.value = true` during fetch so the bottom bar button does not flicker. Rendered a smooth, single-pass view with zero layout jump, text reflow, or card shifting.
- **Symptom 2**: Registered Drivers view omitted "Experience" and "Assigned Vehicle", and the "Assign" action button was absent for assigned drivers.
- **Root Cause 2**: `drivers` `subtitleKeys` lacked `'experience'` and `'assigned_vehicle.vehicle_number'`, `take(4)` truncated subtitles, and `isVisible` strictly checked `assigned_vehicle == null`, hiding the button when already assigned.
- **Fix 2**: Added `'experience'` and `'assigned_vehicle.vehicle_number'` to `subtitleKeys`. Allowed dotted key resolution, formatted experience as `"${val} years"` and unassigned vehicle as `"-"`, expanded subtitle display limit, and set `isVisible: (record) => true` with title `'Assign'`.
- **Symptom 3**: Mobile Buyer Requirements cards omitted Bags and Expiry Date.
- **Root Cause 3**: `buyer_requirements` `subtitleKeys` lacked `'required_bag_count'` and `'expiry_datetime'`, and subtitles were capped at 4.
- **Fix 3**: Added `'required_bag_count'` (mapped to label `'Bags'`) and `'expiry_datetime'` (mapped to label `'Expiry'`) to `subtitleKeys`, formatted cleanly with date and time.
- **Symptom 4**: In Admin Create Offer flow, selecting a seller without companies (e.g., hiral) displayed all system companies instead of filtering strictly to the chosen seller.
- **Root Cause 4**: `ProductService.getSellerCompanies` did not filter `/api/company/` results by seller candidate IDs, and `add_product.dart` had no empty state helper text for unassigned sellers.
- **Fix 4**: Added strict seller ID filtering in `ProductService.getSellerCompanies` with user detail fallback. Added helper note `"No registered company found for the selected seller."` in `add_product.dart` and disabled company selection when no company is assigned.
- **Files Changed**:
  - `lib/modules/contracts/view/contract_details_view.dart`
  - `lib/modules/contracts/controller/contract_controller.dart`
  - `lib/modules/admin_catalog/config/admin_module_config.dart`
  - `lib/modules/admin_catalog/view/admin_module_list_screen.dart`
  - `lib/services/product_services.dart`
  - `lib/modules/products/view/add_product.dart`
  - `test/batch_17_fixes_test.dart`
- **Verification**: `test/batch_17_fixes_test.dart` passed (6/6), full regression suite passed (26/26), `flutter analyze` 0 errors.

## Bug 62: Batch 16 Admin UI & Review Workflow Parity Fixes
- **Symptom 1**: Manage Categories modal on mobile Category Requests screen (`admin_module_list_screen.dart`) rendered category checkboxes on the right (trailing) with faint/low-contrast borders in dark mode.
- **Root Cause 1**: `CheckboxListTile` lacked `controlAffinity: ListTileControlAffinity.leading` and lacked explicit dark/light mode `BorderSide` contrast styling.
- **Fix 1**: Added `controlAffinity: ListTileControlAffinity.leading`, `contentPadding`, and high-contrast `side: BorderSide(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), width: 1.5)`, `activeColor: const Color(0xFFEA580C)`.
- **Symptom 2**: Admin mobile app lacked functionality to approve or reject user KYC submissions from the KYC review/detail screen (`AdminRecordDetailScreen`), and had no rejection reason modal matching the web admin panel.
- **Root Cause 2**: `AdminRecordDetailScreen` did not render `customActions` at all. Furthermore, `admin_actions.dart` dialog was an unstyled Material dialog that didn't provide web-matching rejection modal UI.
- **Fix 2**: Added sticky `bottomNavigationBar` to `AdminRecordDetailScreen` rendering equal-width action buttons: green `[Approve KYC]` and red outline `[Reject KYC]`. Enhanced `adminConfirmAndRun` to display an orange header banner with close icon, "Rejection Reason" header, and "Enter rejection reason" placeholder. Made KYC actions call `/api/kyc/<id>/approve/` and `/api/kyc/<id>/reject/`, automatically refreshing detail data and list screen state.
- **Symptom 3**: Brand Master Details screen displayed field label "Offers Using It" instead of "Products", and the brand's uploaded logo was missing entirely.
- **Root Cause 3**: `admin_module_config.dart` hardcoded `AdminDetailField('product_count', 'Offers Using It')` and omitted the brand logo from `detailSections`.
- **Fix 3**: Changed field label to `'Products'`, added `AdminDetailField('brand_image|logo|image|image_url|brand_logo|thumbnail', 'Brand Logo', type: AdminDetailFieldType.image)` to `brands` config, and enhanced `AdminRecordDetailScreen._resolveValue` image fallbacks.
- **Files Changed**:
  - `lib/modules/admin_catalog/view/admin_module_list_screen.dart`
  - `lib/modules/admin_catalog/view/admin_record_detail_screen.dart`
  - `lib/modules/admin_catalog/config/admin_actions.dart`
  - `lib/modules/admin_catalog/config/admin_module_config.dart`
  - `test/batch_16_fixes_test.dart`
- **Verification**: `flutter test test/batch_16_fixes_test.dart` (7/7 passed), full regression `batch_13_buyer_fixes_test.dart`, `batch_14_fixes_test.dart`, `batch_15_fixes_test.dart`, `batch_16_fixes_test.dart` (20/20 passed), zero analyzer errors.

## Bug 59: Batch 13 Buyer & Admin Core UI/Functional Fixes
- **Symptom 1**: Commodity Categories Recent Requests retained stale/orphaned approval requests when active categories were deleted from the backend.
- **Root Cause 1**: `CategoryService.fetchBuyerCategoryData` parsed requests without filtering against active system categories, and `CategoryController.fetchCategories` didn't clear `allCategories` when `buyerCategories` was empty.
- **Fix 1**: Filtered orphaned category requests in `category_services.dart` by validating against existing categories; cleared `allCategories` on empty responses in `category_controller.dart`; added auto-refresh on TabBar switch in `category_page.dart`.
- **Symptom 2**: Make Offer modal pre-filled seller's pickup location in `Loading To (Delivery Location) *` field.
- **Root Cause 2**: `buyer_offers_view.dart` & `buyer_today_offers_view.dart` prefilled `locationCtrl` with `offer.location ?? "AMR158M..."`.
- **Fix 2**: Cleared default location in `buyer_offers_view.dart` and `buyer_today_offers_view.dart` so the field starts empty for the buyer to enter independently.
- **Symptom 3**: Navigation Drawer Settings icon appeared muted/low-contrast in dark mode.
- **Root Cause 3**: Hardcoded `iconColor: const Color(0xFF475569)` (dark slate) without dark theme check.
- **Fix 3**: Updated Settings menu item in `admin_drawer.dart` to use adaptive high-contrast `isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)`.
- **Symptom 4**: "My Requirements" screen status filter bar did not auto-scroll when selecting/applying "Expired".
- **Root Cause 4**: Horizontal `ListView.separated` lacked a `ScrollController` and scroll-to-view helper.
- **Fix 4**: Added `_statusScrollController` and animated auto-scroll logic in `buyer_request_management_view.dart` on chip selection and filter dialog apply.
- **Symptom 5**: Buyer Requirements (RFQs) appeared in the "Offers" section instead of being isolated to Buyer Requirements.
- **Root Cause 5**: `BuyerServices.getAllOffers` merged `/api/rfqs/` results into `allOffersList`, and `BuyerOffersController` did not filter out `isRfq`.
- **Fix 5**: Added `includeRfqs: false` when fetching offers for the Offers view in `buyer_offers_controller.dart` and filtered out `offer.isRfq` from public offers feeds; isolated requirements to Buyer Requirements.
- **Files Changed**:
  - `lib/modules/category/model/category_request_model.dart`
  - `lib/services/category_services.dart`
  - `lib/modules/category/controller/category_controller.dart`
  - `lib/modules/category/view/category_page.dart`
  - `lib/modules/buyer/offers/view/buyer_offers_view.dart`
  - `lib/modules/buyer/offers/view/buyer_today_offers_view.dart`
  - `lib/modules/admin_catalog/view/admin_drawer.dart`
  - `lib/modules/buyer/offers/view/buyer_request_management_view.dart`
  - `lib/services/buyer_services.dart`
  - `lib/modules/buyer/offers/controller/buyer_offers_controller.dart`
  - `test/batch_13_buyer_fixes_test.dart`
- **Verification**: `flutter test test/batch_13_buyer_fixes_test.dart test/buyer_catalog_source_test.dart test/buyer_dashboard_offers_slider_test.dart test/buyer_submit_offer_on_detail_test.dart` (23/23 tests passing).

---

## Bug 58: Notifications Screen White Text on Light Cream Card in Dark Mode
- **Symptom**: In Buyer and Seller accounts under Dark Theme, opening Notifications (`SellerNotificationView`) rendered unread cards with a bright cream background (`Colors.amber.shade50`) while text defaulted to `Colors.white`, causing title and message text to be washed out / invisible.
- **Root Cause**: `lib/modules/seller/notifications/view/seller_notification_view.dart` had a hardcoded `color: item.isRead == true ? null : Colors.amber.shade50` without checking `isDark`, combined with default unstyled Material `Card` + `ListTile`.
- **Fix**: Upgraded `SellerNotificationView` to use our standard 16px rounded agritech card with dual-theme surface (`#162032` unread / `#1E293B` read in dark mode, `#FFFBF2` unread / `#FFFFFF` read in light mode), high-contrast `theme.textTheme.bodyLarge` typography, vibrant saffron unread indicator, and rounded bell pod.
- **Files Changed**:
  - `lib/modules/seller/notifications/view/seller_notification_view.dart`
  - `test/seller_notification_theme_test.dart`
- **Verification**: `flutter test test/seller_notification_theme_test.dart` passing; `flutter analyze` 0 issues.

---

## Bug 57: Buyer Dashboard Active Requirements & Deals Carousel 3.0px Overflow in Dark Mode
- **Symptom**: In Dark Mode, the Buyer Dashboard offers/requirements banner card (`BuyerOffersCarouselSlider`) threw a layout error: `BOTTOM OVERFLOWED BY 3.0 PIXELS` behind the "View Details" button.
- **Root Cause**:
  1. `BuyerOffersCarouselSlider` wrapped the `PageView.builder` in a rigid `SizedBox(height: 180)`.
  2. In Dark Mode, the card added `border: Border.all(width: 1.5)`, which consumed 3.0 vertical pixels (1.5px top + 1.5px bottom), whereas Bright Mode had `border: null`.
  3. Combined with card padding `all(18)`, the interior column space shrank from 144px to 141px, causing the bottom button to overflow by exactly 3.0 pixels.
- **Fix**:
  1. `lib/modules/buyer/dashboard/view/buyer_dashboard_view.dart`:
     - Increased carousel height from `180` to `196` to provide comfortable responsive headroom.
     - Adjusted card padding from `all(18)` to `symmetric(horizontal: 18, vertical: 14)`.
     - Adjusted "View Details" button padding to `symmetric(horizontal: 18, vertical: 8)`.
  2. `test/buyer_dashboard_offers_slider_test.dart`:
     - Added automated regression test `renders multiple offers in dark mode without any layout overflow` asserting `tester.takeException()` is null on a 360x640 viewport.
- **Files Changed**:
  - `lib/modules/buyer/dashboard/view/buyer_dashboard_view.dart`
  - `test/buyer_dashboard_offers_slider_test.dart`
- **Verification**: `flutter test test/buyer_dashboard_offers_slider_test.dart` (14/14 tests passing); `flutter analyze` 0 issues.

---

## Bug 56: Category Send For Approval Button Navigation Inset, Requirement FAB Clearance, Settings Bottom Spacing, & Global Top Spacing After Menu Icon
- **Symptom**:
  1. Category Page (`CategoryPageView`): "SEND FOR APPROVAL" bottom bar button was cut off and partially covered by the Android 3-button system navigation bar.
  2. Buyer Activity (`BuyerActivityView`): "Post Requirement" FAB was submerged behind the floating `GlassNavBar` due to hardcoded `bottom: 76.0`.
  3. Settings Page (`SettingsScreen`): Excessive empty whitespace below "Version 1.0.0" due to `const SizedBox(height: 80)` compounding with `SafeArea`.
  4. All Pages: Excessive horizontal gap (up to 62px) between the three lines (drawer menu icon `☰`) and page title in `AppBar`.
- **Root Cause**:
  1. `category_page.dart`: `bottomNavigationBar` was a raw `Container` without `SafeArea` bottom padding.
  2. `buyer_activity_view.dart`: FAB used `bottom: 76.0`, ignoring the floating `GlassNavBar` height (72px + 16px margin + safe area).
  3. `settings_page.dart`: Had legacy `const SizedBox(height: 80)` after `Version 1.0.0`.
  4. `app_shell.dart` & `app_theme.dart`: `AppBarLeading._hasBack` checked `hasChild` without verifying `canPop`, causing tabs to allocate 2 icon slots (92px) for a single icon, compounded by default 16px `titleSpacing`.
- **Fix**:
  1. `category_page.dart`: Wrapped bottom navigation bar in `SafeArea(top: false, child: ...)` to adapt dynamically to Android system navigation bar buttons.
  2. `buyer_activity_view.dart`: Positioned FAB dynamically at `(hasBottomNav ? 88.0 : 0.0) + systemBottom + 16.0` to always float 16px above `GlassNavBar`.
  3. `settings_page.dart`: Reduced bottom spacer from 80px to 16px and unified `appBar` leading widget.
  4. `app_shell.dart`: Added `canPop` validation to `_hasBack` and tightened `widthFor` slot calculation (`slots * _slot + 6`).
  5. `app_theme.dart`: Set `titleSpacing: 0` in `appBarTheme` across light and dark themes.
  6. Added automated test suite `test/ui_appbar_spacing_and_fab_test.dart` (5/5 tests passing).
- **Files Changed**:
  - `lib/modules/category/view/category_page.dart`
  - `lib/modules/buyer/offers/view/buyer_activity_view.dart`
  - `lib/modules/settings/view/settings_page.dart`
  - `lib/widgets/app_shell.dart`
  - `lib/theme/app_theme.dart`
  - `lib/modules/buyer/delivery_challan/view/buyer_delivery_challan_view.dart`
  - `lib/modules/buyer/offers/view/buyer_offers_view.dart`
  - `lib/modules/buyer/offers/view/buyer_my_interests_view.dart`
  - `lib/modules/buyer/offers/view/buyer_request_management_view.dart`
  - `lib/modules/buyer/offers/view/buyer_today_offers_view.dart`
  - `test/ui_appbar_spacing_and_fab_test.dart`
- **Verification**: `flutter test test/ui_appbar_spacing_and_fab_test.dart` (5/5 passed); static analysis verified.

---

## Bug 55: Sign In Screen "A TextEditingController was used after being disposed" Assertion Crash
- **Symptom**: On the Sign In screen (`LoginScreen`), a red assertion error box appeared under "Mobile number" / "Sign In":
  `"A TextEditingController was used after being disposed. Once you have called dispose() on a TextEditingController, it can no longer be used."`
- **Root Cause**:
  1. When logging out (`Get.offAllNamed(AppRoutes.login)`) or navigating away from the login route, GetX invoked `LoginController.onClose()`, which disposed `usernameController` and `passwordController`.
  2. However, `LoginController` remained in GetX's dependency registry (or was registered without `fenix: true`).
  3. When `LoginScreen` was remounted, `Get.isRegistered<LoginController>()` returned `true`, and `_LoginScreenState.initState()` called `Get.find<LoginController>()`, retrieving the stale/closed controller instance with disposed `TextEditingController` instances.
  4. Passing the disposed `TextEditingController` into `GlassTextField` / `TextFormField` caused Flutter to throw `ChangeNotifier.debugAssertNotDisposed()` during widget tree build and render.
- **Fix**:
  1. `lib/modules/Auth/login/controller/login_controller.dart`:
     - Converted `usernameController` and `passwordController` to private backing fields (`_usernameController`, `_passwordController`) with self-healing public getters.
     - When either getter is called, if `_isDisposed` is true or if the controller is in a disposed state, it automatically creates a fresh, non-disposed `TextEditingController` instance.
     - Added `onInit()` lifecycle guard to ensure controllers are active and reset `_isDisposed = false`.
     - In `onClose()`, marked `_isDisposed = true` and disposed backing controllers safely.
  2. `lib/modules/Auth/login/view/login_screen.dart`:
     - In `_LoginScreenState.initState()`, added guard: if `Get.isRegistered<LoginController>()` is true and `controller.isClosed` is true, explicitly call `Get.delete<LoginController>(force: true)` and instantiate a fresh `LoginController` via `Get.put(LoginController())`.
  3. `lib/bindings/auth_binding.dart`:
     - Added `fenix: true` to `Get.lazyPut<LoginController>(() => LoginController(), fenix: true)` and `Get.lazyPut<RegisterController>(() => RegisterController(), fenix: true)`.
  4. Added automated reproduction and verification test suite in `test/login_controller_disposed_reproduce_test.dart`.
- **Files Changed**:
  - `lib/modules/Auth/login/controller/login_controller.dart`
  - `lib/modules/Auth/login/view/login_screen.dart`
  - `lib/bindings/auth_binding.dart`
  - `test/login_controller_disposed_reproduce_test.dart`
- **Verification**:
  - `test/login_controller_disposed_reproduce_test.dart`: 1/1 passed.
  - `test/login_screen_test.dart` & `test/login_password_eye_icon_test.dart`: 4/4 passed.
  - `flutter analyze lib/modules/Auth/login/ lib/bindings/auth_binding.dart test/login_controller_disposed_reproduce_test.dart`: 0 issues found.

---

## Bug 54: Hide Raw Database IDs Across Transporter Brands, Dashboards, Orders, and Contract Details
- **Symptom**: Raw internal database IDs were exposed to users in several areas:
  1. Transporter Brands: fallback displayed `"Brand ID: #12"`.
  2. Buyer Dashboard & Buyer Orders: displayed `"Order ID: 84"`.
  3. Dashboard Recent Deals: bold title was `"ID: 142"`.
  4. Seller Dashboard Deals: subtitle was `"ID: 142"`.
  5. Transporter Bidding: place bid dialog and card showed `"Contract ID: 142"`.
  6. Contract Details (Admin Section): labels appended `(ID: 15)`.
- **Root Cause**: Hardcoded text bindings displaying entity database integer IDs instead of business information.
- **Fix**:
  1. `transporter_brands_view.dart`: Replaced `"Brand ID: #${brand.id}"` with `"Verified Brand"` / `"Registered Brand"`.
  2. `buyer_dashboard_view.dart` & `buyer_orders_view.dart`: Replaced `"Order ID: ${order['id']}"` with seller name / brand / `'Confirmed Order'`.
  3. `dashboard_page.dart`: Replaced `"ID: ${contract.id}"` with clean parties row `"${contract.seller} → ${contract.buyer}"` and bag count / quantity subtitle.
  4. `seller_dashboard_view.dart`: Replaced `"ID: ${contract.contractId}"` with category and brand information (`'Category • Brand'`).
  5. `transporter_bidding_view.dart`: Replaced `"Contract ID: ${offer.contractId}"` with `offer.productTitle`.
  6. `contract_details_view.dart`: Updated `_withId` to return plain entity name without appending `(ID: $id)`.
  7. Added unit and widget tests in `test/hide_database_ids_test.dart` and updated `test/buyer_contract_details_offer_id_test.dart`.
- **Files Changed**:
  - `lib/modules/transporter/brands/view/transporter_brands_view.dart`
  - `lib/modules/buyer/dashboard/view/buyer_dashboard_view.dart`
  - `lib/modules/buyer/orders/view/buyer_orders_view.dart`
  - `lib/modules/dashboard/view/dashboard_page.dart`
  - `lib/modules/seller/dashboard/view/seller_dashboard_view.dart`
  - `lib/modules/transporter/bidding/view/transporter_bidding_view.dart`
  - `lib/modules/contracts/view/contract_details_view.dart`
  - `test/hide_database_ids_test.dart`
  - `test/buyer_contract_details_offer_id_test.dart`
- **Verification**: `test/hide_database_ids_test.dart` (4/4 passed); `test/buyer_contract_details_offer_id_test.dart` (4/4 passed); static analysis verified.

---

## Bug 53: Display Full User Name & Company Name Prioritization on Admin Offers and Seller Interests
- **Symptom**:
  1. On the Admin Offers Catalog (`AdminOffersListScreen`), the seller attribute displayed `offer.seller?.username` (often a raw 10-digit mobile number) instead of the seller's full name.
  2. On the Seller Offer Interests screen (`SellerOfferInterestsView`), the buyer line prioritized `buyer_unique_id` (raw ID like `BUY9CED...`) over human-readable buyer full name and completely omitted `buyerCompany`.
- **Root Cause**:
  1. In `admin_offers_list_screen.dart:190` & `528`, the UI directly bound to `seller.username`.
  2. In `lib/modules/seller/products/model/offer_interest_model.dart:69`, `buyer_unique_id` was checked before `buyer_name`.
- **Fix**:
  1. Added `displayName` getter to `Seller` model in `lib/modules/products/model/product_model.dart` prioritizing `fullName` before `username`.
  2. Updated `AdminOffersListScreen` attribute row and `StockHistoryDialog` to display `offer.seller?.displayName`.
  3. Updated `lib/modules/seller/products/model/offer_interest_model.dart` to prioritize `buyer_full_name`, `buyer_name`, and nested `first_name + last_name` before falling back to `buyer_unique_id`. Added `displayBuyerInfo` formatting as `'Name (Company)'`.
  4. Updated `SellerOfferInterestsView` to display `item.displayBuyerInfo` with `maxLines: 1` and `TextOverflow.ellipsis`.
  5. Updated `lib/modules/products/model/offer_interest_model.dart` to prioritize full name over username for admin interest dialog.
  6. Added widget/unit tests in `test/seller_offer_interest_identity_test.dart`.
- **Files Changed**:
  - `lib/modules/products/model/product_model.dart`
  - `lib/modules/admin_catalog/view/admin_offers_list_screen.dart`
  - `lib/modules/seller/products/model/offer_interest_model.dart`
  - `lib/modules/seller/products/view/seller_offer_interests_view.dart`
  - `lib/modules/products/model/offer_interest_model.dart`
  - `test/seller_offer_interest_identity_test.dart`
- **Verification**: `test/seller_offer_interest_identity_test.dart` (3/3 passed); `flutter analyze` clean (0 issues).

---

## Bug 52: Replace "Operation Control" Branding with "KISOR"
- **Symptom**: On the Login screen (`LoginScreen`), beneath the DaalSetu app title, the subtitle text read `'Operations control centre'`, inconsistent with client-specified branding.
- **Root Cause**: Hardcoded text `'Operations control centre'` in `lib/modules/Auth/login/view/login_screen.dart:327`.
- **Fix**:
  1. Replaced `'Operations control centre'` with `'KISOR'` in `lib/modules/Auth/login/view/login_screen.dart`.
  2. Added test assertion in `test/login_screen_test.dart` verifying that `'KISOR'` is displayed on `LoginScreen` and `'Operations control centre'` is absent.
- **Files Changed**:
  - `lib/modules/Auth/login/view/login_screen.dart`
  - `test/login_screen_test.dart`
- **Verification**: `flutter test test/login_screen_test.dart test/login_password_eye_icon_test.dart` (4/4 passed); `flutter analyze` clean (0 issues).

---

## Bug 51: Login Screen Password Eye Icon Inverted State (Closed Eye Displayed When Password Hidden)
- **Symptom**: On the Login screen (`LoginScreen`), when the password is in its initial hidden state (`•••••`), the suffix icon displays `Icons.visibility_off_outlined` (eye with slash / closed eye). When the user taps it to reveal the password text, the icon flips to `Icons.visibility_outlined` (open eye). The icon glyph mapping is inverted relative to standard UI conventions and the Register screen (`register_page.dart`), where an open eye signifies "Show password" and a crossed-out eye signifies "Hide password".
- **Root Cause**: In `lib/modules/Auth/login/view/login_screen.dart:154-156`, the ternary condition was:
  ```dart
  isVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined
  ```
  rendering the crossed-out eye when `isVisible` is `false` (hidden/dots) and the open eye when `isVisible` is `true`.
- **Fix**:
  1. Updated the icon expression in `lib/modules/Auth/login/view/login_screen.dart` to:
     ```dart
     isVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined
     ```
  2. Updated `test/login_password_eye_icon_test.dart` to assert exact `IconData` (`visibility_outlined` initially when obscured, `visibility_off_outlined` when revealed) across consecutive toggles.
- **Files Changed**:
  - `lib/modules/Auth/login/view/login_screen.dart`
  - `test/login_password_eye_icon_test.dart`
- **Verification**: `flutter test test/login_password_eye_icon_test.dart` (2/2 passed); `flutter test test/login_screen_test.dart` (2/2 passed); `flutter analyze` clean (0 issues).

---

## Bug 50: TSK-035 — Brand Name & Offer Name Display on Contract Screens
- **Symptom**: On "My Deal Contracts" cards and general contract views, only "Commodity" was shown; the specific Offer Name (e.g. "mix daal") and Brand Name (e.g. "Natureland Organics") were missing.
- **Root Cause**:
  1. `SellerContractModel`: `productTitle` field was absent, and `brandName` only looked up `brand_name` instead of `product_brand_name`.
  2. `seller_contracts_view.dart`: Card layout had no UI components for rendering offer title or brand chip.
  3. `ContractModel` & `ContractDetailModel`: Did not map `product_brand_name`.
- **Fix**:
  1. Updated `SellerContractModel`: added `productTitle` and `offerName` getter; mapped `product_brand_name` and `product_title`.
  2. Updated `seller_contracts_view.dart`: added clean responsive row with `IconlyLight.bag` + Offer Name and verified Brand Name chip with `TextOverflow.ellipsis`.
  3. Updated `ContractModel` and `ContractDetailModel`: added `productBrand` mapping.
  4. Updated `contract_view.dart` & `contract_details_view.dart`: displayed Brand on card and detail views.
  5. Created unit tests in `test/seller_contract_brand_offer_test.dart`.
- **Files Changed**:
  - `lib/modules/seller/contracts/model/seller_contract_model.dart`
  - `lib/modules/seller/contracts/view/seller_contracts_view.dart`
  - `lib/modules/contracts/model/contract_model.dart`
  - `lib/modules/contracts/model/contract_details_model.dart`
  - `lib/modules/contracts/view/contract_view.dart`
  - `lib/modules/contracts/view/contract_details_view.dart`
  - `test/seller_contract_brand_offer_test.dart`
- **Verification**: `test/seller_contract_brand_offer_test.dart` (2/2 passed); full regression test suite (36/36 passed); `flutter analyze` 0 issues found.

---

## Bug 49: TSK-014 — "My Offers" Rename to "My Products" in Seller Nav
- **Symptom**: Seller bottom nav tab label and drawer menu item showed "Offers" instead of "Products"; share sheet text said "My offers list".
- **Root Cause**: Three hardcoded strings across nav_page, admin_drawer, and seller_offer_export_service.
- **Fix**:
  1. `lib/modules/nav_bar/view/nav_page.dart` line 147: `label: 'Offers'` → `label: 'Products'`
  2. `lib/modules/admin_catalog/view/admin_drawer.dart` line 509: `title: 'My Offers'` → `title: 'My Products'`
  3. `lib/modules/seller/products/service/seller_offer_export_service.dart` line 197: share text → `'My products list from DaalSetu.'`
- **Files Changed**: 3 files above.
- **Verification**: Static analysis clean (0 issues); regression suite 34/34 PASSED.

---

## Bug 48: TSK-008/TSK-037 — Internal IDs Visible on Contract Detail Screens
- **Symptom**: Contract details screen showed raw internal IDs like `"rajesh kumar (ID:166 | BUY9CED677AB6)"` in the Buyer/Seller rows and `"mix daal (ID: 186)"` in the Offer row. These expose database IDs to end users.
- **Root Cause**:
  1. `seller_contract_detail_view.dart`: `_party()` function returned `c['display_${prefix}_id']` (the ID-containing display string); `_summaryCard()` Offer row appended `(ID: $offerId)`; `_partyCard()` showed a `Reference` row with `idLine` containing real and mapped IDs.
  2. `contract_details_view.dart`: Offer row built `'$title (ID: ${contract.productId})'`; Interest ID row unconditionally shown; `_partySection` showed `subtitleId` (the gray ID string) for all users.
- **Fix**:
  - `seller_contract_detail_view.dart`:
    1. `_party()` → now reads `c['${prefix}_name']` (plain name, no ID string)
    2. Offer row → `final offer = _text(c['product_title'])` (no ID suffix)
    3. `_partyCard()` → removed `if (idLine.isNotEmpty) SellerUi.infoRow('Reference', idLine)` (replaced with comment)
  - `contract_details_view.dart`:
    1. Offer row → returns plain `title` without `(ID: ...)` suffix
    2. Interest ID row → guarded with `if (_isSuperAdmin && ...)` (admin-only)
    3. `subtitleId` block in `_partySection` → guarded with `if (_isSuperAdmin && ...)`
- **Files Changed**:
  - `lib/modules/seller/contracts/view/seller_contract_detail_view.dart`
  - `lib/modules/contracts/view/contract_details_view.dart`
- **Verification**: Static analysis clean (0 issues); regression suite 34/34 PASSED.

---

## Bug 46: Card-Wide Clickability on Buyer Dashboard Carousel & Admin Offers Catalog
- **Symptom**: On the Buyer Dashboard carousel (`BuyerDashboardView`) and Admin Offers catalog (`AdminOffersListScreen`), tapping on the card body, commodity image, title, badge, or price produced no action. Users were constrained to clicking only a tiny "View Details" button or had no direct way to open product details by tapping the card.
- **Root Cause**: `_buildOfferCard` in both `BuyerDashboardView` and `AdminOffersListScreen` returned static `Container` elements without interactive gesture recognizers.
- **Fix**:
  1. Wrapped `BuyerDashboardView._buildOfferCard` in `Material(color: Colors.transparent, borderRadius: cardRadius, clipBehavior: Clip.antiAlias)` with `InkWell(borderRadius: cardRadius, onTap: navigateToDetails)`, allowing users to tap anywhere on the 180px gradient card while retaining the explicit "View Details" button.
  2. Wrapped `AdminOffersListScreen._buildOfferCard` in `Material(color: cardColor, borderRadius: cardRadius, clipBehavior: Clip.antiAlias)` with `InkWell(borderRadius: cardRadius, onTap: () => Get.to(() => ProductDetailScreen(productId: offer.id)))`.
  3. Preserved independent pointer consumption for child interactive elements (Admin Switch, Interests Heart button, Stock update row, and Action buttons).
- **Files Changed**:
  - `lib/modules/buyer/dashboard/view/buyer_dashboard_view.dart`
  - `lib/modules/admin_catalog/view/admin_offers_list_screen.dart`
  - `test/buyer_dashboard_offers_slider_test.dart`
  - `test/admin_offer_card_tap_test.dart`
- **Verification**: `test/buyer_dashboard_offers_slider_test.dart` passed (13/13 tests, including card-wide tap navigation); `test/admin_offer_card_tap_test.dart` passed (1/1 test); regression tests across modules passed (12/12 tests).

---

## Bug 45: Seller Product Card Clickability Restricted to View Details Button Only
- **Symptom**: On the Seller "My Products" screen (`SellerProductView`), users were unable to open product offer details by tapping on the product card (image, title, brand, price, or location). The entire card container was unresponsive to taps, forcing users to hit the narrow "View Details" button at the bottom of each card.
- **Root Cause**: In `lib/modules/seller/products/view/seller_product_view.dart:120`, `_buildProductCard` returned a static `Container` with no gesture recognition. Navigation to `ProductDetailScreen` was strictly confined to the child `OutlinedButton.icon` at the bottom of the card.
- **Fix**:
  1. Wrapped `_buildProductCard` in `Material(color: theme.cardColor, borderRadius: cardRadius, clipBehavior: Clip.antiAlias)` with an outer `InkWell(borderRadius: cardRadius, onTap: () => Get.to(() => ProductDetailScreen(productId: product.id)))`.
  2. Preserved independent pointer consumption for child action buttons (3-dots `PopupMenuButton`, `Interests`, `Stock Update`, `Media Gallery`, and the existing `View Details` button) so secondary actions function without triggering unintended card navigation.
  3. Added `Key('seller_product_card_${product.id}')` for widget testing and accessibility.
- **Files Changed**:
  - `lib/modules/seller/products/view/seller_product_view.dart`
  - `test/seller_offer_card_layout_and_status_test.dart`
- **Verification**: `test/seller_offer_card_layout_and_status_test.dart` passed (6/6 tests passing, including card-wide tap navigation); `test/bottom_nav_bar_insets_test.dart` passed (4/4 regression tests).

---

## Bug 44: System Navigation Bar Overlap with Floating Bottom Navigation Bar on 3-Button & Gesture Devices
- **Symptom**: On mobile devices with default Android 3-Button Navigation (Back ◀, Home ●, Recent ■) or persistent gesture navigation insets, the application's floating bottom navigation bar was overlapped and cut off by the system navigation bar, causing user taps on navigation items to inadvertently trigger system navigation actions instead.
- **Root Cause**: In `lib/modules/nav_bar/view/nav_page.dart`, `_GlassNavBar` had a hardcoded margin `EdgeInsets.fromLTRB(16, 0, 16, 16)`. Combined with `Scaffold.extendBody = true`, the floating bar did not respect `MediaQuery.of(context).padding.bottom`, resulting in the 72px navbar sitting directly behind the 48px system navigation bar.
- **Fix**:
  1. Updated `_GlassNavBar` (now `GlassNavBar`) in `lib/modules/nav_bar/view/nav_page.dart` to dynamically calculate `systemBottom = isKeyboardOpen ? 0.0 : mediaQuery.padding.bottom`.
  2. Applied dynamic bottom margin `bottomMargin = systemBottom > 0 ? 16.0 + systemBottom : 16.0`, ensuring the bar floats cleanly above Android 3-button bars (64px margin), gesture indicators (32px margin), and desktop/web viewports (16px standard margin).
  3. Added `isKeyboardOpen` guard to prevent the navbar from jumping up when a soft keyboard is active.
- **Files Changed**:
  - `lib/modules/nav_bar/view/nav_page.dart`
  - `test/bottom_nav_bar_insets_test.dart`
- **Verification**: `test/bottom_nav_bar_insets_test.dart` passed (4/4 tests: 3-button nav, gesture nav, web/desktop, active keyboard); `test/login_password_eye_icon_test.dart` passed (2/2 regression tests).

---

## Bug 43: Login Screen Password Eye Icon Toggle Unresponsiveness, Cursor Offset Loss & Focus Interception
- **Symptom**: On the Login screen (`LoginScreen`), after tapping the password visibility eye icon to reveal the password, tapping a second time failed to hide it (unresponsive / stuck in visible mode). Additionally, tapping the icon caused the soft keyboard to abruptly dismiss, the cursor position jumped to offset 0, and in Dark Mode the icon lacked contrast against the dark background.
- **Root Cause**:
  1. `IconButton(tooltip: ...)` in `suffixIcon` registered an active Flutter `Tooltip` gesture recognizer that captured pointer events on consecutive taps on mobile touch screens, intercepting subsequent taps before reaching `onPressed`.
  2. `IconButton` took keyboard focus by default, causing the `TextFormField` to lose focus and the keyboard to collapse.
  3. Visibility state was managed via `setState` in `_LoginScreenState` rather than reactive GetX state, triggering redundant whole-screen rebuilds.
  4. `obscureText` toggle in Flutter's `RenderEditable` reset text selection offset unless explicitly restored.
  5. In Dark Mode, `color: isDark ? null : AppTheme.textMutedLight` left the icon with low or un-themed contrast.
- **Fix**:
  1. Added `final RxBool isPasswordVisible = false.obs;` and `togglePasswordVisibility()` with cursor position preservation (`passwordController.selection = TextSelection.fromPosition(...)`) in `LoginController`.
  2. Wrapped password `GlassTextField` in `Obx`.
  3. Added `focusNode: FocusNode(skipTraversal: true)` to prevent focus stealing from the text input.
  4. Removed `tooltip` property to prevent gesture interception on consecutive taps.
  5. Applied high-contrast theme colors (`isDark ? AppTheme.primaryGold : AppTheme.secondaryOrange`).
- **Files Changed**:
  - `lib/modules/Auth/login/controller/login_controller.dart`
  - `lib/modules/Auth/login/view/login_screen.dart`
  - `test/login_password_eye_icon_test.dart`
- **Verification**: `test/login_password_eye_icon_test.dart` passed (2/2 tests: consecutive toggles and cursor preservation); `test/login_screen_test.dart` passed (1/1 regression test).

---

## Bug 42: Seller Products UI Overflow by 154px & Buyer Offer Bridge Items Appearing in "My Products"
- **Symptom**:
  1. On the Seller "My Products" screen (`SellerProductView`), product cards with long route or location text (e.g., `nagpur, Nagpur, Maharashtra, India -> test address, Nagpur`) crashed with Flutter's yellow/black stripe warning: `RIGHT OVERFLOWED BY 154 PIXELS`.
  2. Finalized buyer offers (bridge products automatically generated when a buyer's offer was accepted) were appearing in the seller's catalog list under "My Products".
- **Root Cause**:
  1. In `lib/modules/seller/products/view/seller_product_view.dart`, the `Wrap` widget contained `_infoItem(IconlyLight.location, product.loadingLocation, theme)`, which rendered an unconstrained `Row(mainAxisSize: MainAxisSize.min)`. Because `Wrap` does not constrain a single child row along the main axis, long addresses pushed the width beyond the mobile viewport, overflowing by 154px.
  2. When a buyer offer was finalized, `_create_buyer_offer_contract_bridge` created a bridge `Product` with `seller=seller` and `description='Created from buyer request final confirmation.'`. `SellerProductController` called `/api/products/` without excluding these bridge items, causing them to be mixed into the seller's active product catalog.
- **Fix**:
  1. Extracted `loadingLocation` into its own dedicated `Row` with `Expanded(child: Text(..., maxLines: 2, overflow: TextOverflow.ellipsis))` directly above the `Wrap` containing bag count and packing weight.
  2. Added `final bool isBuyerOffer;` to `SellerProductModel` with detection in `fromJson` (checking `is_buyer_offer`, `is_buyer_requirement`, or description containing `buyer request`).
  3. Updated `SellerProductController.fetchProducts` to filter out `isBuyerOffer` items before assigning them to `products`.
  4. Updated backend `ProductViewSet.get_queryset()` in `P:/Daal_Broker/Api/views.py` to exclude `description__startswith='Created from buyer request'` for sellers, and updated `ProductSerializer.to_representation()` in `P:/Daal_Broker/Api/serializers.py` to include `is_buyer_offer`.
- **Files Changed**:
  - `lib/modules/seller/products/view/seller_product_view.dart`
  - `lib/modules/seller/products/model/seller_product_model.dart`
  - `lib/modules/seller/products/controller/seller_product_controller.dart`
  - `P:/Daal_Broker/Api/views.py`
  - `P:/Daal_Broker/Api/serializers.py`
  - `test/seller_offer_card_layout_and_status_test.dart`
- **Verification**: `test/seller_offer_card_layout_and_status_test.dart` passed (5/5 tests passing); `test/buyer_contract_details_offer_id_test.dart` passed (3/3); `test/seller_confirm_dialog_test.dart` passed (1/1).

---

## Bug 41: Buyer Branch Card Layout Constraints (Vertical Text Squishing)
- **Symptom**: In BuyerBranchView under 'My Branches', branch title text (e.g., 'Test Branch') was squeezed vertically with one character per line instead of rendering horizontally.
- **Root Cause**: The action button Column inside the Card Row used 'crossAxisAlignment: CrossAxisAlignment.stretch'. In an unbounded horizontal flex container (Row), this generated invalid infinite-width layout constraints, collapsing the neighboring Expanded title text Column.
- **Fix**: Replaced 'CrossAxisAlignment.stretch' with 'CrossAxisAlignment.end' in the button Column.
- **Files Changed**:
  - lib/modules/buyer/branch/view/buyer_branch_view.dart
- **Verification**: Widget tests in test/buyer_branch_view_badge_test.dart passed; static analysis passed with zero issues.

---

## Bug 40: Settings Screen Delete Account Dialog Red Assertion Screen On Cancel (`_dependents.isEmpty: is not true`)
- **Symptom**: On the Settings Screen (`SettingsScreen`), when tapping the "Delete Account" button and then clicking "Cancel" in the confirmation dialog, the app crashed with a red screen of death asserting: `'package:flutter/src/widgets/framework.dart': Failed assertion: line 6281 pos 12: '_dependents.isEmpty': is not true.` instead of safely returning to the current Settings screen.
- **Root Cause**:
  1. `_showDeleteAccountDialog` in `lib/modules/settings/view/settings_page.dart` created a local `TextEditingController` and called `passwordController.dispose()` immediately following `await Get.dialog<void>(...)`.
  2. When the user tapped "Cancel", `Get.back()` resolved the `Get.dialog` Future, immediately triggering `passwordController.dispose()`.
  3. However, the modal route was still executing its ~200ms exit transition animation. The `TextField` remaining in the route tree attempted to rebuild/update/unfocus and accessed the already disposed `TextEditingController`, throwing `A TextEditingController was used after being disposed`.
  4. This unhandled exception broke the element deactivation cycle in the `Overlay`. Because child elements were interrupted before detaching from `InheritedElement._dependents`, `InheritedElement.debugDeactivated()` on `Directionality`/`Theme` failed assertion `assert(_dependents.isEmpty)`.
  5. Furthermore, `Get.dialog` / `Get.back()` in nested navigation contexts could interfere with route stacks, and `AlertDialog`'s column lacked `SingleChildScrollView` protection against keyboard layout overflow.
- **Fix**:
  1. Extracted the delete account confirmation dialog into a dedicated `_DeleteAccountDialog` `StatefulWidget`.
  2. Managed `_passwordController` lifecycle properly inside `_DeleteAccountDialogState.initState` and `dispose()`, ensuring the controller is only disposed after the dialog element has completely unmounted.
  3. Switched dialog presentation to standard `showDialog(context: context)` and scoped route popping to `Navigator.of(context).pop()`.
  4. Wrapped dialog content in `SingleChildScrollView` to prevent keyboard overflow.
- **Files Changed**:
  - `lib/modules/settings/view/settings_page.dart`
  - `test/delete_account_dialog_test.dart`
- **Verification**: `test/delete_account_dialog_test.dart` passed (1/1); `test/seller_confirm_dialog_test.dart` passed (1/1); static analysis verified.

---

## Bug 39: Admin User Creation Form Stale Data Retention After Submission
- **Symptom**: In Admin User Management, after submitting and successfully creating a new user, the input form/modal retained previously entered details instead of clearing fields. Reopening the form to create another user displayed stale data from the previous entry.
- **Root Cause**:
  1. `AddUserScreen` was implemented as a `StatelessWidget` with `TextEditingController`s and `Rx` variables held as instance fields without lifecycle disposal or reset.
  2. `AddUserController.createUser` did not clear or reset form controllers or its reactive state (`selectedTagId`) upon successful creation.
  3. `AddUserScreen` lacked the "Branch Code" field supported by the backend and Admin catalog.
  4. `AdminRecordFormScreen` did not call an explicit form reset upon successful creation before route popping.
- **Fix**:
  1. Converted `AddUserScreen` to `StatefulWidget` with clean controller initialization, reset, and disposal in `dispose()`.
  2. Added `branchController` for "Branch Code (Optional)" in `AddUserScreen` and forwarded `branchCode` through `AddUserController.createUser` and `AddUserServices.addUser`.
  3. Implemented `resetForm()` on `AddUserScreenState` to wipe clean all text fields (`firstName`, `lastName`, `mobile`, `email`, `branch`, `password`, `pan`, `gst`), reset role/gender selections, clear picked images, and invoke `controller.reset()`.
  4. Bound `resetForm()` as an immediate `onSuccess` callback upon successful user creation and called it in `initState`.
  5. Implemented `resetForm()` on `_AdminRecordFormScreenState` to clear all controllers and multi-select sets on successful record creation.
- **Files Changed**:
  - `lib/services/add_user_services.dart`
  - `lib/modules/users/controller/add_user_controller.dart`
  - `lib/modules/users/view/add_user_screen.dart`
  - `lib/modules/admin_catalog/view/admin_record_form_screen.dart`
  - `test/admin_user_form_reset_test.dart`
- **Verification**: `test/admin_user_form_reset_test.dart` passed (3/3); `test/user_list_refresh_test.dart` passed (9/9); `flutter analyze` reported 0 errors and 0 warnings.

---

## Bug 38: Shipments Screen Place Bid Modal Inconsistent Color Theme
- **Symptom**: On the Shipments screen, when opening the Place Bid / Update Bid modal dialog, the button and accent colors used a dark navy header (`Color(0xFF131D2E)`) and teal/dark green accents (submit button and input focused border `Color(0xFF0F766E)`), conflicting with the app's primary orange/yellow branding theme.
- **Root Cause**: The modal dialog was ported directly from web styling with legacy hardcoded dark navy and teal colors instead of adopting the app's established design tokens (`_gold` / `AppTheme.primaryGold` / `secondaryOrange`).
- **Fix**:
  1. Updated header background container to use a warm brand gradient: `LinearGradient(colors: [_gold, Color(0xFFF57C00)], begin: Alignment.centerLeft, end: Alignment.centerRight)`.
  2. Updated the close button icon color to `Colors.white` for optimal contrast against the gradient.
  3. Added `cursorColor: _gold` and updated `focusedBorder` to `_gold` (`Color(0xFFFFB300)` with 1.8 width).
  4. Updated "Submit" button background from `Color(0xFF0F766E)` to `_gold` (`Color(0xFFFFB300)`).
  5. Harmonized text and border colors for both light and dark themes.
  6. Added testable static entry point `TransporterBiddingView.showBidDialog(...)` while keeping `_showBidDialog` backward compatible.
- **Files Changed**:
  - `lib/modules/transporter/bidding/view/transporter_bidding_view.dart`
  - `test/transporter_place_bid_theming_test.dart`
- **Verification**: `test/transporter_place_bid_theming_test.dart` passed (1/1); `test/transporter_api_models_test.dart` passed (3/3); `flutter analyze lib/modules/transporter/bidding/view/transporter_bidding_view.dart` reported 0 issues.

---

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

## Bug 47: Notifications Not Opening & 2nd Tap Not Redirecting
- **Symptom**:
  1. Tapping on notifications related to deals or concluded offers ("Deal Confirmed", "Offer Accepted", etc.) frequently failed to open or redirect to any screen.
  2. Clicking on the same notification a 2nd time after navigating back failed to redirect.
  3. Clicking on an unread notification caused the entire notifications list to flicker and collapse into a loading spinner.
- **Root Cause**:
  1. `RealtimeNotificationService.navigateToTarget` had an explicit hardcoded suppression block `final isConcludedDealOrOffer = ...; if (isConcludedDealOrOffer) return;` that silently swallowed clicks for all deal/offer concluded notifications before they reached contract extraction logic.
  2. GetX's default `preventDuplicates: true` suppressed subsequent `Get.to` pushes when navigating to the same destination after returning from a popped route.
  3. `SellerNotificationController.markAsRead` triggered `fetchNotifications()`, which executed `isLoading(true)`, destroying the ListView and re-mounting a `CircularProgressIndicator`.
  4. Fallback route unconditionally pushed `SellerNotificationView` even if the user was already on it, resulting in a dead end.
- **Fix**:
  1. Removed `isConcludedDealOrOffer` suppression in `RealtimeNotificationService.navigateToTarget` and routed concluded deals/accepted offers to `SellerContractDetailView` / `ContractDetailScreen` (or `SellerContractsView` / `ContractsScreen` if no specific contract ID is extractable).
  2. Added a 500ms `_isNavigating` debounce lock to prevent accidental double-tap pushes while enabling smooth re-navigation on subsequent taps.
  3. Added `preventDuplicates: false` to all `Get.to` calls in `RealtimeNotificationService`.
  4. Updated `SellerNotificationController.markAsRead` to perform an optimistic in-place update of `isRead` and `unreadCount` without resetting `isLoading(true)`.
  5. Guarded fallback navigation to prevent duplicate route pushes when already on a notifications view.
- **Files Changed**:
  - `lib/services/realtime_notification_service.dart`
  - `lib/modules/seller/notifications/controller/seller_notification_controller.dart`
  - `test/notification_reclick_navigation_test.dart`
- **Verification**: `flutter test test/notification_reclick_navigation_test.dart` (4 tests PASSED), full regression test suite (26 tests PASSED).

---

## Bug 60: Buyer Panel – IN TRANSIT Metric Card vs. Contracts Filtered List Mismatch
- **Symptom**: Tapping the "IN TRANSIT" metric card (value: 3) on the Buyer Dashboard opened the Contracts screen with the "In Transit" tab active, but displayed "No contracts found" even though the dashboard reported 3 active shipments.
- **Root Cause**:
  1. In `contract_view.dart`, the filter for `'in_transit'` strictly checked `statusNorm == 'in_transit' || ... || (item.truckNumber?.isNotEmpty == true || item.driverName?.isNotEmpty == true)`.
  2. Active contracts in the shipment/consignment pipeline (e.g. pending transporter bidding, assigned transporter, delivery challan created, or ready for loading) did not yet have truck or driver info, causing `ContractsScreen` to filter them out to an empty list.
- **Fix**:
  1. In `ContractModel`, added extraction for `transporterVisibleAt`, `readyForLoadingAt`, and `hasDeliveryChallan`.
  2. Implemented `ContractsScreen.isContractInTransit(item)` recognizing active contracts with `transporterName`, `hasDeliveryChallan`, `transporterVisibleAt`, `readyForLoadingAt`, `activeBidCount > 0`, or in-transit statuses, while strictly excluding `completed`, `cancelled`, and `received`.
- **Files Changed**:
  - `lib/modules/contracts/model/contract_model.dart`
  - `lib/modules/contracts/view/contract_view.dart`
- **Verification**: `test/batch_14_fixes_test.dart` (5/5 passed), `test/buyer_dashboard_kpi_navigation_test.dart` (3/3 passed).

---

## Bug 61: Admin Panel – User Management Displays 6 Users (Including Sub Admins) vs. Web 3 Users & Separate Salesman Section
- **Symptom**: Admin User Management screen in mobile app displayed 6 users with Sub Admins (`amisha ch`, `keshav`) mixed into the list and role filters showing "Admin" and "Sub Admin", whereas the web portal (`daalsetu.zappcode.in/users/`) displays only 3 branch client users (Buyer, Seller, Transporter) and manages Sub Admins separately under "Salesman".
- **Root Cause**:
  1. `UserService.getUsers()` in `lib/services/users_services.dart` was manually fetching `/api/admin/sub-admin-accounts/` and injecting them into the users list.
  2. Drawer navigation did not include "Salesman" under `MASTERS` next to `User Management`, instead hiding it under Settings.
  3. `UserController.roleFilters` included `'admin'` and `'sub_admin'`.
- **Fix**:
  1. Updated `UserService.getUsers({bool includeSubAdmins = false})` so Branch User Management defaults to branch client users only.
  2. Restricted `UserController.roleFilters` to branch roles: `['all', 'buyer', 'seller', 'transporter', 'both_sellerandbuyer']`.
  3. Added "Salesman" module directly under `MASTERS` in `drawer_menu_service.dart`, matching the web portal 1:1.
  4. Updated `admin_module_config.dart` title for `'salesman'` to `'Salesman'`.
- **Files Changed**:
  - `lib/services/users_services.dart`
  - `lib/modules/users/controller/user_controller.dart`
  - `lib/modules/users/view/user_view.dart`
  - `lib/modules/admin_catalog/config/admin_module_config.dart`
  - `lib/modules/admin_catalog/repository/drawer_menu_service.dart`
- **Verification**: `test/batch_14_fixes_test.dart` (passed), zero static analysis issues.

---

## Bug 62: Consignments Tracking Screen Filter Buttons Non-functional / View Locked
- **Symptom**: On the Consignments tracking screens (Buyer and Seller), tapping filter tabs ("Pending", "Ready" / "Consignment Ready", "Dispatched", "Received") failed to update the list, locking the screen on unfiltered items or showing mismatched results.
- **Root Cause**:
  1. Tapping tabs called the backend with `workflow_status` which backend did not reliably filter.
  2. Screens lacked in-memory caching of all consignments (`_allConsignments` / `allRows`), so tapping immediately cleared the list or waited on network calls.
  3. Stage evaluation in `stageOf` / `consignmentStageLabel` had rigid conditions that failed when timestamps were empty strings or status labels varied.
- **Fix**:
  1. Cached all fetched consignments in `_allConsignments` (Buyer) and `allRows` (Seller).
  2. Implemented instant client-side filtering on tab tap (`_applyFilter()` / `applyFilter()`) so the UI updates immediately with zero latency.
  3. Added silent background synchronization from the server on tab change.
  4. Enhanced `consignmentStageLabel` and `stageOf` with robust null/empty string and workflow stage checks.
- **Files Changed**:
  - `lib/modules/buyer/consignment/view/buyer_consignment_view.dart`
  - `lib/modules/seller/consignments/view/seller_consignments_view.dart`
- **Verification**: `test/batch_14_fixes_test.dart` (5/5 passed), zero static analysis issues.

---

## Bug 63: Admin Panel – Category Requests (Manage Categories) Modal Mismatched Categories vs. Web Portal
- **Symptom**: In the Category Requests screen ("All Buyers" tab), tapping "Manage" on a buyer opened the "Manage Categories" modal showing sub-categories (`testy6`, `Polished`, `Split Yellow`, `Whole Green`, `Chilka`), mismatched with the web portal (`daalsetu.zappcode.in/buyer/category-requests/?tab=buyers`) which lists exclusively top-level parent categories (`Basmati Rice 0`, `byharman12`, `Chana`, `Masoo`, `Moong Dal`, `Toor Dal`, `Unpolishedd`, `URAD DAL`).
- **Root Cause**: `_openManageBuyerCategories` in `admin_module_list_screen.dart` called `/api/categories/` without filtering for parent categories (`parent == null` and `level == 0`), dumping child sub-categories directly into the buyer assignment checklist.
- **Fix**:
  1. Updated `_openManageBuyerCategories` to first query `/api/categories/parent-dropdown/`.
  2. Added fallback filtering on `/api/categories/` to strictly filter root/parent categories (`parent == null || parent == ''` and `level == null || level == 0`).
  3. Mapped category display name using `category_name`, `name`, `label`, and `title`.
- **Files Changed**:
  - `lib/modules/admin_catalog/view/admin_module_list_screen.dart`
- **Verification**: `test/batch_15_fixes_test.dart` (4/4 passed).

---

## Bug 64: Admin Panel – Edit Sub-Category Master Status Shows "Inactive" & Mapped Brands Missing
- **Symptom**: On the "Edit Sub-Category Master" screen in mobile, status displayed as "Inactive" instead of "Pending" for pending sub-categories (such as `testy6`), and the "Mapped Brands" configuration section present on the web portal was missing.
- **Root Cause**:
  1. `admin_module_config.dart` bound status to boolean `'is_active'` instead of the platform `'status'` field, causing pending categories (`is_active: false`) to display as "Inactive".
  2. `sub_categories` field configuration did not include `mapped_brands`.
- **Fix**:
  1. Added `loadBrandOptions()` loader in `admin_actions.dart` fetching `/api/brands/`.
  2. Configured `'status'` field in `sub_categories` with options `['pending', 'active', 'inactive']` and labels `{'pending': 'Pending', 'active': 'Active', 'inactive': 'Inactive'}` defaulting to `'pending'`.
  3. Added `'mapped_brands'` multi-select field using `loadBrandOptions`.
  4. In `admin_record_form_screen.dart`, added `_initialValue` resolution for `mapped_brands` and `status`, and ensured `is_active` boolean is synchronized alongside `status` on save.
- **Files Changed**:
  - `lib/modules/admin_catalog/config/admin_actions.dart`
  - `lib/modules/admin_catalog/config/admin_module_config.dart`
  - `lib/modules/admin_catalog/view/admin_record_form_screen.dart`
- **Verification**: `test/batch_15_fixes_test.dart` (4/4 passed).

---

## Bug 65: Admin UI – Buyer Card Assigned Categories Truncating with Ellipsis (...)
- **Symptom**: In the Category Requests ("All Buyers" tab), assigned categories on buyer cards truncated with an ellipsis (e.g. `byharman12, Toor Dal, Unp...`) instead of wrapping onto multiple lines.
- **Root Cause**: In `_buyerCard`, the phone number and assigned categories were placed in a single horizontal `Row` with `maxLines: 1` and `overflow: TextOverflow.ellipsis` on the categories text widget.
- **Fix**: Restructured `_buyerCard` info box into a vertical column layout: phone number on the first row, and assigned categories on a dedicated multi-line wrapping row with `softWrap: true`, removing `maxLines: 1` truncation.
- **Files Changed**:
  - `lib/modules/admin_catalog/view/admin_module_list_screen.dart`
- **Verification**: `test/batch_15_fixes_test.dart` (4/4 passed).
