CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);


INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name  VARCHAR(5),
   price INTEGER
);
 -- create table menu( product_id integer, product_name varchar(5), price integer);
INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  
   --QUESTIONS 
   
  -- 1. What is the total amount each customer spent at the restaurant?
  
  SELECT 
    s.customer_id,
    SUM(m.price) AS total_spent
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY s.customer_id;

-- 2. How many days has each customer visited the restaurant?

 SELECT 
 customer_id,
 COUNT(Distinct order_date) AS visit_days
 FROM sales
 GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?

WITH orders_rank As
(
SELECT customer_id,
	order_date,
	product_id,
	DENSE_RANK()OVER(PARTITION BY customer_id ORDER BY order_date ASC ) AS orders_rank
	FROM sales
)
SELECT 
o.customer_id,
m.product_name
FROM orders_rank o JOIN menu m
ON o.product_id=m.product_id
WHERE o.orders_rank=1
ORDER BY o.customer_id;

--CAN USE DENSE_RANK/ROW_NUMBER SINCE THERE IS NO TIMESTAMP IS GIVEN


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT m.product_name,
COUNT(m.product_name) AS most_count
FROM sales s JOIN menu m
ON s.product_id=m.product_id
GROUP BY m.product_name 
ORDER BY most_count DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?

WITH Fev_item AS
(
SELECT
	s.customer_id,
	m.product_name,
	COUNT(m.product_id) AS order_count,
	DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.customer_id)DESC) AS rnk
	FROM menu AS m
	JOIN sales As s
	ON m.product_id=s.product_id
	GROUP BY 1,2
	
)
 SELECT customer_id,product_name,order_count
 FROM fev_item
 WHERE rnk=1;
-- 6. Which item was purchased first by the customer after they became a member?


WITH member_cte AS
(
SELECT 
	s.customer_id,mb.join_date,s.order_date,s.product_id,
	DENSE_RANK() OVER(PARTITION BY s.customer_id
					 ORDER BY s.order_date) AS rnk
	FROM sales s
	JOIN members mb
	ON s.customer_id=mb.customer_id
	WHERE s.order_date>=mb.join_date
				
)

SELECT c.customer_id,c.order_date,m.product_name
FROM member_cte c
JOIN menu m
ON c.product_id=m.product_id
WHERE rnk=1
ORDER BY c.customer_id;


-- 7. Which item was purchased just before the customer became a member?
WITH before_member_cte AS
(
SELECT 
	s.customer_id,mb.join_date,s.order_date,s.product_id,
	DENSE_RANK() OVER(PARTITION BY s.customer_id
					 ORDER BY s.order_date DESC) AS rnk
	FROM sales s
	JOIN members mb
	ON s.customer_id=mb.customer_id
	WHERE s.order_date<mb.join_date
				
)

SELECT bc.customer_id,bc.order_date,m.product_name
FROM before_member_cte bc
JOIN menu m
ON bc.product_id=m.product_id
WHERE rnk=1
ORDER BY bc.customer_id;
-- 8. What is the total items and amount spent for each member before they became a member?

SELECT s.customer_id,
COUNT(DISTINCT s.product_id) AS unique_menu,
SUM(m.price) AS total_sales
FROM sales AS s
JOIN members AS mb
 ON s.customer_id = mb.customer_id
JOIN menu AS m
 ON s.product_id = m.product_id
WHERE s.order_date < mb.join_date
GROUP BY s.customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - 
-- how many points would each customer have?

WITH cte
AS
(
SELECT 
product_id,product_name,price,
CASE 
WHEN product_name='sushi' THEN price*20
ELSE price*10 
END AS points
FROM menu
	)
	
	SELECT
	s.customer_id,
	SUM(c.points) AS totalPoints
	FROM cte c
	JOIN sales s
	ON c.product_id=s.product_id
	GROUP BY s.customer_id
	ORDER BY s.customer_id;
s

-- 10. In the first week after a customer joins the program (including their join date)
-- they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH date_cte
AS
(
SELECT
	customer_id,
	join_date,
	join_date + INTERVAL '6 DAYS' AS first_week,
	(DATE_TRUNC('MONTH','2021-01-31'::DATE)+ INTERVAL '1 MONTH'-INTERVAL '1 DAY') AS last_day
	FROM members
)
SELECT s.customer_id,
SUM(
	CASE WHEN m.product_name='sushi' THEN 2*10*m.price
   WHEN s.order_date BETWEEN dc.join_date AND dc.first_week THEN 2*10*m.price
   ELSE 10*m.price
	END) AS points
FROM sales s
JOIN date_cte dc
ON s.customer_id=dc.customer_id
JOIN menu m
ON s.product_id=m.product_id
 WHERE
 dc.join_date<=s.order_date
AND s.order_date<=dc.last_day
GROUP BY s.customer_id
ORDER BY s.customer_id;
 
 
 --BOnus questions
 --JOIN ALL THINGS
 -- Recreate the table with: customer_id, order_date, product_name, price, member (Y/N)
 
 SELECT 
s.customer_id,
s.order_date,
m.product_name,
m.price,
CASE
WHEN mb.join_date>s.order_date THEN 'N'
	WHEN mb.join_date<=s.order_date THEN 'Y'
	ELSE 'N'
	END
AS member
FROM sales s
LEFT JOIN menu m
ON s.product_id=m.product_id
LEFT JOIN members mb
ON s.customer_id=mb.customer_id;



--Rank All The Things

WITH cust_cte AS
(

 SELECT 
s.customer_id,
s.order_date,
m.product_name,
m.price,
CASE
WHEN mb.join_date>s.order_date THEN 'N'
	WHEN mb.join_date<=s.order_date THEN 'Y'
	ELSE 'N'
	END
AS member
FROM sales s
LEFT JOIN menu m
ON s.product_id=m.product_id
LEFT JOIN members mb
ON s.customer_id=mb.customer_id

)

SELECT customer_id,order_date,product_name,price,member,
CASE
WHEN member='N' THEN NULL
ELSE RANK() OVER(PARTITION BY customer_id,member ORDER BY order_date) 
END AS ranking
FROM cust_cte;

