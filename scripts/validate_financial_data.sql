-- ============================================
-- Financial Data Validation Script
-- Validate Stripe and business data integrity
-- Database: Supabase
-- ============================================

SELECT 'FINANCIAL DATA VALIDATION REPORT' as report_title, NOW() as run_time;

-- ============================================
-- STRIPE DATA VALIDATION
-- ============================================

SELECT '=== STRIPE DATA VALIDATION ===' as section;

-- Basic data integrity checks
WITH stripe_integrity AS (
    SELECT
        'charges' as table_name,
        COUNT(*) as total_records,
        COUNT(DISTINCT id) as unique_records,
        COUNT(CASE WHEN amount <= 0 THEN 1 END) as zero_amount_records,
        COUNT(CASE WHEN currency IS NULL THEN 1 END) as null_currency_records,
        COUNT(CASE WHEN customer IS NULL THEN 1 END) as null_customer_records,
        MIN(TO_TIMESTAMP(created)) as earliest_record,
        MAX(TO_TIMESTAMP(created)) as latest_record,
        SUM(amount) / 100.0 as total_amount_usd
    FROM stripe.charges

    UNION ALL

    SELECT
        'invoices' as table_name,
        COUNT(*) as total_records,
        COUNT(DISTINCT id) as unique_records,
        COUNT(CASE WHEN amount_due <= 0 THEN 1 END) as zero_amount_records,
        COUNT(CASE WHEN currency IS NULL THEN 1 END) as null_currency_records,
        COUNT(CASE WHEN customer IS NULL THEN 1 END) as null_customer_records,
        MIN(TO_TIMESTAMP(created)) as earliest_record,
        MAX(TO_TIMESTAMP(created)) as latest_record,
        SUM(amount_paid) / 100.0 as total_amount_usd
    FROM stripe.invoices

    UNION ALL

    SELECT
        'subscriptions' as table_name,
        COUNT(*) as total_records,
        COUNT(DISTINCT id) as unique_records,
        NULL as zero_amount_records,
        NULL as null_currency_records,
        COUNT(CASE WHEN customer IS NULL THEN 1 END) as null_customer_records,
        MIN(TO_TIMESTAMP(created)) as earliest_record,
        MAX(TO_TIMESTAMP(created)) as latest_record,
        NULL as total_amount_usd
    FROM stripe.subscriptions
)
SELECT * FROM stripe_integrity;

-- ============================================
-- REVENUE CONSISTENCY CHECKS
-- ============================================

SELECT '=== REVENUE CONSISTENCY CHECKS ===' as section;

-- Monthly revenue trends
SELECT
    'monthly_stripe_revenue' as metric_type,
    DATE_TRUNC('month', TO_TIMESTAMP(created)) as month,
    COUNT(*) as charge_count,
    SUM(amount) / 100.0 as total_revenue_usd,
    AVG(amount) / 100.0 as avg_charge_amount,
    COUNT(DISTINCT customer) as unique_customers
FROM stripe.charges
WHERE TO_TIMESTAMP(created) >= CURRENT_DATE - INTERVAL '12 months'
    AND paid = true
GROUP BY DATE_TRUNC('month', TO_TIMESTAMP(created))
ORDER BY month DESC
LIMIT 12;

-- ============================================
-- CUSTOMER PAYMENT PATTERNS
-- ============================================

SELECT '=== CUSTOMER PAYMENT PATTERNS ===' as section;

-- Top customers by payment volume
SELECT
    'top_customers_by_revenue' as analysis_type,
    customer,
    COUNT(*) as total_charges,
    SUM(amount) / 100.0 as total_spent_usd,
    AVG(amount) / 100.0 as avg_charge_amount,
    MIN(TO_TIMESTAMP(created)) as first_charge,
    MAX(TO_TIMESTAMP(created)) as latest_charge
FROM stripe.charges
WHERE paid = true
    AND TO_TIMESTAMP(created) >= CURRENT_DATE - INTERVAL '12 months'
GROUP BY customer
ORDER BY total_spent_usd DESC
LIMIT 10;

-- ============================================
-- SUBSCRIPTION ANALYSIS
-- ============================================

SELECT '=== SUBSCRIPTION ANALYSIS ===' as section;

-- Subscription status breakdown
SELECT
    'subscription_status_breakdown' as analysis_type,
    status,
    COUNT(*) as subscription_count,
    COUNT(CASE WHEN TO_TIMESTAMP(created) >= CURRENT_DATE - INTERVAL '30 days' THEN 1 END) as new_last_30_days
FROM stripe.subscriptions
GROUP BY status
ORDER BY subscription_count DESC;

-- ============================================
-- REFUND ANALYSIS
-- ============================================

SELECT '=== REFUND ANALYSIS ===' as section;

-- Refund rates and patterns
WITH refund_analysis AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP(created)) as month,
        COUNT(*) as total_charges,
        COUNT(CASE WHEN refunded = true THEN 1 END) as refunded_charges,
        SUM(amount) / 100.0 as total_charged_usd,
        SUM(CASE WHEN refunded = true THEN amount ELSE 0 END) / 100.0 as total_refunded_usd
    FROM stripe.charges
    WHERE TO_TIMESTAMP(created) >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY DATE_TRUNC('month', TO_TIMESTAMP(created))
)
SELECT
    'monthly_refund_rates' as analysis_type,
    month,
    total_charges,
    refunded_charges,
    ROUND(
        CASE
            WHEN total_charges > 0 THEN (refunded_charges::DECIMAL / total_charges) * 100
            ELSE 0
        END, 2
    ) as refund_rate_percent,
    total_charged_usd,
    total_refunded_usd,
    ROUND(
        CASE
            WHEN total_charged_usd > 0 THEN (total_refunded_usd / total_charged_usd) * 100
            ELSE 0
        END, 2
    ) as refund_amount_percent
FROM refund_analysis
ORDER BY month DESC;

-- ============================================
-- ZENDESK VALIDATION
-- ============================================

SELECT '=== ZENDESK DATA VALIDATION ===' as section;

-- Ticket volume and resolution trends
SELECT
    'monthly_ticket_volume' as metric_type,
    DATE_TRUNC('month', created_at) as month,
    COUNT(*) as total_tickets,
    COUNT(CASE WHEN status = 'solved' THEN 1 END) as solved_tickets,
    COUNT(CASE WHEN status = 'closed' THEN 1 END) as closed_tickets,
    COUNT(CASE WHEN status = 'open' THEN 1 END) as open_tickets,
    ROUND(
        CASE
            WHEN COUNT(*) > 0 THEN (COUNT(CASE WHEN status IN ('solved', 'closed') THEN 1 END)::DECIMAL / COUNT(*)) * 100
            ELSE 0
        END, 2
    ) as resolution_rate_percent
FROM zendesk.tickets
WHERE created_at >= CURRENT_DATE - INTERVAL '6 months'
GROUP BY DATE_TRUNC('month', created_at)
ORDER BY month DESC;

-- ============================================
-- CROSS-PLATFORM DATA CONSISTENCY
-- ============================================

SELECT '=== CROSS-PLATFORM CONSISTENCY CHECKS ===' as section;

-- Check for data gaps by date
WITH date_coverage AS (
    SELECT
        'stripe_charges' as source,
        DATE_TRUNC('day', TO_TIMESTAMP(created)) as date,
        COUNT(*) as record_count
    FROM stripe.charges
    WHERE TO_TIMESTAMP(created) >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY DATE_TRUNC('day', TO_TIMESTAMP(created))

    UNION ALL

    SELECT
        'zendesk_tickets' as source,
        DATE_TRUNC('day', created_at) as date,
        COUNT(*) as record_count
    FROM zendesk.tickets
    WHERE created_at >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY DATE_TRUNC('day', created_at)
),
daily_activity AS (
    SELECT
        generate_series(
            CURRENT_DATE - INTERVAL '30 days',
            CURRENT_DATE,
            INTERVAL '1 day'
        )::date as date
)
SELECT
    'data_coverage_last_30_days' as check_type,
    d.date,
    COALESCE(s.record_count, 0) as stripe_records,
    COALESCE(z.record_count, 0) as zendesk_records,
    CASE
        WHEN s.record_count IS NULL THEN '❌ No Stripe data'
        WHEN z.record_count IS NULL THEN '⚠️ No Zendesk data'
        ELSE '✅ Both sources have data'
    END as status
FROM daily_activity d
LEFT JOIN date_coverage s ON d.date = s.date AND s.source = 'stripe_charges'
LEFT JOIN date_coverage z ON d.date = z.date AND z.source = 'zendesk_tickets'
ORDER BY d.date DESC
LIMIT 10;

-- ============================================
-- FINANCIAL SUMMARY
-- ============================================

SELECT '=== FINANCIAL SUMMARY ===' as section;

-- Key financial metrics
WITH financial_summary AS (
    SELECT
        COUNT(*) as total_charges,
        SUM(amount) / 100.0 as total_revenue_usd,
        AVG(amount) / 100.0 as avg_order_value,
        COUNT(DISTINCT customer) as unique_customers,
        COUNT(CASE WHEN refunded = true THEN 1 END) as total_refunds,
        SUM(CASE WHEN refunded = true THEN amount ELSE 0 END) / 100.0 as total_refunded_usd
    FROM stripe.charges
    WHERE paid = true
        AND TO_TIMESTAMP(created) >= CURRENT_DATE - INTERVAL '30 days'
)
SELECT
    'last_30_days_summary' as period,
    total_charges,
    total_revenue_usd,
    ROUND(avg_order_value, 2) as avg_order_value,
    unique_customers,
    ROUND(total_revenue_usd / total_charges, 2) as revenue_per_charge,
    total_refunds,
    total_refunded_usd,
    ROUND(
        CASE
            WHEN total_revenue_usd > 0 THEN (total_refunded_usd / total_revenue_usd) * 100
            ELSE 0
        END, 2
    ) as refund_rate_percent
FROM financial_summary;

-- ============================================
-- DATA QUALITY ALERTS
-- ============================================

SELECT '=== DATA QUALITY ALERTS ===' as section;

-- Critical data quality issues
SELECT
    'CRITICAL ALERTS' as alert_level,
    alert_type,
    message,
    affected_count
FROM (
    SELECT
        'DUPLICATE_CHARGES' as alert_type,
        'Duplicate charge IDs found in Stripe data' as message,
        COUNT(*) - COUNT(DISTINCT id) as affected_count
    FROM stripe.charges
    HAVING COUNT(*) - COUNT(DISTINCT id) > 0

    UNION ALL

    SELECT
        'NULL_CUSTOMER_CHARGES' as alert_type,
        'Charges with NULL customer IDs' as message,
        COUNT(*) as affected_count
    FROM stripe.charges
    WHERE customer IS NULL
    HAVING COUNT(*) > 0

    UNION ALL

    SELECT
        'ZERO_AMOUNT_CHARGES' as alert_type,
        'Charges with zero or negative amounts' as message,
        COUNT(*) as affected_count
    FROM stripe.charges
    WHERE amount <= 0
    HAVING COUNT(*) > 0

    UNION ALL

    SELECT
        'STALE_STRIPE_DATA' as alert_type,
        'Stripe data is more than 7 days old' as message,
        CURRENT_DATE - MAX(TO_TIMESTAMP(created))::date as affected_count
    FROM stripe.charges
    HAVING CURRENT_DATE - MAX(TO_TIMESTAMP(created))::date > 7
) alerts
WHERE affected_count > 0;

SELECT 'FINANCIAL DATA VALIDATION COMPLETED' as status, NOW() as completion_time;