-- A. Pizza Metrics
--1 How many pizzas were ordered?
SELECT 
COUNT(*) AS total_pizzas_ordered
FROM customer_orders_clean;


-- 2 How many unique customer orders were made?
SELECT 
COUNT(DISTINCT customer_id) AS unique_customers
FROM customer_orders_clean;

--3 How many successful orders were delivered by each runner?

SELECT runner_id,COUNT(order_id) AS tot_order_delivered
FROM runner_orders_clean
WHERE distance>0
GROUP BY runner_id
ORDER BY runner_id;


-- 4 How many of each type of pizza was delivered?

SELECT pn.pizza_name,COUNT(c.pizza_id) AS pizza_delivered_Number
FROM customer_orders_clean c 
JOIN runner_orders_clean r
ON c.order_id=r.order_id
JOIN pizza_names pn
ON c.pizza_id=pn.pizza_id
WHERE r.distance>0
GROUP BY pn.pizza_name
ORDER BY pn.pizza_name;

-- 5 How many Vegetarian and Meatlovers were ordered by each customer?


SELECT c.customer_id,pn.pizza_name,
COUNT(pn.pizza_name) AS order_count
FROM customer_orders_clean c
JOIN pizza_names pn
ON c.pizza_id=pn.pizza_id
GROUP BY c.customer_id,pn.pizza_name
ORDER BY c.customer_id

-- 6 What was the maximum number of pizzas delivered in a single order?


WITH count_pizza 
AS
( 
SELECT c.order_id,COUNT(c.pizza_id) AS pizza_count
	FROM customer_orders_clean c
	JOIN runner_orders_clean r
	ON c.order_id=r.order_id
	WHERE r.distance>0
	GROUP BY c.order_id
)

SELECT MAX(pizza_count) AS pizza_count
FROM count_pizza;

-- 7 For each customer, how many delivered pizzas had at least 1 change and how many had no changes?



SELECT c.customer_id,
SUM(
CASE WHEN c.exclusions <> NULL OR c.extras <> NULL THEN 1
	ELSE 0
	END 
)AS change,
SUM(
CASE 
	WHEN c.exclusions=NULL or c.extras=NULL THEN 1
	ELSE 0 
	END
) AS no_change
FROM customer_orders_clean c
JOIN runner_orders_clean r
ON c.order_id=r.order_id
WHERE r.distance > 0
GROUP BY c.customer_id
ORDER BY c.customer_id;


-- 8 How many pizzas were delivered that had both exclusions and extras?
SELECT COUNT(*) AS pizza_delivered_with_exclusions_and_extras
FROM customer_orders_clean c JOIN runner_orders_clean r
ON c.order_id=r.order_id
AND r.distance>0
WHERE c.exclusions IS NOT NULL
  AND c.exclusions <> ''
  AND c.extras IS NOT NULL
  AND c.extras <> '';
  
-- 9 What was the total volume of pizzas ordered for each hour of the day?

SELECT EXTRACT(HOUR FROM c.order_time) AS order_hour,
COUNT(c.pizza_id) AS pizza_order_count  -- CAN USE order_id/* both produce same result
FROM customer_orders_clean c
GROUP BY order_hour
ORDER BY order_hour;



-- 10 What was the volume of orders for each day of the week?
SELECT 
	EXTRACT(DOW FROM c.order_time) AS day_number,
	TO_CHAR(c.order_time,'Day') AS day_of_week,
	COUNT(c.order_id) AS order_count
FROM customer_orders_clean c
GROUP BY day_number,day_of_week
ORDER BY day_number;