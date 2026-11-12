---
name: database-migration-review
description: >-
  Use this skill to inspect, review, and evaluate database schemas, models, migrations, relationships, and performance impacts.
---

# Database Migration & Schema Review Skill

## Purpose
Ensures data integrity, backward compatibility, performance optimization, and safe database operations.

## Procedure
1. **Safety First**:
   - Never perform destructive schema modifications (dropping columns or tables) on existing live databases without authorization.
   - For backend changes in `P:\Daal_Broker`, inspect `brokers_app/migrations/` before proposing new migrations.
2. **Model Integrity**:
   - Check foreign key relations, cascade behaviors, and default values.
   - Ensure nullability rules match client-side model expectations.
3. **Query Optimization**:
   - Check for N+1 query patterns.
   - Use `select_related()` and `prefetch_related()` for related lookups.
   - Ensure appropriate database indexes exist for frequently searched or filtered fields (e.g. `brand_name`, `status`).
4. **Rollback Strategy**:
   - Ensure every migration has a corresponding backward rollback plan.
