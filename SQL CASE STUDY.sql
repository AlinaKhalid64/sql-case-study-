-- Case Study Questions


-- 1. How many customers has Foodie-Fi ever had?

SELECT
COUNT(DISTINCT customer_id) AS num_customers
FROM subscriptions;

-- 2. What is the monthly distribution of trial plan start_date values for our dataset — use the start of the month as the GROUP BY value
SELECT MONTH(start_date) AS Months, COUNT(customer_id) AS Num_Customers
FROM subscriptions GROUP BY Months;

-- 3. What plan ‘start_date’ values occur after the year 2020 for our dataset? Show the breakdown by count of events for each ‘plan_name’.
SELECT p.plan_name, p.plan_id , COUNT(*) AS Count_Event
FROM subscriptions s
JOIN plans p ON p.plan_id = s.plan_id
WHERE s.start_date >= '2021-01-01'
GROUP BY p.plan_name, p.plan_id
ORDER BY p.plan_id;

--  4. What is the customer count and percentage of customers who have churned the rounded to 1 decimal place?
SELECT COUNT(*) AS Customer_Churn, ROUND(COUNT(*) * 100/ (SELECT COUNT(DISTINCT customer_id)FROM subscriptions),1) AS Perc_Churn
FROM subscriptions
WHERE plan_id = 4;

--  5. How many the customers have churned straight after their initial free trial — what the percentage is this rounded to the nearest whole number?
WITH cte_churn AS (
SELECT *,
	   LAG(plan_id, 1) OVER(PARTITION BY customer_id ORDER BY plan_id) AS previous_plan
FROM subscriptions
)
SELECT COUNT(previous_plan) AS churn_count, 
	   ROUND(COUNT(*) * 100 / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions), 0) AS percentage_churn
FROM cte_churn
WHERE plan_id = 4 and previous_plan = 0;

-- 6. What is the number and percentage of customer plans after their initial free trial? 
WITH cte_next_plan AS ( 
SELECT *, 
    LEAD (plan_id, 1) OVER(PARTITION BY customer_id ORDER BY plan_id ) AS Next_Plan
  FROM subscriptions)
SELECT 
    Next_Plan, COUNT(*) AS Num_Customer, ROUND(COUNT(*) * 100/(SELECT COUNT(DISTINCT customer_id)
    FROM subscriptions),1) 
       AS Perc_Next_Plan
FROM cte_next_plan
WHERE  Next_Plan IS NOT NULL AND plan_id = 0
GROUP BY  Next_Plan
ORDER BY  Next_Plan;


-- 7. What is the customer count and percentage breakdown of all 5 plan_name values at 2020–12–31?

WITH cte_next_date AS (
  SELECT *,
      LEAD(start_date , 1) OVER(PARTITION BY customer_id ORDER BY start_date) AS Next_Date
  FROM subscriptions
  WHERE start_date <= '2020-12-31'), 
Plans_Breakdown AS (
SELECT 
    plan_id, COUNT(DISTINCT customer_id) AS num_customer
FROM cte_next_date
WHERE (next_date IS NOT NULL AND (start_date < '2021-12-31' AND next_date > '2020-12-31'))
      OR (next_date IS NULL AND start_date < '2020-12-31')
GROUP BY plan_id)
SELECT 
    plan_id,
    num_customer,
    ROUND(num_customer * 100/(SELECT COUNT(DISTINCT customer_id) FROM subscriptions),1) AS Perc_Customer
FROM Plans_Breakdown
GROUP BY  plan_id, num_customer
ORDER BY  plan_id;

-- 8. How many customers have upgraded to an annual in 2020?
SELECT 
COUNT(customer_id) AS num_customer
FROM SUBSCRIPTIONS
WHERE plan_id = 3 AND start_date <= '2020-12-31';

-- 9. How many days on average does it take for a customer to an annual plan from the day they joined Foodie-Fi?
 with annual_plan as( 
 select customer_id, start_date as annual_date 
 from subscriptions where plan_id = 3),
 trial_plan as (
 select customer_id, start_date as trial_date
 from subscriptions where plan_id = 0)
 select round(avg(datediff(annual_date, trail_date)),0) as avg_upgrade
 from annual_plan ap
 join trial_plan tp on ap.customer_id = tp.customer_id;


-- 10. Can you further breakdown this average value into 30 day periods? (i.e. 0–30 days, 31–60 days etc)
with annual_plan as( 
 select customer_id, start_date as annual_date 
 from subscriptions where plan_id = 3),
 trial_plan as (
 select customer_id, start_date as trial_date
 from subscriptions where plan_id = 0), day_period as (
 select datediff(annual_date, trial_date) as diff
 from trial_plan tp
 left join annual_plan ap on tp.customer_id = ap.customer_id
 where annual_date is not null),
 bins as ( select *, floor(diff/30) as bins
 from day_period)
 select 
 concat((bins * 30) + 1, '-', (bins + 1) * 30, 'days') as days,
 count(diff) as total
 from bins
 group by bins;
 
 -- 11. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
WITH next_plan AS (
   SELECT *, 
      LEAD(plan_id,1) OVER(PARTITION BY customer_id 
      ORDER BY start_date, plan_id) AS Plan
   FROM subscriptions)
SELECT 
   COUNT(DISTINCT customer_id) AS Num_Downgrade
FROM next_plan np
LEFT JOIN plans p
ON p.plan_id = np.plan_id
WHERE p.plan_name = 'Pro Monthly' AND np.plan = 1 AND start_date <= '2020-12-31';
