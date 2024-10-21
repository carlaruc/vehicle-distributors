/*The Vehicle Distributors, a fictional wholesale distributor of die cast vehicle models, operates globally with customers in over 15 countries. The company has approached us with a dataset analysis task to help them make critical decisions regarding potential future expansion. The objective of this project is to address their inquiries and provide data-driven answers by examining the available data.

The provided dataset, along with its corresponding schema, can be found [here](https://www.mysqltutorial.org/mysql-sample-database.aspx).
The scale model cars database contains eight tables:

 * Customers: customer data
 * Employees: all employee information
 * Offices: sales office information
 * Orders: customers' sales orders
 * OrderDetails: sales order line for each sales order
 * Payments: customers' payment records
 * Products: a list of scale model cars
 * ProductLines: a list of product line categories */ 

 -- Displaying the first five lines from the products table 
 SELECT *
   FROM products
  LIMIT 5;

-- Number of lines in the product table   
SELECT COUNT (*)
  FROM products;

-- Create a table that shows all available tables within the dataset
SELECT 'customers' AS table_name, (SELECT COUNT(*) FROM PRAGMA_TABLE_INFO('customers')) AS number_of_attributes, COUNT(*) AS number_of_rows
FROM customers

UNION ALL

SELECT 'employees', (SELECT COUNT(*) FROM PRAGMA_TABLE_INFO('employees')), COUNT(*)
FROM employees

UNION ALL

SELECT 'offices', (SELECT COUNT(*) FROM PRAGMA_TABLE_INFO('offices')), COUNT(*)
FROM offices

UNION ALL

SELECT 'productLines', (SELECT COUNT(*) FROM PRAGMA_TABLE_INFO('productlines')), COUNT(*)
FROM productlines

UNION ALL

SELECT 'products', (SELECT COUNT(*) FROM PRAGMA_TABLE_INFO('products')), COUNT(*) 
FROM products

UNION ALL

SELECT 'orderdetails', (SELECT COUNT(*) FROM PRAGMA_TABLE_INFO('orderdetails')), COUNT(*) 
FROM orderdetails

UNION ALL

SELECT 'orders', (SELECT COUNT(*) FROM PRAGMA_TABLE_INFO('orders')), COUNT(*)
FROM orders

UNION ALL

SELECT 'payments', (SELECT COUNT(*) FROM PRAGMA_TABLE_INFO('payments')), COUNT(*)
FROM payments;

-- Which products should we order more of or less off?
-- The answer will depend of the low stock (i.e product in demand) and the product performance
-- The rate of stock is the amount of products ordered divided by the quantity in stock
-- The product performance is mainly the sum of the sales per product
-- Priority for restocking: those with high product performance and low stock

WITH
	low_stock AS (
				  SELECT p.productCode, p.productName, ROUND((SUM(o.quantityOrdered)/p.quantityInStock),2) AS restock_rate
				    FROM products p
				    JOIN orderdetails o
				      ON p.productCode = o.productCode
				   GROUP BY p.productCode
				   ORDER BY restock_rate DESC 
			      ),
    performance_product AS (
							SELECT productCode, ROUND(SUM(quantityOrdered * priceEach),2) AS performance
							FROM orderdetails
							GROUP BY productCode
							ORDER BY performance DESC
							)
							
	SELECT l.productCode, l.productName, l.restock_rate, pp.performance
	  FROM low_stock l
	  JOIN performance_product pp
	    ON l.productCode = pp.productCode
	 WHERE l.productCode IN (SELECT productCode
							   FROM performance_product)
LIMIT 10;

-- Now we want to find the VIPs among our customers those that bring in the most profit to the store and those that least engaged customers (bring the least amount of profit), so we can match the company's marketing strategy accordingly


-- Finding the customers that bring the most amount of profit

WITH vips AS(
			 SELECT o.customerNumber, SUM((od.priceEach-p.buyPrice)*quantityOrdered) AS profit_per_customer
			   FROM orders o
			   JOIN orderdetails od
				 ON o.orderNumber = od.orderNumber
			   JOIN products p
				 ON od.productCode = p.productCode
              GROUP BY o.customerNumber
			  ORDER BY profit_per_customer DESC
             )
-- VIP Customers demographics
	
SELECT c.contactLastName, c.contactFirstName, c.city, c.country, v.profit_per_customer
  FROM customers c
  JOIN vips v
    ON c.customerNumber = v.customerNumber
 ORDER BY profit_per_customer DESC
   LIMIT 5; 

-- Less Engaged customers

SELECT c.contactLastName, c.contactFirstName, c.city, c.country, v.profit_per_customer
  FROM customers c
  JOIN vips v
    ON c.customerNumber = v.customerNumber
 ORDER BY profit_per_customer
 LIMIT 5;
 
-- How much can we spend in acquiring new customers?
-- Let's calculate their LTV (Lifetime Value)

SELECT SUM(profit_per_customer)/COUNT(DISTINCT(customerNumber)) AS average_profit
FROM vips;

/* CONCLUSION

Vintage cars and motorcycles are the priority for restocking. 
They sell frequently, and they are the highest-performance products.
However, from the classic cars. 1968 Ford Mustang is the highest performing car, outselling all other production lines as well.
Therefore, it would be advisable to include it as priiority for restocking.

Average profit tells us how much profit an average customer generates during their lifetime with our store. We can use it to predict our future profit.
So, if we get ten new customers next month, we'll earn 39,395 dollars, and we can decide based on this prediction how much we can spend on acquiring new customers. */
