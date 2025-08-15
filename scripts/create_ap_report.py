#!/usr/bin/env python3
"""
Script to create the Accounts Payable report in Metabase
"""

import requests
import json
from datetime import datetime, timedelta

# MCP Server endpoint
MCP_URL = "http://localhost:8000"

def call_mcp_tool(tool_name, **kwargs):
    """Call an MCP tool via HTTP"""
    payload = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "tools/call",
        "params": {
            "name": tool_name,
            "arguments": kwargs
        }
    }
    
    response = requests.post(f"{MCP_URL}/mcp", json=payload)
    if response.status_code == 200:
        result = response.json()
        return result.get("result", {}).get("content", [])
    else:
        print(f"Error calling {tool_name}: {response.status_code}")
        return None

# First, let's list databases to find the production DB
print("Listing databases...")
databases = call_mcp_tool("list_databases")
print(json.dumps(databases, indent=2))

# Find the production database (Database ID 2 according to CLAUDE.md)
production_db_id = 2

# List tables in production database
print(f"\nListing tables in database {production_db_id}...")
tables = call_mcp_tool("list_tables", database_id=production_db_id)
print(json.dumps(tables, indent=2))

# Get fields for key tables
key_tables = ["sellers", "orders", "refunds", "seller_payouts"]
for table_name in key_tables:
    print(f"\nGetting fields for {table_name} table...")
    # Find table ID first
    table_info = next((t for t in tables if t["name"] == table_name), None)
    if table_info:
        table_id = table_info["id"]
        fields = call_mcp_tool("get_table_fields", table_id=table_id)
        print(f"Fields in {table_name}:")
        for field in fields:
            print(f"  - {field['name']}: {field['base_type']}")