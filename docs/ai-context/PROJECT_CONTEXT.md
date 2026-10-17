# Project Context: DaalSetu Mobile & Admin Application

## 1. Project Purpose & Overview
**DaalSetu** is a multi-sided agricultural commodity trading platform (specifically pulses/daal) connecting **Buyers**, **Sellers**, **Transporters**, and **Admins**. It facilitates end-to-end commodity discovery, counter-offer negotiations, contract generation, challan management, logistics tracking, and brokerage billing.

- **Client App Repo**: `P:\DaalSetu` (Flutter multi-platform: Android, iOS, Web, Windows)
- **Backend Reference Repo**: `P:\Daal_Broker.zip` / `P:\Daal_Broker` (Django, Django REST Framework, PostgreSQL, Celery)
- **Public API Host**: `https://www.daall-setu.com`

---

## 2. Technology Stack & Dependencies
- **Framework**: Flutter SDK (Dart 3.x)
- **State Management & Routing**: GetX (`get: ^4.6.6`)
- **Networking**: HTTP (`http: ^1.2.2`), custom `ApiClient` (`lib/network/api_client.dart`) with Bearer token authentication
- **Secure Token Storage**: `flutter_secure_storage: ^9.2.2` (keys: `access_token`, `refresh_token`, `user_role`, `user_id`)
- **Key UI Packages**: `google_fonts: ^6.2.1`, `iconly: ^1.0.1`, `fl_chart: ^0.66.2`, `image_picker: ^1.1.2`, `open_filex: ^4.7.0`
- **Testing**: `flutter_test`, `shared_preferences` mock initial values, custom fake repositories / controllers

---

## 3. Repository Structure & Key Paths
```text
P:\DaalSetu/
├── lib/
│   ├── comman/                     # API URLs and global constants (ApiUrl, ApiUrls)
│   ├── network/                    # ApiClient with auth headers & error handling
│   ├── routes/                     # AppRoutes and AppPages (GetPage route registry)
│   ├── theme/                      # AppTheme (colors, typography, light/dark themes)
│   ├── widgets/                    # Common UI components (AdminSearchBar, dialogs, buttons)
│   └── modules/
│       ├── admin_catalog/          # Admin master catalog, records, forms, filters, drawers
│       ├── auth/                   # Login, OTP verification, register
│       ├── buyer/                  # Buyer dashboard, requirements, offers, consignments
│       ├── seller/                 # Seller dashboard, offers, bids, challans, stock
│       ├── transporter/            # Transporter fleet, vehicles, drivers, bids, brands
│       └── users/                  # User management, Add User, user profile, status
├── test/                           # Automated unit, widget, and regression test suites
├── docs/ai-context/                # Persistent repository-backed AI knowledge base
└── .agents/skills/                 # Workspace agent skills for autonomous engineering
```

---

## 4. User Roles & Permission Model
The platform supports 6 distinct roles:
1. **Super Admin**: Complete unrestricted system access, branch creation, permissions matrix.
2. **Admin**: Catalog management, approval queue, user management, category requests, vehicle/driver assignment.
3. **Sub-Admin / Salesman**: Operational management within assigned branch/scope.
4. **Buyer**: Post requirements, explore seller offers, submit interest, negotiate prices/quantities.
5. **Seller**: Create offers, view buyer requirements, counter-negotiate, generate delivery challans.
6. **Transporter**: Register vehicles and drivers, bid on transport loads, track dispatches.

---

## 5. Current Development & Bug Resolution Status
- **Bug 9 (Resolved)**: Negotiation submission failure in Seller/Admin panel due to unparsed payload fields and exception handling. Fixed in `lib/modules/admin_catalog/view/negotiation_page.dart` and verified with `test/negotiation_submission_test.dart`.
- **Bug 10 (Resolved)**: Negotiation timestamp discrepancy (UTC vs IST display). Fixed in `negotiation_page.dart` with ISO 8601 UTC-to-local timezone conversion. Verified with `test/negotiation_timestamp_test.dart`.
- **Bug 11 (Resolved)**: Admin panel user list not refreshing after adding a user. Fixed via un-awaited FAB navigation, reactive `ever(users)` listener, `isLoading` re-entrancy guard, and concurrent fetch hook in `AddUserController`. Verified with `test/user_list_refresh_test.dart`.
- **Bug 12 (Resolved)**: Admin Panel Brand Master search retaining previous query upon refresh. Fixed with external `_searchController`, `resetSearch()`, and unified `_refresh()` in `AdminModuleListScreen`. Verified with `test/brand_master_search_refresh_test.dart`.

---

## 6. Critical Constraints & Operating Rules
- **Backend Reference is Read-Only**: `P:\Daal_Broker` is a reference for workflows and API contracts. No modifications without authorization.
- **Mandatory Euroside AI Development Rules**:
  - Never break working features.
  - Impact analysis before every modification.
  - Smallest isolated fix / minimal diff only.
  - Explain problem, root cause, affected files, risks, and rollback plan before modifying.
  - Comprehensive report and verification after implementation.
