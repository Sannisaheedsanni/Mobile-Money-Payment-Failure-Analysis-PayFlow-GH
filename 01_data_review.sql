-- ============================================================
-- PayFlow GH | Mobile Money Payment Failure Analysis
-- FILE: 01_data_review.sql
-- PURPOSE: Full data audit before cleaning
-- Author: Sanni Saheed
-- ============================================================


-- ────────────────────────────────────────────────────────────
-- BLOCK 1: GET THE SHAPE OF THE DATA
-- Understand what we are working with before touching anything
-- ────────────────────────────────────────────────────────────

-- Total row count
SELECT COUNT(*) AS total_rows
FROM payflow_transactions;

-- Date range of the dataset
SELECT
    MIN(transaction_time) AS earliest_transaction,
    MAX(transaction_time) AS latest_transaction
FROM payflow_transactions;

-- Unique customers
SELECT COUNT(DISTINCT customer_id) AS unique_customers
FROM payflow_transactions;

-- Unique transactions
SELECT COUNT(DISTINCT transaction_id) AS unique_transactions
FROM payflow_transactions;


-- ────────────────────────────────────────────────────────────
-- BLOCK 2: CHECK FOR DUPLICATES
-- Duplicates silently inflate every metric if not handled
-- ────────────────────────────────────────────────────────────

-- Duplicate transaction IDs?
SELECT transaction_id, COUNT(*) AS count
FROM payflow_transactions
GROUP BY transaction_id
HAVING COUNT(*) > 1;

-- Does any single customer_id have more than one name attached?
SELECT customer_id, COUNT(DISTINCT customer_name) AS name_count
FROM payflow_transactions
GROUP BY customer_id
HAVING COUNT(DISTINCT customer_name) > 1;

-- Same name appearing under multiple customer IDs?
-- This reveals potential duplicate registrations
SELECT customer_name, COUNT(DISTINCT customer_id) AS id_count
FROM payflow_transactions
GROUP BY customer_name
HAVING COUNT(DISTINCT customer_id) > 1
ORDER BY id_count DESC;


-- ────────────────────────────────────────────────────────────
-- BLOCK 3: CHECK EVERY COLUMN FOR NULLS AND BLANKS
-- One query covers all 14 columns at once
-- ────────────────────────────────────────────────────────────

SELECT
    COUNT(*)                                                    AS total_rows,
    COUNT(*) - COUNT(transaction_id)                            AS null_transaction_id,
    COUNT(*) - COUNT(NULLIF(TRIM(customer_id), ''))             AS null_customer_id,
    COUNT(*) - COUNT(NULLIF(TRIM(customer_name), ''))           AS null_customer_name,
    COUNT(*) - COUNT(NULLIF(TRIM(city), ''))                    AS null_city,
    COUNT(*) - COUNT(NULLIF(TRIM(subscription_plan), ''))       AS null_plan,
    COUNT(*) - COUNT(NULLIF(TRIM(amount_ghs), ''))              AS null_amount,
    COUNT(*) - COUNT(NULLIF(TRIM(network), ''))                 AS null_network,
    COUNT(*) - COUNT(NULLIF(TRIM(transaction_type), ''))        AS null_type,
    COUNT(*) - COUNT(NULLIF(TRIM(status), ''))                  AS null_status,
    COUNT(*) - COUNT(NULLIF(TRIM(failure_reason), ''))          AS null_failure_reason,
    COUNT(*) - COUNT(NULLIF(TRIM(retry_attempted), ''))         AS null_retry,
    COUNT(*) - COUNT(NULLIF(TRIM(transaction_time), ''))        AS null_time,
    COUNT(*) - COUNT(NULLIF(TRIM(day_of_week), ''))             AS null_day,
    COUNT(*) - COUNT(NULLIF(TRIM(is_peak_day), ''))             AS null_peak_day
FROM payflow_transactions;


-- ────────────────────────────────────────────────────────────
-- BLOCK 4: INVESTIGATE THE NULLS
-- Not just how many -- but why they exist
-- ────────────────────────────────────────────────────────────

-- Are failure reason nulls all from successful transactions?
-- If yes -- nulls are expected and correct
SELECT status, COUNT(*) AS count
FROM payflow_transactions
WHERE failure_reason IS NULL OR TRIM(failure_reason) = ''
GROUP BY status;

-- Do null timestamps cluster around a specific network or status?
SELECT network, status, COUNT(*) AS count
FROM payflow_transactions
WHERE transaction_time IS NULL OR TRIM(transaction_time) = ''
GROUP BY network, status
ORDER BY count DESC;


-- ────────────────────────────────────────────────────────────
-- BLOCK 5: CHECK VALUE CONSISTENCY
-- Every categorical column should have clean consistent values
-- ────────────────────────────────────────────────────────────

-- City name variants
SELECT city, COUNT(*) AS count
FROM payflow_transactions
GROUP BY city
ORDER BY city;

-- Network variants
SELECT network, COUNT(*) AS count
FROM payflow_transactions
GROUP BY network
ORDER BY network;

-- Status variants
SELECT status, COUNT(*) AS count
FROM payflow_transactions
GROUP BY status
ORDER BY status;

-- Subscription plan variants
SELECT subscription_plan, COUNT(*) AS count
FROM payflow_transactions
GROUP BY subscription_plan
ORDER BY subscription_plan;

-- Transaction type variants
SELECT transaction_type, COUNT(*) AS count
FROM payflow_transactions
GROUP BY transaction_type
ORDER BY transaction_type;


-- ────────────────────────────────────────────────────────────
-- BLOCK 6: CHECK AMOUNT COLUMN
-- Raw data contains currency symbols and formatting issues
-- ────────────────────────────────────────────────────────────

-- How many rows have GHS prefix?
SELECT COUNT(*) AS ghs_prefix_count
FROM payflow_transactions
WHERE amount_ghs LIKE 'GHS%';

-- Check min, max, average after stripping symbols
SELECT
    MIN(REPLACE(REPLACE(TRIM(amount_ghs), 'GHS ', ''), ',', '.')::NUMERIC) AS min_amount,
    MAX(REPLACE(REPLACE(TRIM(amount_ghs), 'GHS ', ''), ',', '.')::NUMERIC) AS max_amount,
    ROUND(AVG(REPLACE(REPLACE(TRIM(amount_ghs), 'GHS ', ''), ',', '.')::NUMERIC), 2) AS avg_amount
FROM payflow_transactions
WHERE amount_ghs != '' AND amount_ghs IS NOT NULL;


-- ────────────────────────────────────────────────────────────
-- BLOCK 7: CROSS COLUMN LOGIC CHECKS
-- Do columns make logical sense together?
-- ────────────────────────────────────────────────────────────

-- Failed transactions with no failure reason -- should be zero
SELECT COUNT(*) AS failed_no_reason
FROM payflow_transactions
WHERE status = 'failed'
AND (failure_reason IS NULL OR TRIM(failure_reason) = '');

-- Successful transactions with a failure reason -- should be zero
SELECT COUNT(*) AS success_with_reason
FROM payflow_transactions
WHERE status = 'success'
AND failure_reason IS NOT NULL
AND TRIM(failure_reason) != '';

-- Retry breakdown by status -- does retry behaviour align with status?
SELECT retry_attempted, status, COUNT(*) AS count
FROM payflow_transactions
GROUP BY retry_attempted, status
ORDER BY retry_attempted, status;
