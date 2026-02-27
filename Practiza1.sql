USE AdventureWorks2022;
GO

-- EJ1

SELECT TOP 10
    p.Name AS Producto,
    SUM(sod.OrderQty) AS CantidadTotalVendida,
    CONCAT(pp.FirstName, ' ', pp.LastName) AS Cliente
FROM Sales.SalesOrderHeader soh
INNER JOIN Sales.SalesOrderDetail sod 
    ON soh.SalesOrderID = sod.SalesOrderID
INNER JOIN Production.Product p 
    ON sod.ProductID = p.ProductID
INNER JOIN Sales.Customer c 
    ON soh.CustomerID = c.CustomerID
INNER JOIN Person.Person pp 
    ON c.PersonID = pp.BusinessEntityID
WHERE YEAR(soh.OrderDate) = 2014
GROUP BY p.Name, pp.FirstName, pp.LastName
ORDER BY CantidadTotalVendida DESC;

SELECT TOP 10
    p.Name AS Producto,
    SUM(sod.OrderQty) AS CantidadTotalVendida,
    AVG(sod.UnitPrice) AS PrecioUnitarioPromedio,
    CONCAT(pp.FirstName, ' ', pp.LastName) AS Cliente
FROM Sales.SalesOrderHeader soh
INNER JOIN Sales.SalesOrderDetail sod 
    ON soh.SalesOrderID = sod.SalesOrderID
INNER JOIN Production.Product p 
    ON sod.ProductID = p.ProductID
INNER JOIN Sales.Customer c 
    ON soh.CustomerID = c.CustomerID
INNER JOIN Person.Person pp 
    ON c.PersonID = pp.BusinessEntityID
WHERE YEAR(soh.OrderDate) = 2014
AND p.ListPrice > 1000
GROUP BY p.Name, pp.FirstName, pp.LastName
ORDER BY CantidadTotalVendida DESC;


------------------------------------------------------
-- EJ2


SELECT 
    e.BusinessEntityID,
    p.FirstName,
    p.LastName,
    SUM(soh.TotalDue) AS TotalVentas
FROM Sales.SalesOrderHeader soh
INNER JOIN Sales.SalesPerson sp 
    ON soh.SalesPersonID = sp.BusinessEntityID
INNER JOIN HumanResources.Employee e 
    ON sp.BusinessEntityID = e.BusinessEntityID
INNER JOIN Person.Person p 
    ON e.BusinessEntityID = p.BusinessEntityID
INNER JOIN Sales.SalesTerritory st 
    ON soh.TerritoryID = st.TerritoryID
WHERE st.Name = 'Northwest'
GROUP BY e.BusinessEntityID, p.FirstName, p.LastName
HAVING SUM(soh.TotalDue) >
(
    SELECT AVG(VentasPorEmpleado)
    FROM (
        SELECT SUM(soh2.TotalDue) AS VentasPorEmpleado
        FROM Sales.SalesOrderHeader soh2
        INNER JOIN Sales.SalesTerritory st2 
            ON soh2.TerritoryID = st2.TerritoryID
        WHERE st2.Name = 'Northwest'
        GROUP BY soh2.SalesPersonID
    ) AS Promedio
);


WITH VentasEmpleado AS (
    SELECT 
        soh.SalesPersonID,
        SUM(soh.TotalDue) AS TotalVentas
    FROM Sales.SalesOrderHeader soh
    INNER JOIN Sales.SalesTerritory st 
        ON soh.TerritoryID = st.TerritoryID
    WHERE st.Name = 'Northwest'
    GROUP BY soh.SalesPersonID
)

SELECT 
    ve.SalesPersonID,
    p.FirstName,
    p.LastName,
    ve.TotalVentas
FROM VentasEmpleado ve
INNER JOIN Person.Person p 
    ON ve.SalesPersonID = p.BusinessEntityID
WHERE ve.TotalVentas > (SELECT AVG(TotalVentas) FROM VentasEmpleado);

------------------------------------------------------------------------
-- EJ3

SELECT 
    st.Name AS Territorio,
    YEAR(soh.OrderDate) AS Año,
    COUNT(soh.SalesOrderID) AS TotalOrdenes,
    SUM(soh.TotalDue) AS TotalVentas
FROM Sales.SalesOrderHeader soh
INNER JOIN Sales.SalesTerritory st 
    ON soh.TerritoryID = st.TerritoryID
GROUP BY st.Name, YEAR(soh.OrderDate)
HAVING COUNT(soh.SalesOrderID) > 5
AND SUM(soh.TotalDue) > 1000000
ORDER BY TotalVentas DESC;

SELECT 
    st.Name AS Territorio,
    YEAR(soh.OrderDate) AS Año,
    COUNT(soh.SalesOrderID) AS TotalOrdenes,
    SUM(soh.TotalDue) AS TotalVentas,
    STDEV(soh.TotalDue) AS DesviacionEstandar
FROM Sales.SalesOrderHeader soh
INNER JOIN Sales.SalesTerritory st 
    ON soh.TerritoryID = st.TerritoryID
GROUP BY st.Name, YEAR(soh.OrderDate)
HAVING COUNT(soh.SalesOrderID) > 5
AND SUM(soh.TotalDue) > 1000000
ORDER BY TotalVentas DESC;

------------------------------------------------------
-- EJ4
SELECT sp.BusinessEntityID
FROM Sales.SalesPerson sp
WHERE NOT EXISTS (
    SELECT p.ProductID
    FROM Production.Product p
    INNER JOIN Production.ProductSubcategory ps 
        ON p.ProductSubcategoryID = ps.ProductSubcategoryID
    INNER JOIN Production.ProductCategory pc 
        ON ps.ProductCategoryID = pc.ProductCategoryID
    WHERE pc.Name = 'Bikes'
    AND NOT EXISTS (
        SELECT 1
        FROM Sales.SalesOrderDetail sod
        INNER JOIN Sales.SalesOrderHeader soh 
            ON sod.SalesOrderID = soh.SalesOrderID
        WHERE sod.ProductID = p.ProductID
        AND soh.SalesPersonID = sp.BusinessEntityID
    )
);

SELECT sp.BusinessEntityID
FROM Sales.SalesPerson sp
WHERE NOT EXISTS (
    SELECT p.ProductID
    FROM Production.Product p
    INNER JOIN Production.ProductSubcategory ps 
        ON p.ProductSubcategoryID = ps.ProductSubcategoryID
    INNER JOIN Production.ProductCategory pc 
        ON ps.ProductCategoryID = pc.ProductCategoryID
    WHERE pc.Name = 'Clothing'
    AND NOT EXISTS (
        SELECT 1
        FROM Sales.SalesOrderDetail sod
        INNER JOIN Sales.SalesOrderHeader soh 
            ON sod.SalesOrderID = soh.SalesOrderID
        WHERE sod.ProductID = p.ProductID
        AND soh.SalesPersonID = sp.BusinessEntityID
    )
);

------------------------------------------------------------
--EJ5

EXEC sp_addlinkedserver 
    @server = 'ServidorRemoto',
    @provider = 'MSOLEDBSQL19',
    @srvproduct = '',
    @datasrc = 'DESKTOP-0I0029G\SQLEXPRESS',
    @provstr = 'Encrypt=Optional;TrustServerCertificate=Yes;';
GO

EXEC sp_addlinkedsrvlogin 
    @rmtsrvname = 'ServidorRemoto',
    @useself = 'TRUE';
GO

WITH VentasPorProducto AS (

    SELECT 
        ProductID, 
        SUM(OrderQty) AS TotalVendido
    FROM Sales.SalesOrderDetail
    GROUP BY ProductID
),
ProductosPorCategoria AS (
  
    SELECT 
        P.ProductID,
        P.Name AS NombreProducto,
        PC.Name AS NombreCategoria,
        V.TotalVendido
    FROM [ServidorRemoto].[AdventureWorks2022].[Production].[Product] P
    INNER JOIN [ServidorRemoto].[AdventureWorks2022].[Production].[ProductSubcategory] PS 
        ON P.ProductSubcategoryID = PS.ProductSubcategoryID
    INNER JOIN [ServidorRemoto].[AdventureWorks2022].[Production].[ProductCategory] PC 
        ON PS.ProductCategoryID = PC.ProductCategoryID
    INNER JOIN VentasPorProducto V 
        ON P.ProductID = V.ProductID
),
RankingProductos AS (
    SELECT 
        NombreCategoria,
        NombreProducto,
        TotalVendido,
        RANK() OVER (PARTITION BY NombreCategoria ORDER BY TotalVendido DESC) AS Rnk
    FROM ProductosPorCategoria
)
SELECT 
    NombreCategoria,
    NombreProducto,
    TotalVendido
FROM RankingProductos
WHERE Rnk = 1
ORDER BY TotalVendido DESC;