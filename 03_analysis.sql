-- ============================================================
-- PayFlow GH | Mobile Money Payment Failure Analysis
-- FILE: 03_analysis.sql
-- PURPOSE: Full diagnostic analysis of payment failures
-- Author: Sanni Saheed
-- ============================================================


-- ────────────────────────────────────────────────────────────
-- SECTION 1: OVERALL PAYMENT HEALTH
-- What is the overall success vs failure picture?
-- ────────────────────────────────────────────────────────────

-- Transaction status breakdown
SELECT
    status,
    COUNT(*)                                                        AS transactions,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)             AS percentage
FROM payflow_clean
GROUP BY status
ORDER BY transactions DESC;

-- Total revenue lost to unrecovered failures
-- Recovered transactions are excluded -- that money was collected
SELECT SUM(amount) AS total_revenue_lost
FROM payflow_clean
WHERE status = 'failed';

-- Average monthly revenue lost
-- Null timestamps excluded to avoid skewing the monthly average
SELECT ROUND(AVG(monthly_loss), 2) AS avg_monthly_loss
FROM (
    SELECT
        DATE_TRUNC('month', transaction_time)   AS month,
        SUM(amount)                             AS monthly_loss
    FROM payflow_clean
    WHERE status = 'failed'
    AND transaction_time IS NOT NULL
    GROUP BY month
) monthly_data;

-- Monthly loss trend -- is the problem getting better or worse?
SELECT
    DATE_TRUNC('month', transaction_time)   AS month,
    COUNT(*)                                AS failed_transactions,
    SUM(amount)                             AS monthly_loss
FROM payflow_clean
WHERE status = 'failed'
AND transaction_time IS NOT NULL
GROUP BY month
ORDER BY month;


-- ────────────────────────────────────────────────────────────
-- SECTION 2: FAILURE REASON ANALYSIS
-- What is actually causing payments to fail?
-- ────────────────────────────────────────────────────────────

-- Failure reasons ranked by revenue lost
SELECT
    failure_reason,
    COUNT(*)            AS failed_transactions,
    SUM(amount)         AS ghs_lost
FROM payflow_clean
WHERE status = 'failed'
GROUP BY failure_reason
ORDER BY ghs_lost DESC;


-- ────────────────────────────────────────────────────────────
-- SECTION 3: NETWORK ANALYSIS
-- Which mobile money network is failing customers most?
-- ────────────────────────────────────────────────────────────

-- Network failure rate and revenue lost
-- Uses failure rate not just count -- volume alone is misleading
SELECT
    network,
    COUNT(*)                                                                            AS total_txns,
    SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END)                                 AS failed_txns,
    ROUND(100.0 * SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) / COUNT(*), 2)    AS failure_rate_pct,
    SUM(CASE WHEN status = 'failed' THEN amount ELSE 0 END)                             AS ghs_lost
FROM payflow_clean
GROUP BY network
ORDER BY failure_rate_pct DESC;

-- Retry behaviour by network
-- Are customers fighting to recover or simply walking away?
-- PARTITION BY network allows percentage within each network group
SELECT
    network,
    retry_attempted,
    COUNT(*)                                                                AS count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY network), 2) AS pct
FROM payflow_clean
WHERE status = 'failed'
GROUP BY network, retry_attempted
ORDER BY network, retry_attempted;


-- ────────────────────────────────────────────────────────────
-- SECTION 4: SUBSCRIPTION PLAN ANALYSIS
-- Which plan is losing the most customers to payment failure?
-- ────────────────────────────────────────────────────────────

-- Failure rate and revenue lost by subscription plan
SELECT
    subscription_plan,
    COUNT(*)                                                                            AS total_txns,
    SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END)                                 AS failed_txns,
    ROUND(100.0 * SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) / COUNT(*), 2)    AS failure_rate_pct,
    SUM(CASE WHEN status = 'failed' THEN amount ELSE 0 END)                             AS ghs_lost
FROM payflow_clean
GROUP BY subscription_plan
ORDER BY ghs_lost DESC;


-- ────────────────────────────────────────────────────────────
-- SECTION 5: CITY ANALYSIS
-- Where geographically is PayFlow losing the most revenue?
-- ────────────────────────────────────────────────────────────

-- Revenue lost and failure rate by city
SELECT
    city,
    COUNT(*)                                                                            AS total_txns,
    SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END)                                 AS failed_txns,
    ROUND(100.0 * SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) / COUNT(*), 2)    AS failure_rate_pct,
    SUM(CASE WHEN status = 'failed' THEN amount ELSE 0 END)                             AS ghs_lost
FROM payflow_clean
GROUP BY city
ORDER BY ghs_lost DESC;


-- ────────────────────────────────────────────────────────────
-- SECTION 6: TRANSACTION TYPE ANALYSIS
-- Do failures differ between new subscribers, renewals,
-- upgrades, and reactivations?
-- ────────────────────────────────────────────────────────────

-- Failure rate and revenue lost by transaction type
SELECT
    transaction_type,
    COUNT(*)                                                                            AS total_txns,
    SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END)                                 AS failed_txns,
    ROUND(100.0 * SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) / COUNT(*), 2)    AS failure_rate_pct,
    SUM(CASE WHEN status = 'failed' THEN amount ELSE 0 END)                             AS ghs_lost
FROM payflow_clean
GROUP BY transaction_type
ORDER BY failure_rate_pct DESC;

-- Granular: failure reasons broken down within each transaction type
-- Reveals why each type fails -- not just that it fails
SELECT
    transaction_type,
    failure_reason,
    COUNT(*)        AS failed_txns,
    SUM(amount)     AS ghs_lost
FROM payflow_clean
WHERE status = 'failed'
GROUP BY transaction_type, failure_reason
ORDER BY transaction_type, ghs_lost DESC;


-- ────────────────────────────────────────────────────────────
-- SECTION 7: PEAK DAY ANALYSIS
-- Do failures spike on end-of-month and market days?
-- Peak days = end of month + Tuesdays and Fridays (Ghana market days)
-- ────────────────────────────────────────────────────────────

-- Overall failure rate on peak vs non-peak days
SELECT
    is_peak_day,
    COUNT(*)                                                                            AS total_txns,
    SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END)                                 AS failed_txns,
    ROUND(100.0 * SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) / COUNT(*), 2)    AS failure_rate_pct,
    SUM(CASE WHEN status = 'failed' THEN amount ELSE 0 END)                             AS ghs_lost
FROM payflow_clean
GROUP BY is_peak_day;

-- Granular: failure reasons on peak vs non-peak days
-- Reveals whether peak day failures are customer-side or technical
SELECT
    is_peak_day,
    failure_reason,
    COUNT(*)        AS failed_txns,
    SUM(amount)     AS ghs_lost
FROM payflow_clean
WHERE status = 'failed'
GROUP BY is_peak_day, failure_reason
ORDER BY is_peak_day, ghs_lost DESC;
