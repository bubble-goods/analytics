-- ============================================
-- Ad Performance Data Refresh Script
-- Run this daily to update ROAS metrics
-- Database: Supabase
-- ============================================

-- Step 1: Refresh the materialized view
-- This combines Google and Meta ad data into unified metrics
REFRESH MATERIALIZED VIEW CONCURRENTLY analytics.mv_ad_performance_daily;

-- Step 2: Log the refresh
INSERT INTO analytics.refresh_log (
    table_name,
    refresh_time,
    row_count,
    status
)
SELECT 
    'mv_ad_performance_daily',
    NOW(),
    COUNT(*),
    'success'
FROM analytics.mv_ad_performance_daily;

-- Step 3: Data quality checks
DO $$
DECLARE
    google_count INTEGER;
    meta_count INTEGER;
    total_spend DECIMAL;
    days_with_data INTEGER;
BEGIN
    -- Check Google Ads data
    SELECT COUNT(DISTINCT campaign_key) 
    INTO google_count
    FROM analytics.mv_ad_performance_daily
    WHERE platform = 'google'
    AND date >= CURRENT_DATE - INTERVAL '7 days';
    
    -- Check Meta Ads data
    SELECT COUNT(DISTINCT campaign_key)
    INTO meta_count
    FROM analytics.mv_ad_performance_daily
    WHERE platform = 'meta'
    AND date >= CURRENT_DATE - INTERVAL '7 days';
    
    -- Check total spend
    SELECT SUM(total_spend)
    INTO total_spend
    FROM analytics.mv_ad_performance_daily
    WHERE date >= CURRENT_DATE - INTERVAL '7 days';
    
    -- Check data completeness
    SELECT COUNT(DISTINCT date)
    INTO days_with_data
    FROM analytics.mv_ad_performance_daily
    WHERE date >= CURRENT_DATE - INTERVAL '7 days';
    
    -- Alert if issues found
    IF google_count = 0 THEN
        RAISE NOTICE 'WARNING: No Google Ads data in last 7 days';
    END IF;
    
    IF meta_count = 0 THEN
        RAISE NOTICE 'WARNING: No Meta Ads data in last 7 days';
    END IF;
    
    IF total_spend = 0 OR total_spend IS NULL THEN
        RAISE NOTICE 'WARNING: No ad spend recorded in last 7 days';
    END IF;
    
    IF days_with_data < 7 THEN
        RAISE NOTICE 'WARNING: Missing data for % days', 7 - days_with_data;
    END IF;
    
    -- Log summary
    RAISE NOTICE 'Refresh complete: % Google campaigns, % Meta campaigns, $% total spend',
        google_count, meta_count, ROUND(total_spend, 2);
END $$;

-- Step 4: Update statistics for query optimization
ANALYZE analytics.mv_ad_performance_daily;

-- Step 5: Optional - Archive old detailed data
-- Uncomment if you want to archive data older than 90 days
/*
INSERT INTO analytics.ad_performance_archive
SELECT * FROM analytics.mv_ad_performance_daily
WHERE date < CURRENT_DATE - INTERVAL '90 days'
ON CONFLICT (date, campaign_key) DO NOTHING;

DELETE FROM analytics.mv_ad_performance_daily
WHERE date < CURRENT_DATE - INTERVAL '90 days';
*/

-- Step 6: Generate daily summary
SELECT 
    'Daily ROAS Summary' as report,
    CURRENT_DATE as date,
    ROUND(SUM(CASE WHEN platform = 'google' THEN total_spend ELSE 0 END), 2) as google_spend,
    ROUND(SUM(CASE WHEN platform = 'meta' THEN total_spend ELSE 0 END), 2) as meta_spend,
    ROUND(SUM(total_spend), 2) as total_spend,
    ROUND(SUM(total_revenue), 2) as total_revenue,
    ROUND(SUM(total_revenue) / NULLIF(SUM(total_spend), 0), 2) as overall_roas,
    SUM(total_conversions) as total_conversions
FROM analytics.mv_ad_performance_daily
WHERE date = CURRENT_DATE - INTERVAL '1 day';