#!/usr/bin/env python3
"""
Script to explore the actual database structure
"""

import os
import sys
import requests
import json
from pathlib import Path

# Load environment variables from .env file
sys.path.append('/Users/alanmcgee/Projects/bubblegoods/analytics/metabase-mcp')
from dotenv import load_dotenv
load_dotenv('/Users/alanmcgee/Projects/bubblegoods/analytics/metabase-mcp/.env')

# Metabase configuration
METABASE_URL = os.getenv('METABASE_URL')
METABASE_API_KEY = os.getenv('METABASE_API_KEY')

def get_metabase_session():
    """Get authenticated session with Metabase"""
    return {
        'headers': {
            'X-API-KEY': METABASE_API_KEY,
            'Content-Type': 'application/json'
        }
    }

def list_databases():
    """List all databases"""
    session = get_metabase_session()
    response = requests.get(f"{METABASE_URL}/api/database", **session)
    if response.status_code == 200:
        databases = response.json()
        print("📊 Available Databases:")
        
        # Handle case where response might be a dict with 'data' key or directly a list
        if isinstance(databases, dict):
            if 'data' in databases:
                databases = databases['data']
            else:
                print(f"Unexpected response format: {databases}")
                return []
        
        for db in databases:
            if isinstance(db, dict):
                print(f"  {db.get('id', 'N/A')}: {db.get('name', 'N/A')} ({db.get('engine', 'N/A')})")
            else:
                print(f"  Unexpected database format: {db}")
        return databases
    else:
        print(f"Error: {response.status_code} - {response.text}")
    return []

def list_tables(database_id):
    """List all tables in a database"""
    session = get_metabase_session()
    response = requests.get(f"{METABASE_URL}/api/database/{database_id}/schema", **session)
    if response.status_code == 200:
        schemas = response.json()
        print(f"\n📋 Tables in Database {database_id}:")
        
        # Look for seller/brand related tables
        seller_tables = []
        order_tables = []
        payment_tables = []
        
        for schema_name, tables in schemas.items():
            for table in tables:
                table_name = table.lower()
                print(f"  - {table}")
                
                if any(word in table_name for word in ['seller', 'brand', 'vendor', 'merchant']):
                    seller_tables.append(table)
                elif any(word in table_name for word in ['order', 'transaction', 'purchase']):
                    order_tables.append(table)
                elif any(word in table_name for word in ['payment', 'payout', 'refund']):
                    payment_tables.append(table)
        
        print(f"\n🏪 Potential Seller/Brand tables: {seller_tables}")
        print(f"🛒 Potential Order tables: {order_tables}")
        print(f"💰 Potential Payment tables: {payment_tables}")
        
        return schemas
    return {}

def get_table_fields(database_id, table_name):
    """Get fields for a specific table"""
    session = get_metabase_session()
    
    # First get table metadata
    response = requests.get(f"{METABASE_URL}/api/database/{database_id}/metadata", **session)
    if response.status_code == 200:
        metadata = response.json()
        
        # Find the table
        for table in metadata.get('tables', []):
            if table['name'].lower() == table_name.lower():
                print(f"\n📊 Fields in {table_name}:")
                for field in table.get('fields', []):
                    print(f"  - {field['name']}: {field['base_type']} ({field.get('semantic_type', 'N/A')})")
                return table
    
    return None

def main():
    """Main exploration function"""
    print("🔍 Exploring Bubble Goods database structure...\n")
    
    # List databases
    databases = list_databases()
    
    # Find production database (likely ID 2 based on CLAUDE.md)
    prod_db = None
    for db in databases:
        if 'production' in db.get('name', '').lower() or (db.get('id') == 2 and 'mysql' in db.get('engine', '')):
            prod_db = db
            break
    
    if not prod_db:
        print("❌ Could not find production database")
        return
    
    print(f"\n🎯 Using database: {prod_db['name']} (ID: {prod_db['id']})")
    
    # List tables
    schemas = list_tables(prod_db['id'])
    
    # Get details for key tables we think exist
    potential_tables = [
        'sellers', 'brands', 'vendors', 'merchants',
        'orders', 'line_items', 'transactions',
        'payouts', 'payments', 'refunds'
    ]
    
    print(f"\n🔍 Checking for common table names...")
    for table_name in potential_tables:
        # Try to get fields (this will tell us if table exists)
        table_info = get_table_fields(prod_db['id'], table_name)
        if table_info:
            print(f"✅ Found table: {table_name}")
        else:
            print(f"❌ Table not found: {table_name}")

if __name__ == "__main__":
    main()