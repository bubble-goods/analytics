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
**Purpose:** Additional data storage (usage unclear)

## Data Flow Architecture

```
[Shopify Store] → [Production DB] → [Read Replica] → [Metabase]
[Stripe API] → [???] → [Metabase or Direct Analysis]
[Zendesk API] → [???] → [Metabase or Direct Analysis]
[Google Analytics] → [Metabase GA Connector]
[PostHog] → [Direct Dashboard Access]
```

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