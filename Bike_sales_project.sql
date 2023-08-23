CREATE DATABASE bike_sales;
USE bike_sales;

CREATE TABLE bike_sales_data (
Sales_order VARCHAR(25),
Date_of_sale VARCHAR(25),
Day_of_sale VARCHAR(25),
Month_of_sale VARCHAR(25),
Year_of_sale VARCHAR(25),
Customer_Age VARCHAR(25),
Age_Group VARCHAR(25),
Customer_Gender VARCHAR(25),
Country VARCHAR(25),
State VARCHAR(25),
Product_Category VARCHAR(25),
Sub_Category VARCHAR(25),
Product_Description VARCHAR(25),
Order_Quantity VARCHAR(25),
Unit_Cost VARCHAR(25),
Unit_Price VARCHAR(25),
Profit VARCHAR(25),
Cost VARCHAR(25),
Revenue VARCHAR(25));

SELECT * FROM bike_sales_data;

-- DATA CLEANING
DROP TABLE bike_sales_data_cleaned;
CREATE TABLE bike_sales_data_cleaned AS (
WITH cte AS(
SELECT Sales_order, STR_TO_DATE(Date_of_sale,'%d.%m.%Y') as Date_of_sale, Day_of_sale,
Month_of_sale, Year_of_sale, Customer_Age,
CASE 
WHEN Customer_age <25 THEN "Youth (<25)"
WHEN Customer_age BETWEEN 25 AND 34 THEN "Young Adults (25-34)"
WHEN Customer_age BETWEEN 35 AND 64 THEN "Adults (35-64)"
END as Age_Group,
TRIM(Customer_Gender) AS Customer_Gender, TRIM(Country) AS Country, TRIM(State) AS State, TRIM(Product_Category) AS Product_Category,
TRIM(Sub_Category) AS Sub_Category, TRIM(Product_Description) AS Product_Description, 
CASE WHEN Order_Quantity ='' THEN NULL
ELSE Order_Quantity
END AS Order_Quantity, 
REPLACE(REPLACE(Unit_Cost, '$', ''), ' ','') AS Unit_Cost, REPLACE(REPLACE(Unit_Price, '$', ''),' ','') AS Unit_Price,
REPLACE(REPLACE(Profit, '$', ''), ' ','') AS Profit, REPLACE(REPLACE(Cost, '$', ''), ' ','') AS Cost, 
REPLACE(REPLACE(Revenue, '$', ''), ' ','') AS Revenue 
FROM bike_sales_data)
SELECT Sales_order, Date_of_sale, DAY(Date_of_sale) AS Day_of_sale,
MONTHNAME(Date_of_sale) AS Month_of_sale, YEAR(Date_of_sale) AS Year_of_sale,
Customer_Age, Age_Group, Customer_Gender, Country, State, Product_Category, Sub_Category,
Product_Description, Order_Quantity, Unit_Cost, Unit_Price, Profit, Cost, Revenue FROM cte);

SELECT * FROM bike_sales_data_cleaned;
ALTER TABLE bike_sales_data_cleaned MODIFY Sales_order INT;
ALTER TABLE bike_sales_data_cleaned MODIFY Customer_Age INT;
ALTER TABLE bike_sales_data_cleaned MODIFY Customer_Gender CHAR(1);
ALTER TABLE bike_sales_data_cleaned MODIFY Order_Quantity INT;
ALTER TABLE bike_sales_data_cleaned MODIFY Unit_Cost DECIMAL (10,2);
ALTER TABLE bike_sales_data_cleaned MODIFY Unit_Price DECIMAL (10,2);
ALTER TABLE bike_sales_data_cleaned MODIFY Profit DECIMAL (10,2);
ALTER TABLE bike_sales_data_cleaned MODIFY Cost DECIMAL (10,2);
ALTER TABLE bike_sales_data_cleaned MODIFY Revenue DECIMAL (10,2);

SELECT date_of_sale, customer_age, customer_gender, country, state, product_description, order_quantity, 
unit_cost, unit_price, profit, cost, revenue FROM bike_sales_data_cleaned 
WHERE Unit_price = 2295
order by Product_Description;

SELECT product_description, SUM(order_quantity)
FROM bike_sales_data_cleaned 
WHERE Unit_price = 2295 AND product_description <> ''
GROUP BY 1;

SELECT Customer_age,product_description, SUM(order_quantity)
FROM bike_sales_data_cleaned 
WHERE Unit_price = 2295 AND product_description <> ''
GROUP BY 1,2;

SELECT Customer_gender,product_description, SUM(order_quantity)
FROM bike_sales_data_cleaned 
WHERE Unit_price = 2295 AND product_description <> ''
GROUP BY 1,2;

-- missing value in product_descriptom I will replace with 'Mountain-200 Black, 46' as the unit price is the same as unit price 
-- in row without product_description, moreover this was the most times bought bike by 39 - years old female in this patricular
-- unit price. 
UPDATE bike_sales_data_cleaned
SET product_description = "Mountain-200 Black, 46"
WHERE product_description = '';

UPDATE bike_sales_data_cleaned b,
(SELECT CASE 
WHEN unit_cost = 0 AND LEAD(Unit_price) OVER (ORDER BY product_description) = Unit_price
THEN LEAD(Unit_cost) OVER (ORDER BY product_description)
WHEN unit_cost = 0 AND LAG(Unit_price) OVER (ORDER BY product_description) = Unit_price
THEN LAG(Unit_cost) OVER (ORDER BY product_description)
else Unit_cost
END UNIT_COST1
FROM bike_sales_data_cleaned
ORDER BY product_description) a
SET b.Unit_cost = UNIT_COST1
WHERE b.Unit_cost = 0;


UPDATE bike_sales_data_cleaned b,
(WITH Cte AS (SELECT * FROM bike_sales_data_cleaned
WHERE Product_Description = 
(SELECT Product_Description FROM bike_sales_data_cleaned WHERE Order_Quantity IS NULL))
SELECT product_description, 
CASE 
WHEN order_quantity IS NULL THEN LEAD(Order_Quantity) OVER (ORDER BY Order_Quantity)
ELSE Order_quantity
END Order_Quantity FROM Cte) a
SET b.order_quantity = a.order_quantity
WHERE b.order_quantity IS NULL;


UPDATE bike_sales_data_cleaned b, (
WITH CTE AS (SELECT b.product_description, b.order_quantity, b.unit_price FROM bike_sales_data_cleaned a 
LEFT JOIN bike_sales_data_cleaned B ON a.product_description = b.product_description 
WHERE a.Unit_price = 0)
SELECT 
CASE WHEN Unit_price = 0 THEN LEAD(Unit_price) OVER (ORDER BY unit_price) 
ELSE Unit_price
END Unit_price
FROM CTE) a
SET b.unit_price = a.unit_price
WHERE b.unit_price = 0;

UPDATE bike_sales_data_cleaned b, 
(
SELECT order_quantity, unit_cost, CASE 
WHEN cost = 0 THEN order_quantity*unit_cost
ELSE cost
END cost
FROM bike_sales_data_cleaned) a
SET b.cost = a.cost 
WHERE b.cost = 0 ;

UPDATE bike_sales_data_cleaned b, (
SELECT CASE
WHEN Revenue = 0 THEN order_quantity*unit_price
ELSE Revenue
END Revenue
FROM bike_sales_data_cleaned) a
SET a.Revenue = b.Revenue
WHERE b.Revenue = 0;

ALTER TABLE bike_sales_data_cleaned
DROP COLUMN Revenue;

ALTER TABLE bike_sales_data_cleaned
ADD COLUMN Revenue DECIMAL(10,2);

UPDATE bike_sales_data_cleaned
SET Revenue = order_quantity*unit_price
WHERE Revenue IS NULL;

UPDATE bike_sales_data_cleaned
SET Country = 'United States'
WHERE Country = 'United  States';

UPDATE bike_sales_data_cleaned
SET Sales_order = 261696
WHERE Date_of_sale = '2021-12-01' AND Customer_Gender = 'M'

SELECT * FROM bike_sales_data_cleaned;


-- THE MOST POPULAR BIKE FOR MEN/FEMALE/AGE GROUP/COUNTRY
SELECT Customer_Gender, Product_Description, max_total_sell
FROM
(WITH Cte AS (SELECT Customer_Gender, Product_Description, SUM(Order_Quantity) AS Total_sell 
FROM bike_sales_data_cleaned
GROUP BY 1,2 
ORDER BY 3 DESC)
SELECT Customer_Gender, Product_Description, total_sell, MAX(total_sell) OVER (PARTITION BY Customer_Gender)
 as max_total_sell
FROM CTE
GROUP BY 1,2) a
WHERE Total_sell = max_total_sell;


SELECT Age_Group, Product_Description, max_total_sell
FROM
(WITH Cte AS (SELECT Age_Group, Product_Description, SUM(Order_Quantity) AS Total_sell 
FROM bike_sales_data_cleaned
GROUP BY 1,2 
ORDER BY 3 DESC)
SELECT Age_Group, Product_Description, total_sell, MAX(total_sell) OVER (PARTITION BY Age_group) as max_total_sell
FROM CTE
GROUP BY 1,2) a
WHERE Total_sell = max_total_sell;

SELECT Country, Product_Description, max_total_sell
FROM
(WITH Cte AS (SELECT Country, Product_Description, SUM(Order_Quantity) AS Total_sell 
FROM bike_sales_data_cleaned
GROUP BY 1,2 
ORDER BY 3 DESC)
SELECT Country, Product_Description, total_sell, MAX(total_sell) OVER (PARTITION BY Country) as max_total_sell
FROM CTE
GROUP BY 1,2) a
WHERE Total_sell = max_total_sell;


-- HOW MANY BIKES WAS SELL EACH DAY

SELECT Date_of_sale, SUM(Order_Quantity) AS Total_sell 
FROM bike_sales_data_cleaned
GROUP BY 1
ORDER BY 2 DESC;


-- HOW MANY BIKES WERE SOLD IN EACH COUNTRY

SELECT Country, SUM(Order_Quantity) AS Total_sell 
FROM bike_sales_data_cleaned
GROUP BY 1
ORDER BY 2 DESC;

-- AVERAGE PRICE FOR A BIKE

SELECT ROUND(AVG(unit_price),2) AS Average_bike_price
FROM bike_sales_data_cleaned;

-- PEOPLE FROM WHICH COUNTRY SPENT THE MOST MONEY FOR BIKES
SELECT * FROM bike_sales_data_cleaned;
SELECT Country, ROUND(SUM(Revenue),2) as total_money
FROM bike_sales_data_cleaned
GROUP BY 1
ORDER BY 2 DESC;
