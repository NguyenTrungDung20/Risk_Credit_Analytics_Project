# SQL EDA Plan

Source table: `credit_risk_clean`

All EDA queries are read-only. MySQL is responsible for calculation,
aggregation, banding, and analytical views. Power BI is responsible for
visualization, filtering, drill-down, and presentation measures.

## 04 - Overall Risk

File: `sql/04_overall_risk.sql`

- Establish portfolio size, outcome balance, and loan exposure.
- Compare outcome classes using financial and borrower averages.
- Review robust quartiles alongside averages.
- Quantify missingness and cleaning flags in analytical context.
- Confirm initial outcome patterns by loan grade and previous-default flag.

## 05 - Borrower Profile

Planned file: `sql/05_borrower_profile.sql`

- Age and income bands.
- Gender, marital status, and education.
- Employment type and employment length.
- Home ownership.
- Segment size, status-1 rate, exposure, and minimum sample size.

## 06 - Loan Analysis

Planned file: `sql/06_loan_analysis.sql`

- Loan purpose, grade, term, amount, and interest-rate bands.
- Pricing coverage and missing-interest-rate behavior.
- Loan volume and outcome rate by product dimensions.

## 07 - Financial Risk

Planned file: `sql/07_financial_risk.sql`

- Loan-to-income, debt-to-income, and utilization bands.
- Other debt and combined affordability indicators.
- High-risk intersections and exposure concentration.

## 08 - Credit And Stability

Planned file: `sql/08_credit_stability.sql`

- Credit history length, open accounts, and past delinquencies.
- Previous default history.
- Employment and housing stability intersections.

## 09 - Geography And Segmentation

Planned file: `sql/09_geographic_segmentation.sql`

- Country, state, and city performance with sample-size controls.
- Multi-factor risk segments.
- Ranked business opportunities and risk concentrations.

## 10 - Power BI Views

Planned file: `sql/10_powerbi_views.sql`

- Publish stable analytical views based on confirmed EDA logic.
- Keep labels, bands, and metrics consistent between MySQL and Power BI.

## Interpretation Control

Until source documentation confirms the business mapping of `loan_status`,
all EDA uses the neutral terms `status_0`, `status_1`, and `status_1_rate`.
No class should be labeled as default solely from statistical association.
