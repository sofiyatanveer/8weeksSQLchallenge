

-- 1.	How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT customer_id) AS total_customers
FROM subscriptions;

--2.	What is the monthly distribution of trial plan start_date values for our dataset
-- use the start of the month as the group by value


SELECT 
  DATE_TRUNC('month', start_date) AS month_start,
  COUNT(*) AS trial_count
FROM 
  subscriptions
WHERE 
  plan_id = 0  -- Filter for trial plan (plan_id = 0)
GROUP BY 
  DATE_TRUNC('month', start_date)
ORDER BY 
  month_start;

--3.	What plan start_date values occur after the year 2020 for our dataset? 
--Show the breakdown by count of events for each plan_name
SELECT
  p.plan_name,
  COUNT(*) AS start_count
FROM subscriptions s
JOIN plans p
  ON s.plan_id = p.plan_id
WHERE EXTRACT(YEAR FROM start_date)>2020 --OR WHERE start_date>'2020-12-31'
GROUP BY p.plan_name
ORDER BY start_count DESC;

-- 4.	What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
WITH total_customers AS (
  SELECT COUNT(DISTINCT customer_id) AS total_count
  FROM subscriptions
),
churned_customers AS (
  SELECT COUNT(DISTINCT customer_id) AS churned_count
  FROM subscriptions
  WHERE plan_id = 4
)
SELECT
  c.churned_count,
  ROUND((c.churned_count::decimal / t.total_count) * 100, 1) AS churn_percentage
FROM churned_customers c, total_customers t;


-- 5.	How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?


WITH plan_cte AS
(
SELECT customer_id,
	plan_name,
	ROW_NUMBER()OVER (PARTITION BY customer_id ORDER BY start_date)AS rnk
	FROM subscriptions s
	INNER JOIN plans p
	ON s.plan_id=p.plan_id
)
SELECT COUNT(DISTINCT customer_id) AS churned_after_trial,
ROUND(100.0*
	  COUNT(DISTINCT customer_id)/
	 	(SELECT COUNT(DISTINCT customer_id )FROM subscriptions)
	  			) percent_churn_after_trial
	 FROM plan_cte
	 WHERE rnk=2
	 AND plan_name='churn';


--6.	What is the number and percentage of customer plans after their initial free trial?
--sol1

WITH plan_cte AS
(
SELECT s.customer_id,s.plan_id,
	p.plan_name,
	ROW_NUMBER()OVER (PARTITION BY s.customer_id ORDER BY s.start_date)AS rnk
	FROM subscriptions s
	INNER JOIN plans p
	ON s.plan_id=p.plan_id
)
SELECT 
plan_id,plan_name,
COUNT(DISTINCT customer_id) convert_count,
ROUND(100*
	  COUNT(customer_id)::NUMERIC/
	 	(SELECT COUNT(DISTINCT customer_id )FROM subscriptions),1
	  			) convert_percent
	 FROM plan_cte
	 WHERE rnk=2
	 GROUP BY plan_name,plan_id
	 ORDER BY plan_id;
--sol 2
WITH next_plans AS (
  SELECT 
    customer_id, 
    plan_id, 
    LEAD(plan_id) OVER(
      PARTITION BY customer_id 
      ORDER BY plan_id) as next_plan_id
  FROM subscriptions
)

SELECT
  n.next_plan_id ,
  COUNT(n.customer_id) AS converted_customers,
  ROUND(100 * 
    COUNT(n.customer_id)::NUMERIC 
    / (SELECT COUNT(DISTINCT customer_id) 
      FROM subscriptions)
  ,1) AS conversion_percentage
FROM next_plans n
WHERE next_plan_id IS NOT NULL 
AND plan_id=0
  GROUP BY n.plan_id,next_plan_id
ORDER BY next_plan_id;

--7.	What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
WITH CTE AS (
SELECT *
,ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY start_date DESC) as rn
FROM subscriptions
WHERE start_date <= '2020-12-31'
)
SELECT 
cte.plan_id,
plan_name,
COUNT(customer_id) as customer_count,
ROUND((COUNT(customer_id)::NUMERIC/(SELECT COUNT(DISTINCT customer_id) FROM CTE))*100,1) as percent_of_customers
FROM CTE
INNER JOIN plans as P on CTE.plan_id = P.plan_id
WHERE rn = 1
GROUP BY cte.plan_id,plan_name
ORDER BY cte.plan_id;


-- 8.	How many customers have upgraded to an annual plan in 2020?

SELECT p.plan_name,COUNT(s.customer_id)AS count_convert_to_annual
FROM subscriptions s
JOIN plans p
USING(plan_id)
WHERE plan_id=3
AND
EXTRACT(YEAR FROM start_date)=2020
GROUP BY p.plan_name
;



--9.	How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

WITH trial_cte AS
(
SELECT customer_id,start_date AS trial_date
	FROM subscriptions
	WHERE plan_id=0
),
annual_cte AS
(
SELECT customer_id,start_date AS annual_date
	FROM subscriptions 
	WHERE plan_id=3
)
SELECT
ROUND(AVG(a.annual_date-t.trial_date),0) AS avg_days_to_upgrade
FROM trial_cte t JOIN annual_cte a
USING(customer_id);

10.	Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
-- Sol1
WITH trial_cte AS
(
  SELECT
    customer_id,
    MIN(start_date) AS trial_start
  FROM subscriptions
  WHERE plan_id = 0
	GROUP BY customer_id
),
annual_cte AS
(
  SELECT 
    s.customer_id,
    s.start_date AS annual_start,
    (s.start_date - t.trial_start) AS days_to_annual -- Calculate days between trial and annual plan
  FROM subscriptions s
  JOIN trial_cte t
    ON s.customer_id = t.customer_id
  WHERE s.plan_id = 3
)
SELECT 
(CASE 
    WHEN days_to_annual <= 30 THEN 1
    WHEN days_to_annual <= 60 THEN 2
    WHEN days_to_annual <= 90 THEN 3
    WHEN days_to_annual <= 120 THEN 4
    WHEN days_to_annual <= 150 THEN 5
    WHEN days_to_annual <= 180 THEN 6
    WHEN days_to_annual <= 210 THEN 7
    WHEN days_to_annual <= 240 THEN 8
    WHEN days_to_annual <= 270 THEN 9
    WHEN days_to_annual <= 300 THEN 10
    WHEN days_to_annual <= 330 THEN 11
    WHEN days_to_annual <= 360 THEN 12
    ELSE 13
  END) AS sort_order,
  (CASE 
    WHEN days_to_annual <= 30 THEN '0-30'
    WHEN days_to_annual <= 60 THEN '31-60'
    WHEN days_to_annual <= 90 THEN '61-90'
    WHEN days_to_annual <= 120 THEN '91-120'
    WHEN days_to_annual <= 150 THEN '121-150'
    WHEN days_to_annual <= 180 THEN '151-180'
    WHEN days_to_annual <= 210 THEN '181-210'
    WHEN days_to_annual <= 240 THEN '211-240'
    WHEN days_to_annual <= 270 THEN '241-270'
    WHEN days_to_annual <= 300 THEN '271-300'
    WHEN days_to_annual <= 330 THEN '301-330'
    WHEN days_to_annual <= 360 THEN '331-360'
    ELSE '360+' -- Handles cases where days are more than 360
  END) AS bin,
  COUNT(customer_id) AS customer_count,
   ROUND(AVG(days_to_annual), 1) AS average_days_to_annual
   
   
FROM 
annual_cte 

GROUP BY bin,sort_order
ORDER BY sort_order
;

--sol2:
WITH trial_cte AS
(
SELECT customer_id,
	MIN(start_date) AS trial_start_date
	FROM subscriptions s
	WHERE plan_id=0
	GROUP BY customer_id
),
annual_cte AS
(
SELECT s.customer_id,
	s.start_date AS annual_start_date,
	(s.start_date-t.trial_start_date) AS days_to_upgrade
	FROM subscriptions s
	JOIN trial_cte t 
	USING(customer_id)
	WHERE plan_id=3
)

SELECT
	WIDTH_BUCKET(days_to_upgrade,0,365,12) AS bucket,
	
	((WIDTH_BUCKET(days_to_upgrade,0,365,12)-1)*30+1||' - '||WIDTH_BUCKET(days_to_upgrade,0,365,12)*30) AS bin,
	COUNT(*) AS customer_count,
	ROUND(AVG(days_to_upgrade),1) AS avg_days_to_upgrade
	FROM annual_cte a
	GROUP BY bin,bucket
	ORDER BY Bucket ;

11.	How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
--Sol1:
WITH pro_monthly_cte As
(
SELECT
	customer_id,
	start_date AS pro_month_start
	FROM subscriptions
	WHERE plan_id=2
),
 basic_monthly_cte As
(
SELECT
	customer_id,
	start_date AS basic_month_start
	FROM subscriptions
	WHERE plan_id=1
)

SELECT COUNT(DISTINCT p.customer_id) downgrade_count

FROM
pro_monthly_cte p JOIN basic_monthly_cte b
USING(customer_id)
WHERE
p.pro_month_start<b.basic_month_start
AND EXTRACT(YEAR FROM b.basic_month_start)=2020;

--sol2:

WITH pro_to_basic_cte AS (
  SELECT 
    s.customer_id,  
  	p.plan_id,
    p.plan_name, 
	  LEAD(p.plan_id) OVER ( 
      PARTITION BY s.customer_id
      ORDER BY s.start_date) AS next_plan_id
  FROM subscriptions AS s
  JOIN plans AS p
    ON s.plan_id = p.plan_id
 WHERE EXTRACT(YEAR FROM s.start_date) = 2020
)
  
SELECT 
  COUNT(customer_id) AS downgraded_customers
FROM pro_to_basic_cte
WHERE plan_id = 2
  AND next_plan_id = 1;

-- sol3:

WITH pro_monthly_to_basic AS (
  -- Find customers who switched from pro monthly to basic monthly
  SELECT 
    s1.customer_id,
    s1.start_date AS pro_monthly_start,
    s2.start_date AS basic_monthly_start
  FROM subscriptions s1
  JOIN subscriptions s2
    ON s1.customer_id = s2.customer_id
  WHERE 
    s1.plan_id = 2  -- Pro monthly
    AND s2.plan_id = 1  -- Basic monthly
    AND s1.start_date < s2.start_date  -- Downgrade event: pro monthly must occur before basic monthly
    AND EXTRACT(YEAR FROM s2.start_date) = 2020  -- Limit to downgrades in 2020
)
SELECT COUNT(DISTINCT customer_id) AS downgrade_count
FROM pro_monthly_to_basic;


WITH payment_schedule AS (
  -- Identify all subscription changes for customers in 2020
  SELECT 
    s.customer_id,
    s.plan_id,
    p.plan_name,
    p.price,
    s.start_date,
    LEAD(s.start_date) OVER (PARTITION BY s.customer_id ORDER BY s.start_date) AS next_plan_start_date,
    p.plan_name = 'churn' AS has_churned
  FROM subscriptions s
  JOIN plans p ON s.plan_id = p.plan_id
  WHERE EXTRACT(YEAR FROM s.start_date) = 2020
),
payment_calendar AS (
  -- Generate the payment calendar for all customers, taking into account their plan changes
  SELECT 
    ps.customer_id,
    ps.plan_id,
    ps.plan_name,
    ps.start_date AS payment_date,
    ps.price AS amount,
    ROW_NUMBER() OVER (PARTITION BY ps.customer_id ORDER BY ps.start_date) AS payment_order
  FROM payment_schedule ps
  WHERE NOT ps.has_churned -- Exclude churned customers
  UNION ALL
  -- Handle monthly payments until the customer changes plans or churns
  SELECT 
    ps.customer_id,
    ps.plan_id,
    ps.plan_name,
    ps.start_date + INTERVAL '1 month' * generate_series(1, CAST(DATE_PART('month', AGE(COALESCE(next_plan_start_date, '2020-12-31'), ps.start_date)) AS INTEGER)) AS payment_date,
    ps.price AS amount,
    ROW_NUMBER() OVER (PARTITION BY ps.customer_id ORDER BY ps.start_date + INTERVAL '1 month' * generate_series(1, CAST(DATE_PART('month', AGE(COALESCE(next_plan_start_date, '2020-12-31'), ps.start_date)) AS INTEGER))) AS payment_order
  FROM payment_schedule ps
  WHERE ps.plan_name IN ('basic monthly', 'pro monthly')
)
-- Final select to create the payments table for 2020
SELECT 
  customer_id,
  plan_id,
  plan_name,
  payment_date,
  amount,
  payment_order
FROM payment_calendar
WHERE EXTRACT(YEAR FROM payment_date) = 2020
ORDER BY customer_id, payment_order;
