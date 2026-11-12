---
name: security-review
description: >-
  Use this skill to audit code for sensitive credentials, authorization boundaries, input sanitization, token handling, and secure data storage.
---

# Security & Data Protection Skill

## Purpose
Guarantees that credentials, tokens, sensitive customer data, and system permissions are protected across all operations.

## Procedure
1. **Secrets & Credentials Protection**:
   - Never commit passwords, private API keys, certificates, or tokens to version control.
   - Never log authorization headers or full tokens in console output.
2. **Client-Side Storage Audit**:
   - Ensure tokens and sensitive user data use `flutter_secure_storage` instead of plain `SharedPreferences`.
3. **Authorization & Role Verification**:
   - Verify that client-side UI restrictions are backed by strict server-side permission checks.
   - Ensure users cannot access or modify records belonging to other roles or tenants.
4. **Input Sanitization**:
   - Validate and sanitize text inputs against injection attacks and malformed payloads.
