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

### 2. Stripe (Seller Payouts)
**Status:** Referenced but integration unclear
**Purpose:** Seller payment processing and payout tracking
**Contains:**
- Payout schedules and amounts
- Transaction fees
- Payment failures
- Seller financial health metrics

### 3. Zendesk (Customer Communications)
**Status:** Referenced but integration unclear  
**Purpose:** Customer support and seller communications
**Contains:**
- Support ticket volume and resolution times
- Customer satisfaction scores
- Common issue categories
- Support team performance

### 4. Google Analytics (via Metabase)
**Location:** Metabase Database ID: 4
**Purpose:** Web traffic and behavior analytics
**Supplements:** PostHog implementation

### 5. Supabase (PostgreSQL)
**Location:** Metabase Database ID: 5
**Purpose:** Data warehouse for ad performance and analytics
**Key Tables:**
- `analytics.mv_ad_performance_daily` - Unified ROAS metrics
- `google_ads.campaign_performance_report` - Raw Google Ads data
- `meta_ads.ads_insights` - Raw Meta/Facebook Ads data

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
[Stripe API] → [???] → [Metabase or Direct Analysis]
[Zendesk API] → [???] → [Metabase or Direct Analysis]
[Google Analytics] → [Metabase GA Connector]
[PostHog] → [Direct Dashboard Access]
[Google Ads] → [Airbyte] → [Supabase] → [Metabase]
[Meta Ads] → [Airbyte] → [Supabase] → [Metabase]
```

## Data Destinations

### Source to Destination Mapping

| Data Source | ETL Method | Warehouse | Analytics Platform | Update Frequency |
|-------------|-----------|-----------|-------------------|------------------|
| Google Ads | Airbyte | Supabase | Metabase | 6 hours |
| Meta Ads | Airbyte | Supabase | Metabase | 6 hours |
| Shopify Orders | Read Replica | MySQL | Metabase | Real-time |
| User Events | JavaScript SDK | - | PostHog | Real-time |
| Stripe | TBD | TBD | Metabase | Daily |
| Zendesk | TBD | TBD | Metabase | Daily |
| Google Analytics | Native Connector | - | Metabase | Daily |

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