# Data Schema Documentation

## Overview
This document maps the current state of data schemas in Supabase, identifying where different data sources are stored and their freshness status.

## Current Schema Structure

### Stripe Data

#### Primary Schema: `stripe`
- **Purpose:** Main destination for Stripe data
- **Status:** ❌ Stale (132 days old, last update: May 8, 2025)
- **Tables:**
  - `charges` (8,126 rows)
  - `invoices` (4,676 rows)
  - `subscriptions` (355 rows)
  - `refunds`
  - `prices`

#### Secondary Schema: `public`
- **Purpose:** Alternative sync destination (currently active)
- **Status:** ✅ Current (last update: Sept 16, 2025)
- **Tables:**
  - `charges`
  - `invoices`
  - `subscriptions`
  - `subscription_items`
  - `refunds`
  - `prices`

#### Archive Schema: `analytics`
- **Purpose:** Old analytics destination
- **Status:** ❌ Stale (132 days old)
- **Tables:**
  - `charges`
  - `invoices`
  - `subscriptions`

### Zendesk Data

#### Primary Schema: `zendesk`
- **Purpose:** Main destination for Zendesk data
- **Status:** ✅ Current (last update: Today, Sept 17)
- **Tables:**
  - `tickets` (17,369 rows) - ✅ Current
  - `ticket_comments` (88,264 rows) - ✅ Current
  - `ticket_audits` - ✅ Current
  - `ticket_metrics` - ✅ Current
  - `ticket_metric_events` - ✅ Current
  - `ticket_fields` - ✅ Current
  - `ticket_forms` - ✅ Current
  - `satisfaction_ratings` (5,258 rows) - ❌ Stale (105 days old)

#### Archive Schema: `public`
- **Purpose:** Old sync destination
- **Status:** ❌ Stale (131 days old)
- **Tables:** Same as zendesk schema but outdated

## Data Freshness Status

| Source | Schema | Table | Row Count | Last Update | Days Behind | Status |
|--------|--------|-------|-----------|-------------|-------------|---------|
| Stripe | stripe | charges | 8,126 | 2025-05-08 | 132 | ❌ Stale |
| Stripe | public | charges | - | 2025-09-16 | 1 | ⚠️ Wrong Schema |
| Stripe | stripe | invoices | 4,676 | 2025-05-08 | 132 | ❌ Stale |
| Stripe | public | invoices | - | 2025-09-16 | 1 | ⚠️ Wrong Schema |
| Zendesk | zendesk | tickets | 17,369 | 2025-09-17 | 0 | ✅ Current |
| Zendesk | zendesk | ticket_comments | 88,264 | 2025-09-17 | 0 | ✅ Current |
| Zendesk | zendesk | satisfaction_ratings | 5,258 | 2025-06-04 | 105 | ❌ Stale |

## Issues Identified

### Stripe
1. **Schema Mismatch:** Airbyte is syncing to `public` instead of `stripe` schema
2. **Stale Data:** Primary `stripe` schema has 132-day-old data
3. **Data Duplication:** Same tables exist in multiple schemas with different data

### Zendesk
1. **Satisfaction Ratings:** 105 days behind, possible API/permission issue
2. **Schema Cleanup:** Old data in `public` schema should be archived

## Recommended Schema Usage

### For Reporting and Analytics
- **Stripe:** Use `stripe` schema (after data consolidation)
- **Zendesk:** Use `zendesk` schema
- **Avoid:** `public` schema for Stripe/Zendesk (use for consolidation only)

### For Airbyte Configuration
- **Stripe Destination:** Should target `stripe` schema
- **Zendesk Destination:** Currently correct (`zendesk` schema)

## Data Types and Key Fields

### Stripe Tables
- **Timestamps:** Stored as Unix timestamps (bigint), use `TO_TIMESTAMP()` for conversion
- **Key Fields:**
  - `charges.created` - Creation timestamp
  - `charges.amount` - Amount in cents
  - `charges.currency` - Currency code
  - `invoices.created` - Invoice creation
  - `subscriptions.created` - Subscription start

### Zendesk Tables
- **Timestamps:** Stored as ISO strings, directly usable
- **Key Fields:**
  - `tickets.created_at` - Ticket creation
  - `tickets.updated_at` - Last update
  - `tickets.status` - Current status
  - `satisfaction_ratings.score` - Rating score

## Next Steps
1. Fix Airbyte Stripe destination configuration
2. Consolidate Stripe data from `public` to `stripe` schema
3. Investigate satisfaction_ratings sync issue
4. Clean up duplicate tables in `public` schema
5. Set up automated monitoring for data freshness