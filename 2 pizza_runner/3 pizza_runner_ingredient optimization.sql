--C. Ingredient Optimisation

-- 1 What are the standard ingredients for each pizza?
SELECT 
pn.pizza_name,
pt.topping_name
FROM 
pizza_names pn JOIN pizza_recepies_clean pr
ON pn.pizza_id=pr.pizza_id
JOIN pizza_toppings pt
ON pr.topping_id=pt.topping_id
ORDER BY pn.pizza_name,pt.topping_name;

-- 2 What was the most commonly added extra?

WITH extras_cte AS (
    SELECT 
        UNNEST(STRING_TO_ARRAY(extras, ','))::INTEGER AS extras_id
    FROM customer_orders
	WHERE extras IS NOT NULL 
    AND extras != '' 
    AND extras != 'null'  -- Exclude any 'null' strings
  
)
SELECT 
   e.extras_id,
    pt.topping_name AS extras_name,
    COUNT(e.extras_id) AS extras_count
FROM extras_cte e
JOIN pizza_toppings pt 
ON e.extras_id = pt.topping_id
GROUP BY e.extras_id,pt.topping_name
ORDER BY extras_count DESC
--LIMIT 1;

--most common added extra is bacon which count =4

--MOST commonly added extra was bacon count=4

-- 3 What was the most common exclusion?

WITH exclusion_cte AS (
    SELECT 
        UNNEST(STRING_TO_ARRAY(exclusions, ','))::INTEGER AS exclusion_id
    FROM customer_orders
	WHERE exclusions IS NOT NULL 
    AND exclusions != '' 
    AND exclusions != 'null'  -- Exclude any 'null' strings
  
)
SELECT 
   e.exclusion_id,
    pt.topping_name AS exclusion_name,
    COUNT(e.exclusion_id) AS exclusion_count
FROM exclusion_cte e
JOIN pizza_toppings pt 
ON e.exclusion_id = pt.topping_id
GROUP BY e.exclusion_id,pt.topping_name
ORDER BY exclusion_count DESC
--LIMIT 1;

--most common exclusion is chees.

-- 4 Generate an order item for each record in the customers_orders table 
--in the format of one of the following:
--Meat Lovers
--Meat Lovers - Exclude Beef
--Meat Lovers - Extra Bacon
--Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

WITH exclusions_cte AS
(
  SELECT 
	c.order_id,
	c.pizza_id,
	pt.topping_id,
	pt.topping_name
	FROM customer_orders_clean c
	JOIN pizza_toppings pt 
	ON topping_id=ANY(STRING_TO_ARRAY(c.exclusions,',')::INT[])
	
),
extras_cte AS
(
	 SELECT 
	c.order_id,
	c.pizza_id,
	pt.topping_id,
	pt.topping_name
	FROM customer_orders_clean c
	JOIN pizza_toppings pt 
	ON topping_id=ANY(STRING_TO_ARRAY(c.extras,',')::INT[])
	
	
),
orders_cte AS (
  
	SELECT 
	DISTINCT c.order_id,
	c.pizza_id,
	pr.topping_id
	FROM customer_orders_clean c
	INNER JOIN pizza_recepies_clean pr
	ON c.pizza_id=pr.pizza_id
	
),

orders_with_extras_and_exclusions_cte AS
(
	SELECT o.order_id,o.pizza_id,
	CASE WHEN o.pizza_id=1 THEN 'Meat Lovers'
	     WHEN o.pizza_id=2 THEN pn.pizza_name
	END AS pizza_names,
	STRING_AGG(DISTINCT ext.topping_name,',') AS extras,
	STRING_AGG(DISTINCT excl.topping_name,',') AS exclusions
	FROM orders_cte o
	LEFT JOIN extras_cte ext 
	ON ext.order_id=o.order_id AND ext.pizza_id=o.pizza_id
	LEFT JOIN exclusions_cte excl 
	ON excl.order_id=o.order_id AND excl.pizza_id=o.pizza_id AND excl.topping_id=o.topping_id
     INNER JOIN pizza_names pn 
	 ON o.pizza_id=pn.pizza_id
	GROUP BY o.order_id,o.pizza_id,pizza_names
	
)
SELECT 
	order_id,
	pizza_id,
	CONCAT(pizza_names,
		  CASE WHEN exclusions='' THEN '' ELSE '-Exclude'|| exclusions END,
		  CASE WHEN extras='' THEN '' ELSE '-Extras'||extras END) AS order_item
		  FROM orders_with_extras_and_exclusions_cte
		  ORDER BY order_id;

-- 5 Generate an alphabetically ordered comma separated ingredient list 
--for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
--For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"


WITH exclusions_cte AS
(
  SELECT 
	c.order_id,
	c.pizza_id,
	pt.topping_id,
	pt.topping_name
	FROM customer_orders_clean c
	JOIN pizza_toppings pt 
	ON topping_id=ANY(STRING_TO_ARRAY(c.exclusions,',')::INT[])
),

extras_cte AS
(
	 SELECT 
	c.order_id,
	c.pizza_id,
	pt.topping_id,
	pt.topping_name
	FROM customer_orders_clean c
	JOIN pizza_toppings pt 
	ON topping_id=ANY(STRING_TO_ARRAY(c.extras,',')::INT[])	
),

orders_cte AS (
    SELECT 
	DISTINCT c.order_id,
	c.pizza_id,
	pr.topping_id,
	pt.topping_name
	FROM customer_orders_clean c
	INNER JOIN pizza_recepies_clean pr
	ON c.pizza_id=pr.pizza_id
    LEFT JOIN pizza_toppings pt 
	ON pr.topping_id=pt.topping_id
	
),

orders_with_extras_and_exclusions_cte AS
(
    SELECT 
    O.order_id,
    O.pizza_id,
    O.topping_id,
    o.topping_name
    FROM orders_cte AS O
    LEFT JOIN exclusions_cte AS excl
	ON excl.order_id=o.order_id
	AND excl.pizza_id=o.pizza_id
	AND excl.topping_id=o.topping_id
	WHERE excl.topping_id IS NULL
 
    UNION ALL 

    SELECT 
    ext.order_id,
   ext.pizza_id,
   ext.topping_id,
    ext.topping_name
    FROM extras_cte ext
    WHERE ext.topping_id IS NOT NULL
),

count_topping_cte AS
(
SELECT o.order_id,
	o.pizza_id,
	o.topping_name,
	count(*) AS n
	FROM orders_with_extras_and_exclusions_cte AS o
	GROUP BY o.order_id,o.pizza_id,o.topping_name
)

SELECT
	order_id,
	pizza_id,
	STRING_AGG(
				CASE WHEN n>1 THEN n ||'x'||topping_name
				ELSE topping_name
				END,' , ') AS ingredient
				FROM count_topping_cte
				GROUP BY order_id,pizza_id;

-- 6 What is the total quantity of each ingredient used in all delivered pizza
--sorted by most frequent first?
WITH exclusions_cte AS
(
  SELECT 
	c.order_id,
	c.pizza_id,
	pt.topping_id,
	pt.topping_name
	FROM customer_orders_clean c
	JOIN pizza_toppings pt 
	ON topping_id=ANY(STRING_TO_ARRAY(c.exclusions,',')::INT[])
),

extras_cte AS
(
	 SELECT 
	c.order_id,
	c.pizza_id,
	pt.topping_id,
	pt.topping_name
	FROM customer_orders_clean c
	JOIN pizza_toppings pt 
	ON topping_id=ANY(STRING_TO_ARRAY(c.extras,',')::INT[])	
),

orders_cte AS (
    SELECT 
	DISTINCT c.order_id,
	c.pizza_id,
	pr.topping_id,
	pt.topping_name
	FROM customer_orders_clean c
	INNER JOIN pizza_recepies_clean pr
	ON c.pizza_id=pr.pizza_id
    LEFT JOIN pizza_toppings pt 
	ON pr.topping_id=pt.topping_id
	
),

orders_with_extras_and_exclusions_cte AS
(
    SELECT 
    O.order_id,
    O.pizza_id,
    O.topping_id,
    o.topping_name
    FROM orders_cte AS O
    LEFT JOIN exclusions_cte AS excl
	ON excl.order_id=o.order_id
	AND excl.pizza_id=o.pizza_id
	AND excl.topping_id=o.topping_id
	WHERE excl.topping_id IS NULL
 
    UNION ALL 

    SELECT 
    ext.order_id,
   ext.pizza_id,
   ext.topping_id,
    ext.topping_name
    FROM extras_cte ext
    WHERE ext.topping_id IS NOT NULL
)
					   
SELECT 
		 oc.topping_name,
			   COUNT(oc.pizza_id) AS ingredient_count
			   FROM orders_with_extras_and_exclusions_cte AS oc
			   INNER JOIN runner_orders_clean AS r
			   ON oc.order_id=r.order_id
			   WHERE pickup_time IS NOT NULL
			   GROUP BY oc.topping_name
			   ORDER BY COUNT(oc.pizza_id) DESC;
			   
