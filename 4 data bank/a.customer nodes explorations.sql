--A. Customer Nodes Exploration
-- 1 How many unique nodes are there on the Data Bank system?
SELECT COUNT(DISTINCT node_id) AS unique_nodes
 FROM customer_nodes;
-- 2 What is the number of nodes per region?
 SELECT r.region_name,COUNT(DISTINCT cn.node_id) 
 FROM customer_nodes cn JOIN regions r
 USING(region_id)
 GROUP BY r.region_name
 ORDER BY r.region_name;
 
-- 3 How many customers are allocated to each region?
 SELECT r.region_name,COUNT(DISTINCT cn.node_id) 
 FROM customer_nodes cn JOIN regions r
 USING(region_id)
 GROUP BY r.region_name
 ORDER BY r.region_name;
 
-- 4 How many days on average are customers reallocated to a different node?
WITH days_in_node_cte AS (
    SELECT 
    customer_id,
    node_id,
    SUM(end_date-start_date) as days_in_node
    FROM customer_nodes
    WHERE end_date <> '9999-12-31'
    GROUP BY customer_id,
    node_id
)
SELECT 
ROUND(AVG(days_in_node),0) as average_reallocation_days_in_node
FROM days_in_node_cte;

-- 5 What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

WITH reallocation_days_cte AS
(
SELECT 
	cn.region_id,
	r.region_name,
	cn.customer_id,
	cn.node_id,
	SUM(cn.end_date-cn.start_date) AS reallocation_days
	FROM customer_nodes cn
	JOIN regions r
	USING(region_id)
	 WHERE end_date <> '9999-12-31'
    GROUP BY 
	cn.region_id,r.region_name,
    cn.customer_id,
    cn.node_id
	
)
SELECT 
region_name,
ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY reallocation_days)) AS median_days,
ROUND(PERCENTILE_CONT(0.8) WITHIN GROUP (ORDER BY reallocation_days)) AS percentile_80_days,
ROUND(PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY reallocation_days)) AS percentile_95_days
FROM 
reallocation_days_cte
GROUP BY region_name
ORDER BY region_name;

