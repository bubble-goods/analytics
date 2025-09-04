# Bubble Goods Analytics

Analytics infrastructure and reporting tools for Bubble Goods marketplace data.

## 📚 Quick Links

- **[ROAS Dashboard](https://mbase.bubblegoods.com/dashboard/25)** ⭐ - Live TripleWhale replacement
- [Analytics Architecture](docs/ANALYTICS_ARCHITECTURE.md) - System overview and data flow
- [Tool Selection Guide](docs/TOOL_SELECTION.md) - When to use Metabase vs PostHog  
- [Data Sources](docs/DATA_SOURCES.md) - Complete source to destination mapping
- [Data Migrations](migrations/) - Database and connector upgrade history

## Analytics Stack

We use a dual-platform approach for different analytics needs:

- **Metabase**: Business intelligence, financial metrics, ROAS tracking, executive dashboards
- **PostHog**: Product analytics, user behavior, conversion funnels, A/B testing
- **Supabase**: Data warehouse storing transformed data from various sources
- **Airbyte**: ETL pipeline for ingesting data from ad platforms and APIs

### Quick Tool Selection

**Use Metabase when you need:**
- ROAS and advertising metrics
- Revenue and financial reporting  
- SQL-based analysis
- Cross-database queries
- Business KPI dashboards

**Use PostHog when you need:**
- User journey tracking
- Conversion funnel analysis
- Product feature usage
- A/B test results
- Session recordings

## Structure

- **`metabase-mcp/`** - Metabase MCP server for connecting Claude to our self-hosted Metabase instance
- **`reports/`** - Saved queries and analyses organized by frequency
  - `monthly/` - Monthly analytics (includes AP Report)
  - `daily/` - Daily reports (ROAS tracker)
- **`dashboards/`** - Dashboard configurations and documentation
  - `roas/` - ROAS dashboard setup and configuration
- **`docs/`** - Documentation for data sources, workflows, and processes
  - `ANALYTICS_ARCHITECTURE.md` - Complete system architecture
  - `TOOL_SELECTION.md` - When to use Metabase vs PostHog
  - `DATA_SOURCES.md` - Data pipeline and destinations
  - `AD_PERFORMANCE.md` - Ad tracking pipeline details
- **`scripts/`** - Utility scripts for data tasks
- **`migrations/`** - Database and connector migration history

## Available Reports & Dashboards

### Dashboards

#### ROAS Performance Tracker ✅ **LIVE**
- **Purpose:** Track return on ad spend across Google and Meta (replaces TripleWhale)
- **Location:** `dashboards/roas/`
- **Dashboard URL:** https://mbase.bubblegoods.com/dashboard/25
- **Collection:** https://mbase.bubblegoods.com/collection/47
- **Refresh:** Live data from Supabase warehouse
- **Status:** ✅ **Operational** - All data issues resolved
- **Data Quality:** Meta conversions tracking fixed, Google CPC/CPM corrected

### Reports

#### Daily Reports
- **ROAS Tracker** ✅ - Daily ad performance and efficiency metrics
  - Queries: `reports/daily/roas_tracker.sql` 
  - Dashboard: https://mbase.bubblegoods.com/dashboard/25
  - Status: Live with 9 working cards (262-270)
  - Includes: Platform comparison, campaign performance, trend analysis, conversion tracking

#### Monthly Reports
- **Accounts Payable Report** - Monthly brand payouts and obligations
  - Files: `reports/monthly/accounts_payable_final.sql`
  - Documentation: `reports/monthly/AP_REPORT_COLUMN_DEFINITIONS.md`
  - Implementation Guide: `reports/monthly/AP_REPORT_INSTRUCTIONS.md`
  - Metabase Card: [219](https://mbase.bubblegoods.com/card/219)

## Quick Setup

1. Install Python 3.12+ if not already installed
2. Set up Metabase MCP server:
   ```bash
   cd metabase-mcp
   python -m venv venv
   source venv/bin/activate  # or `venv\Scripts\activate` on Windows
   pip install -r requirements.txt
   cp .env.example .env
   # Edit .env with your Metabase credentials
   ```
3. Start the MCP server:
   ```bash
   python server.py
   ```

## Configuration

The MCP server requires:
- `METABASE_URL`: Your self-hosted Metabase instance URL
- `METABASE_API_KEY`: API key from your Metabase instance (recommended)

Alternative authentication:
- `METABASE_USER_EMAIL`: Your Metabase email
- `METABASE_PASSWORD`: Your Metabase password

## Usage

Once configured, you can use Claude to:
- Query Metabase databases directly
- Create and manage dashboards
- Execute SQL queries
- Generate reports and analyses
- Export data in various formats

## Security

- Never commit `.env` files with actual credentials
- Use API key authentication when possible
- Regularly rotate API keys