---
name: project-onboarding
description: >-
  Use this skill when onboarding into a project or starting a session to discover repository structure, architecture, dependencies, user roles, and existing test capabilities.
---

# Project Onboarding Skill

## Purpose
Establishes comprehensive understanding of the project's codebase, architecture, rules, and testing capabilities without making blind assumptions.

## Procedure
1. **Inspect Workspace**:
   - Check directory layout, package manifests (`pubspec.yaml`, `package.json`, `requirements.txt`), and documentation.
   - Inspect `.git` status to identify uncommitted changes.
2. **Inspect Architecture**:
   - Identify frontend clients, backend services, database systems, and integration points.
   - Review route registries, API clients, and authentication mechanisms.
3. **Inspect Rules & Instructions**:
   - Read global rules (`~/.gemini/GEMINI.md`) and workspace rules (`GEMINI.md`, `AGENTS.md`).
   - Review persistent context in `docs/ai-context/` if available.
4. **Discover Testing Capabilities**:
   - Locate test folders (`test/`, `tests/`, `spec/`).
   - Run a safe dry-run test command to confirm testing works.
5. **Record Findings**:
   - Summarize findings in `docs/ai-context/PROJECT_CONTEXT.md` and report to the user.
