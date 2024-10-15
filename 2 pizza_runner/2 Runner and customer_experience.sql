-- B. Runner and Customer Experience
-- 1 How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
SELECT 
	DATE_TRUNC('week',registration_date) AS signup_week,
	COUNT(runner_id) AS runner_count
	FROM runners
	WHERE registration_date>='2021-01-01'
	GROUP BY signup_week
	ORDER BY signup_week;
-- 2 What was the average time in minutes it took for each runner to arrive
-- at the Pizza Runner HQ to pickup the order?
WITH minutes_cte AS
(
	SELECT 
	r.runner_id,
	ROUND(EXTRACT(EPOCH FROM(r.pickup_time-c.order_time))/60 )as avg_arrival_in_minutes
	--EXTRACT(EPOCH FROM ...) returns the difference between two timestamps in seconds. 
	--It calculates the "epoch" or the number of seconds that have passed between two timestamps, 
	-- which can then be converted to minutes by dividing by 60.
	   FROM customer_orders_clean c
	   JOIN runner_orders_clean r
	   ON c.order_id=r.order_id
	WHERE r.pickup_time IS NOT NULL
	   AND c.order_time IS NOT NULL 
	GROUP BY r.runner_id,r.pickup_time,c.order_time
	ORDER BY avg_arrival_in_minutes

)

SELECT ROUND(avg(avg_arrival_in_minutes),2) AS avg_time_in_minutes
		   FROM minutes_cte;
					



--3 Is there any relationship between the number of pizzas and how long the order takes to prepare?

--PIZZA & ORDER PREPARATION TIME

WITH order_preparation_time_cte
AS
(
SELECT 
	r.order_id,
	COUNT(c.pizza_id) AS pizza_count,
	EXTRACT(EPOCH FROM(r.pickup_time-c.order_time))/60 AS preparation_time_in_minutes
	FROM runner_orders_clean r
	JOIN customer_orders_clean c
	ON r.order_id=c.order_id
	AND r.distance>0
	WHERE r.pickup_time IS NOT NULL
	AND c.order_time IS NOT NULL
	GROUP BY r.order_id,r.pickup_time,c.order_time
)

SELECT 
	pizza_count,
	ROUND(AVG(preparation_time_in_minutes)) AVG_prep_time_minutes
	FROM order_preparation_time_cte
	GROUP BY pizza_count
	ORDER BY pizza_count;

-- TO make 1 pizza=12min,3 pizza=18min,3pizza=29 min time


-- 4 What was the average distance travelled for each customer?
-- CUSTOMER AND DISTANCE
SELECT 
c.customer_id,
ROUND(AVG(r.distance)) AS average_distance
FROM customer_orders_clean c
JOIN runner_orders_clean r
ON c.order_id=r.order_id
AND r.duration>0
GROUP BY c.customer_id
ORDER BY c.customer_id;
--Customer 104 stays the nearest to Pizza Runner HQ at average distance of 10km, whereas Customer 105 stays the furthest at 25km.


-- 5 What was the difference between the longest and shortest delivery times for all orders?

SELECT MAX(duration),MIN(duration),(MAX(duration)-MIN(duration)) delivery_time_difference
FROM runner_orders_clean
WHERE duration IS NOT NULL;

--Diff in largest and shortest delivry time is 30 mins


-- 6 What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT 
  r.runner_id, 
  c.customer_id, 
  c.order_id, 
  COUNT(c.order_id) AS pizza_count, 
  r.distance AS distance_in_km,
 (r.duration)AS duration_in_min , 
 ROUND((r.distance/r.duration*60)) AS avg_speed_km_per_hr
FROM runner_orders_clean r
JOIN customer_orders_clean AS c
  ON r.order_id = c.order_id
WHERE distance != 0
GROUP BY r.runner_id, c.customer_id, c.order_id, r.distance, r.duration
ORDER BY c.order_id;

--sol2:
SELECT 
  runner_id, 
  order_id, 
  ROUND(((distance::numeric(3, 1)) /(duration::numeric(3, 1)/60)),2) as speed_km_per_hour
FROM 
  runner_orders_clean
WHERE 
  duration IS NOT NULL
ORDER BY 
  runner_id, 
  order_id 

-- 7 What is the successful delivery percentage for each runner?
 SELECT
	runner_id,
	COUNT(*) As tot_deliveries,
	COUNT(
	CASE WHEN duration IS NOT NULL AND pickup_time IS NOT NULL THEN 1 END
	) AS successful_deliveries,
	ROUND(
		COUNT(
	CASE WHEN duration IS NOT NULL AND pickup_time IS NOT NULL THEN 1 END
	)::DECIMAL/COUNT(*)*100,2
	)AS success_percentage
	FROM runner_orders_clean
	GROUP BY runner_id
	ORDER BY success_percentage DESC;

/*Runner 1 has 100% successful delivery.
Runner 2 has 75% successful delivery.
Runner 3 has 50% successful delivery*/
