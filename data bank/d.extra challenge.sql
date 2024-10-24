--D. Extra Challenge
/*Data Bank wants to try another option which is a bit more difficult to implement 
- they want to calculate data growth using an interest calculation, just like in a traditional savings account you might have with a bank.

If the annual interest rate is set at 6% and the Data Bank team wants to reward its customers 
by increasing their data allocation based off the interest calculated on a daily basis at the end of each day,
how much data would be required for this option on a monthly basis?

Special notes:
Data Bank wants an initial calculation which does not allow for compounding interest,
however they may also be interested in a daily compounding interest calculation
so you can try to perform this calculation 
*/

/*ANS
we’ll assume the interest is calculated as follows:

Daily Interest Rate (for no compounding):

Daily Interest Rate=6%/365=0.000164384
OR can use as (6/100)/365

Where 6% is the annual interest rate.

Steps:
Step 1: Calculate Daily Interest
To calculate the daily interest (without compounding), we can use the running balance of each customer 
at the end of each day, multiply it by the daily interest rate, and sum this value for each day of the month
to estimate the data growth for each customer.

1. Calculate Daily Closing Balance:
First, we calculate the daily closing balance for each customer:

*/
WITH daily_closing_balance AS (
    SELECT
        customer_id,
        txn_date,
        SUM(
            CASE 
                WHEN txn_type = 'deposit' THEN txn_amount
                WHEN txn_type = 'withdrawal' THEN -txn_amount
                ELSE 0 
            END
        ) OVER (PARTITION BY customer_id ORDER BY txn_date) AS daily_balance
    FROM 
        customer_transactions
),

--2. Calculate Daily Interest (Without Compounding):
--Using the daily closing balance, we calculate the interest for each day based on the non-compounded interest rate.


interest_calculation AS (
    SELECT
        customer_id,
        txn_date,
        daily_balance,
        ROUND((daily_balance * 0.000164384),4) AS daily_interest
    FROM 
        daily_closing_balance
)


--3. Summing Interest for Each Month:
--Now, we sum up the daily interest for each customer for every month to calculate 
--how much data needs to be allocated based on this interest calculation:


SELECT
    customer_id,
    DATE_TRUNC('month', txn_date) AS txn_month,
    SUM(daily_interest) AS total_interest
FROM 
    interest_calculation
GROUP BY 
    customer_id, 
    DATE_TRUNC('month', txn_date)
ORDER BY 
    customer_id, 
    txn_month;

--Step 2: Daily Compounding Interest Calculation (Optional)
--For compounding interest, we need to apply the daily interest rate on the balance 
--including the previous day's interest. This will increase the daily balance, and the interest is applied 
--to this updated balance.


--1. Calculate Daily Closing Balance and Compound Interest:

WITH daily_closing_balance AS (
    SELECT
        customer_id,
        txn_date,
        SUM(
            CASE 
                WHEN txn_type = 'deposit' THEN txn_amount
                WHEN txn_type = 'withdrawal' THEN -txn_amount
                ELSE 0 
            END
        ) OVER (PARTITION BY customer_id ORDER BY txn_date) AS daily_balance
    FROM 
        customer_transactions
),
compounding_interest AS (
    SELECT
        customer_id,
        txn_date,
        daily_balance,
        (daily_balance * 0.000164384) AS daily_interest,
        LAG(daily_balance, 1, 0) OVER (PARTITION BY customer_id ORDER BY txn_date) + 
        (LAG(daily_balance * 0.000164384, 1, 0) OVER (PARTITION BY customer_id ORDER BY txn_date)) AS compounded_balance
    FROM 
        daily_closing_balance
)

--2. Sum Compounded Interest for Each Month:
-- sum the compounded interest for each customer for every month:


SELECT
    customer_id,
    DATE_TRUNC('month', txn_date) AS txn_month,
    SUM(compounded_balance * 0.000164384) AS total_compounded_interest_data
FROM 
    compounding_interest
GROUP BY 
    customer_id, 
    DATE_TRUNC('month', txn_date)
ORDER BY 
    customer_id, 
    txn_month;

/*
Without Compounding: The interest is calculated daily on the daily balance without taking into account the 
interest from the previous day. The monthly interest sum gives the total data allocated for each customer.

With Daily Compounding: The interest calculation takes into account the interest accrued from the previous days,
leading to a slightly higher total data allocation at the end of each month.
*/