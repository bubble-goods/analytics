# Metabase MCP Server - Claude Context

## Connection Details
- **URL:** https://mbase.bubblegoods.com
- **Authentication:** API key (configured in .env)
- **Status:** ✅ Operational (tested with 204 cards, 45 collections, 4 databases)

## Available Databases
1. **Bubble Production Read Replica** (MySQL) - Primary business data
2. **Bubble Google Analytics** - Web analytics 
3. **Supabase** (PostgreSQL) - Additional data storage
4. **Sample Database** (H2) - Metabase examples

## Data Sources Context
- **Production DB:** Core business metrics (orders, customers, products, brands)
- **Stripe:** Seller payout data (referenced but may need separate integration)
- **Zendesk:** Customer support interactions (referenced but may need separate integration)

## MCP Tools Available
- `list_databases()` - View all connected databases
- `list_tables(database_id)` - Browse tables in a database  
- `get_table_fields(table_id)` - Examine table structure
- `list_cards()` - View existing questions/reports
- `execute_card(card_id)` - Run existing questions
- `create_card()` - Build new questions
- `execute_query()` - Run custom SQL
- `list_collections()` - Browse dashboard collections
- `create_collection()` - Organize reports

## Current Metabase Assets
- **204 cards/questions** available for execution
- **45 collections** for organization
- Active questions include: AOV analysis, brand revenue, customer loyalty, order analytics

## Usage Patterns
Always run `npm run lint` and `npm run typecheck` after code changes (check for these commands in the project).