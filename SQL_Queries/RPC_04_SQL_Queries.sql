
###############################################################################################################################

-- 1) Provide the list of markets in which customer "Atliq Exclusive" operates its bussiness in the APAC region.
SELECT DISTINCT market FROM dim_customer WHERE customer = 'Atliq Exclusive' AND region = 'APAC';

###############################################################################################################################

-- 2) What is the percentage of unique product increase in 2021 vs 2020?
WITH up_20 AS (
SELECT COUNT(DISTINCT product_code) AS unique_products_2020 FROM fact_gross_price WHERE fiscal_year = 2020
),
up_21 AS (
SELECT COUNT(DISTINCT product_code) AS unique_products_2021 FROM fact_gross_price WHERE fiscal_year = 2021
)
SELECT up_20.unique_products_2020, up_21.unique_products_2021, 
		ROUND(((up_21.unique_products_2021-up_20.unique_products_2020)/up_20.unique_products_2020)*100,2) AS percent_change
FROM up_20 JOIN up_21;

###############################################################################################################################

-- 3) Provide a report with all the unique product counts for each segment and sort them in descending order of product counts.
SELECT segment ,COUNT(DISTINCT product_code) AS unique_product_count 
FROM dim_product
GROUP BY segment
ORDER BY unique_product_count DESC;

###############################################################################################################################

-- 4) Follow-up: Which segment had the most increase in unique products in 2021 vs 2020.
WITH up_20 AS (
SELECT dp.segment ,COUNT(DISTINCT fgp.product_code) AS product_count_2020 
FROM dim_product AS dp JOIN  fact_gross_price AS fgp ON dp.product_code = fgp.product_code 
WHERE fgp.fiscal_year = 2020
GROUP BY dp.segment
),
up_21 AS (
SELECT dp.segment ,COUNT(DISTINCT fgp.product_code) AS product_count_2021 
FROM dim_product AS dp JOIN  fact_gross_price AS fgp ON dp.product_code = fgp.product_code 
WHERE fgp.fiscal_year = 2021
GROUP BY dp.segment
)
SELECT up_20.segment,up_20.product_count_2020, up_21.product_count_2021, 
	   (up_21.product_count_2021-up_20.product_count_2020) AS Difference
FROM up_20 JOIN up_21 ON up_20.segment = up_21.segment
ORDER BY Difference DESC;

###############################################################################################################################

-- 5) Get the products that have the highest and lowest manufacturing costs. 
(SELECT fmc.product_code, dp.product, manufacturing_cost
FROM fact_manufacturing_cost AS fmc JOIN dim_product dp ON fmc.product_code = dp.product_code
ORDER BY manufacturing_cost ASC LIMIT 1)
UNION ALL
(SELECT fmc.product_code, dp.product, manufacturing_cost 
FROM fact_manufacturing_cost AS fmc JOIN dim_product dp ON fmc.product_code = dp.product_code
ORDER BY manufacturing_cost DESC LIMIT 1);

###############################################################################################################################
/*
-- 6) Generate a report which contains the top 5 customers who received an average 
	  high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market. */
SELECT fpid.customer_code, dc.customer, ROUND(AVG(pre_invoice_discount_pct),4) AS average_discount_percentage
FROM dim_customer AS dc JOIN fact_pre_invoice_deductions AS fpid ON dc.customer_code = fpid.customer_code
WHERE dc.market = 'India' AND fpid.fiscal_year = 2021
GROUP BY fpid.customer_code, dc.customer
ORDER BY average_discount_percentage DESC
LIMIT 5;

###############################################################################################################################

/*
-- 7) Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month. 
This analysis helps to get an idea of low and high-performing months and take strategic decisions. */
SELECT 
	MONTH(date) AS Month,
	MONTHNAME(fsm.date) AS Month_Name, 
    YEAR(date) AS Year,
    fsm.fiscal_year AS Fiscal_Year, 
    ROUND(SUM(fsm.sold_quantity * fgp.gross_price)/1000000,2) AS 'Gross_Sales_Amount(Millions)'
FROM fact_gross_price AS fgp JOIN fact_sales_monthly AS fsm ON fgp.product_code = fsm.product_code
							 JOIN dim_customer AS dc ON dc.customer_code = fsm.customer_code
WHERE dc.customer = 'Atliq Exclusive'
GROUP BY Year,Month, Month_Name,Fiscal_Year
ORDER BY Year,Month;

###############################################################################################################################

-- 8) In which quarter of 2020, got the maximum total_sold_quantity? 
WITH cte AS (
SELECT 
		date, sold_quantity,
	CASE
		WHEN MONTH(date) IN (9,10,11) THEN 'Q1'
        WHEN MONTH(date) IN (12,1,2) THEN 'Q2'
        WHEN MONTH(date) IN (3,4,5) THEN 'Q3'
        WHEN MONTH(date) IN (6,7,8) THEN 'Q4'
	END AS Quarter
FROM fact_sales_monthly
WHERE fiscal_year = 2020
)
SELECT Quarter, ROUND(SUM(sold_quantity)/1000000,3) AS total_sold_quantity_Millions
FROM cte
GROUP BY Quarter 
ORDER BY total_sold_quantity_Millions DESC;

# -----------------------------------------------------------------------------------------------------------------------
WITH cte AS (
SELECT 
		date, monthname(date) AS Month_Name, sold_quantity,CASE WHEN MONTHNAME(date) = 'September' THEN 1
WHEN MONTHNAME(date) = "November" THEN 3
WHEN MONTHNAME(date) = "October" THEN 2
WHEN MONTHNAME(date) = "December" THEN 4
WHEN MONTHNAME(date) = "February" THEN 6
WHEN MONTHNAME(date) = "January" THEN 5
WHEN MONTHNAME(date) = "April" THEN 8
WHEN MONTHNAME(date) = "March" THEN 7
WHEN MONTHNAME(date) = "May" THEN 9
WHEN MONTHNAME(date) = "August" THEN 12
WHEN MONTHNAME(date) = "July" THEN 11
WHEN MONTHNAME(date) = "June" THEN 10 END AS Month_order,
	CASE
		WHEN MONTH(date) IN (9,10,11) THEN 'Q1'
        WHEN MONTH(date) IN (12,1,2) THEN 'Q2'
        WHEN MONTH(date) IN (3,4,5) THEN 'Q3'
        WHEN MONTH(date) IN (6,7,8) THEN 'Q4'
	END AS Quarter
FROM fact_sales_monthly
WHERE fiscal_year = 2020
),
cte2 AS (SELECT Quarter,Month_Name,Month_order, ROUND(SUM(sold_quantity)/1000000,3) AS total_sold_quantity_Millions
FROM cte
GROUP BY Quarter,Month_Name,Month_order
ORDER BY Quarter, Month_order ASC)
Select Quarter, Month_Name, total_sold_quantity_Millions from cte2;
# --------------------------------------------------------------------------------------------------------------------------

###############################################################################################################################
-- 9) Which channel helped to bring more gross sales in the fiscal year 2021 and the percentage of contribution?
WITH cte AS (
SELECT 
	dc.channel,
    ROUND(SUM(fsm.sold_quantity * fgp.gross_price)/1000000,2) AS Gross_Sales_Amount_Millions
FROM fact_gross_price AS fgp JOIN fact_sales_monthly AS fsm ON fgp.product_code = fsm.product_code
							 JOIN dim_customer AS dc ON dc.customer_code = fsm.customer_code
WHERE fsm.fiscal_year = 2021
GROUP BY dc.channel)
SELECT *, ROUND((Gross_Sales_Amount_Millions/SUM(Gross_Sales_Amount_Millions) OVER())*100,2) AS percent_contribution
FROM cte
ORDER BY Gross_Sales_Amount_Millions DESC;

###############################################################################################################################

-- 10) Get the Top 3 products in each division that have a high total_sold_quantity in the fiscal_year 2021?
WITH cte AS(
SELECT  dp.division, dp.product_code, CONCAT(dp.product,' - ',dp.variant) AS Product,
		SUM(sold_quantity) AS total_sold_quantity,
		DENSE_RANK() OVER(PARTITION BY dp.division ORDER BY SUM(sold_quantity) DESC) AS product_rank
FROM fact_sales_monthly AS fsm JOIN dim_product AS dp ON fsm.product_code = dp.product_code
WHERE fsm.fiscal_year = 2021
GROUP BY dp.division, dp.product_code, dp.product, dp.variant
ORDER BY dp.division, product_rank)
SELECT * FROM cte WHERE product_rank <= 3;

###############################################################################################################################


