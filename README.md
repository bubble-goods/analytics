# Bubble Goods Analytics

Analytics infrastructure and reporting tools for Bubble Goods marketplace data.

## Structure

- **`metabase-mcp/`** - Metabase MCP server for connecting Claude to our self-hosted Metabase instance
- **`reports/`** - Saved queries and analyses organized by frequency
  - `monthly/` - Monthly analytics (includes AP Report)
  - `weekly/` - Weekly business reports  
  - `ad-hoc/` - One-off analyses
- **`dashboards/`** - Dashboard configurations and documentation
- **`docs/`** - Documentation for data sources, workflows, and processes
- **`scripts/`** - Utility scripts for data tasks

## Available Reports

### Monthly Reports
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