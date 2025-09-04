# Metabase ROAS Dashboard Setup Guide

## Quick Setup Checklist

- [ ] Verify Supabase connection in Metabase
- [ ] Create ROAS Tracking collection
- [ ] Import all 10 queries from roas_tracker.sql
- [ ] Build dashboard with 4 sections
- [ ] Configure filters and auto-refresh
- [ ] Set up alerts for underperformance

## Step-by-Step Instructions

### Step 1: Verify Database Connection

1. Navigate to: https://mbase.bubblegoods.com
2. Go to Settings → Admin → Databases
3. Find "Supabase" (Database ID: 5)
4. Click "Test Connection"
5. If fails, update credentials from Supabase dashboard

### Step 2: Create Collection Structure

1. Go to "Our analytics" collection
2. Click "New Collection"
3. Name: "ROAS Tracking"
4. Description: "Ad performance and return on ad spend metrics"
5. Create sub-collections:
   - "Daily Reports"
   - "Campaign Analysis"
   - "Platform Comparison"

### Step 3: Import Queries as Questions

For each query in `/reports/daily/roas_tracker.sql`:

1. Click "New" → "SQL Query"
2. Select Database: "Supabase"
3. Paste the query
4. Click "Run" to test
5. Save with these names:

   - Query 1 → "ROAS Overview - 30 Day Summary"
   - Query 2 → "Platform Performance Comparison"
   - Query 3 → "Top Performing Campaigns"
   - Query 4 → "Underperforming Campaigns Alert"
   - Query 5 → "Daily Spend and Revenue Trend"
   - Query 6 → "Weekly Performance Analysis"
   - Query 7 → "Campaign Efficiency Metrics"
   - Query 8 → "Revenue Attribution by Platform"
   - Query 9 → "High Spend Zero Revenue Alert"

### Step 4: Create the Dashboard

1. Click "New" → "Dashboard"
2. Name: "ROAS Performance Tracker"
3. Add cards in this layout:

#### Row 1: Executive Summary (4 cards)
- ROAS Overview (Big Number)
- Total Spend (Trend)
- Total Revenue (Trend)
- Active Campaigns (Number)

#### Row 2: Platform Analysis (2 cards)
- Platform Performance Table
- Platform ROAS Trend (Line Chart)

#### Row 3: Campaign Deep Dive (2 cards)
- Top Performers (Bar Chart)
- Underperformers Alert (Table)

#### Row 4: Trends (1 card)
- Daily Spend and Revenue (Combo Chart)

### Step 5: Configure Visualizations

For each card, click the visualization settings (⚙️):

**ROAS Overview:**
- Display: Number
- Style: Large
- Suffix: "x"
- Color: Green if > 1, Red if < 1

**Platform Performance Table:**
- Conditional Formatting:
  - ROAS column: Green (>3), Yellow (>1), Red (<1)
  - Sort by: Spend (Descending)

**Daily Trend Chart:**
- X-axis: Date
- Y-axis: Dollars
- Series: Spend (bars), Revenue (line)
- Stack: By Platform

### Step 6: Add Dashboard Filters

1. Click "Add a Filter"
2. Add these filters:

**Date Range:**
- Type: Date
- Default: Last 30 days
- Widget: Date picker

**Platform:**
- Type: Category
- Options: google, meta
- Widget: Dropdown (multi-select)

**Minimum Spend:**
- Type: Number
- Default: 100
- Widget: Input box

3. Connect filters to relevant cards

### Step 7: Configure Auto-Refresh

1. Dashboard Settings (⚙️)
2. Auto-refresh: Every 60 minutes
3. Cache duration: 60 minutes

### Step 8: Set Up Alerts

For critical metrics, create alerts:

1. Open "Underperforming Campaigns Alert" question
2. Click bell icon (🔔)
3. Set alert: "When rows > 0"
4. Schedule: Daily at 9 AM
5. Recipients: Marketing team

Repeat for:
- Overall ROAS < 1.0
- Meta Revenue = $0 for > 24 hours
- Daily spend > $2000

### Step 9: Create Scheduled Reports

1. Dashboard → Share → Email this dashboard
2. Schedule: Weekly (Mondays 8 AM)
3. Recipients: Executive team
4. Format: PDF attachment

### Step 10: Documentation

1. Add dashboard description:
   ```
   Real-time ROAS tracking across Google and Meta advertising.
   Data refreshes hourly from Supabase warehouse.
   
   ⚠️ Known Issue: Meta conversion tracking showing $0 
   (Airbyte connector configuration needs update)
   ```

2. Pin to homepage for easy access

## Verification Checklist

After setup, verify:

- [ ] All cards show data
- [ ] Filters work correctly
- [ ] Auto-refresh is active
- [ ] Alerts are configured
- [ ] Team has access
- [ ] Mobile view works

## Troubleshooting

### "No data" errors:
```sql
-- Check if materialized view has data
SELECT COUNT(*) FROM analytics.mv_ad_performance_daily;
```

### Slow performance:
```sql
-- Refresh materialized view
REFRESH MATERIALIZED VIEW CONCURRENTLY analytics.mv_ad_performance_daily;
```

### Permission issues:
- Ensure Metabase user has SELECT permission on analytics schema
- Check Supabase RLS policies

## Support

- Technical issues: #tech-analytics Slack
- Data questions: Head of Finance
- Access requests: Admin team