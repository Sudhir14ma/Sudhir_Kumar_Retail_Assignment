-- ==========================================================
-- Project: Retail Sales & Profitability Analysis (Part B)
-- Script: queries.sql
-- Database: superstore_db
-- Target Table: retail_sales
-- ==========================================================

-- Create Database
CREATE DATABASE IF NOT EXISTS superstore_db;
USE superstore_db;

-- Drop table if it already exists
DROP TABLE IF EXISTS retail_sales;

-- Create structured table matching retail_clean.csv
CREATE TABLE retail_sales (
    row_id INT,
    order_id VARCHAR(50),
    order_date DATE,
    ship_date DATE,
    ship_mode VARCHAR(50),
    customer_id VARCHAR(50),
    customer_name VARCHAR(150),
    segment VARCHAR(50),
    country VARCHAR(50),
    city VARCHAR(100),
    state VARCHAR(100),
    postal_code VARCHAR(20),
    region VARCHAR(50),
    product_id VARCHAR(50),
    category VARCHAR(50),
    sub_category VARCHAR(50),
    product_name VARCHAR(255),
    sales DECIMAL(12, 2),
    quantity INT,
    discount DECIMAL(5, 2),
    profit DECIMAL(12, 2),
    profit_margin DECIMAL(8, 4),
    order_month VARCHAR(7),
    loss_flag TINYINT(1)
);


-- --------------------------------------------------------------------
-- Query 1: Total Revenue and Total Profit
-- Objective: Calculate aggregate gross revenue and net profit across the business.
-- --------------------------------------------------------------------
SELECT 
    ROUND(SUM(sales), 2) AS total_revenue,
    ROUND(SUM(profit), 2) AS total_profit
FROM retail_sales;


-- --------------------------------------------------------------------
-- Query 2: Overall Profit Margin (%)
-- Objective: Evaluate overall operational margin efficiency.
-- Formula: (Total Profit / Total Revenue) * 100
-- --------------------------------------------------------------------
SELECT 
    ROUND(SUM(sales), 2) AS total_revenue,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS overall_profit_margin_pct
FROM retail_sales;


-- --------------------------------------------------------------------
-- Query 3: Revenue by Category and Sub-Category
-- Objective: Hierarchical revenue and profit breakdown to identify drivers and laggards.
-- --------------------------------------------------------------------
SELECT 
    category,
    sub_category,
    ROUND(SUM(sales), 2) AS total_revenue,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin_pct
FROM retail_sales
GROUP BY category, sub_category
ORDER BY category ASC, total_revenue DESC;


-- --------------------------------------------------------------------
-- Query 4: Top 10 Products by Sales
-- Objective: Identify highest-grossing products and evaluate their profit contribution.
-- --------------------------------------------------------------------
SELECT 
    product_name,
    category,
    sub_category,
    ROUND(SUM(sales), 2) AS total_revenue,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin_pct
FROM retail_sales
GROUP BY product_name, category, sub_category
ORDER BY total_revenue DESC
LIMIT 10;


-- --------------------------------------------------------------------
-- Query 5: Region-wise Revenue and Profit
-- Objective: Regional sales performance and operating margins comparison.
-- --------------------------------------------------------------------
SELECT 
    region,
    ROUND(SUM(sales), 2) AS total_revenue,
    ROUND(SUM(profit), 2) AS total_profit,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS profit_margin_pct,
    COUNT(DISTINCT order_id) AS total_orders
FROM retail_sales
GROUP BY region
ORDER BY total_revenue DESC;


-- --------------------------------------------------------------------
-- Query 6: Monthly Sales Trend
-- Objective: Track revenue, profit, and monthly margin run-rate chronologically.
-- --------------------------------------------------------------------
SELECT 
    order_month,
    ROUND(SUM(sales), 2) AS monthly_revenue,
    ROUND(SUM(profit), 2) AS monthly_profit,
    ROUND((SUM(profit) / SUM(sales)) * 100, 2) AS monthly_profit_margin_pct,
    COUNT(DISTINCT order_id) AS monthly_orders
FROM retail_sales
GROUP BY order_month
ORDER BY order_month ASC;


-- --------------------------------------------------------------------
-- Query 7: Percentage of Loss-Making Orders
-- Objective: Evaluate the share of customer orders that yielded a net negative profit.
-- Note: Calculated at the Order level using subquery aggregation.
-- --------------------------------------------------------------------
SELECT 
    COUNT(*) AS total_orders,
    SUM(CASE WHEN order_profit < 0 THEN 1 ELSE 0 END) AS loss_making_orders,
    ROUND((SUM(CASE WHEN order_profit < 0 THEN 1 ELSE 0 END) / COUNT(*)) * 100, 2) AS pct_loss_making_orders
FROM (
    SELECT 
        order_id,
        SUM(profit) AS order_profit
    FROM retail_sales
    GROUP BY order_id
) AS order_profit_summary;



