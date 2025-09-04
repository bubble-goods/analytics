# Reports

This directory contains SQL queries and analyses organized by frequency and use case.

## Structure

### Daily Reports
- **ROAS Tracker** ✅ - `daily/roas_tracker.sql`
  - Status: Live dashboard at https://mbase.bubblegoods.com/dashboard/25
  - Purpose: Track ad performance and ROAS across Google and Meta
  - Cards: 9 Metabase cards (IDs: 262-270) with live data
  - Data Quality: All conversion tracking and metric calculation issues resolved

### Monthly Reports
- **Accounts Payable Report** ✅ - `monthly/accounts_payable_final.sql` 
  - Status: Live Metabase card
  - Purpose: Monthly brand payouts and financial obligations
  - Documentation: Complete setup and column definitions available

### Weekly Reports
- Directory for weekly business analysis queries
- Status: Available for future weekly analytics needs

### Ad-hoc Reports  
- Directory for one-time analyses and exploratory queries
- Use for custom investigations and data exploration

## Usage

All SQL files can be:
1. **Run directly** in Supabase or Metabase SQL editor
2. **Imported as Metabase cards** for visualization and scheduling
3. **Modified for custom analysis** as needed

## Data Sources

- **Primary:** Supabase analytics schema (`analytics.mv_ad_performance_daily`)
- **Raw Data:** Google Ads and Meta Ads tables via Airbyte ingestion
- **Additional:** Production database via read replica for order/customer data

## Quality Assurance

✅ **ROAS Data Verified:** Meta conversions tracking, Google CPC/CPM calculations corrected
✅ **Live Dashboards:** All reports connected to operational dashboards
✅ **Documentation:** Complete setup guides and troubleshooting available