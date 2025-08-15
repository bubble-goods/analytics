-- Monthly Accounts Payable Report for Bubble Goods
-- Shows monthly activity only - NOT cumulative liability  
-- Key: "Total AP Owed" = Monthly GMV activity minus commission and refunds

SELECT 
    b.name AS "Brand Name",
    CONCAT(ROUND(b.commission_rate * 100, 1), '%') AS "Commission Rate",
    
    -- Monthly GMV calculation (orders created in the specified month only)
    ROUND(COALESCE(monthly_orders.total_gmv, 0), 2) AS "Total GMV",
    
    -- Monthly Refunds/Damages (refunds processed in the specified month only) 
    ROUND(COALESCE(monthly_refunds.refund_amount, 0), 2) AS "Refunds/Damages",
    
    -- Monthly AP Owed = (Monthly GMV × (1 - Commission Rate)) - Monthly Refunds
    -- This represents what we owe for THIS MONTH'S activity only
    ROUND(COALESCE(
        (monthly_orders.total_gmv * (1 - b.commission_rate)) - 
        COALESCE(monthly_refunds.refund_amount, 0), 
        0), 2) AS "Total AP Owed",
    
    -- Paid This Month (payouts completed in the specified month)
    ROUND(COALESCE(monthly_payments.amount_paid, 0), 2) AS "Paid This Month",
    
    -- Outstanding Balance (all-time cumulative balance for reference)
    ROUND(COALESCE(
        (all_orders.total_lifetime_gmv * (1 - b.commission_rate)) - 
        COALESCE(all_refunds.total_refunds, 0) - 
        COALESCE(all_payments.total_paid, 0),
        0), 2) AS "Outstanding Balance"

FROM brand b

LEFT JOIN (
    SELECT 
        coli.brand_id,
        SUM(coli.quantity * coli.price) AS total_gmv
    FROM customer_order co
    JOIN customer_order_line_item coli ON co.id = coli.customer_order_id
    WHERE co.created >= {{start_date}} 
        AND co.created < {{end_date}}
        AND co.financial_status IN ('paid', 'partially_paid', 'authorized')
        AND co.cancelled_at IS NULL
    GROUP BY coli.brand_id
) monthly_orders ON b.id = monthly_orders.brand_id

LEFT JOIN (
    SELECT 
        lia.brand_id,
        SUM(COALESCE(lia.amount, 0)) AS refund_amount
    FROM line_item_adjustment lia
    JOIN brand_order bo ON lia.brand_order_id = bo.id
    JOIN customer_order co ON bo.customer_order_id = co.id
    WHERE co.created >= {{start_date}} 
        AND co.created < {{end_date}}
        AND lia.amount IS NOT NULL
    GROUP BY lia.brand_id
) monthly_refunds ON b.id = monthly_refunds.brand_id

LEFT JOIN (
    SELECT 
        brand_id,
        SUM(amount) AS amount_paid
    FROM payout
    WHERE created >= {{start_date}} 
        AND created < {{end_date}}
        AND status = 'completed'
    GROUP BY brand_id
) monthly_payments ON b.id = monthly_payments.brand_id

LEFT JOIN (
    SELECT 
        coli.brand_id,
        SUM(coli.quantity * coli.price) AS total_lifetime_gmv
    FROM customer_order co
    JOIN customer_order_line_item coli ON co.id = coli.customer_order_id
    WHERE co.financial_status IN ('paid', 'partially_paid', 'authorized')
        AND co.cancelled_at IS NULL
    GROUP BY coli.brand_id
) all_orders ON b.id = all_orders.brand_id

LEFT JOIN (
    SELECT 
        lia.brand_id,
        SUM(COALESCE(lia.amount, 0)) AS total_refunds
    FROM line_item_adjustment lia
    JOIN brand_order bo ON lia.brand_order_id = bo.id
    JOIN customer_order co ON bo.customer_order_id = co.id
    WHERE lia.amount IS NOT NULL
    GROUP BY lia.brand_id
) all_refunds ON b.id = all_refunds.brand_id

LEFT JOIN (
    SELECT 
        brand_id,
        SUM(amount) AS total_paid
    FROM payout
    WHERE status = 'completed'
    GROUP BY brand_id
) all_payments ON b.id = all_payments.brand_id

WHERE b.status IN ('live', 'in_review', 'ready_for_review')
    AND (
        monthly_orders.total_gmv > 0 
        OR monthly_payments.amount_paid > 0
    )

ORDER BY "Total AP Owed" DESC;