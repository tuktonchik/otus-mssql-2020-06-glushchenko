--1. ��� ������, � �������� ������� ���� "urgent" ��� �������� ���������� � "Animal"
--�������: Warehouse.StockItems.

SELECT *
	FROM [WideWorldImporters].[Warehouse].[StockItems]
WHERE 
	StockItemName LIKE '%urgent%' OR 
	StockItemName LIKE 'Animal%';

--2. ����������� (Suppliers), � ������� �� ���� ������� �� ������ ������ (PurchaseOrders). ������� ����� JOIN, � ����������� ������� ������� �� �����.
--�������: Purchasing.Suppliers, Purchasing.PurchaseOrders.

SELECT Suppliers.*
  FROM [WideWorldImporters].[Purchasing].[Suppliers] AS Suppliers
LEFT JOIN [WideWorldImporters].[Purchasing].[PurchaseOrders] AS PurchaseOrders
  ON Suppliers.SupplierID = PurchaseOrders.SupplierID
WHERE PurchaseOrders.SupplierID IS NULL

--3. ������ (Orders) � ����� ������ ����� 100$ ���� ����������� ������ ������ ����� 20 ���� � �������������� ����� ������������ ����� ������ (PickingCompletedWhen).
--�������:
--* OrderID
--* ���� ������ � ������� ��.��.����
--* �������� ������, � ������� ���� �������
--* ����� ��������, � �������� ��������� �������
--* ����� ����, � ������� ��������� ���� ������� (������ ����� �� 4 ������)
--* ��� ��������� (Customer)
--�������� ������� ����� ������� � ������������ ��������, ��������� ������ 1000 � ��������� ��������� 100 �������. ���������� ������ ���� �� ������ ��������, ����� ����, ���� ������ (����� �� �����������).
--�������: Sales.Orders, Sales.OrderLines, Sales.Customers.

DECLARE
	@pagesize BIGINT = 100,
	@pagenum BIGINT = 11;

SELECT Orders.[OrderID]
      ,CONVERT(nvarchar, Orders.[OrderDate], 104) AS '���� ������ � ������� ��.��.����'
	  ,FORMAT(Orders.[OrderDate], 'MMMM') AS '�������� ������, � ������� ���� �������'
	  ,DATEPART(QUARTER, Orders.[OrderDate]) AS '����� ��������, � �������� ��������� �������'
	  ,CASE WHEN DATEPART(MONTH, Orders.[OrderDate]) <= 4
			THEN 1
			WHEN DATEPART(MONTH, Orders.[OrderDate]) > 4 AND DATEPART(MONTH, Orders.[OrderDate]) <= 8
			THEN 2
			WHEN DATEPART(MONTH, Orders.[OrderDate]) > 8
			THEN 3
		END AS '����� ����, � ������� ��������� ���� ������� (������ ����� �� 4 ������)'
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

--4. ������ ����������� (Purchasing.Suppliers), ������� ���� ��������� � ������ 2014 ���� � ��������� Air Freight ��� Refrigerated Air Freight (DeliveryMethodName).
--�������:
--* ������ �������� (DeliveryMethodName)
--* ���� ��������
--* ��� ����������
--* ��� ����������� ���� ������������ ����� (ContactPerson)
--�������: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.

SET DATEFORMAT ymd
SELECT DeliveryMethods.[DeliveryMethodName] AS '������ ��������'
	  ,PurchaseOrders.[OrderDate] AS '���� ��������'
	  ,Suppliers.[SupplierName] AS '��� ����������'
	  ,People.[PreferredName] AS '��� ����������� ���� ������������ �����'
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


--5. ������ ��������� ������ (�� ����) � ������ ������� � ������ ����������, ������� ������� ����� (SalespersonPerson).
SELECT TOP (10) Orders.[OrderDate] AS '���� �������',
		Customers.[CustomerName] AS '��� �������',
		People.[PreferredName] AS '��� ����������'
  FROM [WideWorldImporters].[Sales].[Orders] AS Orders
INNER JOIN [WideWorldImporters].[Sales].[Customers] AS Customers
	ON Orders.[CustomerID] = Customers.[CustomerID]
INNER JOIN [WideWorldImporters].[Application].[People] AS People
	ON People.[PersonID] = Orders.[SalespersonPersonID]
  ORDER BY Orders.[OrderDate] DESC


--6. ��� �� � ����� �������� � �� ���������� ��������, ������� �������� ����� Chocolate frogs 250g. ��� ������ �������� � Warehouse.StockItems.
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