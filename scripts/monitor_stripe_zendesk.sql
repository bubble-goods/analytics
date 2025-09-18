-- ============================================
-- Stripe & Zendesk Data Pipeline Monitor
-- Run this daily to check data freshness
-- Database: Supabase
-- ============================================

-- Summary Report
SELECT 'STRIPE & ZENDESK DATA PIPELINE HEALTH CHECK' as report_title, NOW() as run_time;

-- ============================================
-- STRIPE DATA FRESHNESS CHECK
-- ============================================

SELECT '=== STRIPE DATA FRESHNESS ===' as section;

-- Check all Stripe schemas for data freshness
WITH stripe_freshness AS (
    SELECT
        'stripe' as schema_name,
        'charges' as table_name,
        COUNT(*) as row_count,
        TO_TIMESTAMP(MAX(created)) as latest_record,
        CURRENT_DATE - TO_TIMESTAMP(MAX(created))::date as days_behind,
        CASE
            WHEN CURRENT_DATE - TO_TIMESTAMP(MAX(created))::date = 0 THEN '✅ Current'
            WHEN CURRENT_DATE - TO_TIMESTAMP(MAX(created))::date <= 7 THEN '⚠️ Behind'
            ELSE '❌ Stale'
        END as status
    FROM stripe.charges

    UNION ALL

    SELECT
        'stripe' as schema_name,
        'invoices' as table_name,
        COUNT(*) as row_count,
        TO_TIMESTAMP(MAX(created)) as latest_record,
        CURRENT_DATE - TO_TIMESTAMP(MAX(created))::date as days_behind,
        CASE
            WHEN CURRENT_DATE - TO_TIMESTAMP(MAX(created))::date = 0 THEN '✅ Current'
            WHEN CURRENT_DATE - TO_TIMESTAMP(MAX(created))::date <= 7 THEN '⚠️ Behind'
            ELSE '❌ Stale'
        END as status
    FROM stripe.invoices

    UNION ALL

    SELECT
        'stripe' as schema_name,
        'subscriptions' as table_name,
        COUNT(*) as row_count,
        TO_TIMESTAMP(MAX(created)) as latest_record,
        CURRENT_DATE - TO_TIMESTAMP(MAX(created))::date as days_behind,
        CASE
            WHEN CURRENT_DATE - TO_TIMESTAMP(MAX(created))::date = 0 THEN '✅ Current'
            WHEN CURRENT_DATE - TO_TIMESTAMP(MAX(created))::date <= 7 THEN '⚠️ Behind'
            ELSE '❌ Stale'
        END as status
    FROM stripe.subscriptions

    UNION ALL

    -- Check public schema (wrong destination)
    SELECT
        'public' as schema_name,
        'charges' as table_name,
        COUNT(*) as row_count,
        MAX(updated_at) as latest_record,
        CURRENT_DATE - MAX(updated_at)::date as days_behind,
        CASE
            WHEN CURRENT_DATE - MAX(updated_at)::date = 0 THEN '⚠️ Wrong Schema'
            WHEN CURRENT_DATE - MAX(updated_at)::date <= 7 THEN '⚠️ Wrong Schema'
            ELSE '❌ Wrong Schema + Stale'
        END as status
    FROM public.charges
    WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'charges')
)
SELECT * FROM stripe_freshness ORDER BY schema_name, table_name;

-- ============================================
-- ZENDESK DATA FRESHNESS CHECK
-- ============================================

SELECT '=== ZENDESK DATA FRESHNESS ===' as section;

WITH zendesk_freshness AS (
    SELECT
        'zendesk' as schema_name,
        'tickets' as table_name,
        COUNT(*) as row_count,
        MAX(created_at) as latest_record,
        CURRENT_DATE - MAX(created_at)::date as days_behind,
        CASE
            WHEN CURRENT_DATE - MAX(created_at)::date = 0 THEN '✅ Current'
            WHEN CURRENT_DATE - MAX(created_at)::date <= 1 THEN '⚠️ Behind'
            ELSE '❌ Stale'
        END as status
    FROM zendesk.tickets

    UNION ALL

    SELECT
        'zendesk' as schema_name,
        'ticket_comments' as table_name,
        COUNT(*) as row_count,
        MAX(created_at) as latest_record,
        CURRENT_DATE - MAX(created_at)::date as days_behind,
        CASE
            WHEN CURRENT_DATE - MAX(created_at)::date = 0 THEN '✅ Current'
            WHEN CURRENT_DATE - MAX(created_at)::date <= 1 THEN '⚠️ Behind'
            ELSE '❌ Stale'
        END as status
    FROM zendesk.ticket_comments

    UNION ALL

    SELECT
        'zendesk' as schema_name,
        'satisfaction_ratings' as table_name,
        COUNT(*) as row_count,
        MAX(created_at) as latest_record,
        CURRENT_DATE - MAX(created_at)::date as days_behind,
        CASE
            WHEN CURRENT_DATE - MAX(created_at)::date = 0 THEN '✅ Current'
            WHEN CURRENT_DATE - MAX(created_at)::date <= 7 THEN '⚠️ Behind'
            ELSE '❌ Stale'
        END as status
    FROM zendesk.satisfaction_ratings
)
SELECT * FROM zendesk_freshness ORDER BY table_name;

-- ============================================
-- AIRBYTE SYNC STATUS CHECK
-- ============================================

SELECT '=== AIRBYTE SYNC STATUS ===' as section;

SELECT
    name as stream_name,
    namespace as schema_name,
    updated_at as last_sync,
    CURRENT_TIMESTAMP - updated_at as time_since_sync,
    CASE
        WHEN CURRENT_TIMESTAMP - updated_at < INTERVAL '1 day' THEN '✅ Recent'
        WHEN CURRENT_TIMESTAMP - updated_at < INTERVAL '7 days' THEN '⚠️ Behind'
        ELSE '❌ Stale'
    END as sync_status
FROM airbyte_internal._airbyte_destination_state
WHERE (namespace = 'stripe' OR namespace = 'zendesk' OR
       (namespace = 'public' AND name IN ('charges', 'invoices', 'subscriptions', 'tickets')))
ORDER BY namespace, name;

-- ============================================
-- DATA VOLUME TRENDS (Last 30 Days)
-- ============================================

SELECT '=== RECENT DATA VOLUME TRENDS ===' as section;

-- Stripe charges by day (last 30 days)
SELECT
    'stripe_charges_daily' as metric,
    DATE_TRUNC('day', TO_TIMESTAMP(created)) as date,
    COUNT(*) as daily_count,
    SUM(amount) / 100.0 as daily_amount_usd
FROM stripe.charges
WHERE TO_TIMESTAMP(created) >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE_TRUNC('day', TO_TIMESTAMP(created))
ORDER BY date DESC
LIMIT 10;

-- Zendesk tickets by day (last 30 days)
SELECT
    'zendesk_tickets_daily' as metric,
    DATE_TRUNC('day', created_at) as date,
    COUNT(*) as daily_count
FROM zendesk.tickets
WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY DATE_TRUNC('day', created_at)
ORDER BY date DESC
LIMIT 10;

-- ============================================
-- CRITICAL ALERTS
-- ============================================

SELECT '=== CRITICAL ALERTS ===' as section;

-- Alert for Stripe data older than 7 days
SELECT
    'STRIPE DATA STALE' as alert_type,
    'stripe.charges' as table_name,
    CURRENT_DATE - TO_TIMESTAMP(MAX(created))::date as days_behind,
    'Stripe charges data is critically stale' as message
FROM stripe.charges
WHERE CURRENT_DATE - TO_TIMESTAMP(MAX(created))::date > 7

UNION ALL

-- Alert for Zendesk satisfaction ratings older than 30 days
SELECT
    'ZENDESK SATISFACTION STALE' as alert_type,
    'zendesk.satisfaction_ratings' as table_name,
    CURRENT_DATE - MAX(created_at)::date as days_behind,
    'Satisfaction ratings data is critically stale' as message
FROM zendesk.satisfaction_ratings
WHERE CURRENT_DATE - MAX(created_at)::date > 30

UNION ALL

-- Alert for wrong schema usage
SELECT
    'WRONG SCHEMA USAGE' as alert_type,
    'public.charges' as table_name,
    NULL as days_behind,
    'Stripe data syncing to wrong schema (public instead of stripe)' as message
WHERE EXISTS (
    SELECT 1 FROM airbyte_internal._airbyte_destination_state
    WHERE namespace = 'public' AND name = 'charges'
    AND updated_at > CURRENT_TIMESTAMP - INTERVAL '2 days'
);

-- ============================================
-- SUMMARY REPORT
-- ============================================

SELECT '=== PIPELINE HEALTH SUMMARY ===' as section;

WITH health_summary AS (
    SELECT
        COUNT(CASE WHEN CURRENT_DATE - TO_TIMESTAMP(MAX(created))::date <= 1 THEN 1 END) as stripe_current_tables,
        COUNT(CASE WHEN CURRENT_DATE - TO_TIMESTAMP(MAX(created))::date > 7 THEN 1 END) as stripe_stale_tables,
        (SELECT COUNT(CASE WHEN CURRENT_DATE - MAX(created_at)::date <= 1 THEN 1 END)
         FROM zendesk.tickets) as zendesk_current_count,
        (SELECT COUNT(CASE WHEN CURRENT_DATE - MAX(created_at)::date > 7 THEN 1 END)
         FROM zendesk.satisfaction_ratings) as zendesk_stale_count
    FROM stripe.charges, stripe.invoices, stripe.subscriptions
)
SELECT
    CASE
        WHEN stripe_stale_tables > 0 THEN '❌ STRIPE ISSUES DETECTED'
        WHEN stripe_current_tables > 0 THEN '✅ STRIPE OK'
        ELSE '⚠️ STRIPE UNKNOWN'
    END as stripe_status,
    CASE
        WHEN zendesk_stale_count > 0 THEN '⚠️ ZENDESK PARTIAL ISSUES'
        WHEN zendesk_current_count > 0 THEN '✅ ZENDESK OK'
        ELSE '❌ ZENDESK ISSUES'
    END as zendesk_status,
    NOW() as last_checked
FROM health_summary;

-- End of monitoring script