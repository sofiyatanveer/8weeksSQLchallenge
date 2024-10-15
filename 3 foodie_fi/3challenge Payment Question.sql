/*C. Challenge Payment Question
The Foodie-Fi team wants you to create a new payments table for the year 2020 
that includes amounts paid by each customer in the subscriptions table with 
the following requirements:

monthly payments always occur on the same day of month as the original start_date 
of any monthly paid plan
upgrades from basic to monthly or pro plans are reduced by the current paid amount 
in that month and start immediately
upgrades from pro monthly to pro annual are paid at the end of the current billing 
period and also starts at the end of the month period
once a customer churns they will no longer make payments
Example outputs for this table might look like the following:

customer_id	plan_id	plan_name	payment_date	amount	payment_order*/

-- Create the payments table for 2020

WITH payment_schedule AS -- Identify all subscription changes for customers in 2020
(
SELECT s.customer_id,
	s.plan_id,
	p.plan_name,
	p.price,
	s.start_date,
	LEAD(s.start_date) OVER (PARTITION BY s.customer_id ORDER BY s.start_date) AS next_plan_start_date,
	p.plan_name='churn' AS has_churned
	FROM subscriptions s
	JOIN plans p
	USING(plan_id)
	WHERE EXTRACT(YEAR FROM s.start_date)=2020
),
payment_calender AS -- Generate the payment calendar for all customers, taking into account their plan changes
(
	SELECT
    ps.customer_id,
	ps.plan_id,
	ps.plan_name,
	ps.start_date AS payment_date,
	ps.price AS amount,
	ROW_NUMBER() OVER(PARTITION BY ps.customer_id ORDER BY ps.start_date) AS payment_order
	FROM payment_schedule ps
	WHERE NOT ps.has_churned --exclude churned
	UNION ALL -- Handle monthly payments until the customer changes plans or churns
	SELECT ps.customer_id,
	ps.plan_id,
	ps.plan_name,
	ps.start_date + INTERVAL '1 month' * generate_series(1, CAST(DATE_PART('month', AGE(COALESCE(next_plan_start_date, '2020-12-31'), ps.start_date)) AS INTEGER)) AS payment_date,
	ps.price AS amount,
	ROW_NUMBER() OVER(PARTITION BY ps.customer_id ORDER BY ps.start_date + INTERVAL '1 month' * generate_series(1, CAST(DATE_PART('month', AGE(COALESCE(next_plan_start_date, '2020-12-31'), ps.start_date)) AS INTEGER)))AS payment_order
	FROM payment_schedule ps
	WHERE ps.plan_name IN('basix monthly','pro monthly')
)
-- create the payments table for 2020
SELECT 
customer_id,
plan_id,
plan_name,
payment_date,
amount,
payment_order
FROM payment_calender 
WHERE
EXTRACT(YEAR FROM payment_date) = 2020
ORDER BY customer_id, payment_order;


