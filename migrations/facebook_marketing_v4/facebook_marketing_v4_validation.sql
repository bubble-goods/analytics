-- ============================================
-- Facebook Marketing v4.0.0 Upgrade Validation
-- Run these queries to validate the upgrade
-- ============================================

-- PRE-UPGRADE BASELINE (Already captured in backup)
-- Total rows: 2435
-- instagram_actor_id populated: 2435 (100%)
-- effective_instagram_story_id populated: 2147 (88.2%)
-- instagram_story_id populated: 0 (0%)
-- source_instagram_media_id populated: 0 (0%)
-- Last sync: 2025-09-03 18:43:49.431+00

-- ============================================
-- POST-UPGRADE VALIDATION QUERIES
-- ============================================

-- 1. Basic row count and sync verification
SELECT 
    'POST-UPGRADE ROW COUNT' as check_type,
    COUNT(*) as current_rows,
    2435 as expected_rows,
    CASE 
        WHEN COUNT(*) >= 2435 THEN '✅ PASS' 
        ELSE '❌ FAIL - Row count decreased' 
    END as status,
    MAX(_airbyte_extracted_at) as last_sync
FROM meta_ads.ad_creatives;

-- 2. Check new field mappings exist and are populated
SELECT 
    'NEW FIELDS VALIDATION' as check_type,
    COUNT(*) FILTER (WHERE instagram_user_id IS NOT NULL) as instagram_user_id_count,
    COUNT(*) FILTER (WHERE effective_instagram_media_id IS NOT NULL) as effective_instagram_media_id_count,
    COUNT(*) FILTER (WHERE source_instagram_media_id IS NOT NULL) as source_instagram_media_id_count,
    CASE 
        WHEN COUNT(*) FILTER (WHERE instagram_user_id IS NOT NULL) > 0 THEN '✅ instagram_user_id populated'
        ELSE '❌ instagram_user_id not populated'
    END as instagram_user_id_status,
    CASE 
        WHEN COUNT(*) FILTER (WHERE effective_instagram_media_id IS NOT NULL) > 0 THEN '✅ effective_instagram_media_id populated'
        ELSE '❌ effective_instagram_media_id not populated'
    END as effective_instagram_media_id_status
FROM meta_ads.ad_creatives;

-- 3. Check if deprecated fields still exist (they shouldn't after upgrade)
SELECT 
    'DEPRECATED FIELDS CHECK' as check_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'meta_ads' 
            AND table_name = 'ad_creatives' 
            AND column_name = 'instagram_actor_id'
        ) THEN '⚠️ instagram_actor_id still exists'
        ELSE '✅ instagram_actor_id removed'
    END as instagram_actor_id_status,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'meta_ads' 
            AND table_name = 'ad_creatives' 
            AND column_name = 'effective_instagram_story_id'
        ) THEN '⚠️ effective_instagram_story_id still exists'
        ELSE '✅ effective_instagram_story_id removed'
    END as effective_instagram_story_id_status;

-- 4. Verify analytics views still work
SELECT 
    'ANALYTICS VIEWS CHECK' as check_type,
    COUNT(*) as meta_daily_rows,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ v_meta_ads_daily working'
        ELSE '❌ v_meta_ads_daily broken'
    END as meta_daily_status
FROM analytics.v_meta_ads_daily
WHERE spend_dt_utc >= CURRENT_DATE - INTERVAL '7 days';

-- 5. Check materialized view refresh
REFRESH MATERIALIZED VIEW CONCURRENTLY analytics.mv_ad_performance_daily;

SELECT 
    'MATERIALIZED VIEW CHECK' as check_type,
    COUNT(*) as mv_rows,
    SUM(CASE WHEN platform = 'meta' THEN 1 ELSE 0 END) as meta_rows,
    CASE 
        WHEN SUM(CASE WHEN platform = 'meta' THEN 1 ELSE 0 END) > 0 THEN '✅ Meta data in mv_ad_performance_daily'
        ELSE '❌ Meta data missing from mv_ad_performance_daily'
    END as mv_status
FROM analytics.mv_ad_performance_daily
WHERE date >= CURRENT_DATE - INTERVAL '7 days';

-- 6. Compare critical fields with backup for data consistency
SELECT 
    'DATA CONSISTENCY CHECK' as check_type,
    bc.id,
    bc.name,
    bc.instagram_actor_id as old_instagram_actor_id,
    ac.instagram_user_id as new_instagram_user_id,
    bc.effective_instagram_story_id as old_effective_instagram_story_id,
    ac.effective_instagram_media_id as new_effective_instagram_media_id,
    CASE 
        WHEN bc.instagram_actor_id = ac.instagram_user_id THEN '✅ Match'
        WHEN bc.instagram_actor_id IS NULL AND ac.instagram_user_id IS NULL THEN '✅ Both NULL'
        ELSE '⚠️ Values differ'
    END as instagram_id_comparison
FROM meta_ads.ad_creatives_backup_pre_v4 bc
JOIN meta_ads.ad_creatives ac ON bc.id = ac.id
LIMIT 10;

-- ============================================
-- ROLLBACK VALIDATION (if needed)
-- ============================================

-- If rollback is needed, verify backup data integrity
SELECT 
    'BACKUP INTEGRITY CHECK' as check_type,
    COUNT(*) as backup_rows,
    COUNT(DISTINCT id) as unique_ids,
    CASE 
        WHEN COUNT(*) = COUNT(DISTINCT id) THEN '✅ No duplicate IDs in backup'
        ELSE '❌ Duplicate IDs found in backup'
    END as backup_status
FROM meta_ads.ad_creatives_backup_pre_v4;

-- ============================================
-- SUMMARY REPORT
-- ============================================

SELECT 
    '=== FACEBOOK MARKETING V4.0.0 UPGRADE SUMMARY ===' as report,
    CURRENT_TIMESTAMP as validation_time,
    '1. Check row counts match pre-upgrade baseline' as step_1,
    '2. Verify new fields are populated with expected data' as step_2,
    '3. Confirm deprecated fields are removed from schema' as step_3,
    '4. Test analytics views and materialized views work' as step_4,
    '5. Spot-check data consistency between old and new fields' as step_5,
    'All checks should show ✅ PASS for successful upgrade' as success_criteria;