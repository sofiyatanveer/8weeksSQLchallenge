/*
A. Customer Journey
Based off the 8 sample customers provided in the sample from the subscriptions table, write a brief description about each customer’s onboarding journey.

Try to keep it as short as possible - you may also want to run some sort of join to make your explanations a bit easier!
*/
SELECT 
s.customer_id, 
p.plan_name,
p.price,
s.start_date
FROM subscriptions s
JOIN plans p
ON s.plan_id = p.plan_id
WHERE s.customer_id IN (1,2,11,13,15,16,18,19)
ORDER BY s.customer_id, s.start_date;

/*
Based on this query, here are brief descriptions of each customer's onboarding journey:

Customer 1:
Journey: Started with a trial on August 1, 2020, and upgraded to the Basic Monthly plan on August 8, 2020.
Customer 2:
Journey: Began with a trial on September 20, 2020, and quickly switched to the Pro Annual plan on September 27, 2020.
Customer 3:
Journey: Initiated with a trial on January 13, 2020, and moved to Basic Monthly a week later, on January 20, 2020.
Customer 4:
Journey: Started a trial on January 17, 2020, upgraded to Basic Monthly on January 24, 2020, but churned on April 21, 2020.
Customer 5:
Journey: Began with a trial on August 3, 2020, and switched to the Basic Monthly plan a week later, on August 10, 2020.
Customer 6:
Journey: Started a trial on December 23, 2020, upgraded to Basic Monthly on December 30, 2020, and churned on February 26, 2021.
Customer 7:
Journey: Began with a trial on February 5, 2020, quickly moved to Basic Monthly on February 12, 2020, and later upgraded to Pro Monthly on May 22, 2020.
Customer 8:
Journey: Started a trial on June 11, 2020, moved to Basic Monthly on June 18, 2020, and upgraded to Pro Monthly on August 3, 2020.
*/