/*******************************************************************************
Project:        Northwind Data Warehouse
Layer:          DDS - Sales Data Mart
File Name:      07-SP_Load_DDS_Fact.sql
Object Name:    sale.usp_load_fact_order_full
Author:         Khatereh Shafaat

Description:
    Performs a Full Load for the Sales Order Fact table.

Full Load Strategy:
    1. Deletes all existing records from sale.fact_order.
    2. Extracts Order Headers and Order Details from Stage.
    3. Deduplicates source records.
    4. Applies data quality transformations.
    5. Resolves Dimension Surrogate Keys.
    6. Maps Gregorian dates to the shared Date Dimension.
    7. Calculates sales measures.
    8. Inserts transformed rows at the defined Fact grain.

Fact Grain:
    One row per Order ID + Product ID.

Date Dimension:
    [dds].[dbo].[dim_date]

Date Lookup:
    Stage Order Date -> dim_date.MiladiDate
    Stored Fact Key  -> dim_date.MiladiDateKey

Transformation Techniques Demonstrated:
    1. Deduplication
    2. Filtering (Rows and Columns)
    3. Cleaning and Mapping
    4. Value Standardization
    5. Joining
    6. Aggregation
    7. Deriving New Values
    8. Removing Unwanted Spaces
    9. Handling Missing Values

Prerequisite:
    EXEC sale.usp_load_dim_northwind;

Execution:
    EXEC sale.usp_load_fact_order_full;
*******************************************************************************/

USE dds;
GO


CREATE OR ALTER PROCEDURE sale.usp_load_fact_order_full
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @load_datetime DATETIME2(3) = SYSUTCDATETIME();

    BEGIN TRY

        BEGIN TRANSACTION;


        /*========================================================================
          1. FULL LOAD
          ------------------------------------------------------------------------
          Remove all existing Fact records before rebuilding the table.
        =========================================================================*/

        TRUNCATE TABLE sale.fact_order;


        /*========================================================================
          2. PREPARE ORDER HEADERS
          ------------------------------------------------------------------------
          Deduplication:
              Retain the latest Stage record for each Order ID.

          Cleaning:
              - Trim Customer ID.
              - Standardize shipping geography.
              - Handle missing freight.
              - Convert dates to DATE.
        =========================================================================*/

        ;WITH order_ranked AS
        (
            SELECT
                order_id,
                customer_id,
                employee_id,
                order_date,
                required_date,
                shipped_date,
                ship_via,
                freight,
                ship_country,
                ship_region,
                ship_city,
                ship_postal_code,
                dwh_inserted_at,

                ROW_NUMBER() OVER
                (
                    PARTITION BY order_id
                    ORDER BY dwh_inserted_at DESC
                ) AS row_number_value

            FROM stage_dw.stage.northwind_orders

            WHERE order_id IS NOT NULL
        ),

        orders_cleaned AS
        (
            SELECT
                order_id,

                LTRIM(RTRIM(customer_id)) AS customer_id,

                employee_id,
                ship_via,

                CAST(order_date AS DATE) AS order_date,
                CAST(required_date AS DATE) AS required_date,
                CAST(shipped_date AS DATE) AS shipped_date,

                COALESCE
                (
                    CAST(freight AS DECIMAL(19,4)),
                    0
                ) AS freight_amount,

                COALESCE
                (
                    NULLIF(UPPER(LTRIM(RTRIM(ship_country))), ''),
                    N'UNKNOWN'
                ) AS ship_country,

                COALESCE
                (
                    NULLIF(UPPER(LTRIM(RTRIM(ship_region))), ''),
                    N'UNKNOWN'
                ) AS ship_region,

                COALESCE
                (
                    NULLIF(UPPER(LTRIM(RTRIM(ship_city))), ''),
                    N'UNKNOWN'
                ) AS ship_city,

                COALESCE
                (
                    NULLIF(UPPER(LTRIM(RTRIM(ship_postal_code))), ''),
                    N'UNKNOWN'
                ) AS ship_postal_code

            FROM order_ranked

            WHERE row_number_value = 1
        ),


        /*========================================================================
          3. PREPARE ORDER DETAILS
          ------------------------------------------------------------------------
          Deduplication:
              Retain the latest record for each Order ID + Product ID.

          Cleaning:
              - Missing Unit Price -> 0
              - Missing Quantity -> 0
              - Negative Discount -> 0
              - Discount > 1 -> 1
        =========================================================================*/

        line_ranked AS
        (
            SELECT
                order_id,
                product_id,
                unit_price,
                quantity,
                discount,
                dwh_inserted_at,

                ROW_NUMBER() OVER
                (
                    PARTITION BY order_id, product_id
                    ORDER BY dwh_inserted_at DESC
                ) AS row_number_value

            FROM stage_dw.stage.northwind_order_details

            WHERE order_id IS NOT NULL
              AND product_id IS NOT NULL
        ),

        lines_cleaned AS
        (
            SELECT
                order_id,
                product_id,

                COALESCE
                (
                    CAST(unit_price AS DECIMAL(19,4)),
                    0
                ) AS unit_price,

                COALESCE
                (
                    CAST(quantity AS INT),
                    0
                ) AS quantity,

                CASE
                    WHEN COALESCE
                    (
                        CAST(discount AS DECIMAL(9,6)),
                        0
                    ) < 0
                        THEN 0

                    WHEN COALESCE
                    (
                        CAST(discount AS DECIMAL(9,6)),
                        0
                    ) > 1
                        THEN 1

                    ELSE COALESCE
                    (
                        CAST(discount AS DECIMAL(9,6)),
                        0
                    )
                END AS discount_rate

            FROM line_ranked

            WHERE row_number_value = 1
        ),


        /*========================================================================
          4. AGGREGATE ORDER LINES
          ------------------------------------------------------------------------
          Fact Grain:
              One row per Order ID + Product ID.

          Aggregation:
              - MAX(Unit Price)
              - SUM(Quantity)
              - MAX(Discount Rate)
        =========================================================================*/

        order_line_aggregated AS
        (
            SELECT
                order_id,
                product_id,

                MAX(unit_price) AS unit_price,

                SUM(quantity) AS quantity,

                MAX(discount_rate) AS discount_rate

            FROM lines_cleaned

            GROUP BY
                order_id,
                product_id
        )


        /*========================================================================
          5. INSERT INTO FACT TABLE
          ------------------------------------------------------------------------
          Dimension Business Keys are converted into Dimension Surrogate Keys.

          If a Dimension record cannot be found:
              Surrogate Key = 0 (Unknown Member)

          Date Mapping:
              Gregorian dates from Stage are matched to dim_date.MiladiDate.

          Measures:
              Gross Amount
              Discount Amount
              Net Amount
              Freight Amount
        =========================================================================*/

        INSERT INTO sale.fact_order
        (
            order_id,
            source_product_id,

            customer_key,
            employee_key,
            supplier_key,
            product_key,
            shipper_key,
            geography_key,

            order_date_key,
            required_date_key,
            shipped_date_key,

            unit_price,
            quantity,
            discount_rate,

            gross_amount,
            discount_amount,
            net_amount,
            freight_amount,

            dwh_inserted_at
        )

        SELECT
            o.order_id,
            ola.product_id,


            /*--------------------------------------------------------------------
              Dimension Surrogate Keys
            --------------------------------------------------------------------*/

            COALESCE
            (
                dc.customer_key,
                0
            ) AS customer_key,

            COALESCE
            (
                de.employee_key,
                0
            ) AS employee_key,

            COALESCE
            (
                dsu.supplier_key,
                0
            ) AS supplier_key,

            COALESCE
            (
                dp.product_key,
                0
            ) AS product_key,

            COALESCE
            (
                dsh.shipper_key,
                0
            ) AS shipper_key,

            COALESCE
            (
                dg.geography_key,
                0
            ) AS geography_key,


            /*--------------------------------------------------------------------
              Date Dimension Surrogate Keys
            --------------------------------------------------------------------*/

            COALESCE
            (
                dd_order.MiladiDateKey,
                0
            ) AS order_date_key,

            COALESCE
            (
                dd_required.MiladiDateKey,
                0
            ) AS required_date_key,

            COALESCE
            (
                dd_shipped.MiladiDateKey,
                0
            ) AS shipped_date_key,


            /*--------------------------------------------------------------------
              Base Measures
            --------------------------------------------------------------------*/

            ola.unit_price,

            ola.quantity,

            ola.discount_rate,


            /*--------------------------------------------------------------------
              Derived Measures
            --------------------------------------------------------------------*/

            -- Gross sales amount before discount
            CAST
            (
                ola.unit_price * ola.quantity
                AS DECIMAL(19,4)
            ) AS gross_amount,


            -- Monetary value of discount
            CAST
            (
                (ola.unit_price * ola.quantity)
                * ola.discount_rate
                AS DECIMAL(19,4)
            ) AS discount_amount,


            -- Final sales amount after discount
            CAST
            (
                (ola.unit_price * ola.quantity)
                -
                (
                    (ola.unit_price * ola.quantity)
                    * ola.discount_rate
                )
                AS DECIMAL(19,4)
            ) AS net_amount,


            /*--------------------------------------------------------------------
              Freight Allocation
              --------------------------------------------------------------------
              Freight is stored at the Order level.

              To allocate freight to each product line, the order freight
              is distributed proportionally based on line quantity.
            --------------------------------------------------------------------*/

            CAST
            (
                (
                    o.freight_amount
                    /
                    NULLIF
                    (
                        SUM(ola.quantity) OVER
                        (
                            PARTITION BY o.order_id
                        ),
                        0
                    )
                )
                * ola.quantity
                AS DECIMAL(19,4)
            ) AS freight_amount,


            @load_datetime


        FROM orders_cleaned AS o


        /*-----------------------------------------------------------------------
          Order Header + Order Detail
          ------------------------------------------------------------------------
          INNER JOIN is used because a valid Fact row requires both:
              - Order Header
              - Order Detail
        -----------------------------------------------------------------------*/

        INNER JOIN order_line_aggregated AS ola
            ON o.order_id = ola.order_id


        /*-----------------------------------------------------------------------
          Customer Dimension
        -----------------------------------------------------------------------*/

        LEFT JOIN sale.dim_customer AS dc
            ON dc.customer_id = o.customer_id


        /*-----------------------------------------------------------------------
          Employee Dimension
        -----------------------------------------------------------------------*/

        LEFT JOIN sale.dim_employee AS de
            ON de.employee_id = o.employee_id


        /*-----------------------------------------------------------------------
          Product Dimension
        -----------------------------------------------------------------------*/

        LEFT JOIN sale.dim_product AS dp
            ON dp.product_id = ola.product_id


        /*-----------------------------------------------------------------------
          Supplier Dimension
          ------------------------------------------------------------------------
          Supplier is obtained from the Product Dimension.
        -----------------------------------------------------------------------*/

        LEFT JOIN sale.dim_supplier AS dsu
            ON dsu.supplier_id = dp.supplier_id


        /*-----------------------------------------------------------------------
          Shipper Dimension
        -----------------------------------------------------------------------*/

        LEFT JOIN sale.dim_shipper AS dsh
            ON dsh.shipper_id = o.ship_via


        /*-----------------------------------------------------------------------
          Geography Dimension
        -----------------------------------------------------------------------*/

        LEFT JOIN sale.dim_geography AS dg
            ON dg.country = o.ship_country
            AND dg.region = o.ship_region
            AND dg.city = o.ship_city
            AND dg.postal_code = o.ship_postal_code


        /*-----------------------------------------------------------------------
          Order Date
        -----------------------------------------------------------------------*/

        LEFT JOIN dds.dbo.dim_date AS dd_order
            ON dd_order.MiladiDate = o.order_date


        /*-----------------------------------------------------------------------
          Required Date
        -----------------------------------------------------------------------*/

        LEFT JOIN dds.dbo.dim_date AS dd_required
            ON dd_required.MiladiDate = o.required_date


        /*-----------------------------------------------------------------------
          Shipped Date
        -----------------------------------------------------------------------*/

        LEFT JOIN dds.dbo.dim_date AS dd_shipped
            ON dd_shipped.MiladiDate = o.shipped_date


        /*========================================================================
          6. DATA QUALITY FILTERING
          ------------------------------------------------------------------------
          Only valid sales transactions are loaded.

          Conditions:
              Quantity > 0
              Unit Price >= 0
        =========================================================================*/

        WHERE ola.quantity > 0
          AND ola.unit_price >= 0;


        /*========================================================================
          7. COMMIT TRANSACTION
        =========================================================================*/

        COMMIT TRANSACTION;


        PRINT 'Full Load completed successfully for sale.fact_order.';


    END TRY


    BEGIN CATCH

        /*-----------------------------------------------------------------------
          Rollback the transaction if an error occurs.
        -----------------------------------------------------------------------*/

        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;


        /*-----------------------------------------------------------------------
          Re-throw the original error.
        -----------------------------------------------------------------------*/

        THROW;

    END CATCH;

END;
GO
