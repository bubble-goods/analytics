# Analytics Architecture

## Overview

Bubble Goods uses a modern analytics stack combining business intelligence (Metabase) with product analytics (PostHog) to provide comprehensive insights across financial, operational, and user behavior metrics.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         DATA SOURCES                             │
├───────────────┬───────────────┬──────────────┬─────────────────┤
│   Shopify     │  Google Ads   │   Meta Ads   │    Stripe       │
│   (Orders)    │  (Campaign)   │  (Campaign)  │   (Payments)    │
└───────┬───────┴──────┬────────┴──────┬───────┴────────┬────────┘
        │              │               │                │
        ▼              ▼               ▼                ▼
┌─────────────────────────────────────────────────────────────────┐
│                          ETL LAYER                               │
├───────────────┬──────────────────────────────┬─────────────────┤
│  Read Replica │        Airbyte              │    Manual        │
│   (MySQL)     │   (6-hour sync)             │    Import        │
└───────┬───────┴──────────┬──────────────────┴────────┬────────┘
        │                  │                            │
        ▼                  ▼                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                      DATA WAREHOUSE                              │
│                        Supabase                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Raw Tables:          Transformed:        Materialized:   │  │
│  │ • google_ads.*      • v_google_ads_*    • mv_ad_perf_*   │  │
│  │ • meta_ads.*        • v_meta_ads_*      • mv_roas_*      │  │
│  │ • shopify_orders    • fact_ad_spend     • mv_cohorts_*   │  │
│  └──────────────────────────────────────────────────────────┘  │
└───────────────────────┬─────────────────┬──────────────────────┘
                        │                 │
                        ▼                 ▼
┌─────────────────────────────┐ ┌────────────────────────────────┐
│        METABASE             │ │         POSTHOG                │
├─────────────────────────────┤ ├────────────────────────────────┤
│ Business Intelligence:      │ │ Product Analytics:             │
│ • ROAS Dashboard           │ │ • User Funnels                │
│ • Financial Reports        │ │ • A/B Testing                 │
│ • Operational Metrics      │ │ • Session Recordings          │
│ • Executive KPIs           │ │ • Feature Flags               │
│ • AP Reports               │ │ • Event Tracking              │
└─────────────────────────────┘ └────────────────────────────────┘
```

## Data Flow Details

### 1. Source Systems

| Source | Type | Update Frequency | Primary Use |
|--------|------|-----------------|-------------|
| Shopify | E-commerce Platform | Real-time | Orders, Customers, Products |
| Google Ads | Advertising | 6 hours | Campaign performance, Spend |
| Meta Ads | Advertising | 6 hours | Campaign performance, Spend |
| Stripe | Payments | Daily | Payouts, Transactions |
| PostHog | Analytics | Real-time | User events, Sessions |
| Zendesk | Support | TBD | Tickets, Customer service |

### 2. ETL Pipeline

| Pipeline | Tool | Schedule | Destination |
|----------|------|----------|-------------|
| Ad Platforms → Warehouse | Airbyte | Every 6 hours | Supabase |
| Shopify → Analytics | Read Replica | Real-time | MySQL → Metabase |
| Warehouse → Materialized Views | SQL Scripts | Daily 2 AM | Supabase |
| Events → PostHog | JavaScript SDK | Real-time | PostHog Cloud |

### 3. Data Warehouse (Supabase)

#### Schema Organization

```
supabase/
├── raw/                    # Unprocessed data from sources
│   ├── google_ads/
│   ├── meta_ads/
│   └── stripe/
├── staging/               # Cleaned and standardized
│   ├── v_google_ads_daily
│   └── v_meta_ads_daily
├── analytics/             # Business-ready datasets
│   ├── mv_ad_performance_daily
│   ├── fact_ad_spend
│   └── dim_campaigns
└── archive/              # Historical data >90 days
```

### 4. Analytics Platforms

#### Metabase (Business Intelligence)

**Purpose:** Financial and operational analytics
**Database Connections:**
- ID 2: Production Read Replica (MySQL)
- ID 4: Google Analytics
- ID 5: Supabase (PostgreSQL)

**Key Dashboards:**
- ROAS Performance Tracker
- Executive Business Overview
- Monthly Financial Reports
- Brand Performance Analysis
- Customer Cohort Analysis

#### PostHog (Product Analytics)

**Purpose:** User behavior and product optimization
**Data Collection:**
- Client-side: JavaScript SDK on bubblegoods.com
- Server-side: API for backend events
- Mobile: SDK integration (future)

**Key Features:**
- Conversion funnel analysis (7.5% → 25% product view target)
- Session recordings for UX optimization
- A/B testing for conversion improvement (1.95% → 3.5% target)
- Feature flags for gradual rollouts
- Custom events for business logic

## Data Governance

### Refresh Schedules

| Dataset | Refresh | Method | Owner |
|---------|---------|--------|-------|
| Ad Performance | Daily 2 AM | Materialized View | Engineering |
| ROAS Metrics | Hourly | Metabase Cache | Marketing |
| User Events | Real-time | PostHog SDK | Product |
| Financial Reports | Monthly | SQL Scripts | Finance |

### Data Quality

**Monitoring:**
- Daily health checks on materialized views
- Alert on missing data (>24 hours)
- Weekly accuracy audits vs source systems

**Known Issues:**
- Meta conversion tracking showing $0 revenue (Airbyte fix needed)
- 6-hour lag on ad platform data
- PostHog cannot visualize external warehouse tables

### Security & Access

**Metabase:**
- Role-based access control
- Read-only connections to production
- API key authentication

**PostHog:**
- Project-level isolation
- GDPR-compliant data retention
- Anonymous user tracking option

**Supabase:**
- Row-level security policies
- SSL encryption in transit
- Daily backups

## Integration Points

### Current Integrations

1. **Airbyte → Supabase**
   - Google Ads connector
   - Facebook Marketing connector
   - Custom transformations

2. **Supabase → Metabase**
   - Direct PostgreSQL connection
   - Materialized views for performance
   - SQL-based queries

3. **Website → PostHog**
   - JavaScript snippet on all pages
   - Custom event tracking
   - User identification

### Planned Integrations

1. **Stripe → Supabase** (Q4 2024)
   - Seller payouts
   - Transaction fees
   - Payment analytics

2. **Zendesk → Metabase** (Q1 2025)
   - Support metrics
   - Customer satisfaction
   - Response times

3. **PostHog → Supabase** (Future)
   - Event export for deep analysis
   - Joining behavioral with transactional data

## Maintenance & Operations

### Daily Tasks
- Monitor materialized view refreshes
- Check Airbyte sync status
- Review error logs

### Weekly Tasks
- Validate ROAS calculations
- Audit data completeness
- Update documentation

### Monthly Tasks
- Performance optimization
- Storage cleanup
- Access review

## Support & Resources

- **Documentation:** `/docs` folder in this repository
- **Metabase:** https://mbase.bubblegoods.com
- **PostHog:** https://app.posthog.com
- **Supabase:** https://app.supabase.com
- **Slack:** #tech-analytics for questions