-- SQL Retail Sales Analysis 

-- Create table 
DROP TABLE IF EXISTS retail_sales;
CREATE TABLe retail_sales(
	transactions_id INT PRIMARY KEY,
	sale_date DATE,
	sale_time TIME,
	customer_id INT,
	gender VARCHAR(15),
	age INT,
	category VARCHAR(15),
	quantity INT,
	price_per_unit FLOAT,
	cogs FLOAT,
	total_sale FLOAT);

SELECT * FROM retail_sales;


-- Total number of Records
SELECT COUNT(*)
FROM retail_sales;

-- Checking NULL values within the data
SELECT * FROM retail_sales
WHERE transactions_id IS NULL
	OR sale_date IS NULL
	OR sale_time IS NULL
	OR customer_id IS NULL
	OR gender IS NULL
	OR age IS NULL
	OR category IS NULL
	OR quantity IS NULL
	OR price_per_unit IS NULL
	OR cogs IS NULL
	OR total_sale IS NULL
;

-- Dropping null values from our Data # Data cleaning
DELETE FROM retail_sales
WHERE transactions_id IS NULL
	OR sale_date IS NULL
	OR sale_time IS NULL
	OR customer_id IS NULL
	OR gender IS NULL
	OR age IS NULL
	OR category IS NULL
	OR quantity IS NULL
	OR price_per_unit IS NULL
	OR cogs IS NULL
	OR total_sale IS NULL
;

-- Data exploration
-- How many Records do we have?
SELECT count(*) AS total_sale
FROM retail_sales;  -- 1987 records 

-- Number of Unique Customer 
SELECT COUNT(DISTINCT customer_id) AS total_sale FROM retail_sales;
-- 155 Customer

-- How many unique cotegory we have in the dataset
SELECT DISTINCT category AS un_category
FROM retail_sales;

-- Total sale by category
SELECT category, sum(total_sale) AS Total_sales
FROM retail_sales
GROUP BY 1;

-- Checking data quality
SELECT transactions_id,
       total_sale,
       quantity * price_per_unit AS sale_check
FROM retail_sales
WHERE ABS(total_sale - quantity * price_per_unit) >= 0.01;


-- **Data Analysis or Bussiness Questions**
-- 1 Write a SQL query to retrieve all columns for sales made on '2022-11-05
SELECT *
FROM retail_sales
WHERE sale_date = '2022-11-05';

-- 2 **Write a SQL query to retrieve all transactions where the category is 'Clothing'
-- and the quantity sold is more than 4 in the month of Nov-2022**:
SELECT * 
FROM retail_sales
WHERE category = 'Clothing'
	AND TO_CHAR(sale_date, 'MM-YYYY') = '11-2022'
	AND quantity >=4;

-- 3. **Write a SQL query to calculate the total sales (total_sale) for each category.**:
SELECT category,
	sum(total_sale) AS Net_sales, 
	COUNT(*) AS Total_orders
FROM retail_sales
GROUP BY 1
ORDER BY sum(total_sale) desc;

-- 4. Write a SQL query to find the average age of customers who purchased items from the 'Beauty' category

SELECT 
	ROUND(AVG(age),2) as  Avg_age
	 -- ROUND(AVG(age), 2) as avg_age
FROM retail_sales
WHERE category = 'Beauty';

-- 5. **Write a SQL query to find all transactions where the total_sale is greater than 1000.**:
SELECT *
FROM retail_sales
WHERE total_sale>1000;

-- 6. **Write a SQL query to find the total number of transactions (transaction_id)
-- made by each gender in each category.**
SELECT  category,gender, COUNT(transactions_id) AS n_transactions
FROM retail_sales
GROUP BY category, gender
ORDER BY category,COUNT(transactions_id) DESC ;

-- 7. **Write a SQL query to calculate the average sale for each month. Find out best selling month in each year**:

-- Using CTEs or subqueries

WITH T1 AS(
	SELECT 
	EXTRACT(YEAR FROM sale_date) AS year,
	EXTRACT(MONTH FROM sale_date) as month,
	AVG(total_sale) AS avg_sale,
	RANK() OVER(PARTITION BY EXTRACT(YEAR FROM sale_date) ORDER BY AVG(total_sale) DESC) AS rank
FROM retail_sales
GROUP BY year, month)

SELECT year, month, avg_sale, rank
FROM T1
WHERE rank =1;

-- .8 **Write a SQL query to find the top 5 customers based on the highest total sales **:
SELECT customer_id,
	SUM(total_sale) as Total_sales
FROM retail_sales
GROUP BY 1
ORDER BY SUM(total_sale) DESC
LIMIT 5;


-- 9. **Write a SQL query to find the number of unique customers who purchased items from each category.**
SELECT  category,COUNT(DISTINCT customer_id) AS N_customers
FROM retail_sales
GROUP BY category;

-- 10. **Write a SQL query to create each shift and number of orders 
-- (Example Morning <12, Afternoon Between 12 & 17, Evening >17)**:
SELECT *
FROM retail_sales;


WITH hourly_sales AS(
	SELECT *,
	CASE WHEN EXTRACT(HOUR FROM sale_time) < 12 THEN 'Morning'
		WHEN EXTRACT(HOUR FROM sale_time) BETWEEN 12 AND 17 THEN 'Afternoon'
		ELSE 'Evening'
		END AS shift
FROM retail_sales
)

SELECT COUNT(*) AS Total_orders,
	shift
From hourly_sales
GROUP BY shift;
		
SELECT COUNT(*) AS Total_orders,
	shift
FROM (SELECT *,
	CASE WHEN EXTRACT(HOUR FROM sale_time) < 12 THEN 'Morning'
		WHEN EXTRACT(HOUR FROM sale_time) BETWEEN 12 AND 17 THEN 'Afternoon'
		ELSE 'Evening'
		END AS shift
FROM retail_sales)
GROUP BY shift;


-- MORE ADVANCED ANALYSIS
-- Profitability by category,
-- Focus Which category has the highest revenue, 
-- and which has the highest profit margin? 
-- Is the top earner also the most profitable?

SELECT
    category,
    ROUND(SUM(total_sale - cogs)) AS profit,
    ROUND(SUM(total_sale)) AS revenue,
    ROUND(
        SUM(total_sale - cogs) /
        NULLIF(SUM(total_sale), 0) * 100
    ) AS profit_margin
FROM retail_sales
GROUP BY category
ORDER BY profit DESC;

/*
Month-over-month revenue growth
Find total revenue for each month, the previous month’s revenue, 
and the percentage change.
Which months had the biggest jump and the biggest drop?
*/

WITH monthly_rev AS(
	SELECT 
		 EXTRACT(YEAR FROM sale_date) AS year,
		 EXTRACT(MONTH FROM sale_date) AS month,
		 ROUND(SUM(total_sale)) AS revenue
	FROM retail_sales
	GROUP BY EXTRACT(YEAR FROM sale_date),
			 EXTRACT(MONTH FROM sale_date)
),
monthly_comparison AS (
SELECT
		year,
		month,
		revenue,
		LAG(revenue) OVER(ORDER BY year, month) previous_month_rev
	FROM monthly_rev
),
monthly_growth AS (
SELECT
	year,
	month,
	revenue,
	previous_month_rev,
	ROUND(
		(revenue - previous_month_rev)/
		NULLIF(previous_month_rev ,0)* 100
	) AS monthly_growth_percentage
FROM monthly_comparison)
SELECT *
FROM monthly_growth
ORDER BY 1,2;

     /*   Month with the biggest jump and drop
			SELECT *
			FROM monthly_growth
			WHERE monthly_growth_percentage IS NOT NULL
			ORDER BY monthly_growth_percentage DESC -- ASC for drop
			LIMIT 1; */


/*
Age-group segmentation
Create age bands (for example under 25, 25-34, 35-49, 50+). 
For each band and category, show number of customers, 
total revenue, and average spend per transaction. 
Which band is most valuable?
*/

SELECT 
	 category,
	 -- customer_id,
	 CASE
	 	WHEN age < 25 THEN 'under 25'
		 WHEN age BETWEEN 25 AND 34 THEN '25-34'
		 WHEN age BETWEEN 35 AND 49 THEN '35-49' 
		 ELSE '50+'
	 END AS age_band,
	 COUNT(DISTINCT customer_id) n_customers,
	 SUM(total_sale) Total_revenue,
	 ROUND(AVG(total_sale):: numeric,2) avg_per_transaction
FROM retail_sales
GROUP BY category, age_band
;

   -- Most valuable age band
SELECT 
	CASE
	 	WHEN age < 25 THEN 'under 25'
		 WHEN age BETWEEN 25 AND 34 THEN '25-34'
		 WHEN age BETWEEN 35 AND 49 THEN '35-49' 
		 ELSE '50+'
	 END AS age_band,
	 SUM(total_sale) AS revenue
FROM retail_sales
GROUP BY age_band
ORDER BY revenue DESC
LIMIT 1

/*
Repeat vs. one-time customers
What percentage of customers bought more than once, and what share of total revenue do they generate?
*/

WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(*) AS total_orders,
        SUM(total_sale) AS total_revenue
    FROM retail_sales
    GROUP BY customer_id
),

repeat_customers AS (
    SELECT *
    FROM customer_orders
    WHERE total_orders > 1
)

SELECT
    -- Percentage of repeat customers
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM customer_orders)
    ) AS repeat_customer_percentage,

    -- Percentage of revenue from repeat customers
    ROUND(
        SUM(total_revenue) * 100.0 /
        (SELECT SUM(total_revenue) FROM customer_orders )
    ) AS repeat_revenue_percentage

FROM repeat_customers;

/*
Top 3 customers within each category
For each category, find the 3 highest-spending customers. 
This differs from your Q8 because the ranking restarts per category.
*/

WITH top3_customer AS (
    SELECT
        category,
        customer_id,
        SUM(total_sale) AS revenue
    FROM retail_sales
    GROUP BY category, customer_id
),

customer_ranking AS (
    SELECT
        category,
        customer_id,
        revenue,
        RANK() OVER (
            PARTITION BY category
            ORDER BY revenue DESC
        ) AS customer_rank
    FROM top3_customer
)

SELECT *
FROM customer_ranking
WHERE customer_rank <= 3
ORDER BY category, customer_rank;


/*
Cumulative revenue and 3-month moving average
Within each year, show cumulative revenue month by month, plus a 3-month moving average of monthly sales.
*/
WITH monthly_sale AS (
	SELECT 
		 EXTRACT(YEAR FROM sale_date) AS year,
		 EXTRACT(MONTH FROM sale_date) AS month,
		 SUM(total_sale) monthly_revenue
	FROM retail_sales
	GROUP BY 1,2
),
cum_monthly_revenue AS (
 SELECT year,
 		month,
		 monthly_revenue,
		 SUM(monthly_revenue) OVER(
	     PARTITION BY year
	     ORDER BY month
	 ) AS cumulative_revenue
	FROM monthly_sale 
),
month_moving_avg AS(
	SELECT *,
	ROUND(
	AVG(monthly_revenue) OVER(
		PARTITION BY year
		ORDER BY month
		ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
	)
	) AS moving_avg_3_month
FROM cum_monthly_revenue
)
SELECT *
FROM month_moving_avg
ORDER BY year,month;