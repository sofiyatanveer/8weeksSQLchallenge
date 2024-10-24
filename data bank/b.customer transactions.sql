--B. Customer Transactions
-- 1 What is the unique count and total amount for each transaction type?
SELECT 
DISTINCT(txn_type) AS transaction_type,
COUNT(*) AS unique_transaction_count,
SUM(txn_amount) AS total_amount
FROM customer_transactions
GROUP BY transaction_type
ORDER BY transaction_type;
-- 2 What is the average total historical deposit counts and amounts for all customers?
WITH CTE AS (
SELECT 
customer_id,
AVG(txn_amount) as avg_deposit,
COUNT(*) as transaction_count
FROM customer_transactions
WHERE txn_type = 'deposit'
GROUP BY customer_id
)
SELECT 
ROUND(AVG(avg_deposit),2) as avg_deposit_amount,
ROUND(AVG(transaction_count),0) as avg_transactions
FROM CTE;
-- 3 For each month - how many Data Bank customers make more than 1 deposit and either 1 purchase or 1 withdrawal in a single month?
WITH customer_monthly_transactions AS (
    
    SELECT 
        customer_id,
        EXTRACT(YEAR FROM txn_date) AS txn_year,
        EXTRACT(MONTH FROM txn_date) AS txn_month,
	-- we can use  DATE_TRUNC('month', txn_date) also
        SUM(CASE WHEN txn_type = 'deposit' THEN 1 ELSE 0 END) AS deposit_count,
        SUM(CASE WHEN txn_type = 'purchase' THEN 1 ELSE 0 END) AS purchase_count,
        SUM(CASE WHEN txn_type = 'withdrawal' THEN 1 ELSE 0 END) AS withdrawal_count
    FROM 
        customer_transactions
    GROUP BY 
        customer_id, EXTRACT(YEAR FROM txn_date), EXTRACT(MONTH FROM txn_date)
)
-- Filter customers who meet the criteria
SELECT 
    txn_year,
    txn_month,
    COUNT(DISTINCT customer_id) AS customer_count
FROM 
    customer_monthly_transactions
WHERE 
    deposit_count > 1 
    AND (purchase_count >= 1 OR withdrawal_count >= 1)
GROUP BY 
    txn_year, txn_month
ORDER BY 
    txn_year, txn_month;


-- 4 What is the closing balance for each customer at the end of the month?
--SOL1:
WITH cust_monthly_trans AS (
   
    SELECT 
        customer_id,
        EXTRACT(YEAR FROM txn_date) AS txn_yr,
        EXTRACT(MONTH FROM txn_date) AS txn_month,
	TO_CHAR(txn_date, 'Month') AS txn_month_name,
        SUM(CASE 
            WHEN txn_type = 'deposit' THEN txn_amount
            WHEN txn_type = 'withdrawal' THEN -txn_amount
            ELSE 0
        END) AS monthly_balance
    FROM 
        customer_transactions
    GROUP BY 
        customer_id, EXTRACT(YEAR FROM txn_date), EXTRACT(MONTH FROM txn_date),	TO_CHAR(txn_date, 'Month')
),

running_balance AS
(
SELECT customer_id,
	txn_yr,
	txn_month,
	txn_month_name,
	SUM(monthly_balance) OVER(PARTITION BY customer_id
								ORDER BY txn_yr,txn_month
								ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
							 ) AS closing_balance
								
	FROM cust_monthly_trans
)

SELECT 
customer_id,
txn_yr,
txn_month,
txn_month_name,
closing_balance
FROM running_balance
ORDER BY 
customer_id,
txn_yr,
txn_month,
txn_month_name

--SOL2:
WITH monthly_transactions AS (
    SELECT 
        customer_id,
        DATE_TRUNC('month', txn_date) AS txn_month,
        TO_CHAR(txn_date, 'Month') AS month_name,
        SUM(
            CASE 
                WHEN txn_type = 'deposit' THEN txn_amount
                WHEN txn_type = 'withdrawal' THEN -txn_amount
                ELSE 0  -- Handle other transaction types as needed
            END
        ) AS net_change
    FROM 
        customer_transactions
    GROUP BY 
        customer_id, 
        DATE_TRUNC('month', txn_date), 
        TO_CHAR(txn_date, 'Month')
),
cumulative_balances AS (
    SELECT 
        customer_id,
        txn_month,
        month_name,
        net_change,
        SUM(net_change) OVER (
            PARTITION BY customer_id 
            ORDER BY txn_month 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS closing_balance
    FROM 
        monthly_transactions
)
SELECT 
    customer_id,
    TO_CHAR(txn_month + INTERVAL '1 month' - INTERVAL '1 day', 'YYYY-MM-DD') AS end_of_month,
    closing_balance
FROM 
    cumulative_balances
ORDER BY 
    customer_id, 
    txn_month;


-- 5 What is the percentage of customers who increase their closing balance by more than 5%?

WITH monthly_balances AS (
    -- Step 1: Get closing balances for each customer at the end of each month
    SELECT 
        customer_id,
        DATE_TRUNC('month', txn_date) AS txn_month,
        SUM(
            CASE 
                WHEN txn_type = 'deposit' THEN txn_amount
                WHEN txn_type = 'withdrawal' THEN -txn_amount
                ELSE 0
            END
        ) AS closing_balance
    FROM 
        customer_transactions
    GROUP BY 
        customer_id, 
        DATE_TRUNC('month', txn_date)
	ORDER BY 
	 customer_id, 
        DATE_TRUNC('month', txn_date)
),
balance_changes AS (
    -- Step 2: Calculate the percentage change in balance compared to the previous month
    SELECT 
        customer_id,
        txn_month,
        closing_balance,
        LAG(closing_balance) OVER (PARTITION BY customer_id ORDER BY txn_month) AS previous_balance,
        CASE 
            WHEN LAG(closing_balance) OVER (PARTITION BY customer_id ORDER BY txn_month) > 0 
            THEN (closing_balance - LAG(closing_balance) OVER (PARTITION BY customer_id ORDER BY txn_month)) / LAG(closing_balance) OVER (PARTITION BY customer_id ORDER BY txn_month) * 100
            ELSE NULL -- Handle cases where the previous balance is 0 or doesn't exist
        END AS percentage_change
    FROM 
        monthly_balances
),
customers_with_increase AS (
    -- Step 3: Identify customers whose closing balance increased by more than 5%
    SELECT 
        customer_id
    FROM 
        balance_changes
    WHERE 
        percentage_change > 5
    GROUP BY 
        customer_id
),
total_customers AS (
    -- Step 4: Count total distinct customers
    SELECT 
        COUNT(DISTINCT customer_id) AS total_customer_count
    FROM 
        customer_transactions
)
-- Step 5: Calculate the percentage of customers who increased their balance by more than 5%
SELECT 
   ROUND( COUNT(DISTINCT cwi.customer_id) * 100.0 / tc.total_customer_count,2) AS percentage_increased
   FROM 
    customers_with_increase cwi, 
    total_customers tc
	GROUP BY 
	tc.total_customer_count;



