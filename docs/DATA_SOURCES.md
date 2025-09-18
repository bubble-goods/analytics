# Bubble Goods Data Sources Documentation

## Primary Data Sources

### 1. Production Database Read Replica (MySQL)
**Location:** Metabase Database ID: 2
**Purpose:** Core business operations data
**Tables Include:**
- `orders` - Customer transactions
- `customers` - User accounts and profiles  
- `products` - Product catalog
- `brands` - Seller/brand information
- `line_items` - Order details
- `variants` - Product variations

**Key Metrics Available:**
- Monthly GMV (~$109K current)
- Order volume (1,390 last 30 days)
- AOV (~$72)
- Customer acquisition and retention
- Brand performance
- Product performance

### 2. Stripe (Payment Processing)
**Status:** ⚠️ Active but data issues - needs consolidation
**Location:** Supabase `stripe` schema (primary), `public` schema (current sync)
**Purpose:** Payment processing and seller payout tracking
**Contains:**
- Charges (8,126 records) - Customer payments
- Invoices (4,676 records) - Billing records
- Subscriptions (355 records) - Recurring payments
- Refunds - Payment reversals
- Prices - Product pricing data
**Data Issues:**
- Primary data in `stripe` schema is 132 days old
- Current syncs going to wrong schema (`public`)
- Requires data consolidation

### 3. Zendesk (Customer Support)
**Status:** ✅ Active and current
**Location:** Supabase `zendesk` schema
**Purpose:** Customer support and communication tracking
**Contains:**
- Tickets (17,369 records) - ✅ Current
- Ticket Comments (88,264 records) - ✅ Current
- Ticket Audits - Change history
- Satisfaction Ratings (5,258 records) - ❌ 105 days old
- Support metrics and performance data

### 4. Google Analytics (via Metabase)
**Location:** Metabase Database ID: 4
**Purpose:** Web traffic and behavior analytics
**Supplements:** PostHog implementation

### 5. Supabase (PostgreSQL Data Warehouse)
**Location:** Metabase Database ID: 5
**Purpose:** Central data warehouse for all external data sources
**Schema Organization:**
- `stripe.*` - Payment and financial data (needs consolidation)
- `zendesk.*` - Support and communication data
- `google_ads.*` - Google advertising data
- `meta_ads.*` - Meta/Facebook advertising data
- `analytics.*` - Transformed and materialized views
- `public.*` - Mixed data (needs cleanup)
**Key Tables:**
- `analytics.mv_ad_performance_daily` - Unified ROAS metrics
- `stripe.charges` - Payment transactions
- `zendesk.tickets` - Support tickets

### 6. Google Ads (via Airbyte)
**Status:** Active - syncing every 6 hours
**Purpose:** Advertising campaign performance
**Contains:**
- Campaign spend and budgets
- Click and impression data
- Conversion tracking (working)
- ROAS: 1.21x current

### 7. Meta Ads (via Airbyte)
**Status:** Active but conversion tracking broken
**Purpose:** Facebook/Instagram advertising
**Contains:**
- Campaign spend data
- Engagement metrics
- Conversion tracking (currently showing $0)
- ROAS: 0.00x (needs fix)

## Data Flow Architecture

```
[Shopify Store] → [Production DB] → [Read Replica] → [Metabase]
[Stripe API] → [Airbyte] → [Supabase stripe schema] → [Metabase]
[Zendesk API] → [Airbyte] → [Supabase zendesk schema] → [Metabase]
[Google Analytics] → [Metabase GA Connector]
[PostHog] → [Direct Dashboard Access]
[Google Ads] → [Airbyte] → [Supabase google_ads schema] → [Metabase]
[Meta Ads] → [Airbyte] → [Supabase meta_ads schema] → [Metabase]
```

## Data Destinations

### Source to Destination Mapping

| Data Source | ETL Method | Warehouse Schema | Analytics Platform | Update Frequency | Status |
|-------------|-----------|------------------|-------------------|------------------|---------|
| Google Ads | Airbyte | `supabase.google_ads` | Metabase | 6 hours | ✅ Current |
| Meta Ads | Airbyte | `supabase.meta_ads` | Metabase | 6 hours | ⚠️ 10 days behind |
| Shopify Orders | Read Replica | MySQL | Metabase | Real-time | ✅ Current |
| User Events | JavaScript SDK | - | PostHog | Real-time | ✅ Current |
| Stripe | Airbyte | `supabase.stripe` | Metabase | Daily | ❌ Schema mismatch |
| Zendesk | Airbyte | `supabase.zendesk` | Metabase | Daily | ✅ Mostly current |
| Google Analytics | Native Connector | - | Metabase | Daily | ✅ Current |

### Platform Usage Guidelines

**Send to Metabase:**
- Financial data (revenue, costs, margins)
- Advertising metrics (ROAS, CAC, spend)
- Business KPIs (GMV, AOV, conversion rates)
- Operational metrics (fulfillment, inventory)
- Cross-database queries

**Send to PostHog:**
- User interactions (clicks, views, scrolls)
- Conversion funnels
- Session data
- A/B test events
- Feature usage tracking

## Critical Business Metrics to Track

### Conversion Funnel
- Traffic → Product Views (currently 7.5%, target 25%)
- Product Views → Conversion (currently 1.95%, target 3.5%)
- Mobile vs Desktop performance

### Financial Health  
- Monthly GMV progression toward $1M goal
- AOV trends and optimization opportunities
- Customer lifetime value (CLV)
- Brand contribution to GMV

### Operational Efficiency
- Order fulfillment times
- Customer support ticket trends
- Seller payout processing
- Inventory turnover

## Data Quality Considerations
- Production read replica lag times
- Data freshness requirements for different metrics
- Historical data availability and retention
- Cross-platform data consistency