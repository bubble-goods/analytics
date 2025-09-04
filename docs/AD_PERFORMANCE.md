# Ad Performance & ROAS Tracking

## Overview

This document describes our advertising performance tracking system, replacing TripleWhale with an in-house solution using Airbyte, Supabase, and Metabase.

## Architecture

```
Google Ads → 
              Airbyte → Supabase → Metabase Dashboards
Meta Ads   →
```

## Data Pipeline

### 1. Source Systems

**Google Ads**
- Connected via Airbyte Google Ads connector
- Syncs to `google_ads.campaign_performance_report` table
- Updates: Every 6 hours
- Contains: Campaign performance, cost, conversions

**Meta Ads** 
- Connected via Airbyte Facebook Marketing connector
- Syncs to `meta_ads.ads_insights` table
- Updates: Every 6 hours
- ⚠️ Issue: Conversion tracking showing $0 revenue (needs fix)

### 2. Data Warehouse (Supabase)

**Raw Tables:**
- `google_ads.campaign_performance_report` - Raw Google Ads data
- `meta_ads.ads_insights` - Raw Meta/Facebook data

**Transformation Views:**
- `analytics.v_google_ads_daily` - Standardized Google metrics
- `analytics.v_meta_ads_daily` - Standardized Meta metrics

**Materialized View:**
- `analytics.mv_ad_performance_daily` - Combined performance metrics
- Refreshed: Daily at 2 AM UTC
- Contains: Unified ROAS metrics across all platforms

### 3. Key Metrics

**Primary KPIs:**
- **ROAS** (Return on Ad Spend): Revenue / Spend
- **CAC** (Customer Acquisition Cost): Spend / Conversions
- **CPM** (Cost Per Mille): (Spend / Impressions) × 1000
- **CPC** (Cost Per Click): Spend / Clicks
- **CTR** (Click-Through Rate): (Clicks / Impressions) × 100

**Current Performance (30-day):**
- Total Spend: $54,987.69
- Total Revenue: $24,110.41
- Overall ROAS: 0.44
- Google ROAS: 1.21 ✅
- Meta ROAS: 0.00 ⚠️ (tracking issue)

## Materialized View Schema

```sql
analytics.mv_ad_performance_daily
├── date (DATE)
├── platform (VARCHAR) - 'google' or 'meta'
├── campaign_key (VARCHAR) - Unique campaign identifier
├── total_spend (DECIMAL)
├── total_revenue (DECIMAL)
├── total_impressions (BIGINT)
├── total_clicks (BIGINT)
├── total_conversions (INT)
├── roas (DECIMAL) - Calculated: revenue/spend
├── avg_ctr (DECIMAL) - Click-through rate %
├── avg_cpc (DECIMAL) - Cost per click
├── avg_cpm (DECIMAL) - Cost per 1000 impressions
└── updated_at (TIMESTAMP)
```

## Metabase Integration

**Database Connection:**
- Database ID: 5 (Supabase PostgreSQL)
- Schema: `analytics`
- Primary Table: `mv_ad_performance_daily`

**Dashboard Components:**
1. ROAS Overview Card
2. Platform Comparison Chart
3. Campaign Performance Table
4. Daily Spend Trend
5. Conversion Funnel

## Known Issues

### Meta Conversion Tracking
- **Problem:** Meta showing $0 revenue despite $35k+ spend
- **Impact:** ROAS appears as 0.00 for all Meta campaigns
- **Root Cause:** Likely misconfiguration in Airbyte connector
- **Fix Required:** 
  1. Check Meta pixel implementation
  2. Verify purchase event mapping in Airbyte
  3. Consider implementing Conversions API

### Data Freshness
- Airbyte syncs every 6 hours
- Materialized view refreshes daily
- Consider more frequent updates for real-time needs

## Maintenance

### Daily Tasks
- Monitor materialized view refresh status
- Check for data anomalies
- Verify platform connections

### Weekly Tasks  
- Validate ROAS calculations
- Compare with payment processor data
- Review campaign performance

### Monthly Tasks
- Audit data accuracy vs source platforms
- Update transformation logic if needed
- Generate performance reports

## SQL Refresh Command

```sql
-- Manual refresh of materialized view
REFRESH MATERIALIZED VIEW CONCURRENTLY analytics.mv_ad_performance_daily;

-- Check last refresh time
SELECT schemaname, matviewname, last_refresh 
FROM pg_stat_user_tables 
WHERE schemaname = 'analytics' 
AND matviewname = 'mv_ad_performance_daily';
```

## Support

For issues or questions:
- Check Airbyte sync logs
- Review Supabase query performance
- Verify Metabase card configurations
- Contact: Engineering team via Slack #tech-analytics