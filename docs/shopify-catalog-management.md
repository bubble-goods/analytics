# Shopify Catalog Management Tools

Complete toolkit for managing and analyzing Shopify product catalogs across multiple sales channels.

## Tools Overview

### 1. Catalog Comparison (`scripts/compare-catalogs.js`)
- Compares product publication status between Online Store and Hydrogen storefront
- Generates detailed reports with CSV exports
- Identifies products needing synchronization

### 2. Batch Publisher (`scripts/publish-to-hydrogen.js`)
- Automatically publishes products to Hydrogen storefront
- Handles rate limiting and error recovery
- Verifies publication success

## Prerequisites

- Node.js 18+ installed
- Shopify Admin API access token with permissions:
  - `read_products` - To fetch product data
  - `read_publications` - To access sales channel information
  - `write_publications` - To publish products (for publishing script)

## Quick Start

1. **Install dependencies:**
   ```bash
   npm install @shopify/admin-api-client@^1.1.1 chalk@^5.3.0 cli-progress@^3.12.0 csv-writer@^1.6.0 dotenv@^16.4.7
   ```

2. **Configure environment:**
   ```bash
   cp .env.catalog.example .env.catalog
   # Edit .env.catalog with your Shopify credentials
   ```

3. **Run comparison:**
   ```bash
   node scripts/compare-catalogs.js
   ```

4. **Publish missing products (optional):**
   ```bash
   # First, update the Hydrogen publication ID in publish-to-hydrogen.js
   node scripts/publish-to-hydrogen.js
   ```

## Shopify Admin API Setup

1. Go to Shopify Admin → **Settings** → **Apps and sales channels** → **Develop apps**
2. Click **Create an app** or select existing custom app
3. Go to **Configuration** tab
4. Under **Admin API access scopes**, enable required permissions
5. **Save** and go to **API credentials** tab
6. **Install app** and copy the **Admin API access token**

## Expected Output

### Catalog Comparison
```
🛍️  Shopify Catalog Comparison Tool

📡 Fetching sales channels...
✅ Found 7 sales channels:
  - Online Store (gid://shopify/Publication/123)
  - Hydrogen Storefront (gid://shopify/Publication/456)
  ...

📦 Fetching products...
Progress |████████████████████████████████████████| 100% | 5766/5766 products | ETA: 0s
✅ Fetched 5766 products

📊 CATALOG COMPARISON SUMMARY
==================================================
🏪 Online Store
⚡ Hydrogen Storefront

📈 STATISTICS:
Total Products: 5766
Both Channels: 1981 (34.4%)
Online Store Only: 4 (0.1%)
Hydrogen Storefront Only: 0 (0.0%)
Neither Channel: 3781 (65.6%)

💾 Full report exported to: catalog-diff-2025-09-16T11-45-23.csv
✅ Catalog comparison complete!
```

### Publishing Results
```
🚀 Publish Products to Hydrogen Storefront

📦 Found 82 products to publish to Hydrogen
🎯 Target: Hydrogen Storefront (gid://shopify/Publication/456)

📤 Starting publication process...
Publishing |████████████████████████████████████████| 100% | 82/82 products | ETA: 0s

✅ Successfully published: 82 products
🔍 Verifying publications...
✅ Verified: 5 products successfully published
🎉 Publication process complete!
```

## CSV Export Format

Generated reports include:
- **Product ID** - Shopify product ID
- **Title** - Product name
- **Handle** - URL slug
- **Status** - active, archived, draft
- **Channel Availability** - Where published
- **Published Channels** - All active channels
- **Created At** - Creation timestamp
- **Updated At** - Last modification

## Rate Limiting & Error Handling

Both scripts include:
- Automatic rate limit detection and retry
- Exponential backoff for failed requests
- Progress indicators for long operations
- Comprehensive error reporting
- Graceful handling of API timeouts

## Security Best Practices

- Never commit `.env.catalog` to version control
- Store access tokens in secure credential management
- Use environment-specific tokens for different stages
- Regularly rotate API access tokens
- Monitor API usage and permissions

## Troubleshooting

### Authentication Errors
- Verify access token is correct
- Ensure all required scopes are enabled
- Check that app is installed in store

### Rate Limiting
- Scripts automatically handle rate limits
- For very large catalogs, expect longer runtimes
- Consider running during off-peak hours

### Missing Publications
- Scripts use intelligent matching for channel names
- Manually verify publication IDs if needed
- Update publication ID constants for your store

## Integration Examples

### CI/CD Pipeline
```yaml
- name: Shopify Catalog Sync
  run: |
    cp .env.catalog.example .env.catalog
    echo "SHOPIFY_STORE_URL=${{ secrets.SHOPIFY_STORE_URL }}" >> .env.catalog
    echo "SHOPIFY_ADMIN_ACCESS_TOKEN=${{ secrets.SHOPIFY_ADMIN_ACCESS_TOKEN }}" >> .env.catalog
    node scripts/compare-catalogs.js
```

### Scheduled Monitoring
```bash
# Daily catalog check at 2 AM
0 2 * * * cd /path/to/analytics && node scripts/compare-catalogs.js
```

## Performance Notes

- **Small catalogs** (<1,000 products): ~30 seconds
- **Medium catalogs** (1,000-10,000): 2-5 minutes
- **Large catalogs** (10,000+): 10+ minutes
- Memory usage scales with product count
- Network latency affects total runtime