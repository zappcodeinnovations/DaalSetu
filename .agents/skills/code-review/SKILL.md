---
name: code-review
description: >-
  Use this skill to perform rigorous code reviews, check minimal diffs, ensure backward compatibility, and verify adherence to Euroside engineering rules.
---

# Code Review & Quality Assurance Skill

## Purpose
Performs strict, production-grade code reviews before finalizing any pull request or development task.

## Procedure
1. **Minimal Diff Verification**:
   - Inspect `git diff` to confirm only the exact lines required for the task were changed.
   - Reject arbitrary whitespace changes, file reorganizations, or unrequested refactors.
2. **Backward Compatibility Check**:
   - Verify that existing APIs, models, parameter defaults, and view arguments remain backward-compatible.
3. **Architecture & Conventions**:
   - Confirm reuse of existing services, controllers, mixins, and design tokens.
   - Guard against duplicate business logic and N+1 query patterns.
4. **Documentation & Tests**:
   - Confirm new code has corresponding unit/widget test coverage.
   - Ensure `docs/ai-context/` is updated with all verified changes.
