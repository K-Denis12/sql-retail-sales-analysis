# Retail Sales Analysis SQL Project

## Project Overview

**Project Title**: Retail Sales Analysis
**Database**: `sql_project_1` (PostgreSQL)

This project uses SQL to set up, clean, explore and analyze a retail sales dataset of 2,000 transactions (January 2022 to December 2023). I started from a guided retail-sales tutorial that provided the dataset and the 10 core questions, then added my own data-quality audit and six extended analyses (profitability, growth, segmentation, loyalty, rankings and moving averages) to practise CTEs and window functions.

## Objectives

1. **Set up a retail sales database**: create the table and load the sales data.
2. **Data cleaning**: find and remove records with missing values, and validate that the numbers are consistent.
3. **Exploratory data analysis (EDA)**: understand the size and shape of the data.
4. **Business analysis**: answer 10 core business questions.
5. **Extended analysis**: answer 6 more questions of my own using CTEs and window functions.

## Dataset

| Column | Description |
|---|---|
| `transactions_id` | Unique transaction ID (primary key) |
| `sale_date`, `sale_time` | When the sale happened |
| `customer_id` | Customer identifier |
| `gender`, `age` | Customer attributes |
| `category` | Beauty, Clothing or Electronics |
| `quantity` | Units sold (1 to 4) |
| `price_per_unit` | Selling price of one unit |
| `cogs` | Cost of goods sold: the business's cost for the transaction |
| `total_sale` | Revenue = `quantity × price_per_unit` |

**Profit** = `total_sale − cogs`. **Profit margin** = profit ÷ revenue.
I treated `cogs` as the total cost of the whole transaction. If it were a per-unit cost, margins would be about 46% instead of 79%.

## Project Structure

### 1. Database Setup

```sql
CREATE DATABASE sql_project_1;

DROP TABLE IF EXISTS retail_sales;
CREATE TABLE retail_sales
(
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
    total_sale FLOAT
);
```

The CSV spells `quantity` as `quantiy`, so I mapped the columns by position when importing, and loaded blank cells as `NULL`.

### 2. Data Exploration & Cleaning

- **Record count**: how many rows are in the dataset.
- **Customer count**: how many unique customers.
- **Category count**: which product categories exist.
- **Null check**: find rows with missing values and delete them.
- **Consistency check**: confirm `total_sale = quantity × price_per_unit`.

```sql
SELECT COUNT(*) FROM retail_sales;
SELECT COUNT(DISTINCT customer_id) FROM retail_sales;
SELECT DISTINCT category FROM retail_sales;

SELECT * FROM retail_sales
WHERE transactions_id IS NULL OR sale_date IS NULL OR sale_time IS NULL
   OR customer_id IS NULL OR gender IS NULL OR age IS NULL
   OR category IS NULL OR quantity IS NULL OR price_per_unit IS NULL
   OR cogs IS NULL OR total_sale IS NULL;

DELETE FROM retail_sales
WHERE transactions_id IS NULL OR sale_date IS NULL OR sale_time IS NULL
   OR customer_id IS NULL OR gender IS NULL OR age IS NULL
   OR category IS NULL OR quantity IS NULL OR price_per_unit IS NULL
   OR cogs IS NULL OR total_sale IS NULL;

-- Data quality: rows where total_sale does not match quantity x price
SELECT transactions_id, total_sale, quantity * price_per_unit AS sale_check
FROM retail_sales
WHERE ABS(total_sale - quantity * price_per_unit) >= 0.01;
```

**Results**

| Check | Result |
|---|---:|
| Raw rows | 2,000 |
| Rows with a missing age | 10 |
| Rows missing quantity, price, `cogs` and `total_sale` | 3 |
| Rows deleted | 13 |
| **Rows after cleaning** | **1,987** |
| Unique customers | 155 |
| Categories | 3 (Beauty, Clothing, Electronics) |
| Duplicate transaction IDs | 0 |
| Rows where `total_sale ≠ quantity × price_per_unit` | 0 |

### 3. Data Analysis & Findings

#### Q1. Retrieve all columns for sales made on '2022-11-05'

```sql
SELECT *
FROM retail_sales
WHERE sale_date = '2022-11-05';
```

**Result:** 11 transactions totalling 6,830 in revenue.
**Analysis:** That is about 621 per transaction, well above the dataset average of about 457, so this was a high-value day.

#### Q2. Clothing transactions with quantity of 4 or more in November 2022

```sql
SELECT *
FROM retail_sales
WHERE category = 'Clothing'
  AND TO_CHAR(sale_date, 'MM-YYYY') = '11-2022'
  AND quantity >= 4;
```

**Result:** 17 of the 52 Clothing transactions that month.

#### Q3. Total sales and number of orders for each category

```sql
SELECT category,
       SUM(total_sale) AS net_sales,
       COUNT(*) AS total_orders
FROM retail_sales
GROUP BY 1
ORDER BY net_sales DESC;
```

| Category | Net sales | Orders |
|---|---:|---:|
| Electronics | 311,445 | 678 |
| Clothing | 309,995 | 698 |
| Beauty | 286,790 | 611 |

**Analysis:** Electronics earns the most revenue even though Clothing has the most orders. 

#### Q4. Average age of customers who bought from the 'Beauty' category

```sql
SELECT ROUND(AVG(age), 2) AS avg_age
FROM retail_sales
WHERE category = 'Beauty';
```

**Result:** 40.42 years.
**Analysis:** Beauty customers are middle-aged on average

#### Q5. Transactions where total_sale is greater than 1000

```sql
SELECT *
FROM retail_sales
WHERE total_sale > 1000;
```

**Result:** 306 transactions.

#### Q6. Number of transactions by each gender in each category

```sql
SELECT category, gender, COUNT(transactions_id) AS n_transactions
FROM retail_sales
GROUP BY category, gender
ORDER BY category, n_transactions DESC;
```

| Category | Female | Male |
|---|---:|---:|
| Beauty | 330 | 281 |
| Clothing | 347 | 351 |
| Electronics | 335 | 343 |

**Analysis:** Purchases are almost evenly split between genders. The only noticeable difference is Beauty, where women account for 54% of transactions.

#### Q7. Average sale for each month, and the best month in each year

```sql
WITH t1 AS (
    SELECT EXTRACT(YEAR FROM sale_date)  AS year,
           EXTRACT(MONTH FROM sale_date) AS month,
           AVG(total_sale) AS avg_sale,
           RANK() OVER (PARTITION BY EXTRACT(YEAR FROM sale_date)
                        ORDER BY AVG(total_sale) DESC) AS rank
    FROM retail_sales
    GROUP BY year, month
)
SELECT year, month, avg_sale, rank
FROM t1
WHERE rank = 1;
```

| Year | Best month by average sale | Best month by total revenue |
|---|---|---|
| 2022 | July (541.34) | December (71,880) |
| 2023 | February (535.53) | December (69,145) |

**Analysis:** "Best selling month" depends on the definition. Ranking by average sale picks quiet months where a few big baskets lift the average, while ranking by total revenue picks December both years. I report both so the answer is not misleading.

#### Q8. Top 5 customers based on total sales

```sql
SELECT customer_id, SUM(total_sale) AS total_sales
FROM retail_sales
GROUP BY 1
ORDER BY total_sales DESC
LIMIT 5;
```

| Customer | Total sales |
|---|---:|
| 3 | 38,440 |
| 1 | 30,750 |
| 5 | 30,405 |
| 2 | 25,295 |
| 4 | 23,580 |


#### Q9. Unique customers who purchased from each category

```sql
SELECT category, COUNT(DISTINCT customer_id) AS n_customers
FROM retail_sales
GROUP BY category;
```

| Category | Unique customers |
|---|---:|
| Clothing | 149 |
| Electronics | 144 |
| Beauty | 141 |

**Analysis:** out of 155 customers, 141 to 149 bought from each category, so most customers shop across all three instead of sticking to one.

#### Q10. Orders by shift (Morning < 12, Afternoon 12–17, Evening > 17)

```sql
WITH hourly_sales AS (
    SELECT *,
           CASE WHEN EXTRACT(HOUR FROM sale_time) < 12 THEN 'Morning'
                WHEN EXTRACT(HOUR FROM sale_time) BETWEEN 12 AND 17 THEN 'Afternoon'
                ELSE 'Evening'
           END AS shift
    FROM retail_sales
)
SELECT shift, COUNT(*) AS total_orders
FROM hourly_sales
GROUP BY shift;
```

| Shift | Orders | Share |
|---|---:|---:|
| Evening | 1,062 | 53.5% |
| Morning | 548 | 27.6% |
| Afternoon | 377 | 19.0% |

**Analysis:** the hour is extracted as a whole number, so Afternoon covers 12:00 to 17:59 and Evening starts at 18:00. More than half of all orders happen in the evening, and the afternoon is the quietest period.

### 4. Extended Analysis 

#### E1. Which category has the highest revenue, and which has the highest profit margin?

```sql
SELECT category,
       ROUND(SUM(total_sale - cogs)::NUMERIC)  AS profit,
       ROUND(SUM(total_sale)::NUMERIC)         AS revenue,
       ROUND((SUM(total_sale - cogs) / NULLIF(SUM(total_sale), 0) * 100)::NUMERIC, 2) AS profit_margin
FROM retail_sales
GROUP BY category
ORDER BY profit DESC;
```

| Category | Revenue | Profit | Margin |
|---|---:|---:|---:|
| Clothing | 309,995 | 245,945 | 79.34% |
| Electronics | 311,445 | 244,768 | 78.59% |
| Beauty | 286,790 | 228,589 | 79.71% |

**Analysis:** The top earner is not the most profitable. Electronics leads on revenue, Clothing on total profit and Beauty on margin, but all margins are within about 1.1 points. 

#### E2. Month-over-month revenue growth

```sql
WITH monthly_rev AS (
    SELECT EXTRACT(YEAR FROM sale_date)  AS year,
           EXTRACT(MONTH FROM sale_date) AS month,
           ROUND(SUM(total_sale)::NUMERIC) AS revenue
    FROM retail_sales
    GROUP BY 1, 2
),
monthly_comparison AS (
    SELECT year, month, revenue,
           LAG(revenue) OVER (ORDER BY year, month) AS previous_month_rev
    FROM monthly_rev
)
SELECT year, month, revenue, previous_month_rev,
       ROUND((revenue - previous_month_rev) / NULLIF(previous_month_rev, 0) * 100) AS growth_pct
FROM monthly_comparison
ORDER BY year, month;
```

| Event | Month | Change |
|---|---|---:|
| Biggest jump | September 2022 | +192% (21,075 → 61,620) |
| Second biggest jump | September 2023 | +139% |
| Biggest drop | January 2023 | −67% (71,880 → 23,790) |

**Analysis:** Revenue sits around 20,000 to 30,000 a month from January to August, then roughly triples from September to December in both years, and falls back in January. The business is strongly seasonal.

#### E3. Age-group segmentation

```sql
SELECT CASE WHEN age < 25 THEN 'under 25'
            WHEN age BETWEEN 25 AND 34 THEN '25-34'
            WHEN age BETWEEN 35 AND 49 THEN '35-49'
            ELSE '50+' END AS age_band,
       SUM(total_sale) AS revenue,
       ROUND(AVG(total_sale)::NUMERIC, 2) AS avg_per_transaction
FROM retail_sales
GROUP BY age_band
ORDER BY revenue DESC;
```

| Age band | Revenue | Avg per transaction |
|---|---:|---:|
| 50+ | 282,845 | 426.61 |
| 35–49 | 282,135 | 452.87 |
| 25–34 | 194,090 | 479.23 |
| Under 25 | 149,160 | 503.92 |

**Analysis:** the 50+ band is the most valuable by total revenue, narrowly ahead of 35 to 49, because it has the most transactions. The youngest customers spend the most per purchase but buy less often. 

#### E4. Repeat vs. one-time customers

```sql
WITH customer_orders AS (
    SELECT customer_id, COUNT(*) AS total_orders, SUM(total_sale) AS total_revenue
    FROM retail_sales
    GROUP BY customer_id
),
repeat_customers AS (
    SELECT * FROM customer_orders WHERE total_orders > 1
)
SELECT ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customer_orders)) AS repeat_customer_pct,
       ROUND(SUM(total_revenue) * 100.0 / (SELECT SUM(total_revenue) FROM customer_orders)) AS repeat_revenue_pct
FROM repeat_customers;
```

**Result:** 100% of customers are repeat customers and generate 100% of revenue.
**Analysis:** every one of the 155 customers bought at least twice, so no one-time segment exists to compare against. This is another sign the dataset is synthetic.

#### E5. Top 3 customers within each category

```sql
WITH category_revenue AS (
    SELECT category, customer_id, SUM(total_sale) AS revenue
    FROM retail_sales
    GROUP BY category, customer_id
),
customer_ranking AS (
    SELECT *, RANK() OVER (PARTITION BY category ORDER BY revenue DESC) AS customer_rank
    FROM category_revenue
)
SELECT * FROM customer_ranking
WHERE customer_rank <= 3
ORDER BY category, customer_rank;
```

| Category | #1 | #2 | #3 |
|---|---|---|---|
| Beauty | Customer 1 (11,985) | Customer 3 (9,740) | Customer 4 (6,750) |
| Clothing | Customer 5 (12,040) | Customer 1 (11,730) | Customer 3 (11,545) |
| Electronics | Customer 3 (17,155) | Customer 5 (13,235) | Customer 2 (11,750) |

**Analysis:** The ranking restarts in each category, and the same few customers (IDs 1 to 5) lead all three, which matches the Q8 result.

#### E6. Cumulative revenue and 3-month moving average

```sql
WITH monthly_sale AS (
    SELECT EXTRACT(YEAR FROM sale_date) AS year,
           EXTRACT(MONTH FROM sale_date) AS month,
           SUM(total_sale) AS monthly_revenue
    FROM retail_sales
    GROUP BY 1, 2
)
SELECT year, month, monthly_revenue,
       SUM(monthly_revenue) OVER (PARTITION BY year ORDER BY month) AS cumulative_revenue,
       ROUND(AVG(monthly_revenue) OVER (PARTITION BY year ORDER BY month
             ROWS BETWEEN 2 PRECEDING AND CURRENT ROW)) AS moving_avg_3_month
FROM monthly_sale
ORDER BY year, month;
```

Excerpt for 2022:

| Month | Revenue | Cumulative | 3-month avg |
|---|---:|---:|---:|
| Aug | 21,075 | 179,185 | 21,323 |
| Sep | 61,620 | 240,805 | 34,963 |
| Oct | 67,735 | 308,540 | 50,143 |
| Nov | 68,915 | 377,455 | 66,090 |
| Dec | 71,880 | 449,335 | 69,510 |

**Analysis:** Annual revenue was 449,335 in 2022 and 458,895 in 2023 (about +2.1%), so growth is nearly flat. The moving average turns the sudden September jump into a gradual climb that reflects the new, higher level of sales, peaking at 69,510 in December 2022 and 61,387 in December 2023.

## Findings

- **Seasonality**: September to December brings in about 57% of all revenue, at roughly three times the monthly level of the rest of the year.
- **Categories**: Electronics, Clothing and Beauty are close in revenue and margin, but they lead on different measures (revenue, profit and margin respectively).
- **Customers**: all 155 customers are repeat buyers, a few (IDs 1 to 5) account for 16.3% of revenue, and most customers buy from every category.
- **Demographics**: gender is evenly split. Customers aged 50+ bring the most revenue, while under-25s spend the most per purchase.
- **Timing**: over half of all orders are placed after 18:00.
- **High-value sales**: about 15% of transactions exceed 1,000.
- **Pricing**: 70 single-unit sales were made at a loss.

## Recommendations

- Prepare stock and campaigns for September onward, and plan a promotion to soften the January drop.
- Review the prices of the loss-making single-unit items.
- Schedule staff and promotions around the evening peak.
- Reward and retain the top customers.
- Try bundles or multi-unit offers for the 50+ band to lift their lower average basket.

## Conclusion

This project took me through the full analyst workflow: setting up a database, cleaning and validating the data, exploring it, answering business questions, and going further with CTEs and window functions. The main business insight is the strong September to December seasonality; the main technical lessons were checking data quality before analysing it, stating clear definitions when a question is ambiguous ("best selling month", `cogs`), and casting `FLOAT` to `NUMERIC` for `ROUND` in PostgreSQL.

**Limitations:** the data looks synthetic (79% margins, every customer a repeat buyer) The results show the method rather than real business truth. 

## How to Use

1. **Clone the repository** from GitHub.
2. **Set up the database**: create a PostgreSQL database (for example `sql_project_1`) and run the table-creation section of `proj_1.sql`.
3. **Import the data**: load `SQL - Retail Sales Analysis_utf .csv` into `retail_sales` by column position (the CSV header says `quantiy`), with blank cells loaded as `NULL`.
4. **Clean and analyze**: run the cleaning section, then the analysis queries.
5. **Explore**: modify the queries to answer your own questions.

```text
.
├── README.md
├── proj_1.sql
└── SQL - Retail Sales Analysis_utf .csv
```

## Author - Denis Kabenge

This project is part of my portfolio, showcasing the SQL skills essential for data analyst roles. Feel free to get in touch with feedback or to collaborate.

- **GitHub**: (https://github.com/K-Denis12)
