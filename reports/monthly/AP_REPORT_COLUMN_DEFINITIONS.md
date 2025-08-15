# AP Report Column Definitions for Accounting Team

## Report Information
- **Report Name:** Accounts Payable by Brand - Monthly
- **Metabase Card ID:** 219
- **Database:** Bubble Production Read Replica (MySQL)
- **Report URL:** https://mbase.bubblegoods.com/card/219

---

## Column Definitions

### **1. Brand Name**
**Definition:** Vendor/supplier name  
**Purpose:** Identifies the seller partner for payment tracking  
**Source of Truth:** `brand.name` table in production database  
**SQL Reference:** `SELECT b.name AS "Brand Name"`

### **2. Commission Rate**
**Definition:** Bubble Goods' platform fee percentage  
**Example:** "35%" means Bubble Goods keeps 35% of sales as revenue  
**Accounting:** This is our revenue share/commission income rate  
**Source of Truth:** `brand.commission_rate` table in production database  
**SQL Reference:** `CONCAT(ROUND(b.commission_rate * 100, 1), '%') AS "Commission Rate"`  
**Data Transformation:** Decimal to percentage (0.35 → "35%")

### **3. Total GMV**
**Definition:** Gross Merchandise Value - total customer payments to the brand for the month  
**Calculation:** Sum of all paid order line items (quantity × price)  
**Exclusions:** Cancelled orders and unpaid orders  
**Accounting:** Gross sales before any deductions  
**Source of Truth:** `customer_order_line_item` joined with `customer_order` and `brand_order` tables  
**SQL Reference:** 
```sql
SUM(CASE 
  WHEN co.financial_status IN ('paid', 'partially_paid', 'authorized') 
    AND co.cancelled_at IS NULL 
    AND co.created >= {{start_date}} 
    AND co.created < {{end_date}}
  THEN coli.quantity * coli.price 
  ELSE 0 
END) AS "Total GMV"
```

### **4. Bubble Goods Revenue**
**Definition:** Our commission earnings from this brand  
**Calculation:** Total GMV × Commission Rate  
**Accounting:** Commission revenue recognized for the period  
**Source of Truth:** Calculated field using GMV and commission rate  
**SQL Reference:** `(Total GMV calculation) * b.commission_rate AS "Bubble Goods Revenue"`

### **5. Refunds/Damages**
**Definition:** Deductions from seller payout due to returns, refunds, or damages  
**Note:** Currently $0.00 for all brands in July 2024 data  
**Accounting:** Contra-revenue reducing amounts owed to vendor  
**Source of Truth:** `line_item_adjustment` table via `brand_order_line_item` relationship  
**SQL Reference:**
```sql
SUM(CASE 
  WHEN co.created >= {{start_date}} 
    AND co.created < {{end_date}}
  THEN COALESCE(lia.amount, 0) 
  ELSE 0 
END) AS "Refunds/Damages"
```

### **6. Total AP Owed**
**Definition:** Net amount owed to brand for THIS MONTH only  
**Calculation:** (GMV × (1 - Commission Rate)) - Refunds  
**Note:** Shows $0.00 for all brands - this may indicate that brands earned commission on orders that haven't reached the Net 30 payment terms yet, or that monthly activity was captured in a different period  
**Accounting:** Monthly accounts payable liability for new obligations created in this period  
**Payment Terms:** Net 30 from transaction date  
**Source of Truth:** Calculated field combining GMV, commission rate, and refunds  
**SQL Reference:** `((Total GMV) * (1 - b.commission_rate)) - (Refunds) AS "Total AP Owed"`

### **7. Paid This Month**
**Definition:** Actual payments made to the brand during the month  
**Accounting:** Cash outflows to vendors  
**Source of Truth:** `payout` table filtered by date range and status  
**SQL Reference:**
```sql
SUM(CASE 
  WHEN p.created >= {{start_date}} 
    AND p.created < {{end_date}} 
    AND p.status = 'completed'
  THEN p.amount 
  ELSE 0 
END) AS "Paid This Month"
```

### **8. Outstanding Balance**
**Definition:** **CUMULATIVE** amount owed to brand (all-time balance)  
**Calculation:** Total historical brand earnings - total historical payments - refunds  
**Key Points:**
- **Positive values:** We owe money to the brand (unpaid invoices aging beyond Net 30)
- **Negative values:** Brand has been overpaid or has obligations to us  
**Accounting:** Net accounts payable balance per vendor - represents aging of unpaid amounts  
**Payment Terms Context:** With Net 30 terms, positive balances indicate orders from >30 days ago that haven't been paid yet  
**Source of Truth:** Calculated using all historical data from multiple tables  
**SQL Reference:**
```sql
(SUM(All GMV * (1 - commission_rate)) - SUM(All Refunds) - SUM(All Payments)) 
AS "Outstanding Balance"
```

---

## Database Schema References

### Primary Tables Used:
- **`brand`** - Brand information and commission rates
- **`customer_order`** - Main order records with financial status
- **`customer_order_line_item`** - Individual line items for GMV calculation
- **`brand_order`** - Links brands to customer orders
- **`brand_order_line_item`** - Brand-specific line items
- **`line_item_adjustment`** - Refunds and adjustments
- **`payout`** - Payment records to brands

### Key Relationships:
```
customer_order → brand_order → brand
customer_order_line_item → brand_order_line_item → line_item_adjustment
brand → payout
```

---

## Important Accounting Notes

- **Monthly vs. Cumulative:** Columns 3-7 are monthly figures; Column 8 is all-time cumulative
- **Negative Balances:** Common due to advance payments or timing differences
- **Revenue Recognition:** Based on 'paid', 'partially_paid', or 'authorized' order status
- **Payment Terms:** Net 30 from transaction date - payments made approximately 30 days after order creation
- **Date Parameters:** Report uses `start_date` and `end_date` parameters for flexible monthly reporting

---

## Data Quality Validation

### Filters Applied:
- Only orders with `financial_status` IN ('paid', 'partially_paid', 'authorized')
- Excludes orders where `cancelled_at IS NOT NULL`
- Only includes brands with status 'live', 'in_review', or 'ready_for_review'
- Date range filtering based on `created` timestamps

### Cross-Reference Recommendations:
- Total GMV should match other GMV reports for the same period
- Commission revenue total should equal sum of "Bubble Goods Revenue" column
- Payment amounts should cross-reference with Stripe payout data
- Outstanding balances should reconcile with general ledger AP aging

---

**Report Generated:** August 15, 2025  
**Data Source:** Bubble Production Read Replica Database  
**SQL Query Location:** `/Users/alanmcgee/Projects/bubblegoods/analytics/reports/monthly/accounts_payable_final.sql`