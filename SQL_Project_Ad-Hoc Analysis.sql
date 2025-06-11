# Provide the list of markets in which customer  "Atliq  Exclusive"  operates its business in the  APAC  region.

SELECT DISTINCT market
FROM dim_customer
WHERE customer = "Atliq Exclusive" AND region = "APAC";


# What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields, 
# unique_products_2020 , # unique_products_2021 , # percentage_chg

WITH CTE1 AS (
	SELECT COUNT(DISTINCT product_code) AS Year_2020
	FROM fact_sales_monthly
	WHERE fiscal_year = 2020),
CTE2 AS (
	SELECT COUNT(DISTINCT product_code) AS Year_2021
	FROM fact_sales_monthly
	WHERE fiscal_year = 2021)
SELECT CTE1.Year_2020 AS unique_products_2020,
	   CTE2.Year_2021 AS unique_products_2021,
       ROUND(((CTE2.Year_2021-CTE1.Year_2020)*100/CTE1.Year_2020),2) AS percentage_chg
	FROM CTE1 CROSS JOIN CTE2;
    
    
# Provide a report with all the unique product counts for each segment and sort them in descending order of product counts. The final output contains 2 fields, 
# segment , product_count

SELECT 
	segment,
    COUNT(DISTINCT (product_code)) AS product_count
FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;


# Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields, 
# segment , product_count_2020 , product_count_2021 , difference

WITH CTE1 AS (
		SELECT
			p.segment,
			COUNT(DISTINCT s.product_code) AS product_count_2020
		FROM fact_sales_monthly s
		JOIN dim_product p 
			ON p.product_code = s.product_code
		WHERE fiscal_year = 2020
        GROUP BY p.segment
        ORDER BY product_count_2020 DESC),
CTE2 AS (
		SELECT
			p.segment,
			COUNT(DISTINCT s.product_code) AS product_count_2021
		FROM fact_sales_monthly s
		JOIN dim_product p 
			ON p.product_code = s.product_code
		WHERE fiscal_year = 2021
		GROUP BY p.segment
        ORDER BY product_count_2021 DESC)
SELECT 
	CTE1.segment,
    product_count_2020,
	product_count_2021,
    (product_count_2021-product_count_2020) AS difference
FROM CTE1 
JOIN CTE2
	ON CTE1.segment = CTE2.segment
ORDER BY difference DESC;


# Get the products that have the highest and lowest manufacturing costs. The final output should contain these fields, 
# product_code , product , manufacturing_cost

SELECT 
	m.product_code,
    p.product,
    m.manufacturing_cost
FROM fact_manufacturing_cost m 
JOIN dim_product p
	ON m.product_code = p.product_code
WHERE manufacturing_cost IN (
		SELECT 
			MAX(manufacturing_cost)
		FROM fact_manufacturing_cost
        UNION
		SELECT 
			MIN(manufacturing_cost)
		FROM fact_manufacturing_cost)
ORDER BY manufacturing_cost DESC;


# Generate a report which contains the top 5 customers who received an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.
# The final output contains these fields, # customer_code , customer , average_discount_percentage


SELECT 
	c.customer_code,
    c.customer,
    ROUND(AVG(pre_invoice_discount_pct)*100,2) AS average_discount_percentage
FROM dim_customer c 
JOIN fact_pre_invoice_deductions p 
	ON c.customer_code = p.customer_code
WHERE fiscal_year = 2021 AND market = "India"
GROUP BY customer_code
ORDER BY average_discount_percentage DESC
LIMIT 5;

    

# Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. 
# This analysis helps to get an idea of low and high-performing months and take strategic decisions. The final report contains these columns: 
# Month , Year , Gross sales Amount

SELECT 
    CONCAT(MONTHNAME(s.date), ' [', YEAR(s.date), ']') AS Month,
    s.fiscal_year AS Year,
    ROUND(SUM(s.sold_quantity * g.gross_price), 2) AS Gross_Sales_Amount
FROM fact_sales_monthly s
JOIN dim_customer c 
	ON s.customer_code = c.customer_code
JOIN fact_gross_price g 
	ON s.product_code = g.product_code
WHERE c.customer = 'Atliq Exclusive'
GROUP BY Month, s.fiscal_year
ORDER BY s.fiscal_year;



# In which quarter of 2020, got the maximum total_sold_quantity? The final output contains these fields sorted by the total_sold_quantity, 
# Quarter , total_sold_quantity


SELECT
	CASE
		WHEN date BETWEEN '2019-09-01' AND '2019-11-30' THEN 'Q1'
        WHEN date BETWEEN '2019-12-01' AND '2020-02-29' THEN 'Q2'
        WHEN date BETWEEN '2020-03-01' AND '2020-05-31' THEN 'Q3'
        WHEN date BETWEEN '2020-06-01' AND '2020-08-31' THEN 'Q4'
    END AS quarter,
    SUM(sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY quarter;


# Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution? The final output contains these fields, 
# channel , gross_sales_mln , percentage 


WITH CTE1 AS (
		SELECT
			c.channel,
			ROUND(SUM(g.gross_price * s.sold_quantity)/ 1000000, 2) AS gross_sales_mln
		FROM fact_sales_monthly s 
		JOIN dim_customer c  
			ON s.customer_code = c.customer_code
		JOIN fact_gross_price g 
			ON s.product_code = g.product_code
		WHERE s.fiscal_year = 2021
        GROUP BY c.channel)
SELECT *,
		ROUND(gross_sales_mln*100/SUM(gross_sales_mln) OVER(),2) AS percentage
FROM CTE1
ORDER BY percentage DESC;



# Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021? The final output contains these fields,
# division , product_code , product , total_sold_quantity , rank_order

WITH CTE1 AS(
	SELECT 
		division,
        s.product_code,
        product,
		SUM(s.sold_quantity) AS total_sold_quantity
	FROM dim_product p 
	JOIN fact_sales_monthly s 
		ON p.product_code = s.product_code
	WHERE fiscal_year = 2021
    GROUP BY division, s.product_code, product
),
CTE2 AS (
	SELECT
		*, 
        RANK() OVER (PARTITION BY division ORDER BY total_sold_quantity DESC) AS rank_order
	FROM CTE1)
SELECT *
FROM CTE2
WHERE rank_order <= 3











