/*******************************************************************************
SQL_Foundations_ETL.sql
*******************************************************************************/


/*
--------------------------------------------------------------------------------
1. Transaction Management
--------------------------------------------------------------------------------

Transaction management is important in ETL processes because it helps ensure
data consistency. The goal is to follow an "All or Nothing" approach:
either all changes are successfully applied, or all changes are rolled back.
*/


-- A) SET XACT_ABORT ON
-- Ensures that if a run-time error occurs during a transaction,
-- SQL Server automatically terminates and rolls back the transaction.
SET XACT_ABORT ON;


-- B) TRY-CATCH Pattern
-- The TRY-CATCH structure provides error handling and supports the
-- "All or Nothing" principle during ETL operations.

BEGIN TRY

    -- Start the transaction
    BEGIN TRANSACTION;

    -- ETL operations (INSERT / UPDATE / DELETE) should be placed here.
    PRINT 'Transaction Started... Loading Data...';

    -- Example:
    -- UPDATE sale.dim_product
    -- SET current_unit_price = 10
    -- WHERE product_id = 1;


    -- If execution reaches this point, no error has occurred.
    -- COMMIT TRANSACTION permanently applies all changes.
    COMMIT TRANSACTION;

    PRINT 'Transaction Committed Successfully.';

END TRY


BEGIN CATCH

    -- If an error occurs, execution moves to the CATCH block.


    -- C) @@TRANCOUNT
    -- Checks whether an active transaction still exists.
    -- If a transaction is open, it should be rolled back.
    IF @@TRANCOUNT > 0
    BEGIN

        -- D) ROLLBACK TRANSACTION
        -- Cancels all changes made within the current transaction.
        ROLLBACK TRANSACTION;

        PRINT 'Error Occurred! Transaction Rolled Back.';

    END;


    -- E) THROW
    -- Re-raises the original error, including the original error message,
    -- error number, and line information.
    -- This allows the calling process or user to receive the actual error.
    THROW;

END CATCH;


/*
--------------------------------------------------------------------------------
2. NULL Handling and Data Cleaning
--------------------------------------------------------------------------------

ETL processes often need to handle missing values, empty strings,
and inconsistent text values before loading data into the target tables.
*/


-- F) NULLIF
-- Compares two expressions.
-- If they are equal, NULLIF returns NULL.
--
-- ETL use case:
-- Converting an empty string ('') into a real NULL value.

SELECT
    NULLIF(N'', N'') AS Result_is_NULL;
-- Result: NULL


-- G) COALESCE
-- Returns the first non-NULL value from the list of expressions.
--
-- ETL use case:
-- Replacing missing values with a meaningful default value,
-- such as 'Unknown'.

SELECT
    COALESCE(NULL, NULL, N'Baran', N'Unknown') AS First_Non_Null;
-- Result: 'Baran'


/*
--------------------------------------------------------------------------------
3. The Golden Pattern for String Cleaning
--------------------------------------------------------------------------------

The following pattern is commonly useful in ETL data cleaning:

    COALESCE(NULLIF(LTRIM(RTRIM(Column)), ''), 'Unknown')

It handles:
    1. Leading and trailing spaces
    2. Empty strings
    3. NULL values
    4. Replacement of missing values with a default value
*/


-- Step 1: LTRIM and RTRIM
-- Remove leading and trailing spaces from the value.


-- Step 2: NULLIF
-- If the cleaned string is empty, convert it to NULL.


-- Step 3: COALESCE
-- If the value is NULL, replace it with 'Unknown'.


/*
Formula:

COALESCE(
    NULLIF(LTRIM(RTRIM(Column)), ''),
    'Unknown'
)
*/


-- Practical example using sample data:

SELECT
    RawValue,

    COALESCE(
        NULLIF(LTRIM(RTRIM(RawValue)), ''),
        N'Unknown'
    ) AS CleanedValue

FROM
(
    SELECT N'   021-1234   ' AS RawValue   -- Leading/trailing spaces
    UNION ALL
    SELECT N''                              -- Empty string
    UNION ALL
    SELECT NULL                             -- NULL value
    UNION ALL
    SELECT N'Actual Data'                   -- Valid value
) AS SampleTable;


/*
--------------------------------------------------------------------------------
4. ETL Summary
--------------------------------------------------------------------------------

Key practices demonstrated in this script:

1. Use SET XACT_ABORT ON together with TRY-CATCH to protect Dimension
   and Fact table loads from partial transactions.

2. Use COMMIT TRANSACTION when all ETL operations complete successfully.

3. Use ROLLBACK TRANSACTION when an error occurs.

4. Use THROW to return the original error to the calling process.

5. Use NULLIF to convert empty strings into NULL values.

6. Use COALESCE to replace NULL values with meaningful defaults,
   such as 'Unknown'.

7. Use LTRIM and RTRIM together with NULLIF and COALESCE to clean
   inconsistent text values before loading them into the Data Warehouse.
--------------------------------------------------------------------------------
*/
