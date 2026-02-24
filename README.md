# Mobile-Money-Payment-Failure-Analysis-PayFlow-GH
A data-driven investigation into mobile money payment failures for a Ghana-based SaaS platform — covering data cleaning, root cause diagnosis, and business recommendations 





## 📊 PayFlow GH — Mobile Money Payment Failure Analysis

> **Tools:** PostgreSQL &nbsp;|&nbsp; **Market:** Ghana Fintech &nbsp;|&nbsp; **Role:** Data Analyst &nbsp;|&nbsp; **Records:** 2,111 Transactions

---

<!-- 💡 IMAGE SUGGESTION #1: Add a clean project banner here -->
<!-- A simple banner with "PayFlow GH | Payment Failure Analysis" text on a dark background -->
<!-- You can create one free at canva.com — recommended size 1280x640px -->

---

# Project Background

PayFlow GH is a Ghanaian SaaS company founded in 2021, operating in the business management software industry. The company sells subscription-based software to small and medium enterprises (SMEs) across Ghana — helping them manage invoicing, payments, and customer records. PayFlow GH operates on a monthly recurring revenue (MRR) model, with customers paying subscription fees entirely via mobile money — MTN MoMo, Vodafone Cash, and AirtelTigo Money.

As a data analyst working at PayFlow GH, I was tasked with investigating a growing concern: payment failures were silently eroding revenue in two ways — causing existing customers to drop off and blocking new customers from completing their first payment. With a Series A fundraise approaching, leadership needed a clear picture of the scale of the problem, its root causes, and actionable fixes — before the next investor call.

Key business metrics monitored in this analysis:

- **Monthly Revenue Loss:** Average GHS lost per month to unrecovered payment failures
- **Failure Rate by Network:** Percentage of transactions failing per mobile money network
- **Failure Rate by Transaction Type:** How failure rates differ across new subscriptions, renewals, upgrades, and reactivations
- **Retry Behaviour:** Percentage of failed customers who attempt to retry payment
- **Revenue at Risk:** Total GHS lost to failures that were never recovered

The SQL queries used to inspect and clean the data can be found here → [`sql/01_data_review.sql`](https://github.com/Sannisaheedsanni/Mobile-Money-Payment-Failure-Analysis-PayFlow-GH/blob/eaffa48013d6bd11d6aac27034b2ab4166ef78cd/01_data_review.sql) and [`sql/02_cleaning.sql`]([sql/02_cleaning.sql](https://github.com/Sannisaheedsanni/Mobile-Money-Payment-Failure-Analysis-PayFlow-GH/blob/e648615e9242d4679eae6139f7a8135285563bf2/02_cleaning.sql))

The targeted SQL queries used for business analysis can be found here → [`sql/03_analysis.sql`](sql/03_analysis.sql)

The stakeholder memo summarising findings for non-technical leadership can be found here → [`memo/findings_summary.md`](memo/findings_summary.md)

---

# Data Structure & Initial Checks

The PayFlow GH database for this analysis consists of a single transactions table — `payflow_transactions` — with 2,111 records representing individual mobile money payment attempts made between January 2023 and December 2024.

| Column | Description |
| --- | --- |
| `transaction_id` | Unique identifier for each payment attempt |
| `customer_id` | Unique identifier for each customer |
| `customer_name` | Full name of the customer |
| `city` | City where the customer is based |
| `subscription_plan` | Plan tier — Starter, Growth, Pro, Enterprise |
| `amount_ghs` | Transaction amount in Ghanaian Cedis |
| `network` | Mobile money network used — MTN MoMo, Vodafone Cash, AirtelTigo Money |
| `transaction_type` | Type of payment — new subscription, renewal, upgrade, reactivation |
| `status` | Outcome — success, failed, or recovered |
| `failure_reason` | Reason for failure where applicable |
| `retry_attempted` | Whether the customer attempted a retry after failure |
| `transaction_time` | Timestamp of the payment attempt |
| `day_of_week` | Day the transaction occurred |
| `is_peak_day` | Whether the transaction fell on a peak day (end of month or market day) |

<!-- 💡 IMAGE SUGGESTION #2: Add an ERD or simple table schema diagram here -->
<!-- Since this is a single table project, a clean column map or data dictionary visual works well -->
<!-- You can screenshot your table structure from pgAdmin or create a simple diagram in dbdiagram.io (free) -->

**Initial data quality issues identified and resolved:**

- Currency symbols embedded in amount column (`GHS 153.5`) — stripped and cast to NUMERIC
- Inconsistent city name casing (`accra`, `ACCRA`, `Accra`) — standardised via INITCAP and TRIM
- 44 null timestamps randomly distributed — excluded from time-based analysis only
- 1,950 null failure reasons — confirmed expected, all belong to successful transactions
- 278 unique customer IDs mapping to 224 unique names — possible duplicate registrations, flagged to engineering, all analysis uses `customer_id` as the unique key

---

# Executive Summary

### Overview of Findings

PayFlow GH is losing **GHS 941.68 every month** to unrecovered payment failures — totalling GHS 19,580.50 across the two-year analysis period. Failures split clearly into two categories: customer-side problems (insufficient funds, PIN confusion, daily limit hits) accounting for GHS 12,155.50, and technical infrastructure failures (network timeouts, interoperability errors, system errors) accounting for GHS 7,425.00. New subscribers carry the highest failure rate at 6.33% — meaning PayFlow is losing customers at the exact moment they are trying to join — while AirtelTigo Money customers fail at nearly three times the rate of MTN MoMo customers.

<!-- 💡 IMAGE SUGGESTION #3: This is the most important image placement in the whole README -->
<!-- Add a screenshot of your key metrics summary query results here -->
<!-- A clean table showing: Total Loss | Monthly Avg | Top Failure Reason | Worst Network | New Sub Failure Rate -->
<!-- Screenshot it from pgAdmin/DBeaver with a dark theme for visual impact -->

---

# Insights Deep Dive

### Category 1: Revenue Loss & Monthly Trends

- **PayFlow loses GHS 941.68 every month** to unrecovered payment failures — a recurring, measurable, and largely preventable drain on MRR across the January 2023 to December 2024 period.

- **The monthly trend is not stable.** Losses peaked at GHS 2,595 in September 2023 and have trended downward into 2024 — dropping to GHS 49–199 in the most recent months. This suggests some natural improvement but the pattern needs monitoring to confirm it is sustained.

- **Over 60% of failures are customer-side problems** — insufficient funds, wrong PIN lockouts, and daily limit hits — meaning the majority of losses are addressable through product design and proactive communication rather than engineering overhauls alone.

- **Technical failures account for GHS 7,425** — network timeouts at GHS 5,482.50 and interoperability errors at GHS 1,193.50 represent infrastructure failures entirely outside the customer's control that require direct engineering intervention.

<!-- 💡 IMAGE SUGGESTION #4: Add a screenshot of your monthly loss query results here -->
<!-- The month-by-month table showing the trend from 2023 peak down to 2024 is visually compelling -->
<!-- Screenshot from your SQL client -->

---

### Category 2: Network Performance

- **AirtelTigo Money carries the highest failure rate at 10.30%** — nearly three times MTN MoMo's 3.55% and double Vodafone Cash's 5.32%. This means 1 in every 10 AirtelTigo transactions fails.

- **MTN MoMo generates the largest absolute loss at GHS 14,103** — not because its failure rate is the worst, but because it handles 73% of all transactions. Volume makes even a low failure rate expensive at scale.

- **These are two different problems requiring two different solutions.** MTN is the priority today based on absolute revenue impact. AirtelTigo is the strategic risk tomorrow — as PayFlow grows its customer base, a 10.30% failure rate becomes increasingly damaging.

- **Vodafone Cash customers retry at 40%** — nearly double the retry rate of MTN (25%) and AirtelTigo (24%) customers. This suggests Vodafone customers are more engaged or more familiar with the retry process, providing a behavioural benchmark to target across all networks.

<!-- 💡 IMAGE SUGGESTION #5: Screenshot of your network failure rate query results -->
<!-- The table showing network | total_txns | failed_txns | failure_rate_pct | ghs_lost is clean and impactful -->

---

### Category 3: Transaction Type Analysis

- **New subscriptions fail at the highest rate of any transaction type — 6.33%** — costing GHS 8,770 in lost acquisition revenue. PayFlow is losing customers at the exact moment they are trying to join, which directly undermines growth and compounds the customer retention problem.

- **Wrong PIN lockout is the top failure reason for new subscribers at GHS 2,541.** This is not a customer knowledge problem — new subscribers already use mobile money daily. The likely cause is a UX labelling issue where customers confuse their PayFlow account credentials with their mobile money PIN on the payment screen, make three wrong attempts, and get locked out entirely.

- **Reactivation failures are dominated by network timeouts at GHS 1,496.50** — lapsed customers returning after a gap may be on weaker network connections or have outdated payment configurations, making them more vulnerable to infrastructure failures.

- **Subscription renewals fail most due to insufficient funds at GHS 1,946** — existing customers are running low on mobile money balance at the exact time their automated renewal processes. A balance reminder sent 24 hours before renewal would directly target this failure type.

<!-- 💡 IMAGE SUGGESTION #6: Screenshot of your transaction type granular breakdown query -->
<!-- The table showing transaction_type | failure_reason | failed_txns | ghs_lost is one of the strongest visuals in the project -->

---

### Category 4: Peak Day Patterns

- **Peak days carry a higher failure rate at 4.68% vs 4.09% on normal days.** Peak days in Ghana are end-of-month dates and market days — Tuesdays and Fridays — when mobile money activity spikes across the country.

- **Daily limit exceeded failures spike significantly on peak days** — GHS 1,045.50 lost on peak days vs GHS 747.50 on normal days. End of month is salary day in Ghana — customers are sending money to family, paying bills, and topping up wallets, exhausting their daily mobile money limit before their PayFlow subscription renewal processes.

- **Network timeouts are elevated on peak days** — high mobile money activity nationally creates network congestion that directly increases technical failure rates on PayFlow's platform, even for customers who have sufficient funds.

- **The fix is a scheduling intervention, not a technical one.** Moving renewal attempts to early morning on peak days — before customers begin their daily transactions — would reduce both daily limit and network congestion failures without any engineering change to the payment infrastructure.

<!-- 💡 IMAGE SUGGESTION #7: Screenshot of your peak day analysis query results -->
<!-- Side-by-side comparison of peak vs non-peak failure reasons is visually clean and tells a clear story -->

---

# Recommendations

Based on the insights and findings above, the following recommendations are provided to the PayFlow GH product, engineering, and customer success teams:

- **New subscribers are failing due to PIN confusion on the payment screen, costing GHS 2,541 in lost acquisition revenue.** Relabel the payment PIN input field to clearly read "Enter your MTN MoMo / Vodafone Cash / AirtelTigo PIN" and add a one-line helper text beneath it. This is a low-effort UX fix with direct revenue impact on the highest-failing transaction type.

- **75% of MTN and AirtelTigo customers who fail a payment never attempt to retry, representing the largest single behavioural driver of revenue loss.** Deploy an automated WhatsApp or SMS retry prompt immediately after any payment failure. Prioritise Pro and Enterprise customers given their higher transaction values. If retry rates move from 25% to 40% — matching Vodafone's organic rate — projected monthly recovery is GHS 300–400.

- **Insufficient funds is the top failure reason for subscription renewals at GHS 1,946, driven by customers running low on mobile money balance at renewal time.** Send an automated balance reminder to customers 24 hours before their renewal date. The customer wants to pay — they simply need a timely nudge to top up before the automated payment processes.

- **Daily limit exceeded failures spike on peak days as customers exhaust their mobile money limits before PayFlow renewals process.** Schedule subscription renewal attempts for early morning on end-of-month and market days — before customers begin their daily transactions. This is a scheduling change requiring minimal engineering effort.

- **Network timeouts and interoperability errors account for GHS 6,675 in technical failures outside the customer's control.** Escalate to the engineering team with the full revenue impact breakdown attached. These failures cannot be addressed through product design or communication — they require infrastructure-level fixes and should be prioritised in the next engineering sprint.

---

# Stakeholder Memo

*The following is the findings memo delivered to Kwame Ofosu, Head of Product, following Phase 1 data validation.*

---

**To:** Kwame Ofosu, Head of Product
**From:** Sanni Saheed, Data Analyst
**Date:** February 3, 2024
**Re:** Data Review Summary — PayFlow Transaction Dataset

---

The dataset covers customer transactions from January 1, 2023 through December 30, 2024. It contains 2,111 rows, each representing a single payment transaction, with details including customer ID, customer name, transaction amount, mobile money network, subscription plan, failure reasons, and transaction timestamp. This gives us a complete two-year view of PayFlow's mobile money payment activity.

During the review I found several issues that required attention. First, some amount fields contained currency symbol prefixes such as "GHS 153.5" which prevented numerical calculations — these were stripped and the column recast as a numeric type. Second, city names were stored inconsistently across records — "accra", "ACCRA", and "Accra" all appeared for the same city — and were standardised. Third, 44 transactions are missing timestamps. These are randomly distributed across the dataset and have been excluded only from time-based analysis — they remain in all other calculations. Fourth, 1,950 transactions have no failure reason recorded — this is expected and correct, as every one of these belongs to a successful transaction. Finally, the dataset contains 278 unique customer IDs mapping to only 224 unique names, suggesting some customers may have registered more than once under different IDs. This cannot be safely resolved without additional identifiers such as phone number or email. All analysis uses customer ID as the unique key. Recommended action: engineering should add deduplication logic at the signup stage.

After these fixes the data is in good shape for analysis. Time-based queries will exclude the 44 transactions with missing timestamps — this has negligible impact on findings and will be noted wherever relevant. The customer ID situation has been documented and flagged for the engineering team but does not affect the reliability of the payment failure analysis.

---

# Assumptions and Caveats

Throughout the analysis, several assumptions were made to manage challenges with the data:

- **Synthetic dataset modelled on published benchmarks** — the transaction data was generated using Bank of Ghana 2024 Payment Systems Oversight Report figures (MTN 73% market share, average transaction value GHS 372), GSMA mobile money benchmarks, and Ghana Statistical Service city distribution data. Real production data may surface additional failure patterns not captured here.

- **Duplicate customer registrations could not be resolved** — 278 unique customer IDs map to 224 unique names. Without phone number or email as additional identifiers, merging duplicate accounts would risk incorrectly combining records for two different customers who share a common Ghanaian name. All analysis uses customer_id as the unique key and findings are not materially affected by this limitation.

- **44 null timestamps excluded from time-based analysis only** — these rows are retained in all non-time-based calculations. The exclusion has negligible impact on findings given the random distribution of the missing values.

- **Retry recovery projection is an estimate** — the projected GHS 300–400 monthly recovery from improved retry prompts assumes the retry success rate holds at 60% and that a prompt intervention moves MTN and AirtelTigo retry rates to match Vodafone's 40%. Real intervention impact should be validated through an A/B test before scaling.

- **1,950 null failure reasons are correct and expected** — confirmed via cross-column validation that every null failure reason belongs to a transaction with a successful status. These were retained in the clean dataset.

---

<!-- 💡 FINAL IMAGE SUGGESTION: Add your GitHub repo structure as a screenshot at the bottom -->
<!-- Shows hiring managers you organised your work professionally -->

---

## 📂 Repository Structure

```
payflow-gh-analysis/
│
├── README.md                        ← You are here
├── data/
│   └── payflow_transactions.csv     ← Raw dataset
├── sql/
│   ├── 01_data_review.sql           ← Audit queries
│   ├── 02_cleaning.sql              ← payflow_clean build
│   └── 03_analysis.sql              ← All Phase 2 queries
└── memo/
    └── findings_summary.md          ← Stakeholder memo
```

---

## 📚 Data Sources

| Source | What It Informed |
| --- | --- |
| Bank of Ghana Payment Systems Oversight Annual Report 2024 | MTN 73% market share, average transaction GHS 372, transaction type distribution |
| GSMA State of the Industry Report on Mobile Money 2024 | Network failure rates, retry behaviour benchmarks |
| Oxford Business Group Ghana 2024 | AirtelTigo and Vodafone market share |
| Ghana Statistical Service | City population distribution for transaction volume modelling |

---

*Built by Sanni Saheed · PostgreSQL · Ghana Fintech · SaaS Analytics*
