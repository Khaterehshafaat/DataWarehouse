/*
=========================================================================================
Project:        Northwind Data Warehouse (Modern BI Architecture)
Layer:          Staging Area (ETL Automation)
Object Name:    stage.usp_load_stg_northwind_full
Author:         Khatereh Shafaat
Date:           2024-05-20

Description:
This stored procedure serves as the main orchestration process for the
Northwind Staging layer.

Key Features:
    - Implements TRY...CATCH blocks for robust error handling.
    - Records execution results, including rows inserted, execution status,
      error messages, and timestamps, in the stage.northwind_etrun_log table.
    - Uses UTC timestamps through SYSUTCDATETIME() to ensure global consistency.
    - Performs a full load by truncating each staging table before loading
      the latest data from the Northwind OLTP database.
    - Uses TABLOCK to improve bulk insert performance.

Execution:
    EXEC stage.usp_load_stg_northwind_full;
=========================================================================================
*/

USE stage_dw;
GO

CREATE OR ALTER PROCEDURE stage.usp_load_stg_northwind_full
AS
BEGIN

    -- Suppress row count messages to reduce unnecessary output
    SET NOCOUNT ON;

    -- Declare variables for execution tracking and audit logging
    DECLARE @StartTime DATETIME2(3);
    DECLARE @EndTime DATETIME2(3);
    DECLARE @RowsInserted INT;
    DECLARE @CurrentTime DATETIME2(3);

    PRINT '==================================================';
    PRINT 'Starting Full Load Process from Northwind to Stage';
    PRINT '==================================================';


    ------------------------------------------------------------------
    -- 1. Extract and Load: stage.northwind_categories
    ------------------------------------------------------------------
    BEGIN TRY

        SET @StartTime = SYSUTCDATETIME();
        SET @CurrentTime = SYSUTCDATETIME();

        -- Clear the target staging table before loading new data
        TRUNCATE TABLE stage.northwind_categories;

        -- Bulk insert using TABLOCK for improved loading performance
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
            @CurrentTime
        FROM Northwind.dbo.Categories;

        -- Capture the number of successfully inserted rows
        SET @RowsInserted = @@ROWCOUNT;
        SET @EndTime = SYSUTCDATETIME();

        -- Record successful execution in the ETL execution log
        INSERT INTO stage.northwind_etrun_log
            (package_name, table_name, rows_inserted, status, start_time, end_time)
        VALUES
            ('usp_load_stg_northwind_full',
             'stage.northwind_categories',
             @RowsInserted,
             'SUCCESS',
             @StartTime,
             @EndTime);

        PRINT 'Table stage.northwind_categories loaded successfully. Rows: '
              + CAST(@RowsInserted AS VARCHAR);

    END TRY

    BEGIN CATCH

        SET @EndTime = SYSUTCDATETIME();

        -- Record execution failure and error details in the ETL log
        INSERT INTO stage.northwind_etrun_log
            (package_name, table_name, rows_inserted, status, error_message, start_time, end_time)
        VALUES
            ('usp_load_stg_northwind_full',
             'stage.northwind_categories',
             0,
             'ERROR',
             ERROR_MESSAGE(),
             @StartTime,
             @EndTime);

        PRINT 'Error loading stage.northwind_categories: ' + ERROR_MESSAGE();

    END CATCH;


    ------------------------------------------------------------------
    -- 2. Extract and Load: stage.northwind_customers
    ------------------------------------------------------------------
    BEGIN TRY

        SET @StartTime = SYSUTCDATETIME();
        SET @CurrentTime = SYSUTCDATETIME();

        -- Clear the target staging table
        TRUNCATE TABLE stage.northwind_customers;

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
            @CurrentTime
        FROM Northwind.dbo.Customers;

        -- Capture the number of inserted rows
        SET @RowsInserted = @@ROWCOUNT;
        SET @EndTime = SYSUTCDATETIME();

        -- Log successful execution
        INSERT INTO stage.northwind_etrun_log
            (package_name, table_name, rows_inserted, status, start_time, end_time)
        VALUES
            ('usp_load_stg_northwind_full',
             'stage.northwind_customers',
             @RowsInserted,
             'SUCCESS',
             @StartTime,
             @EndTime);

        PRINT 'Table stage.northwind_customers loaded successfully. Rows: '
              + CAST(@RowsInserted AS VARCHAR);

    END TRY

    BEGIN CATCH

        SET @EndTime = SYSUTCDATETIME();

        -- Log execution failure
        INSERT INTO stage.northwind_etrun_log
            (package_name, table_name, rows_inserted, status, error_message, start_time, end_time)
        VALUES
            ('usp_load_stg_northwind_full',
             'stage.northwind_customers',
             0,
             'ERROR',
             ERROR_MESSAGE(),
             @StartTime,
             @EndTime);

        PRINT 'Error loading stage.northwind_customers: ' + ERROR_MESSAGE();

    END CATCH;


    ------------------------------------------------------------------
    -- 3. Extract and Load: stage.northwind_employees
    ------------------------------------------------------------------
    BEGIN TRY

        SET @StartTime = SYSUTCDATETIME();
        SET @CurrentTime = SYSUTCDATETIME();

        -- Clear the target staging table
        TRUNCATE TABLE stage.northwind_employees;

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
            @CurrentTime
        FROM Northwind.dbo.Employees;

        -- Capture the number of inserted rows
        SET @RowsInserted = @@ROWCOUNT;
        SET @EndTime = SYSUTCDATETIME();

        -- Log successful execution
        INSERT INTO stage.northwind_etrun_log
            (package_name, table_name, rows_inserted, status, start_time, end_time)
        VALUES
            ('usp_load_stg_northwind_full',
             'stage.northwind_employees',
             @RowsInserted,
             'SUCCESS',
             @StartTime,
             @EndTime);

        PRINT 'Table stage.northwind_employees loaded successfully. Rows: '
              + CAST(@RowsInserted AS VARCHAR);

    END TRY

    BEGIN CATCH

        SET @EndTime = SYSUTCDATETIME();

        -- Log execution failure
        INSERT INTO stage.northwind_etrun_log
            (package_name, table_name, rows_inserted, status, error_message, start_time, end_time)
        VALUES
            ('usp_load_stg_northwind_full',
             'stage.northwind_employees',
             0,
             'ERROR',
             ERROR_MESSAGE(),
             @StartTime,
             @EndTime);

        PRINT 'Error loading stage.northwind_employees: ' + ERROR_MESSAGE();

    END CATCH;


    ------------------------------------------------------------------
    -- 4. Extract and Load: stage.northwind_suppliers
    ------------------------------------------------------------------
    BEGIN TRY

        SET @StartTime = SYSUTCDATETIME();
        SET @CurrentTime = SYSUTCDATETIME();

        -- Clear the target staging table
        TRUNCATE TABLE stage.northwind_suppliers;

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
            @CurrentTime
        FROM Northwind.dbo.Suppliers;

        -- Capture the number of inserted rows
        SET @RowsInserted = @@ROWCOUNT;
        SET @EndTime = SYSUTCDATETIME();

        -- Log successful execution
        INSERT INTO stage.northwind_etrun_log
            (package_name, table_name, rows_inserted, status, start_time, end_time)
        VALUES
            ('usp_load_stg_northwind_full',
             'stage.northwind_suppliers',
             @RowsInserted,
             'SUCCESS',
             @StartTime,
             @EndTime);

        PRINT 'Table stage.northwind_suppliers loaded successfully. Rows: '
              + CAST(@RowsInserted AS VARCHAR);

    END TRY

    BEGIN CATCH

        SET @EndTime = SYSUTCDATETIME();

        -- Log execution failure
        INSERT INTO stage.northwind_etrun_log
            (package_name, table_name, rows_inserted, status, error_message, start_time, end_time)
        VALUES
            ('usp_load_stg_northwind_full',
             'stage.northwind_suppliers',
             0,
             'ERROR',
             ERROR_MESSAGE(),
             @StartTime,
             @EndTime);

        PRINT 'Error loading stage.northwind_suppliers: ' + ERROR_MESSAGE();

    END CATCH;


    ------------------------------------------------------------------
    -- 5. Extract and Load: stage.northwind_products
    ------------------------------------------------------------------
    BEGIN TRY

        SET @StartTime = SYSUTCDATETIME();
        SET @CurrentTime = SYSUTCDATETIME();

        -- Clear the target staging table
        TRUNCATE TABLE stage.northwind_products;

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
            @CurrentTime
        FROM Northwind.dbo.Products;

        -- Capture the number of inserted rows
        SET @RowsInserted = @@ROWCOUNT;
        SET @EndTime = SYSUTCDATETIME();

        -- Log successful execution
        INSERT INTO stage.northwind_etrun_log
            (package_name, table_name, rows_inserted, status, start_time, end_time)
        VALUES
            ('usp_load_stg_northwind_full',
             'stage.northwind_products',
             @RowsInserted,
             'SUCCESS',
             @StartTime,
             @EndTime);

        PRINT 'Table stage.northwind_products loaded successfully. Rows: '
              + CAST(@RowsInserted AS VARCHAR);

    END TRY

    BEGIN CATCH

        SET @EndTime = SYSUTCDATETIME();

        -- Log execution failure
        INSERT INTO stage.northwind_etrun_log
            (package_name, table_name, rows_inserted, status, error_message, start_time, end_time)
        VALUES
            ('usp_load_stg_northwind_full',
             'stage.northwind_products',
             0,
             'ERROR',
             ERROR_MESSAGE(),
             @StartTime,
             @EndTime);

        PRINT 'Error loading stage.northwind_products: ' + ERROR_MESSAGE();

    END CATCH;


    ------------------------------------------------------------------
    -- 6. Extract and Load: stage.northwind_shippers
    ------------------------------------------------------------------
    BEGIN TRY

        SET @StartTime = SYSUTCDATETIME();
        SET @CurrentTime = SYSUTCDATETIME();

        -- Clear the target staging table
        TRUNCATE TABLE stage.northwind_shippers;

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
            @CurrentTime
        FROM Northwind.dbo.Shippers;

        -- Capture the number of inserted rows
        SET @RowsInserted = @@ROWCOUNT;
        SET @EndTime = SYSUTCDATETIME();

        -- Log successful execution
        INSERT INTO stage.northwind_etrun_log
            (package_name, table_name, rows_inserted, status, start_time, end_time)
        VALUES
            ('usp_load_stg_northwind_full',
             'stage.northwind_shippers',
             @RowsInserted,
             'SUCCESS',
             @StartTime,
             @EndTime);

        PRINT 'Table stage.northwind_shippers loaded successfully. Rows: '
              + CAST(@RowsInserted AS VARCHAR);

    END TRY

    BEGIN CATCH

        SET @EndTime = SYSUTCDATETIME();

        -- Log execution failure
        INSERT INTO stage.northwind_etrun_log
            (package_name, table_name, rows_inserted, status, error_message, start_time, end_time)
        VALUES
            ('usp_load_stg_northwind_full',
             'stage.northwind_shippers',
             0,
             'ERROR',
             ERROR_MESSAGE(),
             @StartTime,
             @EndTime);

        PRINT 'Error loading stage.northwind_shippers: ' + ERROR_MESSAGE();

    END CATCH;


    ------------------------------------------------------------------
    -- 7. Extract and Load: stage.northwind_orders
    ------------------------------------------------------------------
    BEGIN TRY

        SET @StartTime = SYSUTCDATETIME();
        SET @CurrentTime = SYSUTCDATETIME();

        -- Clear the target staging table
        TRUNCATE TABLE stage.northwind_orders;

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
            @CurrentTime
        FROM Northwind.dbo.Orders;

        -- Capture the number of inserted rows
        SET @RowsInserted = @@ROWCOUNT;
        SET @EndTime = SYSUTCDATETIME();

        -- Log successful execution
        INSERT INTO stage.northwind_etrun_log
            (package_name, table_name, rows_inserted, status, start_time, end_time)
        VALUES
            ('usp_load_stg_northwind_full',
             'stage.northwind_orders',
             @RowsInserted,
             'SUCCESS',
             @StartTime,
             @EndTime);

        PRINT 'Table stage.northwind_orders loaded successfully. Rows: '
              + CAST(@RowsInserted AS VARCHAR);

    END TRY

    BEGIN CATCH

        SET @EndTime = SYSUTCDATETIME();

        -- Log execution failure
        INSERT INTO stage.northwind_etrun_log
            (package_name, table_name, rows_inserted, status, error_message, start_time, end_time)
        VALUES
            ('usp_load_stg_northwind_full',
             'stage.northwind_orders',
             0,
             'ERROR',
             ERROR_MESSAGE(),
             @StartTime,
             @EndTime);

        PRINT 'Error loading stage.northwind_orders: ' + ERROR_MESSAGE();

    END CATCH;


    ------------------------------------------------------------------
    -- 8. Extract and Load: stage.northwind_order_details
    ------------------------------------------------------------------
    BEGIN TRY

        SET @StartTime = SYSUTCDATETIME();
        SET @CurrentTime = SYSUTCDATETIME();

        -- Clear the target staging table
        TRUNCATE TABLE stage.northwind_order_details;

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
            @CurrentTime
        FROM Northwind.dbo.[Order Details];

        -- Capture the number of inserted rows
        SET @RowsInserted = @@ROWCOUNT;
        SET @EndTime = SYSUTCDATETIME();

        -- Log successful execution
        INSERT INTO stage.northwind_etrun_log
            (package_name, table_name, rows_inserted, status, start_time, end_time)
        VALUES
            ('usp_load_stg_northwind_full',
             'stage.northwind_order_details',
             @RowsInserted,
             'SUCCESS',
             @StartTime,
             @EndTime);

        PRINT 'Table stage.northwind_order_details loaded successfully. Rows: '
              + CAST(@RowsInserted AS VARCHAR);

    END TRY

    BEGIN CATCH

        SET @EndTime = SYSUTCDATETIME();

        -- Log execution failure
        INSERT INTO stage.northwind_etrun_log
            (package_name, table_name, rows_inserted, status, error_message, start_time, end_time)
        VALUES
            ('usp_load_stg_northwind_full',
             'stage.northwind_order_details',
             0,
             'ERROR',
             ERROR_MESSAGE(),
             @StartTime,
             @EndTime);

        PRINT 'Error loading stage.northwind_order_details: ' + ERROR_MESSAGE();

    END CATCH;


    PRINT '==================================================';
    PRINT 'Full Load Process Completed Successfully.';
    PRINT '==================================================';

END;
GO
