# Airbyte Configuration and Troubleshooting Guide

## Current Status Summary

### Working Connections
- ✅ **Google Ads**: Syncing correctly to `google_ads` schema (last sync: 4 hours ago)
- ✅ **Zendesk**: Syncing correctly to `zendesk` schema (last sync: current)

### Problem Connections
- ❌ **Stripe**: Syncing to wrong schema (`public` instead of `stripe`)
- ❌ **Meta Ads**: Data stopped flowing after Sept 7 (10 days behind)
- ⚠️ **Zendesk Satisfaction Ratings**: 105 days old (possible API issue)

## Stripe Configuration Issues

### Problem
Airbyte is currently syncing Stripe data to the `public` schema instead of the `stripe` schema, causing:
- Primary `stripe` schema data is 132 days old
- Current data is scattered across `public`, `analytics`, and `stripe` schemas
- Reporting tools are looking at stale data

### Root Cause
The Airbyte destination configuration for Stripe is targeting the wrong schema.

### Fix Steps
1. **Check Current Configuration**
   ```sql
   -- Check current sync destinations
   SELECT name, namespace, updated_at
   FROM airbyte_internal._airbyte_destination_state
   WHERE name IN ('charges', 'invoices', 'subscriptions')
   ORDER BY namespace, updated_at DESC;
   ```

2. **Update Airbyte Destination**
   - Log into Airbyte dashboard
   - Navigate to Stripe connection
   - Check destination configuration
   - Ensure schema is set to `stripe` (not `public`)

3. **Run Data Consolidation**
   ```bash
   # Run the consolidation script created
   psql -h [supabase-host] -d postgres -f scripts/consolidate_stripe_data.sql
   ```

### Expected Schema Configuration
```yaml
destinations:
  stripe:
    schema: "stripe"  # Should be this
    # NOT: schema: "public"
```

## Meta Ads Configuration Issues

### Problem
Meta Ads stopped syncing new data after September 7, 2025 (10 days behind).

### Possible Causes
1. **API Token Expiration**: Meta API tokens typically expire every 60 days
2. **Permission Changes**: Meta may have revoked API permissions
3. **Rate Limiting**: Account may have hit API rate limits
4. **Connector Configuration**: Airbyte connector settings may need updates

### Troubleshooting Steps

1. **Check API Credentials**
   - Verify Meta API access token is still valid
   - Check token expiration date
   - Ensure all required permissions are granted:
     - `ads_read`
     - `ads_management`
     - `business_management`

2. **Review Airbyte Logs**
   ```bash
   # Check for error messages in Airbyte logs
   # Look for:
   # - Authentication errors
   # - Rate limit messages
   # - API permission errors
   ```

3. **Test API Connection**
   ```bash
   # Test Meta API connectivity
   curl -G \
     -d "access_token={access-token}" \
     "https://graph.facebook.com/v18.0/me/accounts"
   ```

4. **Update Connector Configuration**
   - Check if Airbyte Meta Ads connector needs updating
   - Verify account ID and ad account permissions
   - Update API version if needed

## Zendesk Satisfaction Ratings Issue

### Problem
Satisfaction ratings data is 105 days old while other Zendesk data is current.

### Possible Causes
1. **Stream Configuration**: Satisfaction ratings stream may be disabled
2. **API Permissions**: Missing permission for satisfaction ratings endpoint
3. **Data Volume**: Low satisfaction rating volume may cause sync issues

### Fix Steps
1. **Check Stream Configuration**
   - Verify satisfaction ratings stream is enabled in Airbyte
   - Check sync frequency settings

2. **Verify API Permissions**
   - Ensure Zendesk API key has access to satisfaction ratings
   - Test endpoint: `/api/v2/satisfaction_ratings.json`

3. **Manual Data Pull Test**
   ```bash
   # Test Zendesk satisfaction ratings API
   curl -u {email}:{api_token} \
     "https://{subdomain}.zendesk.com/api/v2/satisfaction_ratings.json"
   ```

## General Airbyte Troubleshooting

### Check Sync Status
```sql
-- Monitor all sync statuses
SELECT
    name as stream_name,
    namespace as schema_name,
    updated_at as last_sync,
    CURRENT_TIMESTAMP - updated_at as time_since_sync,
    CASE
        WHEN CURRENT_TIMESTAMP - updated_at < INTERVAL '1 day' THEN '✅ Recent'
        WHEN CURRENT_TIMESTAMP - updated_at < INTERVAL '7 days' THEN '⚠️ Behind'
        ELSE '❌ Stale'
    END as sync_status
FROM airbyte_internal._airbyte_destination_state
WHERE namespace IN ('stripe', 'zendesk', 'google_ads', 'meta_ads', 'public')
ORDER BY updated_at DESC;
```

### Common Issues and Solutions

#### Schema Mismatch
**Problem**: Data syncing to wrong schema
**Solution**: Update destination configuration in Airbyte

#### API Token Expiration
**Problem**: Authentication failures
**Solution**:
1. Generate new API tokens
2. Update Airbyte connection credentials
3. Test connection

#### Rate Limiting
**Problem**: API calls being throttled
**Solution**:
1. Reduce sync frequency
2. Implement exponential backoff
3. Check API usage limits

#### Missing Permissions
**Problem**: Access denied errors
**Solution**:
1. Review required API permissions
2. Update token scope
3. Re-authorize applications

### Monitoring Scripts

#### Daily Health Check
```bash
# Run daily monitoring
psql -h [host] -d postgres -f scripts/monitor_stripe_zendesk.sql
```

#### Data Validation
```bash
# Run weekly validation
psql -h [host] -d postgres -f scripts/validate_financial_data.sql
```

## Recovery Procedures

### Stripe Data Recovery
1. Run consolidation script to merge data from all schemas
2. Update Airbyte destination to correct schema
3. Trigger full resync if needed
4. Validate data integrity

### Meta Ads Recovery
1. Update API credentials
2. Check connector configuration
3. Trigger full historical resync
4. Monitor for new data flow

### General Recovery
1. **Backup Current Data**
   ```sql
   CREATE TABLE backup_table_name AS SELECT * FROM original_table;
   ```

2. **Reset Connection**
   - Delete and recreate Airbyte connection
   - Reconfigure all settings
   - Test with small date range first

3. **Historical Backfill**
   - Configure historical sync period
   - Monitor progress closely
   - Validate data after completion

## Best Practices

### Configuration Management
- Document all Airbyte connection settings
- Version control configuration changes
- Test changes in development first

### Monitoring
- Set up automated alerts for sync failures
- Monitor data freshness daily
- Track API usage and limits

### Data Quality
- Implement validation checks after syncs
- Monitor for schema changes
- Set up data consistency alerts

## Contact Information

### API Support
- **Stripe**: https://stripe.com/docs/api
- **Meta**: https://developers.facebook.com/docs/marketing-api
- **Zendesk**: https://developer.zendesk.com/api-reference/

### Internal Escalation
- Data pipeline issues: Engineering team
- API access issues: Operations team
- Billing/account issues: Finance team