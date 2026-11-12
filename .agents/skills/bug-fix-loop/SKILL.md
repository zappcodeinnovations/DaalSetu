---
name: bug-fix-loop
description: >-
  Use this skill to diagnose, reproduce, implement minimal fixes, and execute the self-correcting debugging loop for reported software bugs.
---

# Bug-Fix Loop Skill

## Purpose
Executes a disciplined, evidence-based debugging cycle:
`Inspect → Reproduce → Diagnose → Minimal Fix → Test → Analyze → Refine → Regression Check → Report`

## Procedure
1. **Understand & Reproduce**:
   - Trace code execution path from user input to backend response.
   - Write an automated reproducing test in `test/`.
2. **Impact Analysis (Rule 20)**:
   - Identify files affected, upstream/downstream dependencies, and regression risks.
   - Formulate explanation: Problem, Root Cause, Files Affected, Risk, Implementation Plan, Rollback Plan.
3. **Safe Minimal Fix**:
   - Apply the smallest targeted modification.
   - Never replace whole files or refactor untouched logic.
4. **Iterative Verification (Up to 5 Loops)**:
   - Run the target test (`flutter test test/<test_file>.dart`).
   - If it fails, read the full error trace, refine the fix, and re-test.
5. **Document**:
   - Update `docs/ai-context/BUG_LOG.md` and report completion details.
