--C. Data Allocation Challenge
/*To test out a few different hypotheses - the Data Bank team wants to run an experiment where different groups of customers would be allocated data using 3 different options:

Option 1: data is allocated based off the amount of money at the end of the previous month
Option 2: data is allocated on the average amount of money kept in the account in the previous 30 days
Option 3: data is updated real-time
For this multi-part challenge question - you have been requested to generate the following data elements to help the Data Bank team estimate how much data will need to be provisioned for each option:

running customer balance column that includes the impact each transaction
customer balance at the end of each month
minimum, average and maximum values of the running balance for each customer
Using all of the data available - how much data would have been required for each option on a monthly basis?

*/
/*
1. Running Customer Balance (Impact of Each Transaction)
We will calculate a running balance that reflects the impact of each transaction on the customer's account.

2. Customer Balance at the End of Each Month
For Option 1, we need to calculate the customer balance at the end of each month, which will help allocate data based on this balance for the next month.

3. Minimum, Average, and Maximum Running Balance for Each Customer
For Option 2 (average balance over the last 30 days) and for understanding trends (Option 3), we will compute the minimum, average, and maximum running balance for each customer.
*/

-- Step 1:Calculate the Running Balance for Each Customer
--We first calculate the running balance based on the transactions (deposits and withdrawals) for each customer.


WITH running_balances AS (
    SELECT
        customer_id,
        txn_date,
        SUM(
            CASE 
                WHEN txn_type = 'deposit' THEN txn_amount
                WHEN txn_type = 'withdrawal' THEN -txn_amount
                ELSE 0 
            END
        ) OVER (PARTITION BY customer_id ORDER BY txn_date) AS running_balance
    FROM 
        customer_transactions
)


--(Option 1)
-- Step 2:Calculate the Customer Balance at the End of Each Month 
--For Option 1, we will use the customer balance at the end of each month. 
--The LAG function is used to get the previous month's balance.


WITH end_of_month_balances AS (
    SELECT 
        customer_id,
        DATE_TRUNC('month', txn_date) AS txn_month,
        SUM(
            CASE 
                WHEN txn_type = 'deposit' THEN txn_amount
                WHEN txn_type = 'withdrawal' THEN -txn_amount
                ELSE 0 
            END
        ) AS monthly_balance,
        ROW_NUMBER() OVER (PARTITION BY customer_id, DATE_TRUNC('month', txn_date) ORDER BY txn_date DESC) AS rn
    FROM 
        customer_transactions
    GROUP BY 
        customer_id,
        DATE_TRUNC('month', txn_date),
        txn_date
)
SELECT 
    customer_id,
    txn_month,
    LAG(monthly_balance) OVER (PARTITION BY customer_id ORDER BY txn_month) AS data_allocated_for_next_month
FROM 
    end_of_month_balances
WHERE 
    rn = 1;

-- (Option 2)
--Step 3: Calculate Minimum, Average, and Maximum Running Balances
--For Option 2, where the allocation is based on the average balance over the previous 30 days, 
--we calculate the min, max, and average running balances.

WITH running_balances AS (
    SELECT
        customer_id,
        txn_date,
        SUM(
            CASE 
                WHEN txn_type = 'deposit' THEN txn_amount
                WHEN txn_type = 'withdrawal' THEN -txn_amount
                ELSE 0 
            END
        ) OVER (PARTITION BY customer_id ORDER BY txn_date) AS running_balance
    FROM 
        customer_transactions
)
SELECT 
    customer_id,
    MIN(running_balance) AS min_balance,
    AVG(running_balance) AS avg_balance,
    MAX(running_balance) AS max_balance
FROM 
    running_balances
GROUP BY 
    customer_id;
	
	
--(Option 3)	
--Step 4: Calculate Real-Time Balance 
--For Option 3, we need the total real-time running balance per day.


WITH daily_balances AS (
    SELECT 
        customer_id,
        txn_date,
        SUM(
            CASE 
                WHEN txn_type = 'deposit' THEN txn_amount
                WHEN txn_type = 'withdrawal' THEN -txn_amount
                ELSE 0 
            END
        ) OVER (PARTITION BY customer_id ORDER BY txn_date) AS running_balance
    FROM 
        customer_transactions
)
SELECT 
    customer_id,
    DATE_TRUNC('month', txn_date) AS txn_month,
    SUM(running_balance) AS total_real_time_balance
FROM 
    daily_balances
GROUP BY 
    customer_id,
    DATE_TRUNC('month', txn_date);