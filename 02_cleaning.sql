-- ============================================================
-- PayFlow GH | Mobile Money Payment Failure Analysis
-- FILE: 02_cleaning.sql
-- PURPOSE: Build payflow_clean -- the trusted analysis table
-- Author: Sanni Saheed
-- ============================================================


-- ────────────────────────────────────────────────────────────
-- STEP 1: BUILD THE CLEAN TABLE
-- Fixes all issues identified in 01_data_review.sql
-- ────────────────────────────────────────────────────────────

CREATE TABLE payflow_clean AS
SELECT
    transaction_id,
    customer_id,

    -- Remove leading and trailing whitespace from names
    TRIM(customer_name)                                         AS customer_name,

    -- Standardise city casing
    -- INITCAP handles all casing variants: accra, ACCRA, Accra → Accra
    -- No misspellings found in audit so INITCAP is sufficient
    INITCAP(TRIM(city))                                         AS city,

    subscription_plan,

    -- Strip GHS currency prefix and cast to numeric
    -- TRIM removes whitespace left after stripping the symbol
    TRIM(REPLACE(amount_ghs, 'GHS', ''))::NUMERIC               AS amount,

    network,
    transaction_type,
    status,

    -- Null failure reasons are expected for successful transactions
    -- No change needed -- retained as is
    failure_reason,

    retry_attempted,

    -- Cast timestamp safely
    -- NULLIF converts empty strings to NULL before casting
    -- Prevents Postgres throwing an error on blank timestamp fields
    CAST(NULLIF(TRIM(transaction_time), '') AS TIMESTAMP)       AS transaction_time,

    day_of_week,
    is_peak_day

FROM payflow_transactions
WHERE transaction_id IS NOT NULL
  AND transaction_id != '';


-- ────────────────────────────────────────────────────────────
-- STEP 2: VERIFY THE CLEAN TABLE
-- Never assume the cleaning worked -- always confirm
-- ────────────────────────────────────────────────────────────

-- Row count should match raw table
SELECT COUNT(*) AS total_rows
FROM payflow_clean;

-- Cities should now be consistent
SELECT DISTINCT city
FROM payflow_clean
ORDER BY city;

-- Amount should now be numeric with sensible range
SELECT
    MIN(amount)             AS min_amount,
    MAX(amount)             AS max_amount,
    ROUND(AVG(amount), 2)   AS avg_amount
FROM payflow_clean;

-- Timestamp should cast correctly
SELECT
    MIN(transaction_time) AS earliest,
    MAX(transaction_time) AS latest
FROM payflow_clean;

-- Confirm null failure reasons all belong to successful transactions
SELECT status, COUNT(*) AS count
FROM payflow_clean
WHERE failure_reason IS NULL
GROUP BY status;
