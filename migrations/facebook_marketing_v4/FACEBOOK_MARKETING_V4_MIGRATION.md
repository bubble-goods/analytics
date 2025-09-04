# Facebook Marketing Connector v4.0.0 Migration Guide

## Migration Overview

**Deadline:** September 8, 2025
**Connector:** Facebook Marketing (Airbyte)
**Impact Level:** LOW - No impact on current analytics or dashboards

## Pre-Migration Status ✅ COMPLETE

### Backup Created
- **Table:** `meta_ads.ad_creatives_backup_pre_v4`
- **Records:** 2,435 ad creatives backed up
- **Last Sync:** September 3, 2025 at 18:43:49 UTC
- **Location:** Supabase project `xvneymjzgffbgkhpruwn`

### Current Field Population
- `instagram_actor_id`: 2,435 records (100%)
- `effective_instagram_story_id`: 2,147 records (88.2%)  
- `instagram_story_id`: 0 records (0%)
- `source_instagram_media_id`: 0 records (0%)

## Field Mappings in v4.0.0

| Deprecated Field | New Field | Current Data |
|------------------|-----------|--------------|
| `instagram_actor_id` | `instagram_user_id` | 2,435 values |
| `effective_instagram_story_id` | `effective_instagram_media_id` | 2,147 values |
| `instagram_story_id` | `source_instagram_media_id` | 0 values |

## Migration Steps

### Phase 1: Pre-Upgrade (✅ COMPLETE)
1. ✅ Created backup table `meta_ads.ad_creatives_backup_pre_v4`
2. ✅ Documented current schema and field mappings
3. ✅ Created validation queries in `scripts/facebook_marketing_v4_validation.sql`
4. ✅ Verified current sync status (last sync 24 hours ago)

### Phase 2: Airbyte Upgrade (READY FOR EXECUTION)
**Instructions for Airbyte UI:**

1. **Pause the Facebook Marketing connection**
   - Go to Airbyte dashboard
   - Find "Facebook Marketing" source
   - Click "Pause" to stop current syncs

2. **Upgrade to v4.0.0**
   - Click on the Facebook Marketing connection
   - Look for upgrade notification/banner
   - Click "Upgrade" button
   - Confirm v4.0.0 upgrade

3. **Resume connection**
   - After upgrade completes, click "Resume"
   - Monitor the first sync for errors

### Phase 3: Post-Upgrade Validation (READY)

Run the validation script:
```sql
-- Execute this in Supabase SQL Editor
\i scripts/facebook_marketing_v4_validation.sql
```

**Expected Results:**
- Row count should remain 2,435+ records
- New fields (`instagram_user_id`, `effective_instagram_media_id`) should be populated
- Analytics views should continue working
- Materialized view `mv_ad_performance_daily` should refresh successfully

## Impact Analysis ✅ CONFIRMED SAFE

### ✅ No Impact Areas
- **ROAS Dashboard**: Uses `meta_ads.ads_insights`, not `ad_creatives`
- **Analytics Views**: `v_meta_ads_daily` doesn't reference deprecated fields
- **Materialized Views**: `mv_ad_performance_daily` unaffected
- **Metabase Dashboards**: No dependencies on AdCreatives table
- **Python Scripts**: No references to deprecated fields found

### ⚠️ Monitoring Required
- First sync after upgrade (watch for errors)
- New field population rates
- Data consistency between old and new fields

## Rollback Plan (If Needed)

If the upgrade causes issues:

1. **Immediate Rollback in Airbyte:**
   - Pause the connection
   - Contact Airbyte support for downgrade assistance
   - Check if connector version rollback is possible

2. **Data Recovery:**
   ```sql
   -- Restore from backup if needed
   DROP TABLE meta_ads.ad_creatives;
   CREATE TABLE meta_ads.ad_creatives AS 
   SELECT * FROM meta_ads.ad_creatives_backup_pre_v4;
   ```

## Post-Migration Cleanup (Optional)

After confirming successful upgrade (wait 1 week):

```sql
-- Remove backup table if no longer needed
-- DROP TABLE meta_ads.ad_creatives_backup_pre_v4;
```

## Contact Information

- **Technical Issues**: Engineering team via Slack #tech-analytics
- **Data Validation**: Run validation queries and report results
- **Airbyte Support**: If connector upgrade fails

## Migration Checklist

- [x] Backup created
- [x] Impact assessment complete
- [x] Validation queries prepared
- [x] Migration guide documented
- [ ] Airbyte upgrade executed
- [ ] Post-upgrade validation run
- [ ] Results verified and documented
- [ ] Team notified of completion

---

**Status:** Ready for Airbyte upgrade execution
**Next Action:** Execute Phase 2 (Airbyte Upgrade) before September 8, 2025