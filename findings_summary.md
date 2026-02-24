# PayFlow GH — Stakeholder Findings Memo

---

### Memo 1 — Data Review Summary
**To:** Kwame Ofosu, Head of Product
**From:** Sanni Saheed, Data Analyst
**Date:** February 3, 2024
**Re:** Phase 1 Data Review — PayFlow Transaction Dataset

---

The dataset covers customer transactions from January 1, 2023 through December 30, 2024. It contains 2,111 rows, each representing a single payment transaction, with details including customer ID, customer name, transaction amount, mobile money network, subscription plan, failure reasons, and transaction timestamp. This gives us a complete two-year view of PayFlow's mobile money payment activity.

During the review I found several issues that required attention. Some amount fields contained currency symbol prefixes such as "GHS 153.5" which prevented numerical calculations — these were stripped and the column recast as a numeric type. City names were stored inconsistently across records — "accra", "ACCRA", and "Accra" all appeared for the same city — and were standardised. Forty-four transactions are missing timestamps. These are randomly distributed across the dataset and have been excluded only from time-based analysis — they remain in all other calculations. One thousand nine hundred and fifty transactions have no failure reason recorded — this is expected and correct, as every one of these belongs to a successful transaction. Finally, the dataset contains 278 unique customer IDs mapping to only 224 unique names, suggesting some customers may have registered more than once under different IDs. This cannot be safely resolved without additional identifiers such as phone number or email. All analysis uses customer ID as the unique key. Recommended action: engineering should add deduplication logic at the signup stage.

After these fixes the data is in good shape for analysis. Time-based queries will exclude the 44 transactions with missing timestamps — this has negligible impact on findings and will be noted wherever relevant. The customer ID situation has been documented and flagged for the engineering team but does not affect the reliability of the payment failure analysis.

---

### Memo 2 — Payment Failure Findings
**To:** Akosua Asante, CEO
**From:** Sanni Saheed, Data Analyst
**Date:** February 17, 2024
**Re:** Phase 2 Findings — Payment Failure Revenue Impact

---

PayFlow GH is losing GHS 941.68 every month to unrecovered payment failures — totalling GHS 19,580.50 across the two-year analysis period. This is not a single isolated problem. It is driven by a combination of customer-side behaviour and technical infrastructure failures.

The analysis identified two distinct categories of failure. Customer-side problems — insufficient funds, PIN confusion, and daily mobile money limit hits — account for GHS 12,155.50 of total losses and are largely addressable through product design and proactive communication. Technical problems — network timeouts, interoperability errors between mobile money networks, and system-level failures — account for GHS 7,425.00 and require direct engineering intervention. The most urgent finding is that new subscribers are failing at the highest rate of any transaction type — 6.33% — meaning PayFlow is losing customers at the exact moment they are trying to join. The leading cause is PIN confusion on the payment screen, costing GHS 2,541 in lost acquisition revenue. On the network side, AirtelTigo Money carries a 10.30% failure rate — nearly three times MTN MoMo's 3.55% — and 75% of failed MTN and AirtelTigo customers never attempt to retry, compounding the revenue loss.

Five recommendations have been prepared for the product and engineering teams. First, relabel the payment PIN field for new subscribers to clearly specify the mobile money PIN — a low-effort UX fix targeting GHS 2,541 in lost acquisition revenue. Second, deploy automated WhatsApp or SMS retry prompts immediately after any payment failure — projected to recover extra revenue per month if retry rates improve to match Vodafone's 40% organic rate. Third, send balance reminders to customers 24 hours before renewal — directly targeting the GHS 1,946 lost to insufficient funds on renewal payments. Fourth, schedule automated follow-ups the morning after any daily limit failure — since timing is the only barrier. Fifth, escalate network timeouts and interoperability errors to engineering with the full GHS 6,675 revenue impact attached to drive sprint prioritisation.

---

### Memo 3 — Revenue Impact for Finance Review
**To:** Ama Boateng, Finance Manager
**From:** Sanni Saheed, Data Analyst
**Date:** February 17, 2024
**Re:** Methodology & Revenue at Risk — Payment Failure Analysis

---

This memo documents the methodology behind the revenue at risk figures presented to the CEO. All calculations were performed on a cleaned and validated dataset of 2,111 transactions. The cleaning process, assumptions made, and rows excluded are documented in full in the accompanying data review memo and SQL files.

The total revenue at risk figure of GHS 19,580.50 represents the sum of transaction amounts where the payment status is recorded as "failed" and no subsequent recovery was recorded. Transactions with a "recovered" status — where the customer retried and succeeded — are excluded from this figure as the revenue was ultimately collected. The monthly average of GHS 941.68 was calculated by summing failed transaction amounts per calendar month using DATE_TRUNC, excluding the 44 transactions with null timestamps, and averaging across the resulting 20 months of data. This approach was chosen over a simple division by total months to account for months with no failed transactions, which would otherwise deflate the average.

Three assumptions underpin these figures. First, the dataset covers transactions between January 2023 and December 2024 — any failures outside this window are not captured. Second, the 44 transactions with null timestamps were excluded from monthly calculations only — they are included in the total GHS 19,580.50 figure. Third, the retry recovery projection of GHS extra revenue per month is an estimate based on moving MTN and AirtelTigo retry rates to match Vodafone's observed 40% organic rate, assuming a steady retry success rate. This projection should be validated through an A/B test before being used in financial planning.

---

