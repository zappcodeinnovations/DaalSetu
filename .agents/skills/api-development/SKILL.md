---
name: api-development
description: >-
  Use this skill when developing, integrating, debugging, or validating REST API endpoints, HTTP payloads, query parameters, and network communication.
---

# API Development & Integration Skill

## Purpose
Maintains stable, backwards-compatible, secure, and predictable communication between client apps and backend APIs.

## Procedure
1. **Verify Contract Before Coding**:
   - Consult `docs/ai-context/API_CONTRACTS.md` and reference backend (`P:\Daal_Broker`).
   - Check endpoint URI, HTTP method (GET, POST, PATCH, PUT, DELETE), header auth requirements, and query parameters.
2. **Payload & Validation**:
   - Validate required parameters client-side before dispatching.
   - Match exact backend field keys and data types (e.g. integer vs string IDs, floating-point prices).
3. **Robust Error Handling**:
   - Inspect status codes (400, 401, 403, 404, 500).
   - Parse backend error responses and display user-friendly, actionable messages.
   - Avoid generic "Something went wrong" messages when specific server validation errors exist.
4. **Idempotency & Concurrency**:
   - Guard against duplicate submissions by checking `isLoading` flags before dispatching requests.
