# UI Design System & Component Library

## 1. Visual Theme Tokens
Located in [`lib/theme/app_theme.dart`](file:///P:/DaalSetu/lib/theme/app_theme.dart).

### Primary Colors
- **Primary Gold**: `#F4B400` (`AppTheme.primaryGold`)
- **Secondary Orange**: `#E37400` (`AppTheme.secondaryOrange`)
- **Success Green**: `#22C55E` / `#16A34A`
- **Error Red**: `#EF4444` / `#DC2626`
- **Warning Amber**: `#F59E0B` / `#D97706`

### Neutral & Background Colors
- **Light Scaffold**: `#F8F9FA`
- **Dark Scaffold**: `#0F1724`
- **Light Surface / Card**: `#FFFFFF`
- **Dark Surface / Card**: `#202B3D`
- **Borders**: `#E2E8F0` (light) / `#2D3B55` (dark)
- **Light Text Tokens**:
  - Primary: `#0A0F1D` (Deep rich charcoal)
  - Secondary: `#1E293B` (High-contrast slate)
  - Muted: `#475569` (Medium slate)

---

## 2. Typography Hierarchy
Utilizes Google Fonts (Poppins for titles/headers, Inter for body/controls):
- **Headline / Title Large**: Poppins, 20-24px, Bold (`FontWeight.w700` / `w800`)
- **Title Medium**: Poppins, 16-18px, Semi-Bold (`FontWeight.w600`)
- **Title Small**: Poppins, 14px, Semi-Bold (`FontWeight.w600`)
- **Body Large**: Inter, 16px, Semi-Bold (`FontWeight.w600`)
- **Body Medium**: Inter, 14px, Medium (`FontWeight.w500`)
- **Body Small / Captions**: Inter, 12px, Medium (`FontWeight.w500`)
- **Stats Numbers**: Poppins, 22-26px, Extra Bold (`FontWeight.w800` / `w900`)

---

## 3. Standard UI Components
1. **Search Bar**: [`AdminSearchBar`](file:///P:/DaalSetu/lib/widgets/admin_common_widgets.dart) with 16px rounded borders, prefix search icon, and reactive clear button.
2. **Choice Chips**: Horizontal scrollable list for category and status filtering (`pending`, `active`, `inactive`, `rejected`).
3. **Stat Cards**: Grid / horizontal carousel cards with category icon, stat label, and bold value.
4. **Empty / Error / Loading States**: `AdminEmptyWidget`, `AdminErrorWidget`, `AdminLoadingWidget`.
5. **Floating Action Button**: Extended FAB with icon + label positioned at bottom-right.
