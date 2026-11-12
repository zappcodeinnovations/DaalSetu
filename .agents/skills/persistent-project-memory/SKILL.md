---
name: persistent-project-memory
description: >-
  Use this skill to maintain, read, and synchronize the persistent repository-backed knowledge system in docs/ai-context/ across sessions and bug fixes.
---

# Persistent Project Memory Skill

## Purpose
Maintains long-term, repository-backed documentation in `docs/ai-context/` so project context, decisions, API contracts, and bug history persist reliably across conversations.

## Procedure
1. **At Task Start**:
   - Read `docs/ai-context/TASK_STATE.md` and `docs/ai-context/PROJECT_CONTEXT.md`.
   - Verify uncommitted Git changes before writing any code.
2. **During Implementation**:
   - Record significant design choices and trade-offs in `docs/ai-context/DECISIONS.md`.
   - Update endpoint contracts in `docs/ai-context/API_CONTRACTS.md` when verified.
3. **At Task Completion**:
   - Update `docs/ai-context/TASK_STATE.md` with completed items and next steps.
   - Append resolved issues to `docs/ai-context/BUG_LOG.md`.
   - Keep notes factual, concise, and backed by verifiable evidence.
