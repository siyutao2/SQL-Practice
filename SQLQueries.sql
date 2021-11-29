USE WideWorldImporters
GO
-- 1. List of PersONs’ full name, all their fax AND phone numbers, AS well AS the phone number AND fax of the company they are workINg FOR (if any). 
;
SELECT pp.FullName AS Full_name, pp.FaxNumber AS PersON_fax, pp.phonenumber persON_number,
sp.phoneNumber AS company_Number, sp.FaxNumber AS company_Fax
FROM Application.people AS pp
LEFT JOIN Purchasing.suppliers AS sp
ON pp.PersONID = sp.primaryContactPersonID
GO
;
--2. If the customer's primary contact person hAS the same phone number AS the customer’s phone number, list the customer companies. 
SELECT cs.CustomerName 
FROM sales.Customers cs
JOIN Application.People pp 
ON cs.PrimaryContactPersonID = pp.PersONID
WHERE cs.phoneNumber = pp.phoneNumber
;


-- 3. List of customers to whom we made a sale priOR to 2016 but no sale sINce 2016-01-01.
with CTE AS (
SELECT  MIN(pp.FullName) AS name, MAX(cs.TransactiONDate) AS lASt_Purchase
FROM Application.People pp
JOIN sales.CustomerTransactiONs cs ON pp.PersONID = cs.CustomerID
GROUP BY pp.PersONID
HAVING MIN(YEAR(cs.TransactiONDate)) <=2015
)

SELECT name
FROM CTE
;

-- 4. List of Stock Items AND total quantity FOR each stock item IN Purchase Orders IN YEAR 2013.
SELECT si.StockItemID, si.StockItemName, PT.TotalQuantity 
FROM Warehouse.StockItems si
JOIN 
(SELECT pol.StockItemID, SUM(pol.OrderedOuters) AS TotalQuantity FROM Purchasing.PurchaseOrderLines pol
JOIN 
Purchasing.PurchaseOrders po ON pol.PurchaseOrderID = po.PurchaseOrderID
WHERE YEAR(po.OrderDate) = 2013
GROUP BY pol.StockItemID) AS PT 
ON si.StockItemID = PT.StockItemID
;

-- 5. List of stock items that have at leASt 10 characters in decsriptiON.
SELECT si.StockItemID, si.StockItemName
FROM Warehouse.Stockitems si
WHERE len(si.SearchDetails) >= 10

-- 6. List of stock items that are NOT sold to the state of Alabama AND Georgia in 2014.
SELECT DISTINCT si.StockItemID, si.StockItemname 
FROM WareHouse.StockItems si
JOIN Sales.OrderLines ol ON si.StockItemID = ol.StockItemID
JOIN Sales.Orders so ON so.OrderID = ol.OrderID
JOIN sales.Customers cs ON so.CustomerID = cs.CustomerID
JOIN Application.Cities c ON c.CityID=cs.DeliveryCityID
JOIN Application.StateProvinces sp ON sp.StateProvinceID = c.StateProvinceID
WHERE YEAR(so.OrderDate) = 2014 AND sp.StateProvinceName NOT IN ('Alabama', 'Georgia')
;
-- 7. List of States AND AVG dates FOR Processing (confirmed delivery DATE – order date).
SELECT sp.StateProvinceCode, 
AVG(DATEDIFF(DAYOFYEAR, o.Orderdate,i.confirmedDeliveryTime)) AVG_dates
FROM sales.invoices i 
JOIN sales.Orders o ON o.OrderID = i.OrderID
JOIN sales.customers cs ON cs.CustomerID = o.CustomerID
JOIN Application.Cities c ON cs.DeliveryCityID = c.CityID
JOIN Application.StateProvinces sp ON sp.StateProvinceID = c.StateProvinceID
GROUP BY sp.StateProvinceCode
;

-- 8. List of States AND AVG dates FOR Processing (confirmed delivery DATE – order date) by MONTH.

SELECT StateProvinceCode,  
[1] AS Jan, [2] AS Feb, [3] AS Mar, [4] AS Apr, [5] AS May, [6] AS Jun, 
[7] AS Jul, [8] AS Aug, [9] AS Sep, [10] AS Oct, [11] AS Nov, [12] AS Dec
FROM 
(SELECT sp.StateProvinceCode, MONTH(o.OrderDate) AS om, 
AVG(DATEDIFF(DAYOFYEAR, o.OrderDate, i.confirmedDeliveryTime)) Avg_date_Processing
FROM sales.invoices i 
JOIN sales.Orders o ON o.OrderID = i.OrderID
JOIN sales.customers cs ON cs.CustomerID = o.CustomerID
JOIN Application.Cities c ON cs.DeliveryCityID = c.CityID
JOIN Application.StateProvinces sp ON sp.StateProvinceID = c.StateProvinceID
GROUP BY sp.StateProvinceCode, MONTH(o.OrderDate)) AS a
PIVOT 
(AVG(a.AVG_date_Processing) 
FOR om IN ([1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12])
) AS result
;

-- 9. List of StockItems that the company Purchased more than sold in the year of 2015.

SELECT wsi2.StockItemName
FROM Warehouse.StockItems wsi2
LEFT JOIN 
(SELECT wsi1.StockItemID , SUM(pol.OrderedOuters) quantity FROM Warehouse.StockItems wsi1
LEFT JOIN Purchasing.PurchaseOrderLines pol ON wsi1.StockItemID=pol.StockItemID
LEFT JOIN Purchasing.PurchaseOrders po ON po.PurchaseOrderID = pol.PurchaseOrderID
WHERE YEAR(po.OrderDate)=2015
GROUP BY wsi1.StockItemID ) p ON p.StockItemID = wsi2.StockItemID
LEFT JOIN
(SELECT wsi3.StockItemID , SUM(ol.Quantity) quantity FROM Warehouse.StockItems wsi3
LEFT JOIN sales.OrderLines ol ON wsi3.StockItemID=ol.StockItemID
LEFT JOIN sales.orders o ON o.OrderID = ol.OrderID
WHERE YEAR(o.OrderDate)=2015
GROUP BY wsi3.StockItemID
) s ON p.StockItemID=s.StockItemID 
WHERE p.quantity>s.quantity
;

-- 10. List of Customers AND their phone number, together with the primary contact person’s name,
-- to whom we did NOT sell more than 10  mugs (search by name) IN the YEAR 2016.
SELECT cn.Customer_Name, c2.PhoneNumber, p.FullName AS PrimaryContact
FROM
(SELECT max(c.CustomerName) as Customer_Name,SUM(ol.Quantity) AS total_sale
FROM sales.Customers c
JOIN sales.Orders o ON c.CustomerID=o.CustomerID
JOIN sales.OrderLines ol ON o.OrderID=ol.OrderID
JOIN Warehouse.StockItems wsi1 ON wsi1.StockItemID=ol.StockItemID
JOIN Warehouse.StockItemStockGroups wsi2 ON wsi1.StockItemID=wsi2.StockItemID
JOIN Warehouse.StockGroups wsi3 ON wsi2.StockGroupID=wsi3.StockGroupID
WHERE wsi3.StockGroupName ='mugs' AND YEAR(o.OrderDate)=2016 
GROUP BY c.CustomerID) AS cn
JOIN sales.Customers c2
ON cn.Customer_Name=c2.CustomerName
JOIN Application.People p
ON c2.PrimaryContactPersonID= p.PersONID
WHERE cn.total_sale <= 10
;


-- 11. List all the cities that were updated after 2015-01-01.
SELECT CityName FROM Application.Cities
WHERE YEAR(Validfrom) > 2014
;

--12. List all the Order Detail (Stock Item name, delivery address, delivery state, city, country, customer name, 
-- customer contact person name, customer phone, quantity) for the date of 2014-07-01. info should be relevant to that date.

SELECT  si.StockItemName, cus.CustomerID,cus.CustomerName,cus.phoneNumber, cus.DeliveryAddressLine1,cus.DeliveryAddressLine2,
city.CityName, sp.StateProvinceName,c.countryName, ol.Quantity,p.FullName AS customer_contact_person_name
FROM Sales.orders o
JOIN Sales.Customers cus ON o.CustomerID= cus.CustomerID
JOIN  Sales.OrderLines ol ON o.OrderID= ol.OrderID
JOIN Warehouse.StockItems si ON ol.StockItemID = si.StockItemID
JOIN Application.People p ON cus.PrimaryContactPersonID = p.PersonID
JOIN Application.Cities  city ON  cus.DeliveryCityID= city.CityID
JOIN Application.StateProvinces sp ON city.StateProvinceID= sp.StateProvinceID
JOIN Application.countries c ON sp.countryID= c.countryID
WHERE o.OrderDate = '2014-07-01'
;
  
--13. List of stock item groups and total quantity Purchased, total quantity sold, and the remaining stock quantity (quantity Purchased – quantity sold)
WITH CTE AS (
SELECT sg.StockGroupID, SUM(CAST(pol.OrderedOuters AS BIGINT)) AS quantity_order,SUM(ol.Quantity) AS quantity_sale
FROM Warehouse.StockItemStockGroups sg
JOIN Purchasing.PurchaseOrderLines pol
ON sg.StockItemID =pol.StockItemID
JOIN Sales.OrderLines ol
ON pol.StockItemID=ol.StockItemID
GROUP BY sg.StockGroupID)

SELECT CTE.stockgroupid, CTE.quantity_order, CTE.quantity_sale, CTE.quantity_order-CTE.quantity_sale AS remaining_stock_quantity 
FROM CTE
;

-- 14. List of Cities in the US and the stock item that the city got the most deliveries in 2016. 
-- If the city did not purchase any stock items in 2016, print “No Sales”.

WITH CTE AS (
	SELECT max(c.CityName) AS CityName, ol.StockItemID, SUM(ol.Quantity) AS total_quant,
			ROW_NUMBER() OVER (PARTITION BY c.CityID ORDER BY SUM(ol.Quantity) DESC ) quant_rank
	FROM Application.Cities c 
	LEFT JOIN Sales.Customers cus
	ON cus.PostalCityID = c.CityID
	LEFT JOIN Sales.Orders o
	ON o.CustomerID=cus.CustomerID
	LEFT JOIN Sales.OrderLines ol
	ON o.OrderID = ol.OrderID
	WHERE YEAR(o.OrderDate)=2016 
	GROUP BY c.CityID, ol.StockItemID
)
SELECT CityName, StockItemID, total_quant FROM cte
WHERE CTE.quant_rank = 1;
;

-- 15. List any orders that had more than one delivery attempt (located IN invoice table).

SELECT OrderID FROM Sales.invoices
WHERE JSON_VALUE(ReturnedDeliveryData,'$.Events[1].Comment') is NOT NULL
;
-- 16. List all stock items that are manufactured in China. (country of Manufacture)

SELECT DISTINCT si.StockItemID, si.StockItemName
FROM Warehouse.StockItems si
WHERE JSON_VALUE(CustomFields,'$.CountryOfManufacture')= 'China'
;

-- 17. Total quantity of stock items sold in 2015, group by country of manufacturing.
WITH CTE AS (
SELECT ol.quantity, JSON_VALUE(CustomFields,'$.CountryOfManufacture') AS countryOfManufacture
FROM Warehouse.StockItems si
JOIN Sales.OrderLines ol ON ol.StockItemID = si.StockItemID
JOIN Sales.Orders o ON o.OrderID = ol.OrderID
WHERE YEAR(o.OrderDate) = 2015
)
SELECT SUM(quantity), CountryOfManufacture
from CTE
GROUP BY CountryOfManufacture
;

--18. CREATE a view that shows the total quantity of stock items of each stock group sold (in orders) by YEAR 2013-2017.
-- [Stock Group Name, 2013, 2014, 2015, 2016, 2017]
CREATE VIEW item_quantity_sold_by_group_2013_2017
AS
SELECT item_group,[2013], [2014], [2015], [2016], [2017]
FROM 
(SELECT max(StockGroupName) item_group, YEAR(orderdate) year_p, sum(Quantity) quantity
FROM Warehouse.StockGroups sg 
JOIN Warehouse.StockItemStockGroups sisg ON sg.StockGroupID = sisg.StockGroupID
JOIN Warehouse.StockItems si ON sisg.StockItemID = si.StockItemID
JOIN Sales.OrderLines ol ON ol.StockItemID = si.StockItemID
JOIN Sales.Orders o ON o.OrderID = ol.OrderID
group by YEAR(orderdate),sg.StockGroupID ) p
PIVOT
(
    sum(quantity) FOR year_p IN ([2013], [2014], [2015], [2016], [2017])
) pvt;


--19. CREATE a VIEW that shows the total quantity of stock items of each stock group sold (in orders) by year 2013-2017. 
-- [year, Stock Group Name1, Stock Group Name2, Stock Group Name3, … , Stock Group Name10] 

CREATE VIEW item_quantity_sold_by_group_2013_2017_switch
AS 
SELECT year_p , [T-Shirts], [USB Novelties], [Packaging Materials], [Clothing], 
[Novelty Items], [Furry Footwear], [Mugs], [Computing Novelties], [Toys]

FROM 
(SELECT max(StockGroupName) item_group, YEAR(orderdate) year_p, sum(Quantity) quantity
FROM Warehouse.StockGroups sg 
JOIN Warehouse.StockItemStockGroups sisg ON sg.StockGroupID = sisg.StockGroupID
JOIN Warehouse.StockItems si ON sisg.StockItemID = si.StockItemID
JOIN Sales.OrderLines ol ON ol.StockItemID = si.StockItemID
JOIN Sales.Orders o ON o.OrderID = ol.OrderID
group by YEAR(orderdate),sg.StockGroupID ) p
PIVOT
(
    sum(quantity) FOR item_group IN ([T-Shirts], [USB Novelties], [Packaging Materials], [Clothing], 
[Novelty Items], [Furry Footwear], [Mugs], [Computing Novelties], [Toys])
) pvt;
 
--20. CREATE a function, input: order id; return: total of that order. List invoices
--and use that function to attach the order total to the other fields of invoices. 
CREATE FUNCTION sales.invoice_order_total (@orderid INT)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @OrderTotal DECIMAL(20,2);
    SELECT @OrderTotal = SUM(Quantity * UnitPrice)
    FROM Sales.OrderLines
    WHERE OrderID = @orderid;
    RETURN @OrderTotal;
END




-- 21. CREATE a new table called ods.Orders. CREATE a stored procedure, 
-- with proper error handling and  transactions, that input is a date;
-- when Executed, it would find orders of that day, calculate order total, 
-- AND save the information (order id, order date, order total, customer id) into the new table. 
-- If a given date is already existing in the new table, throw an error and roll back.
--Excute Cute the stored procedure 5 times using different dates. 
GO
CREATE SCHEMA ods
GO
DROP TABLE ods.Orders;
CREATE TABLE ods.Orders (
    OrderID INT PRIMARY KEY NOT NULL, 
    OrderDate DATE NOT NULL, 
    OrderTotal DECIMAL(20,2), 
    CustomerID INT NOT NULL
)
GO
CREATE OR ALTER PROC store_order(@OrderDate DATETIME)
AS
    BEGIN TRY
        BEGIN TRANSACTION
        INSERT INTO ods.Orders
		SELECT o.orderID, o.OrderDate, SUM(ol.Quantity*ol.UnitPrice) OrderTotal,max( o.CustomerID)
		FROM Sales.Orders o
		LEFT JOIN Sales.OrderLines ol
		ON o.OrderID = ol.OrderID
		WHERE o.OrderDate = @OrderDate
		GROUP BY o.OrderDate,o.OrderID;
        COMMIT TRANSACTION
    END TRY  
    BEGIN CATCH   
        PRINT 'Error: Date already exists in the ods.Orders table.'
        SELECT ERROR_MESSAGE() AS error
        ROLLBACK TRANSACTION  
    END CATCH;  
GO
EXEC store_order @orderDATE = '2015-08-08';
SELECT * FROM ods.Orders ;
EXEC store_order @orderDATE = '2015-08-08';
SELECT * FROM ods.Orders; 
EXEC store_order @orderDATE = '2015-08-09';
SELECT * FROM ods.Orders ;
EXEC store_order @orderDATE = '2015-08-10';
SELECT * FROM ods.Orders ;
EXEC store_order @orderDATE = '2015-08-11';
SELECT * FROM ods.Orders ;


 --   22. CREATE a new table called ods.StockItem. It has following columns: [StockItemID], [StockItemName] ,
 -- [SupplierID] ,[ColorID] ,[UnitPackageID] ,[OuterPackageID] ,[Brand] ,[Size] ,[LeadTimeDays] ,[QuantityPerOuter] ,
 -- [IsChillerStock] ,[Barcode] ,[TaxRate]  ,[UnitPrice],[RecommendedRetailPrice] ,[TypicalWeightPerUnit] ,[MarketINgComments]  ,
 -- [internalComments], [countryOfManufacture], [Range], [Shelflife]. Migrate all the data in the original stock item table.

IF OBJECT_ID('ods.StockItem', 'U') IS NOT NULL 
    DROP TABLE ods.StockItem; 
SELECT StockItemID, StockItemName, SupplierID, ColorID, UnitPackageID, OuterPackageID, Brand, 
Size, LeadTimeDays, QuantityPerOuter, IsChillerStock, Barcode, TaxRate, UnitPrice, 
RecommendedRetailPrice, TypicalWeightPerUnit, MarketingComments, internalComments, 
JSON_VALUE(CustomFields,'$.countryOfManufacture') countryOfManufacture,
JSON_VALUE(CustomFields,'$.Range') 'Range',
JSON_VALUE(CustomFields,'$.ShelfLife') 'ShelfLife'
INTO ods.StockItem
FROM Warehouse.StockItems


 
-- 23. Rewrite your stored procedure in (21). Now with a given date, it should wipe out all the order data prior to the input date
-- and load the order data that was placed in the next 7 days following the input date.
CREATE OR ALTER  PROC store_order(@OrderDate DATETIME)
AS 
	BEGIN TRY
		BEGIN TRANSACTION
		DELETE FROM ods.Orders WHERE OrderDate < @orderdate
		SELECT o.orderID, o.OrderDate, SUM(ol.Quantity*ol.UnitPrice) OrderTotal,max( o.CustomerID)
		FROM Sales.Orders o
		LEFT JOIN Sales.OrderLines ol
		ON o.OrderID = ol.OrderID
		WHERE o.OrderDate >= @OrderDate AND o.OrderDate <= @OrderDate +7
		GROUP BY o.OrderDate,o.OrderID;
		COMMIT TRANSACTION
    END TRY
	 BEGIN CATCH   
        PRINT 'Error: Entered DATE is already existINg IN the new table.'
        SELECT ERROR_MESSAGE() AS error
        ROLLBACK TRANSACTION  
    END CATCH;  

EXEC store_order @orderDATE = '2015-08-10';
SELECT * FROM ods.Orders 
 

 
 -- 25. Revisit your answer IN (19). Convert the result in JSON string and save it to the server using TSQL FOR JSON PATH.
SELECT year_p,
ISNULL(ClothINg,0) AS 'StockGroup.ClothINg',
ISNULL([ComputINg Novelties],0) AS 'StockGroup.ComputINg Novelties',
ISNULL([Furry Footwear],0) AS 'StockGroup.Furry Footwear',
ISNULL(Mugs,0) AS 'StockGroup.Mugs',
ISNULL([Novelty Items],0) AS 'StockGroup.Novelty Items',
ISNULL([PackagINg Materials],0) AS 'StockGroup.PackagINg Materials',
ISNULL([T-Shirts],0) AS 'StockGroup.T-Shirts',
ISNULL(Toys,0) AS 'StockGroup.Toys',
ISNULL([USB Novelties],0) AS 'StockGroup.USB Novelties'
FROM item_quantity_sold_by_group_2013_2017_switch
ORDER BY year_p
FOR JSON PATH
;


 -- 26. Revisit your answer in (19). Convert the result into an XML string and save it to the server using TSQL FOR XML PATH.
SELECT year_p, 
ISNULL(ClothINg,0) AS 'StockGroup/ClothINg',
ISNULL([ComputINg Novelties],0) AS 'StockGroup/ComputINgNovelties',
ISNULL([Furry Footwear],0) AS 'StockGroup/FurryFootwear',
ISNULL(Mugs,0) AS 'StockGroup/Mugs',
ISNULL([Novelty Items],0) AS 'StockGroup/NoveltyItems',
ISNULL([PackagINg Materials],0) AS 'StockGroup/PackagINgMaterials',
ISNULL([T-Shirts],0) AS 'StockGroup/T-Shirts',
ISNULL(Toys,0) AS 'StockGroup/Toys',
ISNULL([USB Novelties],0) AS 'StockGroup/USBNovelties'
FROM item_quantity_sold_by_group_2013_2017_switch
ORDER BY year_p
FOR  XML PATH('stock_quantity_year'), ROOT('StockGroupQuantity')

