---
name: premium-ui
description: >-
  Use this skill when designing, building, or refining user interfaces to deliver production-quality, accessible, responsive, and consistent UI/UX.
---

# Premium UI/UX Engine Skill

## Purpose
Guarantees clean, modern, professional, and accessible user interfaces aligned with the project's established design system.

## Procedure
1. **Inspect Existing Design Tokens**:
   - Consult `docs/ai-context/UI_DESIGN_SYSTEM.md` and `lib/theme/app_theme.dart`.
   - Never invent arbitrary colors, margins, or font families that clash with existing screens.
2. **Handle All UI States**:
   - Initial Loading: Display proper spinners or skeleton shimmer.
   - Empty Data: Show meaningful empty illustration and actionable call-to-action (`AdminEmptyWidget`).
   - Error State: Render clean error message with "Try again" action (`AdminErrorWidget`).
   - Active Search & Filter: Provide responsive search feedback and easy clear mechanisms.
   - Form Submissions: Disable buttons and show loading spinners to prevent double-submissions.
3. **Responsive & Accessible Design**:
   - Ensure layouts adapt cleanly between mobile screens, tablets, and desktop/web widths.
   - Verify color contrast and touch targets (minimum 44x44px).
