--D. Pricing and Ratings
-- 1 If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes 
-- how much money has Pizza Runner made so far if there are no delivery fees?

WITH pizza_prices AS
(
SELECT 'Meatlovers' AS pizza_name, 12 AS price
	UNION ALL
	SELECT 'vegetarian',10
)

SELECT SUM(p.price) AS total
FROM customer_orders_clean c
JOIN pizza_names pn
ON c.pizza_id=pn.pizza_id
JOIN pizza_prices p
ON pn.pizza_name=p.pizza_name
WHERE
	c.order_id NOT IN(
					SELECT r.order_id 
		FROM runner_orders_clean r
		WHERE r.cancellation IS NOT NULL
		);
-- 2 What if there was an additional $1 charge for any pizza extras?
--Add cheese is $1 extra

WITH pizza_prices AS
(
SELECT 'Meatlovers' AS pizza_name, 12 AS price
	UNION ALL
	SELECT 'vegetarian',10
),

extra_cost_cte AS
(
SELECT c.order_id,
	c.pizza_id,
	COALESCE(extra_count.extra_cost,0) AS extra_cost
	FROM customer_orders_clean c
	LEFT JOIN LATERAL
	(
	--split the extras and count num of extras
		SELECT COUNT(*) AS extra_cost
	 FROM UNNEST(STRING_TO_ARRAY(c.extras,',')) AS extra
		WHERE c.extras IS NOT NULL AND c.extras <>''
	) AS extra_count 
	ON TRUE
)

SELECT SUM(p.price+ec.extra_cost) AS total
FROM customer_orders_clean c
JOIN pizza_names pn
ON c.pizza_id=pn.pizza_id
JOIN pizza_prices p
ON pn.pizza_name=p.pizza_name
JOIN extra_cost_cte ec
ON c.order_id=ec.order_id
WHERE
	c.order_id NOT IN(
					SELECT r.order_id 
		FROM runner_orders_clean r
		WHERE r.cancellation IS NOT NULL
		);

-- 3 The Pizza Runner team now wants to add an additional ratings system 
--that allows customers to rate their runner, how would you design 
--an additional table for this new dataset
-- generate a schema for this new table and 
--insert your own data for ratings for each successful customer order between 1 to 5.


CREATE TABLE runner_ratings (
    rating_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL,
    runner_id INTEGER NOT NULL CHECK(runner_id  BETWEEN 1 AND 4),
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    rating_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


INSERT INTO runner_ratings (order_id, runner_id, rating, comment)
VALUES
    (1, 1, 5, 'The runner was very prompt and friendly!'),
    (2, 1, 4, 'Great service, but a bit delayed.'),
    (3, 2, 5, 'Perfect delivery, thank you!'),
    (4, 2, 3, 'The delivery was okay, but the runner was not very polite.'),
    (5, 3, 4, 'Good service overall, will order again.'),
    (6, 3, 5, 'Outstanding delivery experience!'),
    (7, 2, 4, 'The runner was quick but forgot my drink.'),
    (8, 2, 5, 'Excellent, very satisfied with the service.'),
    (9, 1, 3, 'It was fine, but nothing special.'),
    (10, 1, 4, 'The runner was nice and on time, thanks!');
	
	
	SELECT * FROM runner_ratings;

-- 4 Using your newly generated table - can you join all of the information together to form a table 
--which has the following information for successful deliveries?
--customer_id
--order_id
--runner_id
--rating
--order_time
--pickup_time
--Time between order and pickup
--Delivery duration
--Average speed
--Total number of pizzas

WITH delivery_info_cte AS
(
SELECT c.customer_id,
c.order_id,
r.runner_id,
rr.rating,
c.order_time,
r.pickup_time,
-- Calculate time between order and pickup
ROUND(EXTRACT(EPOCH FROM(r.pickup_time-c.order_time))/60,2)||' min' AS time_between_order_and_pickup,
r.duration||' min' AS delivery_duration_in_minutes,
-- Calculate average speed assuming distance is in km
       
CASE WHEN r.distance IS NOT NULL AND r.distance>0 THEN
	ROUND((r.distance::FLOAT/r.duration*60))||'km/hr'
END AS average_speed,
COUNT(c.pizza_id) AS total_pizzas

 FROM 
        customer_orders_clean c
    JOIN 
        runner_orders_clean  r ON c.order_id = r.order_id
    LEFT JOIN 
        runner_ratings rr ON c.order_id = rr.order_id
    WHERE 
        r.cancellation IS NULL  -- Make sure the order is successful
    GROUP BY 
        c.customer_id, c.order_id, r.runner_id, rr.rating, 
		c.order_time, r.pickup_time, r.duration, r.distance
)

SELECT *
FROM delivery_info_cte
ORDER BY order_id;  -- Order by order_id for better readability



-- 5 If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled 
-- how much money does Pizza Runner have left over after these deliveries?
WITH pizza_sales AS (
  SELECT 
    c.pizza_id,
    p.pizza_name,
    COUNT(*) AS pizza_count,
    CASE
      WHEN p.pizza_name = 'Meatlovers' THEN COUNT(*) * 12
      WHEN p.pizza_name = 'Vegetarian' THEN COUNT(*) * 10
    END AS total_revenue
  FROM customer_orders_clean c
  JOIN pizza_names p ON c.pizza_id = p.pizza_id
  GROUP BY c.pizza_id, p.pizza_name
),
runner_costs AS (
  SELECT 
    order_id,
    runner_id,
    COALESCE( distance_in_km, 0)::NUMERIC AS distance_km
  FROM runner_orders_clean
  WHERE cancellation IS NULL  -- Only include non-canceled orders
)

SELECT 
  (SELECT SUM(total_revenue) FROM pizza_sales) --revenue calculation
  - 
  (SELECT SUM(distance_km) * 0.30 FROM runner_costs)--runner cost calculation
  AS profit_left_over;





--E. Bonus Questions
--If Danny wants to expand his range of pizzas - how would this impact the existing data design?
--Write an INSERT statement to demonstrate what would happen if a new Supreme pizza 
--with all the toppings was added to the Pizza Runner menu?

-- Insert into pizza_names
INSERT INTO pizza_names (pizza_id, pizza_name)
VALUES (3, 'Supreme');

-- Insert into pizza_recipes with all toppings
INSERT INTO pizza_recipes (pizza_id, toppings)
VALUES (3, '1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12');

SELECT * FROM pizza_names;
SELECT * FROM pizza_recipes;
