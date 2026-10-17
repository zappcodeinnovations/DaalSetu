# System Architecture & Technical Specifications

## 1. High-Level Architecture Overview
DaalSetu utilizes a client-server architecture:
```text
┌────────────────────────────────────────────────────────┐
│           Flutter Client (P:\DaalSetu)                 │
│  - GetX Controllers & Reactive State (Obx / .obs)       │
│  - Module Views & Dynamic Forms (AdminRecordFormScreen)│
│  - ApiClient (Http + Secure Token Interception)        │
└──────────────────────────┬─────────────────────────────┘
                           │ HTTPS REST (JSON / Multipart)
                           ▼
┌────────────────────────────────────────────────────────┐
│      Django REST Framework API (P:\Daal_Broker)        │
│  - Authentication: SimpleJWT / Session Tokens          │
│  - ViewSets: UserViewSet, BrandViewSet, ContractViewSet │
│  - Celery Tasks & Asynchronous Notification Queues     │
│  - PostgreSQL Relational Database                      │
└────────────────────────────────────────────────────────┘
```

---

## 2. Module Boundaries & Routing Strategy
- **Route Manager**: [`lib/routes/app_pages.dart`](file:///P:/DaalSetu/lib/routes/app_pages.dart) registered using `GetPage`.
- **Dynamic Admin Catalog Router**:
  [`AdminModules`](file:///P:/DaalSetu/lib/modules/admin_catalog/config/admin_module_config.dart) defines catalog configurations for:
  - `brands`, `categories`, `sub_categories`, `tags`, `drivers`, `vehicles`, `consignments`, `buyer_offers`, `buyer_requirements`, `branch_requests`, `branches`, `billing_companies`, etc.
  - Generates uniform URLs: `/admin/:moduleKey` mapped to [`AdminModuleListScreen`](file:///P:/DaalSetu/lib/modules/admin_catalog/view/admin_module_list_screen.dart).
  - Handles item detail routes: `/admin/:moduleKey?id=:id` mapped to [`AdminRecordDetailScreen`](file:///P:/DaalSetu/lib/modules/admin_catalog/view/admin_record_detail_screen.dart).

---

## 3. State Management & Lifecycle Guidelines
- **Controller Scope**:
  - Global controllers (`AuthController`) put with `Get.put(..., permanent: true)`.
  - Screen controllers (`AdminCatalogController`, `UserController`) tagged with unique identity hash or disposed via `Get.delete()` upon screen dispose.
- **Reactivity Rules**:
  - Use `RxList`, `RxString`, `RxBool` (`.obs`).
  - Listen to reactive dependencies using `ever()`, `debounce()`, or `interval()`.
  - Avoid wrapping whole screen trees in unnecessary nested `Obx`. Prefer isolated sub-trees.
  - Guard async actions against concurrent overlapping requests: `if (isLoading.value) return;`.

---

## 4. Network Layer & Authentication Architecture
- **API Client**: [`lib/network/api_client.dart`](file:///P:/DaalSetu/lib/network/api_client.dart)
  - Intercepts requests and injects `Authorization: Bearer <token>`.
  - Handles multipart uploads for PAN, GST, vehicle registration, and offer media.
  - Parses status codes and normalizes structured error maps.
  - Exposes `suppressErrorDialog` parameter to allow screens to handle specific business exceptions gracefully.

---

## 5. Timezone & Localization Architecture
- **Backend Standard**: UTC timestamps formatted as ISO 8601 strings (e.g., `2026-10-17T08:30:00Z`).
- **Frontend Display**: Converted to device local time (`DateTime.parse(ts).toLocal()`) with standard 12-hour AM/PM formatting.
