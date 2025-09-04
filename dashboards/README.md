# Dashboards

Documentation and configurations for Metabase dashboards.

## Active Dashboards

### ROAS Performance Tracker ✅ **LIVE & OPERATIONAL**
- **URL:** https://mbase.bubblegoods.com/dashboard/25
- **Collection:** https://mbase.bubblegoods.com/collection/47
- **Purpose:** Replaces TripleWhale - tracks return on ad spend across Google and Meta advertising
- **Queries:** 9 cards with live data (IDs: 262-270)
- **Data Source:** Supabase `analytics.mv_ad_performance_daily`
- **Owner:** Marketing Team
- **Status:** ✅ **Fully Operational** - Dashboard complete, data issues resolved
- **Recent Fixes:** Meta conversions now tracking, Google CPC/CPM corrected
- **Performance:** 248 conversions, $17,558 revenue (last 7 days)

### Business Overview
- **URL:** https://mbase.bubblegoods.com/dashboard/[TBD]
- **Purpose:** Executive KPIs including GMV, conversion rate, AOV
- **Metrics:** 
  - Monthly GMV vs $1M target
  - Conversion rate (current: 1.95%, target: 3.5%)
  - Product view rate (current: 7.5%, target: 25%)
- **Refresh:** Real-time from read replica

### Sales Analytics  
- **URL:** https://mbase.bubblegoods.com/dashboard/[TBD]
- **Purpose:** Deep dive into sales performance and trends
- **Includes:**
  - Order volume and AOV trends
  - Category performance
  - Time-of-day patterns
  - Mobile vs desktop sales
- **Refresh:** Real-time from read replica

### Brand Performance
- **URL:** https://mbase.bubblegoods.com/dashboard/[TBD]
- **Purpose:** Track seller/brand metrics and rankings
- **Includes:**
  - Top performing brands by GMV
  - Brand growth trends
  - Product performance by brand
  - Commission calculations
- **Refresh:** Daily

### Customer Analytics
- **URL:** https://mbase.bubblegoods.com/dashboard/[TBD]
- **Purpose:** Customer behavior, segmentation, and retention
- **Includes:**
  - Cohort retention analysis
  - Customer lifetime value
  - Purchase frequency
  - Geographic distribution
- **Refresh:** Daily

## Dashboard Guidelines

- Keep dashboards focused on specific use cases
- Use consistent naming conventions
- Document refresh schedules and data sources
- Include links to related reports