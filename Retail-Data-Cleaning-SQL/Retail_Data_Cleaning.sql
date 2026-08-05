/* ============================================================
   PROJECT: Indian Retail Sales Data Cleaning
   DATABASE: RetailData
   PURPOSE:
       Import raw retail data into the Bronze layer,
       clean and validate it, and load it into the Silver layer.
   ============================================================ */


-- ============================================================
-- 1. CREATE DATABASE
-- ============================================================

USE master;
GO

IF DB_ID('RetailData') IS NULL
BEGIN
    CREATE DATABASE RetailData;
END;
GO

USE RetailData;
GO


-- ============================================================
-- 2. CREATE BRONZE AND SILVER SCHEMAS
-- ============================================================

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'bronze'
)
BEGIN
    EXEC('CREATE SCHEMA bronze');
END;
GO

IF NOT EXISTS (
    SELECT 1
    FROM sys.schemas
    WHERE name = 'silver'
)
BEGIN
    EXEC('CREATE SCHEMA silver');
END;
GO


-- ============================================================
-- 3. CREATE RAW BRONZE TABLE
-- ============================================================
-- All columns are stored as NVARCHAR because Bronze preserves
-- the raw CSV values before cleaning and type conversion.

DROP TABLE IF EXISTS bronze.orders;
GO

CREATE TABLE bronze.orders (
    order_id NVARCHAR(50),
    order_date NVARCHAR(100),
    customer_id NVARCHAR(50),
    customer_name NVARCHAR(150),
    age NVARCHAR(50),
    gender NVARCHAR(50),
    region NVARCHAR(100),
    city NVARCHAR(100),
    product_category NVARCHAR(100),
    product_name NVARCHAR(200),
    quantity NVARCHAR(50),
    unit_price NVARCHAR(100),
    discount_pct NVARCHAR(50),
    sales_amount NVARCHAR(100),
    profit NVARCHAR(100),
    shipping_cost NVARCHAR(100),
    payment_method NVARCHAR(100),
    customer_satisfaction NVARCHAR(50),
    return_flag NVARCHAR(50),
    order_status NVARCHAR(100),
    days_to_ship NVARCHAR(50)
);
GO


/* ============================================================
   4. IMPORT THE CSV FILE

   The CSV file was imported into bronze.orders using the
   SQL Server/DBeaver Import Data Wizard.

   Bronze data should remain unchanged after import.
   ============================================================ */


-- Check the raw imported data

SELECT COUNT(*) AS bronze_row_count
FROM bronze.orders;

SELECT TOP (10) *
FROM bronze.orders;
GO


-- ============================================================
-- 5. RAW DATA QUALITY CHECKS
-- ============================================================


-- Check missing or blank order IDs

SELECT *
FROM bronze.orders
WHERE NULLIF(TRIM(order_id), '') IS NULL;


-- Check duplicate order IDs

SELECT
    TRIM(order_id) AS order_id,
    COUNT(*) AS duplicate_count
FROM bronze.orders
WHERE NULLIF(TRIM(order_id), '') IS NOT NULL
GROUP BY TRIM(order_id)
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;


-- Check raw gender values

SELECT
    gender,
    COUNT(*) AS total_rows
FROM bronze.orders
GROUP BY gender
ORDER BY total_rows DESC;


-- Check raw order status values

SELECT
    order_status,
    COUNT(*) AS total_rows
FROM bronze.orders
GROUP BY order_status
ORDER BY total_rows DESC;


-- Check raw return flag values

SELECT
    return_flag,
    COUNT(*) AS total_rows
FROM bronze.orders
GROUP BY return_flag
ORDER BY total_rows DESC;


-- Check date values that cannot be converted

SELECT DISTINCT
    order_date
FROM bronze.orders
WHERE NULLIF(TRIM(order_date), '') IS NOT NULL
  AND CASE
        WHEN TRIM(order_date) LIKE '__/__/____'
            THEN TRY_CONVERT(DATE, TRIM(order_date), 103)

        WHEN TRIM(order_date) LIKE '____-__-__'
            THEN TRY_CONVERT(DATE, TRIM(order_date), 23)

        ELSE TRY_CAST(TRIM(order_date) AS DATE)
      END IS NULL;


-- Check invalid ages

SELECT DISTINCT
    age
FROM bronze.orders
WHERE NULLIF(TRIM(age), '') IS NOT NULL
  AND (
        TRY_CAST(TRIM(age) AS DECIMAL(5,1)) IS NULL
        OR TRY_CAST(TRIM(age) AS DECIMAL(5,1)) < 0
        OR TRY_CAST(TRIM(age) AS DECIMAL(5,1)) > 100
      );


-- Check invalid quantities

SELECT DISTINCT
    quantity
FROM bronze.orders
WHERE NULLIF(TRIM(quantity), '') IS NOT NULL
  AND (
        TRY_CAST(TRIM(quantity) AS DECIMAL(10,1)) IS NULL
        OR TRY_CAST(TRIM(quantity) AS DECIMAL(10,1)) <= 0
      );


-- ============================================================
-- 6. CREATE CLEAN SILVER TABLE
-- ============================================================

DROP TABLE IF EXISTS silver.orders;
GO

CREATE TABLE silver.orders (
    order_id NVARCHAR(50) NOT NULL,
    order_date DATE,
    customer_id NVARCHAR(50),
    customer_name NVARCHAR(150),
    age INT,
    gender NVARCHAR(20),
    region NVARCHAR(100),
    city NVARCHAR(100),
    product_category NVARCHAR(100),
    product_name NVARCHAR(200),
    quantity INT,
    unit_price DECIMAL(12,2),
    discount_pct DECIMAL(5,2),
    sales_amount DECIMAL(12,2),
    profit DECIMAL(12,2),
    shipping_cost DECIMAL(12,2),
    payment_method NVARCHAR(100),
    customer_satisfaction DECIMAL(3,1),
    return_flag BIT,
    order_status NVARCHAR(50),
    days_to_ship INT
);
GO


-- ============================================================
-- 7. CLEAN AND LOAD DATA INTO SILVER
-- ============================================================
-- DISTINCT removes fully identical duplicate rows.
-- Rows without a valid order ID are excluded.

INSERT INTO silver.orders (
    order_id,
    order_date,
    customer_id,
    customer_name,
    age,
    gender,
    region,
    city,
    product_category,
    product_name,
    quantity,
    unit_price,
    discount_pct,
    sales_amount,
    profit,
    shipping_cost,
    payment_method,
    customer_satisfaction,
    return_flag,
    order_status,
    days_to_ship
)

SELECT DISTINCT

    -- Remove surrounding spaces and convert blanks to NULL
    NULLIF(TRIM(order_id), '') AS order_id,

    -- Convert mixed date formats into the DATE data type
    CASE
        WHEN NULLIF(TRIM(order_date), '') IS NULL
            THEN NULL

        WHEN TRIM(order_date) LIKE '__/__/____'
            THEN TRY_CONVERT(DATE, TRIM(order_date), 103)

        WHEN TRIM(order_date) LIKE '____-__-__'
            THEN TRY_CONVERT(DATE, TRIM(order_date), 23)

        ELSE TRY_CAST(TRIM(order_date) AS DATE)
    END AS order_date,

    NULLIF(TRIM(customer_id), '') AS customer_id,
    NULLIF(TRIM(customer_name), '') AS customer_name,

    -- Convert values such as 39.0 into integer ages
    -- Invalid ages are replaced with NULL
    CASE
        WHEN TRY_CAST(TRIM(age) AS DECIMAL(5,1))
             BETWEEN 0 AND 100
        THEN CAST(
            TRY_CAST(TRIM(age) AS DECIMAL(5,1))
            AS INT
        )
        ELSE NULL
    END AS age,

    -- Standardize inconsistent gender values
    CASE
        WHEN UPPER(TRIM(gender)) IN ('F', 'FEMALE')
            THEN 'Female'

        WHEN UPPER(TRIM(gender)) IN ('M', 'MALE')
            THEN 'Male'

        WHEN UPPER(TRIM(gender)) IN ('OTHER', 'O')
            THEN 'Other'

        ELSE NULL
    END AS gender,

    NULLIF(TRIM(region), '') AS region,
    NULLIF(TRIM(city), '') AS city,
    NULLIF(TRIM(product_category), '') AS product_category,
    NULLIF(TRIM(product_name), '') AS product_name,

    -- Quantity must be greater than zero
    CASE
        WHEN TRY_CAST(TRIM(quantity) AS DECIMAL(10,1)) > 0
        THEN CAST(
            TRY_CAST(TRIM(quantity) AS DECIMAL(10,1))
            AS INT
        )
        ELSE NULL
    END AS quantity,

    -- Unit price cannot be negative
    CASE
        WHEN TRY_CAST(TRIM(unit_price) AS DECIMAL(12,2)) >= 0
        THEN TRY_CAST(TRIM(unit_price) AS DECIMAL(12,2))
        ELSE NULL
    END AS unit_price,

    -- Discount percentage must be between zero and one
    CASE
        WHEN TRY_CAST(TRIM(discount_pct) AS DECIMAL(5,2))
             BETWEEN 0 AND 1
        THEN TRY_CAST(TRIM(discount_pct) AS DECIMAL(5,2))
        ELSE NULL
    END AS discount_pct,

    -- Sales amount cannot be negative
    CASE
        WHEN TRY_CAST(TRIM(sales_amount) AS DECIMAL(12,2)) >= 0
        THEN TRY_CAST(TRIM(sales_amount) AS DECIMAL(12,2))
        ELSE NULL
    END AS sales_amount,

    -- Negative profit is preserved because it represents a loss
    TRY_CAST(
        NULLIF(TRIM(profit), '')
        AS DECIMAL(12,2)
    ) AS profit,

    -- Shipping cost cannot be negative
    CASE
        WHEN TRY_CAST(TRIM(shipping_cost) AS DECIMAL(12,2)) >= 0
        THEN TRY_CAST(TRIM(shipping_cost) AS DECIMAL(12,2))
        ELSE NULL
    END AS shipping_cost,

    NULLIF(TRIM(payment_method), '') AS payment_method,

    -- Satisfaction must be between zero and five
    CASE
        WHEN TRY_CAST(
                TRIM(customer_satisfaction)
                AS DECIMAL(3,1)
             ) BETWEEN 0 AND 5
        THEN TRY_CAST(
                TRIM(customer_satisfaction)
                AS DECIMAL(3,1)
             )
        ELSE NULL
    END AS customer_satisfaction,

    -- Standardize return flag as BIT
    CASE
        WHEN UPPER(TRIM(return_flag))
             IN ('TRUE', 'YES', 'Y', '1')
            THEN 1

        WHEN UPPER(TRIM(return_flag))
             IN ('FALSE', 'NO', 'N', '0')
            THEN 0

        ELSE NULL
    END AS return_flag,

    -- Standardize order status values
    CASE
        WHEN UPPER(TRIM(order_status)) = 'DELIVERED'
            THEN 'Delivered'

        WHEN UPPER(TRIM(order_status)) = 'SHIPPED'
            THEN 'Shipped'

        WHEN UPPER(TRIM(order_status)) = 'PENDING'
            THEN 'Pending'

        WHEN UPPER(TRIM(order_status)) = 'CANCELLED'
            THEN 'Cancelled'

        WHEN UPPER(TRIM(order_status)) = 'RETURNED'
            THEN 'Returned'

        ELSE NULL
    END AS order_status,

    -- Shipping days must be zero or greater
    CASE
        WHEN TRY_CAST(TRIM(days_to_ship) AS DECIMAL(10,1)) >= 0
        THEN CAST(
            TRY_CAST(TRIM(days_to_ship) AS DECIMAL(10,1))
            AS INT
        )
        ELSE NULL
    END AS days_to_ship

FROM bronze.orders

WHERE NULLIF(TRIM(order_id), '') IS NOT NULL;
GO


-- ============================================================
-- 8. SILVER DATA VALIDATION
-- ============================================================


-- Compare raw and cleaned row counts

SELECT
    (SELECT COUNT(*) FROM bronze.orders) AS bronze_rows,
    (SELECT COUNT(*) FROM silver.orders) AS silver_rows;


-- Preview cleaned data

SELECT TOP (20) *
FROM silver.orders;


-- Verify order IDs are unique after removing duplicate rows

SELECT
    order_id,
    COUNT(*) AS duplicate_count
FROM silver.orders
GROUP BY order_id
HAVING COUNT(*) > 1;


-- Check invalid ages

SELECT *
FROM silver.orders
WHERE age < 0
   OR age > 100;


-- Check invalid quantities

SELECT *
FROM silver.orders
WHERE quantity <= 0;


-- Check invalid discounts

SELECT *
FROM silver.orders
WHERE discount_pct < 0
   OR discount_pct > 1;


-- Check invalid prices and amounts

SELECT *
FROM silver.orders
WHERE unit_price < 0
   OR sales_amount < 0
   OR shipping_cost < 0;


-- Check invalid satisfaction ratings

SELECT *
FROM silver.orders
WHERE customer_satisfaction < 0
   OR customer_satisfaction > 5;


-- Check invalid shipping days

SELECT *
FROM silver.orders
WHERE days_to_ship < 0;


-- Check standardized gender values

SELECT
    gender,
    COUNT(*) AS total_rows
FROM silver.orders
GROUP BY gender
ORDER BY total_rows DESC;


-- Check standardized order status values

SELECT
    order_status,
    COUNT(*) AS total_rows
FROM silver.orders
GROUP BY order_status
ORDER BY total_rows DESC;


-- Check standardized return values

SELECT
    return_flag,
    COUNT(*) AS total_rows
FROM silver.orders
GROUP BY return_flag
ORDER BY total_rows DESC;


-- ============================================================
-- 9. NULL SUMMARY
-- ============================================================

SELECT
    COUNT(*) AS total_rows,

    SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END)
        AS missing_order_dates,

    SUM(CASE WHEN customer_id IS NULL THEN 1 ELSE 0 END)
        AS missing_customer_ids,

    SUM(CASE WHEN customer_name IS NULL THEN 1 ELSE 0 END)
        AS missing_customer_names,

    SUM(CASE WHEN age IS NULL THEN 1 ELSE 0 END)
        AS missing_or_invalid_ages,

    SUM(CASE WHEN gender IS NULL THEN 1 ELSE 0 END)
        AS missing_or_invalid_gender,

    SUM(CASE WHEN product_name IS NULL THEN 1 ELSE 0 END)
        AS missing_product_names,

    SUM(CASE WHEN quantity IS NULL THEN 1 ELSE 0 END)
        AS missing_or_invalid_quantities,

    SUM(CASE WHEN unit_price IS NULL THEN 1 ELSE 0 END)
        AS missing_or_invalid_unit_prices,

    SUM(CASE WHEN discount_pct IS NULL THEN 1 ELSE 0 END)
        AS missing_or_invalid_discounts,

    SUM(CASE WHEN sales_amount IS NULL THEN 1 ELSE 0 END)
        AS missing_or_invalid_sales,

    SUM(CASE WHEN customer_satisfaction IS NULL THEN 1 ELSE 0 END)
        AS missing_or_invalid_satisfaction,

    SUM(CASE WHEN return_flag IS NULL THEN 1 ELSE 0 END)
        AS missing_or_invalid_return_flags,

    SUM(CASE WHEN order_status IS NULL THEN 1 ELSE 0 END)
        AS missing_or_invalid_order_status,

    SUM(CASE WHEN days_to_ship IS NULL THEN 1 ELSE 0 END)
        AS missing_or_invalid_shipping_days

FROM silver.orders;
GO