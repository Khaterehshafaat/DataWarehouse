/*
=========================================================================================
Project:        Northwind Data Warehouse (Modern BI Architecture)
Layer:          Staging Area (stage_dw)
File Name:      Northwind_Stage_LoadData.sql
Author:         Khatereh Shafaat
Date:           2026-08-08

Description:
This file contains modular scripts for the initial ingestion of data into the
Staging layer.

The scripts follow the TRUNCATE-AND-LOAD pattern (Full Load). For each staging
table, existing data is first removed and then the latest data is loaded from
the Northwind OLTP source database.

This approach ensures that the Staging layer remains a clean and up-to-date
replica of the source data.

The WITH (TABLOCK) table hint is used to improve the performance of bulk insert
operations and optimize transaction logging during data loading.

Source:
Northwind OLTP Database

Target:
stage_dw.stage.*
=========================================================================================
*/


-- 1. Clear the target table
TRUNCATE TABLE stage.northwind_categories;

-- 2. Load new data
INSERT INTO stage.northwind_categories WITH (TABLOCK) (
    category_id, 
    category_name, 
    category_desc, 
    picture, 
    dwh_inserted_at
)
SELECT 
    CategoryID, 
    CategoryName, 
    Description, 
    Picture, 
    SYSUTCDATETIME()
FROM Northwind.dbo.Categories;


-- *******************************************************
-- 1. Clear the target table
TRUNCATE TABLE stage.northwind_customers;

-- 2. Load new data
INSERT INTO stage.northwind_customers WITH (TABLOCK) (
    customer_id, 
    company_name, 
    contact_name, 
    contact_title, 
    address, 
    city, 
    region, 
    postal_code, 
    country, 
    phone, 
    fax, 
    dwh_inserted_at
)
SELECT 
    CustomerID, 
    CompanyName, 
    ContactName, 
    ContactTitle, 
    Address, 
    City, 
    Region, 
    PostalCode, 
    Country, 
    Phone, 
    Fax, 
    SYSUTCDATETIME()
FROM Northwind.dbo.Customers;


-- *******************************************************
-- 1. Clear the target table
TRUNCATE TABLE stage.northwind_employees;

-- 2. Load new data
INSERT INTO stage.northwind_employees WITH (TABLOCK) (
    employee_id, 
    last_name, 
    first_name, 
    title, 
    title_of_courtesy, 
    birth_date, 
    hire_date, 
    address, 
    city, 
    region, 
    postal_code, 
    country, 
    home_phone, 
    extension, 
    photo, 
    notes, 
    reports_to, 
    photo_path, 
    dwh_inserted_at
)
SELECT 
    EmployeeID, 
    LastName, 
    FirstName, 
    Title, 
    TitleOfCourtesy, 
    BirthDate, 
    HireDate, 
    Address, 
    City, 
    Region, 
    PostalCode, 
    Country, 
    HomePhone, 
    Extension, 
    Photo, 
    Notes, 
    ReportsTo, 
    PhotoPath, 
    SYSUTCDATETIME()
FROM Northwind.dbo.Employees;


-- *******************************************************
-- 1. Clear the target table
TRUNCATE TABLE stage.northwind_suppliers;

-- 2. Load new data
INSERT INTO stage.northwind_suppliers WITH (TABLOCK) (
    supplier_id, 
    company_name, 
    contact_name, 
    contact_title, 
    address, 
    city, 
    region, 
    postal_code, 
    country, 
    phone, 
    fax, 
    home_page, 
    dwh_inserted_at
)
SELECT 
    SupplierID, 
    CompanyName, 
    ContactName, 
    ContactTitle, 
    Address, 
    City, 
    Region, 
    PostalCode, 
    Country, 
    Phone, 
    Fax, 
    HomePage, 
    SYSUTCDATETIME()
FROM Northwind.dbo.Suppliers;


-- *******************************************************
-- 1. Clear the target table
TRUNCATE TABLE stage.northwind_products;

-- 2. Load new data
INSERT INTO stage.northwind_products WITH (TABLOCK) (
    product_id, 
    product_name, 
    supplier_id, 
    category_id, 
    quantity_per_unit, 
    unit_price, 
    units_in_stock, 
    units_on_order, 
    reorder_level, 
    discontinued, 
    dwh_inserted_at
)
SELECT 
    ProductID, 
    ProductName, 
    SupplierID, 
    CategoryID, 
    QuantityPerUnit, 
    UnitPrice, 
    UnitsInStock, 
    UnitsOnOrder, 
    ReorderLevel, 
    Discontinued, 
    SYSUTCDATETIME()
FROM Northwind.dbo.Products;


-- *******************************************************
-- 1. Clear the target table
TRUNCATE TABLE stage.northwind_shippers;

-- 2. Load new data
INSERT INTO stage.northwind_shippers WITH (TABLOCK) (
    shipper_id, 
    company_name, 
    phone, 
    dwh_inserted_at
)
SELECT 
    ShipperID, 
    CompanyName, 
    Phone, 
    SYSUTCDATETIME()
FROM Northwind.dbo.Shippers;


-- *******************************************************
-- 1. Clear the target table
TRUNCATE TABLE stage.northwind_orders;

-- 2. Load new data
INSERT INTO stage.northwind_orders WITH (TABLOCK) (
    order_id, 
    customer_id, 
    employee_id, 
    order_date, 
    required_date, 
    shipped_date, 
    ship_via, 
    freight, 
    ship_name, 
    ship_address, 
    ship_city, 
    ship_region, 
    ship_postal_code, 
    ship_country, 
    dwh_inserted_at
)
SELECT 
    OrderID, 
    CustomerID, 
    EmployeeID, 
    OrderDate, 
    RequiredDate, 
    ShippedDate, 
    ShipVia, 
    Freight, 
    ShipName, 
    ShipAddress, 
    ShipCity, 
    ShipRegion, 
    ShipPostalCode, 
    ShipCountry, 
    SYSUTCDATETIME()
FROM Northwind.dbo.Orders;


-- *******************************************************
-- 1. Clear the target table
TRUNCATE TABLE stage.northwind_order_details;

-- 2. Load new data
INSERT INTO stage.northwind_order_details WITH (TABLOCK) (
    order_id, 
    product_id, 
    unit_price, 
    quantity, 
    discount, 
    dwh_inserted_at
)
SELECT 
    OrderID, 
    ProductID, 
    UnitPrice, 
    Quantity, 
    Discount, 
    SYSUTCDATETIME()
FROM Northwind.dbo.[Order Details];

-- *******************************************************
