#!/usr/bin/env python3
"""
Script to create the Accounts Payable card directly in Metabase
"""

import os
import sys
import requests
import json
from pathlib import Path

# Add the metabase-mcp directory to path to import the server modules
sys.path.append('/Users/alanmcgee/Projects/bubblegoods/analytics/metabase-mcp')

# Load environment variables from .env file
from dotenv import load_dotenv
load_dotenv('/Users/alanmcgee/Projects/bubblegoods/analytics/metabase-mcp/.env')

# Metabase configuration
METABASE_URL = os.getenv('METABASE_URL')
METABASE_API_KEY = os.getenv('METABASE_API_KEY')

def get_metabase_session():
    """Get authenticated session with Metabase"""
    if METABASE_API_KEY:
        return {
            'headers': {
                'X-API-KEY': METABASE_API_KEY,
                'Content-Type': 'application/json'
            }
        }
    else:
        print("No API key found. Please configure METABASE_API_KEY in .env file")
        return None

def read_sql_file():
    """Read the SQL query from file"""
    sql_file = Path('/Users/alanmcgee/Projects/bubblegoods/analytics/reports/monthly/accounts_payable_query.sql')
    with open(sql_file, 'r') as f:
        return f.read()

def create_accounts_payable_card():
    """Create the accounts payable card in Metabase"""
    session = get_metabase_session()
    if not session:
        return False
    
    # Read SQL query
    sql_query = read_sql_file()
    
    # Card configuration
    card_data = {
        "name": "Accounts Payable by Brand - Monthly",
        "description": "Monthly AP report showing GMV, commissions, refunds, payments, and outstanding balances per seller/brand. Use start_date (first day of month) and end_date (first day of next month) parameters.",
        "dataset_query": {
            "type": "native",
            "native": {
                "query": sql_query,
                "template-tags": {
                    "start_date": {
                        "id": "start_date",
                        "name": "start_date",
                        "display-name": "Month Start Date",
                        "type": "date",
                        "required": True,
                        "default": "2024-07-01"
                    },
                    "end_date": {
                        "id": "end_date", 
                        "name": "end_date",
                        "display-name": "Month End Date", 
                        "type": "date",
                        "required": True,
                        "default": "2024-08-01"
                    }
                }
            },
            "database": 2  # Production read replica database ID
        },
        "display": "table",
        "visualization_settings": {
            "table.columns": [
                {"name": "Brand Name", "enabled": True, "fieldRef": ["field", "Brand Name", {"base-type": "type/Text"}]},
                {"name": "Commission Rate", "enabled": True, "fieldRef": ["field", "Commission Rate", {"base-type": "type/Text"}]},
                {"name": "Total GMV", "enabled": True, "fieldRef": ["field", "Total GMV", {"base-type": "type/Currency"}]},
                {"name": "Bubble Goods Revenue", "enabled": True, "fieldRef": ["field", "Bubble Goods Revenue", {"base-type": "type/Currency"}]},
                {"name": "Refunds/Damages", "enabled": True, "fieldRef": ["field", "Refunds/Damages", {"base-type": "type/Currency"}]},
                {"name": "Total AP Owed", "enabled": True, "fieldRef": ["field", "Total AP Owed", {"base-type": "type/Currency"}]},
                {"name": "Paid This Month", "enabled": True, "fieldRef": ["field", "Paid This Month", {"base-type": "type/Currency"}]},
                {"name": "Outstanding Balance", "enabled": True, "fieldRef": ["field", "Outstanding Balance", {"base-type": "type/Currency"}]}
            ]
        }
    }
    
    # Create the card
    try:
        response = requests.post(
            f"{METABASE_URL}/api/card",
            json=card_data,
            **session
        )
        
        if response.status_code == 200:
            card = response.json()
            print(f"✅ Successfully created card: {card['name']}")
            print(f"🔗 Card ID: {card['id']}")
            print(f"🌐 URL: {METABASE_URL}/question/{card['id']}")
            return card
        else:
            print(f"❌ Failed to create card: {response.status_code}")
            print(f"Response: {response.text}")
            return None
            
    except Exception as e:
        print(f"❌ Error creating card: {e}")
        return None

def find_financial_collection():
    """Find or create a Financial Reports collection"""
    session = get_metabase_session()
    if not session:
        return None
    
    try:
        # List existing collections
        response = requests.get(f"{METABASE_URL}/api/collection", **session)
        if response.status_code == 200:
            collections = response.json()
            
            # Look for Financial Reports or similar collection
            for collection in collections:
                if 'financial' in collection.get('name', '').lower() or 'seller' in collection.get('name', '').lower():
                    print(f"📁 Found collection: {collection['name']} (ID: {collection['id']})")
                    return collection['id']
            
            # If no financial collection found, use root collection
            print("📁 Using root collection for now. Consider creating a 'Financial Reports' collection.")
            return None
            
    except Exception as e:
        print(f"❌ Error finding collections: {e}")
        return None

def main():
    """Main function"""
    print("🚀 Creating Accounts Payable card in Metabase...")
    
    # Check configuration
    if not METABASE_URL:
        print("❌ METABASE_URL not found in environment variables")
        return False
    
    if not METABASE_API_KEY:
        print("❌ METABASE_API_KEY not found in environment variables")
        return False
    
    print(f"🔗 Connecting to Metabase at: {METABASE_URL}")
    
    # Find collection (optional)
    collection_id = find_financial_collection()
    
    # Create the card
    card = create_accounts_payable_card()
    
    if card:
        print("\n✅ Card created successfully!")
        print("\n📋 Usage Instructions:")
        print("1. Navigate to the card URL above")
        print("2. Set start_date to first day of month (e.g., 2024-07-01)")
        print("3. Set end_date to first day of next month (e.g., 2024-08-01)")
        print("4. Click 'Get Answer' to run the report")
        return True
    else:
        print("\n❌ Failed to create card")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)