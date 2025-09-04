-- ROAS Tracking Queries
-- Database: Supabase (ID: 5)
-- Schema: analytics
-- Table: mv_ad_performance_daily

-- ============================================
-- 1. Overall ROAS Summary (Last 30 Days)
-- ============================================
SELECT 
    COUNT(DISTINCT campaign_key) as total_campaigns,
    SUM(total_spend) as total_spend,
    SUM(total_revenue) as total_revenue,
    ROUND(SUM(total_revenue) / NULLIF(SUM(total_spend), 0), 2) as overall_roas,
    SUM(total_clicks) as total_clicks,
    SUM(total_impressions) as total_impressions,
    SUM(total_conversions) as total_conversions,
    ROUND(SUM(total_clicks)::NUMERIC / NULLIF(SUM(total_impressions), 0) * 100, 2) as overall_ctr,
    ROUND(SUM(total_spend) / NULLIF(SUM(total_clicks), 0), 2) as overall_cpc
FROM analytics.mv_ad_performance_daily
WHERE date >= CURRENT_DATE - INTERVAL '30 days';

-- ============================================
-- 2. Platform Comparison
-- ============================================
SELECT 
    platform,
    COUNT(DISTINCT campaign_key) as campaigns,
    ROUND(SUM(total_spend)::NUMERIC, 2) as spend,
    ROUND(SUM(total_revenue)::NUMERIC, 2) as revenue,
    ROUND(SUM(total_revenue) / NULLIF(SUM(total_spend), 0), 2) as roas,
    SUM(total_conversions) as conversions,
    ROUND(SUM(total_spend) / NULLIF(SUM(total_conversions), 0), 2) as cac
FROM analytics.mv_ad_performance_daily
WHERE date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY platform
ORDER BY spend DESC;

-- ============================================
-- 3. Top Performing Campaigns by ROAS
-- ============================================
SELECT 
    campaign_key,
    platform,
    ROUND(SUM(total_spend)::NUMERIC, 2) as spend,
    ROUND(SUM(total_revenue)::NUMERIC, 2) as revenue,
    ROUND(SUM(total_revenue) / NULLIF(SUM(total_spend), 0), 2) as roas,
    SUM(total_conversions) as conversions,
    SUM(total_clicks) as clicks,
    ROUND(AVG(avg_ctr)::NUMERIC, 2) as avg_ctr
FROM analytics.mv_ad_performance_daily
WHERE date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY campaign_key, platform
HAVING SUM(total_spend) > 100  -- Filter out test/tiny campaigns
ORDER BY roas DESC
LIMIT 20;

-- ============================================
-- 4. Underperforming Campaigns (Need Attention)
-- ============================================
SELECT 
    campaign_key,
    platform,
    ROUND(SUM(total_spend)::NUMERIC, 2) as spend,
    ROUND(SUM(total_revenue)::NUMERIC, 2) as revenue,
    ROUND(SUM(total_revenue) / NULLIF(SUM(total_spend), 0), 2) as roas,
    CASE 
        WHEN SUM(total_revenue) / NULLIF(SUM(total_spend), 0) < 0.5 THEN 'Critical'
        WHEN SUM(total_revenue) / NULLIF(SUM(total_spend), 0) < 1.0 THEN 'Unprofitable'
        ELSE 'Monitor'
    END as status
FROM analytics.mv_ad_performance_daily
WHERE date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY campaign_key, platform
HAVING SUM(total_spend) > 50
    AND SUM(total_revenue) / NULLIF(SUM(total_spend), 0) < 1.0
ORDER BY spend DESC;

-- ============================================
-- 5. Daily Trend Analysis
-- ============================================
SELECT 
    date,
    platform,
    ROUND(SUM(total_spend)::NUMERIC, 2) as daily_spend,
    ROUND(SUM(total_revenue)::NUMERIC, 2) as daily_revenue,
    ROUND(SUM(total_revenue) / NULLIF(SUM(total_spend), 0), 2) as daily_roas
FROM analytics.mv_ad_performance_daily
WHERE date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY date, platform
ORDER BY date DESC, platform;

-- ============================================
-- 6. Week-over-Week Performance
-- ============================================
WITH weekly_metrics AS (
    SELECT 
        DATE_TRUNC('week', date) as week_start,
        platform,
        SUM(total_spend) as weekly_spend,
        SUM(total_revenue) as weekly_revenue,
        SUM(total_conversions) as weekly_conversions
    FROM analytics.mv_ad_performance_daily
    WHERE date >= CURRENT_DATE - INTERVAL '4 weeks'
    GROUP BY DATE_TRUNC('week', date), platform
)
SELECT 
    week_start,
    platform,
    ROUND(weekly_spend::NUMERIC, 2) as spend,
    ROUND(weekly_revenue::NUMERIC, 2) as revenue,
    ROUND(weekly_revenue / NULLIF(weekly_spend, 0), 2) as roas,
    weekly_conversions as conversions,
    ROUND(weekly_spend / NULLIF(weekly_conversions, 0), 2) as cac
FROM weekly_metrics
ORDER BY week_start DESC, platform;

-- ============================================
-- 7. Campaign Efficiency Metrics
-- ============================================
SELECT 
    platform,
    ROUND(AVG(avg_ctr)::NUMERIC, 2) as avg_ctr_percent,
    ROUND(AVG(avg_cpc)::NUMERIC, 2) as avg_cpc_usd,
    ROUND(AVG(avg_cpm)::NUMERIC, 2) as avg_cpm_usd,
    COUNT(DISTINCT campaign_key) as active_campaigns
FROM analytics.mv_ad_performance_daily
WHERE date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY platform;

-- ============================================
-- 8. Revenue Attribution by Platform
-- ============================================
SELECT 
    platform,
    SUM(total_revenue) as revenue,
    ROUND(100.0 * SUM(total_revenue) / 
        SUM(SUM(total_revenue)) OVER (), 2) as revenue_share_pct,
    SUM(total_spend) as spend,
    ROUND(100.0 * SUM(total_spend) / 
        SUM(SUM(total_spend)) OVER (), 2) as spend_share_pct
FROM analytics.mv_ad_performance_daily
WHERE date >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY platform
ORDER BY revenue DESC;

-- ============================================
-- 9. Alert: Campaigns Needing Immediate Review
-- ============================================
SELECT 
    'High Spend, Zero Revenue' as alert_type,
    campaign_key,
    platform,
    ROUND(SUM(total_spend)::NUMERIC, 2) as spend_last_7d,
    SUM(total_conversions) as conversions
FROM analytics.mv_ad_performance_daily
WHERE date >= CURRENT_DATE - INTERVAL '7 days'
GROUP BY campaign_key, platform
HAVING SUM(total_spend) > 500
    AND SUM(total_revenue) = 0
ORDER BY spend_last_7d DESC;

-- ============================================
-- 10. Refresh Materialized View
-- ============================================
-- Run this daily or as needed to update data
-- REFRESH MATERIALIZED VIEW CONCURRENTLY analytics.mv_ad_performance_daily;