# Data Migrations

This directory tracks database schema changes, connector upgrades, and data pipeline migrations for the Bubble Goods analytics infrastructure.

## Migration History

### Facebook Marketing Connector v4.0.0 (September 2025)
**Status:** ✅ Completed Successfully  
**Location:** `facebook_marketing_v4/`

Upgraded Airbyte Facebook Marketing connector from v3.x to v4.0.0 to meet platform requirements.

**Key Changes:**
- Deprecated Instagram fields replaced with new field mappings:
  - `instagram_actor_id` → `instagram_user_id`
  - `effective_instagram_story_id` → `effective_instagram_media_id`
  - `instagram_story_id` → `source_instagram_media_id`

**Impact:** Zero business impact - affected `ad_creatives` table is not used in core ROAS tracking

**Files:**
- `FACEBOOK_MARKETING_V4_MIGRATION.md` - Migration planning and instructions
- `FACEBOOK_MARKETING_V4_MIGRATION_RESULTS.md` - Post-migration validation results
- `facebook_marketing_v4_validation.sql` - Validation queries

---

## Migration Guidelines

When planning future migrations:

1. **Assessment Phase**
   - Document current state and dependencies
   - Identify impact on dashboards and reports
   - Create backup strategies

2. **Testing Phase**
   - Create backups of affected data
   - Prepare validation queries
   - Test on non-production data if possible

3. **Execution Phase**
   - Follow documented migration steps
   - Monitor for errors during sync/processing
   - Validate data integrity immediately after

4. **Documentation**
   - Document results and any issues encountered
   - Update relevant documentation
   - Archive migration artifacts in this directory

## Contact

For questions about past migrations or planning new ones:
- Engineering team via Slack #tech-analytics
- Reference existing migration docs for patterns and best practices