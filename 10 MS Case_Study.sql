-- Step 1: Categorize channels as 'Non-Paid' or 'Paid'
SELECT
    attribute,
    CASE
        WHEN attribute IN ('A', 'B', 'C') THEN 'Non-Paid'
        WHEN attribute IN ('D', 'E', 'F', 'G') THEN 'Paid'
        ELSE 'Unknown'
    END AS channel_type
FROM
    AttributionTouchEvents;

-- Step 2: Identify high-ticket item purchases
WITH HighTicketOrders AS (
    SELECT
        order_id,
        paid_amount
    FROM
        OrderRecords
    WHERE
        paid_amount > 5000
),

-- Step 3: Determine the last touchpoint before each purchase
LastTouchpoint AS (
    SELECT
        t.order_id,
        t.attribute AS channel,
        MAX(t.touch_date) AS last_touch_date
    FROM
        AttributionTouchEvents t
    JOIN
        HighTicketOrders h ON t.order_id = h.order_id
    WHERE
        t.touch_date <= (SELECT transaction_date FROM OrderRecords WHERE order_id = t.order_id)
    GROUP BY
        t.order_id, t.attribute
),

-- Step 4: Calculate the conversion rate for high-ticket items for each channel
ConversionRates AS (
    SELECT
        channel,
        COUNT(DISTINCT order_id) AS high_ticket_orders,
        COUNT(*) AS total_orders,
        ROUND((COUNT(DISTINCT order_id) * 100.0) / COUNT(*), 2) AS conversion_rate
    FROM
        LastTouchpoint
    GROUP BY
        channel
)

-- Step 5: Determine the channel with the highest conversion rate for high-ticket items
SELECT TOP 1
    channel,
    high_ticket_orders,
    total_orders,
    conversion_rate
FROM
    ConversionRates
ORDER BY
    conversion_rate DESC;
