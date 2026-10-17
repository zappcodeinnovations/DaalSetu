# Confirmed Technical & Product Decisions

## 1. Decision Log

| Date | Decision | Rationale | Alternatives Considered |
|---|---|---|---|
| 2026-10-17 | **Minimal Diff Implementation** | Adhere strictly to Euroside AI Rules. Change only the exact lines necessary to resolve the reported defect without refactoring untouched modules. | Complete module rewrites (rejected due to regression risk). |
| 2026-10-17 | **External Search Controller in AdminSearchBar** | Supply an external `TextEditingController` to `AdminSearchBar` so that the parent screen can clear search state deterministically during pull-to-refresh or AppBar refresh. | Retaining internal `TextField` controller (rejected because text persisted across refreshes). |
| 2026-10-17 | **UTC to Local Conversion in Negotiation Page** | Timestamps from Django backend are in UTC. Negotiation log displays must explicitly call `.toLocal()` and format as readable `dd MMM yyyy, hh:mm a`. | Applying fixed `+5:30` offsets (rejected because it breaks across daylight saving time or non-IST timezones). |
| 2026-10-17 | **Concurrent Fetch Hook in User Creation** | When `AddUserController` receives `status == "success"`, it notifies `UserController.fetchUsers()` immediately so network data arrives while the 900ms success snackbar is showing. | Relying solely on route return value (rejected because it added perceptible delay after screen popped). |
| 2026-10-17 | **Read-Only Web Backend Policy** | `P:\Daal_Broker` serves as the golden reference for business logic and database contracts. All fixes must be implemented on the Flutter app side unless explicit backend authorization is granted. | Modifying Django backend directly without authorization (rejected). |

---

## 2. Testing Decision Standards
- Every bug fix must include an automated unit or widget test reproducing the exact defect and verifying the fix.
- Tests must not make uncontrolled live network requests or invoke platform secure storage directly without proper mocking or harness isolation.
