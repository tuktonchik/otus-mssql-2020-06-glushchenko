--1. Все товары, в названии которых есть "urgent" или название начинается с "Animal"
--Таблицы: Warehouse.StockItems.

SELECT *
	FROM [WideWorldImporters].[Warehouse].[StockItems]
WHERE 
	StockItemName LIKE '%urgent%' OR 
	StockItemName LIKE 'Animal%';

--2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders). Сделать через JOIN, с подзапросом задание принято не будет.
--Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.

SELECT Suppliers.*
  FROM [WideWorldImporters].[Purchasing].[Suppliers] AS Suppliers
LEFT JOIN [WideWorldImporters].[Purchasing].[PurchaseOrders] AS PurchaseOrders
  ON Suppliers.SupplierID = PurchaseOrders.SupplierID
WHERE PurchaseOrders.SupplierID IS NULL

--3. Заказы (Orders) с ценой товара более 100$ либо количеством единиц товара более 20 штук и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
--Вывести:
--* OrderID
--* дату заказа в формате ДД.ММ.ГГГГ
--* название месяца, в котором была продажа
--* номер квартала, к которому относится продажа
--* треть года, к которой относится дата продажи (каждая треть по 4 месяца)
--* имя заказчика (Customer)
--Добавьте вариант этого запроса с постраничной выборкой, пропустив первую 1000 и отобразив следующие 100 записей. Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).
--Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.

DECLARE
	@pagesize BIGINT = 100,
	@pagenum BIGINT = 11;

SELECT Orders.[OrderID]
      ,CONVERT(nvarchar, Orders.[OrderDate], 104) AS 'дата заказа в формате ДД.ММ.ГГГГ'
	  ,FORMAT(Orders.[OrderDate], 'MMMM') AS 'название месяца, в котором была продажа'
	  ,DATEPART(QUARTER, Orders.[OrderDate]) AS 'номер квартала, к которому относится продажа'
	  ,CASE WHEN DATEPART(MONTH, Orders.[OrderDate]) <= 4
			THEN 1
			WHEN DATEPART(MONTH, Orders.[OrderDate]) > 4 AND DATEPART(MONTH, Orders.[OrderDate]) <= 8
			THEN 2
			WHEN DATEPART(MONTH, Orders.[OrderDate]) > 8
			THEN 3
		END AS 'треть года, к которой относится дата продажи (каждая треть по 4 месяца)'
      ,Customers.[CustomerName]
  FROM [WideWorldImporters].[Sales].[Orders] AS Orders
INNER JOIN [WideWorldImporters].[Sales].[OrderLines] AS OrderLines
  ON Orders.[OrderID] = OrderLines.[OrderID]
INNER JOIN [WideWorldImporters].[Sales].[Customers] AS Customers
  ON Orders.[CustomerID] = Customers.[CustomerID]
  WHERE OrderLines.[UnitPrice] > 100 OR (OrderLines.[Quantity] > 20 AND OrderLines.[PickingCompletedWhen] IS NOT NULL)
  ORDER BY
	DATEPART(QUARTER, Orders.[OrderDate]),
	CASE WHEN DATEPART(MONTH, Orders.[OrderDate]) <= 4
		THEN 1
		WHEN DATEPART(MONTH, Orders.[OrderDate]) > 4 AND DATEPART(MONTH, Orders.[OrderDate]) <= 8
		THEN 2
		WHEN DATEPART(MONTH, Orders.[OrderDate]) > 8
		THEN 3
	END,
	Orders.[OrderDate]
  OFFSET (@pagenum - 1) * @pagesize ROWS FETCH FIRST @pagesize ROWS ONLY;

--4. Заказы поставщикам (Purchasing.Suppliers), которые были исполнены в январе 2014 года с доставкой Air Freight или Refrigerated Air Freight (DeliveryMethodName).
--Вывести:
--* способ доставки (DeliveryMethodName)
--* дата доставки
--* имя поставщика
--* имя контактного лица принимавшего заказ (ContactPerson)
--Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.

SET DATEFORMAT ymd
SELECT DeliveryMethods.[DeliveryMethodName] AS 'способ доставки'
	  ,PurchaseOrders.[OrderDate] AS 'дата доставки'
	  ,Suppliers.[SupplierName] AS 'имя поставщика'
	  ,People.[PreferredName] AS 'имя контактного лица принимавшего заказ'
	FROM [WideWorldImporters].[Purchasing].[PurchaseOrders] AS PurchaseOrders
INNER JOIN [WideWorldImporters].[Purchasing].[Suppliers] AS Suppliers
	ON PurchaseOrders.[SupplierID] = Suppliers.[SupplierID]
INNER JOIN [WideWorldImporters].[Application].[DeliveryMethods] AS DeliveryMethods
	ON DeliveryMethods.[DeliveryMethodID] = PurchaseOrders.[DeliveryMethodID]
INNER JOIN [WideWorldImporters].[Application].[People] AS People
	ON People.[PersonID] = PurchaseOrders.[ContactPersonID]
WHERE 
(DeliveryMethods.[DeliveryMethodName] = 'Air Freight' OR DeliveryMethods.[DeliveryMethodName] = 'Refrigerated Air Freight')
AND PurchaseOrders.[OrderDate] >= '20140101' AND PurchaseOrders.[OrderDate] < '20140201'
AND PurchaseOrders.[IsOrderFinalized] = 1


--5. Десять последних продаж (по дате) с именем клиента и именем сотрудника, который оформил заказ (SalespersonPerson).
SELECT TOP (10) Orders.[OrderDate] AS 'дата продажи',
		Customers.[CustomerName] AS 'имя клиента',
		People.[PreferredName] AS 'имя сотрудника'
  FROM [WideWorldImporters].[Sales].[Orders] AS Orders
INNER JOIN [WideWorldImporters].[Sales].[Customers] AS Customers
	ON Orders.[CustomerID] = Customers.[CustomerID]
INNER JOIN [WideWorldImporters].[Application].[People] AS People
	ON People.[PersonID] = Orders.[SalespersonPersonID]
  ORDER BY Orders.[OrderDate] DESC


--6. Все ид и имена клиентов и их контактные телефоны, которые покупали товар Chocolate frogs 250g. Имя товара смотреть в Warehouse.StockItems.
SELECT DISTINCT Customers.[CustomerID]
      ,Customers.[CustomerName]
	  ,Customers.[PhoneNumber]
	  ,Customers.[FaxNumber]
  FROM [WideWorldImporters].[Sales].[Orders] AS Orders
INNER JOIN [WideWorldImporters].[Sales].[OrderLines] AS OrderLines
  ON Orders.[OrderID] = OrderLines.[OrderID]
INNER JOIN [WideWorldImporters].[Sales].[Customers] AS Customers
  ON Orders.[CustomerID] = Customers.[CustomerID]
INNER JOIN [WideWorldImporters].[Warehouse].[StockItems] AS StockItems
  ON OrderLines.[StockItemID] = StockItems.[StockItemID]
  WHERE StockItems.[StockItemName] = 'Chocolate frogs 250g'