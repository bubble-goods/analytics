-- ============================================
-- Stripe Data Consolidation Script
-- Consolidate Stripe data from public schema to stripe schema
-- Database: Supabase
-- ============================================

-- IMPORTANT: Run this script carefully and review results before committing
-- This script will merge newer data from public schema into stripe schema

BEGIN;

SELECT 'STRIPE DATA CONSOLIDATION STARTED' as status, NOW() as start_time;

-- ============================================
-- BACKUP CURRENT STRIPE SCHEMA DATA
-- ============================================

-- Create backup tables with timestamp
DO $$
DECLARE
    backup_suffix TEXT := '_backup_' || TO_CHAR(NOW(), 'YYYY_MM_DD_HH24_MI_SS');
BEGIN
    EXECUTE format('CREATE TABLE stripe.charges%s AS SELECT * FROM stripe.charges', backup_suffix);
    EXECUTE format('CREATE TABLE stripe.invoices%s AS SELECT * FROM stripe.invoices', backup_suffix);
    EXECUTE format('CREATE TABLE stripe.subscriptions%s AS SELECT * FROM stripe.subscriptions', backup_suffix);
    EXECUTE format('CREATE TABLE stripe.refunds%s AS SELECT * FROM stripe.refunds', backup_suffix);
    EXECUTE format('CREATE TABLE stripe.prices%s AS SELECT * FROM stripe.prices', backup_suffix);

    RAISE NOTICE 'Backup tables created with suffix: %', backup_suffix;
END $$;

-- ============================================
-- ANALYZE DATA DIFFERENCES
-- ============================================

SELECT 'DATA ANALYSIS' as section;

-- Compare row counts between schemas
SELECT
    'charges' as table_name,
    (SELECT COUNT(*) FROM stripe.charges) as stripe_count,
    (SELECT COUNT(*) FROM public.charges WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'charges')) as public_count,
    (SELECT MAX(TO_TIMESTAMP(created)) FROM stripe.charges) as stripe_latest,
    (SELECT MAX(updated_at) FROM public.charges WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'charges')) as public_latest
UNION ALL
SELECT
    'invoices' as table_name,
    (SELECT COUNT(*) FROM stripe.invoices) as stripe_count,
    (SELECT COUNT(*) FROM public.invoices WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'invoices')) as public_count,
    (SELECT MAX(TO_TIMESTAMP(created)) FROM stripe.invoices) as stripe_latest,
    (SELECT MAX(updated_at) FROM public.invoices WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'invoices')) as public_latest
UNION ALL
SELECT
    'subscriptions' as table_name,
    (SELECT COUNT(*) FROM stripe.subscriptions) as stripe_count,
    (SELECT COUNT(*) FROM public.subscriptions WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'subscriptions')) as public_count,
    (SELECT MAX(TO_TIMESTAMP(created)) FROM stripe.subscriptions) as stripe_latest,
    (SELECT MAX(updated_at) FROM public.subscriptions WHERE EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'subscriptions')) as public_latest;

-- ============================================
-- CONSOLIDATE CHARGES DATA
-- ============================================

SELECT 'CONSOLIDATING CHARGES' as section;

-- Check if public.charges exists and has newer data
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'charges') THEN
        -- Insert newer records from public to stripe schema
        -- Assuming 'id' is the primary key and we want to avoid duplicates

        INSERT INTO stripe.charges
        SELECT DISTINCT p.*
        FROM public.charges p
        LEFT JOIN stripe.charges s ON p.id = s.id
        WHERE s.id IS NULL  -- Only insert records that don't exist in stripe schema
           OR p.updated_at > TO_TIMESTAMP(s.updated);  -- Or records that are newer

        GET DIAGNOSTICS rows_affected = ROW_COUNT;
        RAISE NOTICE 'Inserted % new/updated charge records', rows_affected;
    ELSE
        RAISE NOTICE 'No public.charges table found';
    END IF;
END $$;

-- ============================================
-- CONSOLIDATE INVOICES DATA
-- ============================================

SELECT 'CONSOLIDATING INVOICES' as section;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'invoices') THEN
        INSERT INTO stripe.invoices
        SELECT DISTINCT p.*
        FROM public.invoices p
        LEFT JOIN stripe.invoices s ON p.id = s.id
        WHERE s.id IS NULL
           OR p.updated_at > TO_TIMESTAMP(s.updated);

        GET DIAGNOSTICS rows_affected = ROW_COUNT;
        RAISE NOTICE 'Inserted % new/updated invoice records', rows_affected;
    ELSE
        RAISE NOTICE 'No public.invoices table found';
    END IF;
END $$;

-- ============================================
-- CONSOLIDATE SUBSCRIPTIONS DATA
-- ============================================

SELECT 'CONSOLIDATING SUBSCRIPTIONS' as section;

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'subscriptions') THEN
        INSERT INTO stripe.subscriptions
        SELECT DISTINCT p.*
        FROM public.subscriptions p
        LEFT JOIN stripe.subscriptions s ON p.id = s.id
        WHERE s.id IS NULL
           OR p.updated_at > TO_TIMESTAMP(s.updated);

        GET DIAGNOSTICS rows_affected = ROW_COUNT;
        RAISE NOTICE 'Inserted % new/updated subscription records', rows_affected;
    ELSE
        RAISE NOTICE 'No public.subscriptions table found';
    END IF;
END $$;

-- ============================================
-- CONSOLIDATE OTHER TABLES
-- ============================================

-- Handle subscription_items (only exists in public)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'subscription_items') THEN
        -- Create table in stripe schema if it doesn't exist
        IF NOT EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'stripe' AND table_name = 'subscription_items') THEN
            CREATE TABLE stripe.subscription_items AS SELECT * FROM public.subscription_items WHERE 1=0; -- Create structure only
        END IF;

        INSERT INTO stripe.subscription_items
        SELECT DISTINCT p.*
        FROM public.subscription_items p
        LEFT JOIN stripe.subscription_items s ON p.id = s.id
        WHERE s.id IS NULL;

        GET DIAGNOSTICS rows_affected = ROW_COUNT;
        RAISE NOTICE 'Inserted % subscription_items records', rows_affected;
    END IF;
END $$;

-- ============================================
-- POST-CONSOLIDATION ANALYSIS
-- ============================================

SELECT 'POST-CONSOLIDATION ANALYSIS' as section;

-- Final row counts
SELECT
    'charges' as table_name,
    COUNT(*) as final_count,
    MAX(TO_TIMESTAMP(created)) as latest_record,
    MIN(TO_TIMESTAMP(created)) as earliest_record
FROM stripe.charges
UNION ALL
SELECT
    'invoices' as table_name,
    COUNT(*) as final_count,
    MAX(TO_TIMESTAMP(created)) as latest_record,
    MIN(TO_TIMESTAMP(created)) as earliest_record
FROM stripe.invoices
UNION ALL
SELECT
    'subscriptions' as table_name,
    COUNT(*) as final_count,
    MAX(TO_TIMESTAMP(created)) as latest_record,
    MIN(TO_TIMESTAMP(created)) as earliest_record
FROM stripe.subscriptions;

-- Check for recent data (last 30 days)
SELECT
    'Recent Activity Check' as analysis_type,
    COUNT(*) as charges_last_30_days,
    SUM(amount) / 100.0 as total_amount_usd
FROM stripe.charges
WHERE TO_TIMESTAMP(created) >= CURRENT_DATE - INTERVAL '30 days';

-- ============================================
-- CREATE UNIFIED VIEWS
-- ============================================

SELECT 'CREATING UNIFIED VIEWS' as section;

-- Create a view that always shows the most current data
CREATE OR REPLACE VIEW stripe.v_current_charges AS
SELECT
    id,
    amount,
    currency,
    TO_TIMESTAMP(created) as created_at,
    TO_TIMESTAMP(updated) as updated_at,
    customer,
    description,
    paid,
    refunded,
    status
FROM stripe.charges
ORDER BY created DESC;

CREATE OR REPLACE VIEW stripe.v_current_invoices AS
SELECT
    id,
    amount_paid,
    amount_due,
    currency,
    TO_TIMESTAMP(created) as created_at,
    TO_TIMESTAMP(updated) as updated_at,
    customer,
    subscription,
    status
FROM stripe.invoices
ORDER BY created DESC;

-- ============================================
-- CLEANUP RECOMMENDATIONS
-- ============================================

SELECT 'CLEANUP RECOMMENDATIONS' as section;

SELECT
    'After verifying data integrity, consider:' as recommendation
UNION ALL
SELECT '1. Update Airbyte destination to stripe schema'
UNION ALL
SELECT '2. Archive or drop duplicate tables in public schema'
UNION ALL
SELECT '3. Set up monitoring alerts for schema mismatches'
UNION ALL
SELECT '4. Schedule regular data validation checks';

-- ============================================
-- VALIDATION CHECKS
-- ============================================

SELECT 'VALIDATION CHECKS' as section;

-- Check for data integrity
WITH integrity_check AS (
    SELECT
        COUNT(DISTINCT id) as unique_charges,
        COUNT(*) as total_charges,
        COUNT(CASE WHEN amount <= 0 THEN 1 END) as zero_amount_charges,
        COUNT(CASE WHEN currency IS NULL THEN 1 END) as null_currency_charges
    FROM stripe.charges
)
SELECT
    'charges_integrity' as check_type,
    CASE
        WHEN unique_charges = total_charges THEN '✅ No duplicates'
        ELSE '❌ Duplicates found: ' || (total_charges - unique_charges)
    END as duplicate_check,
    CASE
        WHEN zero_amount_charges = 0 THEN '✅ All amounts > 0'
        ELSE '⚠️ ' || zero_amount_charges || ' charges with amount <= 0'
    END as amount_check,
    CASE
        WHEN null_currency_charges = 0 THEN '✅ All currencies present'
        ELSE '⚠️ ' || null_currency_charges || ' charges missing currency'
    END as currency_check
FROM integrity_check;

COMMIT;

SELECT 'STRIPE DATA CONSOLIDATION COMPLETED' as status, NOW() as end_time;