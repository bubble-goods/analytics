#!/usr/bin/env python3
"""
Script to create the ROAS dashboard layout in Metabase
Arranges the created cards into a comprehensive dashboard
"""

import asyncio
import sys

# Add metabase-mcp to path
sys.path.append('/Users/alanmcgee/Projects/bubblegoods/analytics/metabase-mcp')
from server import metabase_client

# Constants
ROAS_COLLECTION_ID = 47

# Card IDs from the created cards
CARD_IDS = {
    "ROAS Overview - 30 Day Summary": 262,
    "Platform Performance Comparison": 263,
    "Top Performing Campaigns": 264,
    "Underperforming Campaigns Alert": 265,
    "Daily Spend and Revenue Trend": 266,
    "Weekly Performance Analysis": 267,
    "Campaign Efficiency Metrics": 268,
    "Revenue Attribution by Platform": 269,
    "High Spend Zero Revenue Alert": 270
}

# Dashboard layout configuration
DASHBOARD_CARDS = [
    # Row 1: Executive Summary Cards
    {
        "id": CARD_IDS["ROAS Overview - 30 Day Summary"],
        "card_id": CARD_IDS["ROAS Overview - 30 Day Summary"],
        "row": 0,
        "col": 0,
        "size_x": 4,
        "size_y": 3,
        "visualization_settings": {
            "scalar.field": "overall_roas",
            "scalar.switch_positive_negative": False
        }
    },
    {
        "id": CARD_IDS["Revenue Attribution by Platform"],
        "card_id": CARD_IDS["Revenue Attribution by Platform"],
        "row": 0,
        "col": 4,
        "size_x": 4,
        "size_y": 3,
    },
    {
        "id": CARD_IDS["Campaign Efficiency Metrics"],
        "card_id": CARD_IDS["Campaign Efficiency Metrics"],
        "row": 0,
        "col": 8,
        "size_x": 4,
        "size_y": 3,
    },
    
    # Row 2: Platform Analysis
    {
        "id": CARD_IDS["Platform Performance Comparison"],
        "card_id": CARD_IDS["Platform Performance Comparison"],
        "row": 3,
        "col": 0,
        "size_x": 6,
        "size_y": 4,
    },
    {
        "id": CARD_IDS["Daily Spend and Revenue Trend"],
        "card_id": CARD_IDS["Daily Spend and Revenue Trend"],
        "row": 3,
        "col": 6,
        "size_x": 6,
        "size_y": 4,
        "visualization_settings": {
            "graph.dimensions": ["date"],
            "graph.metrics": ["daily_spend", "daily_revenue"]
        }
    },
    
    # Row 3: Campaign Performance
    {
        "id": CARD_IDS["Top Performing Campaigns"],
        "card_id": CARD_IDS["Top Performing Campaigns"],
        "row": 7,
        "col": 0,
        "size_x": 6,
        "size_y": 4,
    },
    {
        "id": CARD_IDS["Underperforming Campaigns Alert"],
        "card_id": CARD_IDS["Underperforming Campaigns Alert"],
        "row": 7,
        "col": 6,
        "size_x": 6,
        "size_y": 4,
    },
    
    # Row 4: Analysis & Alerts
    {
        "id": CARD_IDS["Weekly Performance Analysis"],
        "card_id": CARD_IDS["Weekly Performance Analysis"],
        "row": 11,
        "col": 0,
        "size_x": 6,
        "size_y": 4,
    },
    {
        "id": CARD_IDS["High Spend Zero Revenue Alert"],
        "card_id": CARD_IDS["High Spend Zero Revenue Alert"],
        "row": 11,
        "col": 6,
        "size_x": 6,
        "size_y": 4,
    }
]

async def create_dashboard():
    """Create the ROAS Performance Tracker dashboard"""
    try:
        dashboard_data = {
            "name": "ROAS Performance Tracker",
            "description": "Complete ROAS tracking dashboard replacing TripleWhale. Monitors Google and Meta ad performance with real-time metrics from Supabase data warehouse.",
            "collection_id": ROAS_COLLECTION_ID,
            "cards": DASHBOARD_CARDS
        }
        
        result = await metabase_client.request("POST", "/dashboard", json=dashboard_data)
        return result
        
    except Exception as e:
        print(f"❌ Error creating dashboard: {e}")
        return None

async def add_dashboard_filters(dashboard_id):
    """Add filters to the dashboard"""
    try:
        # Date Range Filter
        date_filter = {
            "name": "Date Range",
            "slug": "date_range",
            "id": "date_range",
            "type": "date/all-options",
            "target": ["dimension", ["template-tag", "date_range"]],
            "default": "past30days"
        }
        
        # Platform Filter
        platform_filter = {
            "name": "Platform",
            "slug": "platform",
            "id": "platform", 
            "type": "string/=",
            "target": ["dimension", ["template-tag", "platform"]],
            "default": None
        }
        
        # Add filters to dashboard
        filter_data = {
            "parameters": [date_filter, platform_filter]
        }
        
        result = await metabase_client.request("PUT", f"/dashboard/{dashboard_id}", json=filter_data)
        return result
        
    except Exception as e:
        print(f"❌ Error adding filters: {e}")
        return None

async def test_cards():
    """Test that all cards return data"""
    print("🧪 Testing cards with live data...")
    
    working_cards = []
    for card_name, card_id in CARD_IDS.items():
        try:
            result = await metabase_client.request("POST", f"/card/{card_id}/query")
            if result.get('status') == 'completed' and result.get('data', {}).get('rows'):
                row_count = len(result['data']['rows'])
                print(f"   ✅ {card_name}: {row_count} rows")
                working_cards.append(card_name)
            else:
                print(f"   ⚠️ {card_name}: No data returned")
        except Exception as e:
            print(f"   ❌ {card_name}: Error - {e}")
    
    return working_cards

async def main():
    """Main function to create the dashboard"""
    print("🎯 Creating ROAS Dashboard Layout")
    
    try:
        # Test cards first
        print("\n1️⃣ Testing card data...")
        working_cards = await test_cards()
        print(f"   📊 {len(working_cards)} out of {len(CARD_IDS)} cards have data")
        
        # Create dashboard
        print("\n2️⃣ Creating dashboard...")
        dashboard = await create_dashboard()
        
        if dashboard:
            dashboard_id = dashboard['id']
            print(f"   ✅ Dashboard created: ID {dashboard_id}")
            print(f"   🔗 URL: https://mbase.bubblegoods.com/dashboard/{dashboard_id}")
            
            # Add filters
            print("\n3️⃣ Adding dashboard filters...")
            filters_result = await add_dashboard_filters(dashboard_id)
            if filters_result:
                print("   ✅ Filters added successfully")
            else:
                print("   ⚠️ Could not add filters (dashboard still usable)")
            
            print("\n🎉 ROAS Dashboard created successfully!")
            print(f"🔗 Dashboard URL: https://mbase.bubblegoods.com/dashboard/{dashboard_id}")
            print(f"📁 Collection URL: https://mbase.bubblegoods.com/collection/{ROAS_COLLECTION_ID}")
            
            return dashboard_id
        else:
            print("   ❌ Failed to create dashboard")
            return None
            
    except Exception as e:
        print(f"❌ Error in main: {e}")
        return None
    
    finally:
        await metabase_client.close()

if __name__ == "__main__":
    dashboard_id = asyncio.run(main())
    if dashboard_id:
        print(f"\n✅ Success! Dashboard ID: {dashboard_id}")
        sys.exit(0)
    else:
        print(f"\n❌ Failed to create dashboard")
        sys.exit(1)