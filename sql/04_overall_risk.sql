-- ============================================================
-- RISK CREDIT ANALYTICS PROJECT
-- FILE: 04_overall_risk.sql
-- PURPOSE: Establish the portfolio-level outcome baseline for EDA.
-- MYSQL VERSION: 8.0+
-- ============================================================
-- SOURCE: credit_risk_clean only.
-- This file is read-only. Run one numbered query at a time.
--
-- CLEANED-TABLE GRAIN
-- Validation confirmed 32,581 rows, 32,581 distinct client_ID values,
-- and one primary-key column on client_ID. For the current snapshot,
-- each row is therefore one loan record linked to one distinct client.
--
-- TARGET INTERPRETATION CONTROL
-- loan_status contains only 0 and 1, but their business mapping has
-- not been independently confirmed from authoritative documentation.
-- Use only status_0, status_1, and status_1_rate terminology.
-- ============================================================

USE risk_credit_analytics;

-- ============================================================
-- 1. PORTFOLIO OVERVIEW
-- ============================================================

-- 1.1 Portfolio size and pricing coverage.
-- Business question:
-- How large is the portfolio, and how complete is loan pricing data?
-- Median loan amount is calculated as the midpoint of the one or two
-- central ordered observations, which is compatible with MySQL 8.0.
WITH ranked_loan_amounts AS (
    SELECT
        loan_amnt,
        ROW_NUMBER() OVER (ORDER BY loan_amnt) AS row_num,
        COUNT(*) OVER () AS total_rows
    FROM credit_risk_clean
), loan_amount_summary AS (
    SELECT
        AVG(
            CASE
                WHEN row_num IN (
                    FLOOR((total_rows + 1) / 2),
                    CEIL((total_rows + 1) / 2)
                ) THEN loan_amnt
            END
        ) AS median_loan_amount
    FROM ranked_loan_amounts
), portfolio_summary AS (
    SELECT
        COUNT(*) AS total_loans,
        COUNT(DISTINCT client_ID) AS distinct_clients,
        SUM(loan_amnt) AS total_loan_exposure,
        AVG(loan_amnt) AS average_loan_amount,
        AVG(loan_int_rate) AS average_interest_rate,
        COUNT(loan_int_rate) AS valid_interest_rate_loans,
        COUNT(*) AS total_interest_rate_loans
    FROM credit_risk_clean
)
SELECT
    p.total_loans,
    p.distinct_clients,
    ROUND(p.total_loan_exposure, 2) AS total_loan_exposure,
    ROUND(p.average_loan_amount, 2) AS average_loan_amount,
    ROUND(l.median_loan_amount, 2) AS median_loan_amount,
    ROUND(p.average_interest_rate, 2) AS average_interest_rate,
    p.valid_interest_rate_loans,
    ROUND(
        100.0 * p.valid_interest_rate_loans
        / NULLIF(p.total_interest_rate_loans, 0),
        2
    ) AS interest_rate_coverage_pct
FROM portfolio_summary AS p
CROSS JOIN loan_amount_summary AS l;

-- ============================================================
-- 2. OUTCOME DISTRIBUTION
-- ============================================================

-- 2.1 Loan-count and exposure distribution by outcome.
-- Business question:
-- What share of loans and loan exposure belongs to each outcome?
WITH outcome_summary AS (
    SELECT
        loan_status,
        COUNT(*) AS loan_count,
        SUM(loan_amnt) AS loan_exposure
    FROM credit_risk_clean
    GROUP BY loan_status
), portfolio_totals AS (
    SELECT
        COUNT(*) AS total_loans,
        SUM(loan_amnt) AS total_loan_exposure,
        AVG(loan_status = 1) AS status_1_rate
    FROM credit_risk_clean
)
SELECT
    o.loan_status,
    o.loan_count,
    ROUND(
        100.0 * o.loan_count / NULLIF(p.total_loans, 0),
        2
    ) AS pct_of_loans,
    ROUND(o.loan_exposure, 2) AS loan_exposure,
    ROUND(
        100.0 * o.loan_exposure
        / NULLIF(p.total_loan_exposure, 0),
        2
    ) AS pct_of_exposure,
    ROUND(100.0 * p.status_1_rate, 2) AS portfolio_status_1_rate_pct
FROM outcome_summary AS o
CROSS JOIN portfolio_totals AS p
ORDER BY o.loan_status;

-- ============================================================
-- 3. OUTCOME FINANCIAL COMPARISON
-- ============================================================

-- 3.1 Robust financial statistics by outcome.
-- Business question:
-- How do the two outcome groups differ in their overall financial
-- characteristics without creating detailed borrower segments?
-- P25 and P75 use the nearest-rank method. The median is the midpoint
-- of the one or two central observations. Coverage is shown because
-- loan_int_rate contains intentional NULL values after cleaning.
WITH financial_values AS (
    SELECT loan_status, 'person_income' AS metric_name,
           person_income AS metric_value
    FROM credit_risk_clean

    UNION ALL
    SELECT loan_status, 'loan_amnt', loan_amnt
    FROM credit_risk_clean

    UNION ALL
    SELECT loan_status, 'loan_int_rate', loan_int_rate
    FROM credit_risk_clean
    WHERE loan_int_rate IS NOT NULL

    UNION ALL
    SELECT loan_status, 'loan_to_income_ratio', loan_to_income_ratio
    FROM credit_risk_clean

    UNION ALL
    SELECT loan_status, 'debt_to_income_ratio', debt_to_income_ratio
    FROM credit_risk_clean

    UNION ALL
    SELECT loan_status, 'credit_utilization_ratio', credit_utilization_ratio
    FROM credit_risk_clean

    UNION ALL
    SELECT loan_status, 'other_debt', other_debt
    FROM credit_risk_clean

    UNION ALL
    SELECT loan_status, 'loan_term_months', loan_term_months
    FROM credit_risk_clean
), ranked_values AS (
    SELECT
        loan_status,
        metric_name,
        metric_value,
        ROW_NUMBER() OVER (
            PARTITION BY loan_status, metric_name
            ORDER BY metric_value
        ) AS row_num,
        COUNT(*) OVER (
            PARTITION BY loan_status, metric_name
        ) AS valid_observations
    FROM financial_values
), outcome_counts AS (
    SELECT loan_status, COUNT(*) AS outcome_loan_count
    FROM credit_risk_clean
    GROUP BY loan_status
)
SELECT
    r.loan_status,
    r.metric_name,
    MAX(r.valid_observations) AS valid_observations,
    ROUND(
        100.0 * MAX(r.valid_observations)
        / NULLIF(MAX(o.outcome_loan_count), 0),
        2
    ) AS coverage_pct,
    ROUND(MIN(r.metric_value), 4) AS min_value,
    ROUND(MAX(
        CASE
            WHEN r.row_num = CEIL(r.valid_observations * 0.25)
            THEN r.metric_value
        END
    ), 4) AS p25_value,
    ROUND(AVG(
        CASE
            WHEN r.row_num IN (
                FLOOR((r.valid_observations + 1) / 2),
                CEIL((r.valid_observations + 1) / 2)
            ) THEN r.metric_value
        END
    ), 4) AS median_value,
    ROUND(AVG(r.metric_value), 4) AS average_value,
    ROUND(MAX(
        CASE
            WHEN r.row_num = CEIL(r.valid_observations * 0.75)
            THEN r.metric_value
        END
    ), 4) AS p75_value,
    ROUND(MAX(r.metric_value), 4) AS max_value
FROM ranked_values AS r
JOIN outcome_counts AS o
  ON r.loan_status = o.loan_status
GROUP BY r.loan_status, r.metric_name
ORDER BY
    r.loan_status,
    FIELD(
        r.metric_name,
        'person_income',
        'loan_amnt',
        'loan_int_rate',
        'loan_to_income_ratio',
        'debt_to_income_ratio',
        'credit_utilization_ratio',
        'other_debt',
        'loan_term_months'
    );

-- ============================================================
-- 4. OUTCOME BORROWER COMPARISON
-- ============================================================

-- 4.1 Broad borrower and credit characteristics by outcome.
-- Business question:
-- How do the two outcome groups differ in broad borrower and credit
-- characteristics before any detailed demographic banding?
SELECT
    loan_status,
    COUNT(*) AS loan_count,
    COUNT(person_age) AS valid_age_observations,
    ROUND(
        100.0 * COUNT(person_age) / NULLIF(COUNT(*), 0),
        2
    ) AS age_coverage_pct,
    ROUND(AVG(person_age), 2) AS average_age,
    COUNT(person_emp_length) AS valid_emp_length_observations,
    ROUND(
        100.0 * COUNT(person_emp_length) / NULLIF(COUNT(*), 0),
        2
    ) AS emp_length_coverage_pct,
    ROUND(AVG(person_emp_length), 2) AS average_emp_length,
    ROUND(AVG(cb_person_cred_hist_length), 2)
        AS average_credit_history_length,
    ROUND(AVG(open_accounts), 2) AS average_open_accounts,
    ROUND(AVG(past_delinquencies), 4) AS average_past_delinquencies
FROM credit_risk_clean
GROUP BY loan_status
ORDER BY loan_status;

-- ============================================================
-- 5. ANALYTICAL DATA COVERAGE
-- ============================================================

-- 5.1 Coverage of nullable metrics used in this file.
-- Business question:
-- How much data supports the nullable metrics used in this baseline?
WITH metric_coverage AS (
    SELECT
        'person_age' AS metric_name,
        COUNT(*) AS total_loans,
        COUNT(person_age) AS valid_observations
    FROM credit_risk_clean

    UNION ALL
    SELECT
        'person_emp_length',
        COUNT(*),
        COUNT(person_emp_length)
    FROM credit_risk_clean

    UNION ALL
    SELECT
        'loan_int_rate',
        COUNT(*),
        COUNT(loan_int_rate)
    FROM credit_risk_clean
)
SELECT
    metric_name,
    total_loans,
    valid_observations,
    total_loans - valid_observations AS missing_observations,
    ROUND(
        100.0 * valid_observations / NULLIF(total_loans, 0),
        2
    ) AS coverage_pct
FROM metric_coverage
ORDER BY FIELD(
    metric_name,
    'person_age',
    'person_emp_length',
    'loan_int_rate'
);

-- 5.2 Cleaning flags that affect baseline interpretation.
-- Business question:
-- Which important cleaning conditions should qualify interpretation
-- of the metrics in this file?
WITH flag_summary AS (
    SELECT 'age_invalid' AS flag_name,
           SUM(is_age_invalid) AS affected_loans
    FROM credit_risk_clean

    UNION ALL
    SELECT 'employment_length_missing', SUM(is_emp_length_missing)
    FROM credit_risk_clean

    UNION ALL
    SELECT 'employment_length_invalid', SUM(is_emp_length_invalid)
    FROM credit_risk_clean

    UNION ALL
    SELECT 'interest_rate_missing', SUM(is_loan_int_rate_missing)
    FROM credit_risk_clean

    UNION ALL
    SELECT 'high_dti', SUM(is_high_dti)
    FROM credit_risk_clean
)
SELECT
    flag_name,
    affected_loans,
    ROUND(
        100.0 * affected_loans
        / NULLIF((SELECT COUNT(*) FROM credit_risk_clean), 0),
        2
    ) AS affected_pct
FROM flag_summary
ORDER BY affected_loans DESC, flag_name;

-- ============================================================
-- 6. INITIAL OUTCOME SIGNALS
-- ============================================================

-- 6.1 Initial outcome pattern by loan grade.
-- Business question:
-- Does loan grade show an initial descriptive outcome pattern after
-- accounting for both segment size and loan exposure?
WITH grade_summary AS (
    SELECT
        loan_grade,
        COUNT(*) AS loan_count,
        SUM(loan_status = 0) AS status_0_count,
        SUM(loan_status = 1) AS status_1_count,
        AVG(loan_status = 1) AS status_1_rate,
        SUM(loan_amnt) AS loan_exposure,
        SUM(CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END)
            AS status_1_exposure
    FROM credit_risk_clean
    GROUP BY loan_grade
), portfolio_totals AS (
    SELECT
        COUNT(*) AS total_loans,
        SUM(loan_amnt) AS total_loan_exposure
    FROM credit_risk_clean
)
SELECT
    g.loan_grade,
    g.loan_count,
    ROUND(
        100.0 * g.loan_count / NULLIF(p.total_loans, 0),
        2
    ) AS portfolio_share_pct,
    g.status_0_count,
    g.status_1_count,
    ROUND(100.0 * g.status_1_rate, 2) AS status_1_rate_pct,
    ROUND(g.loan_exposure, 2) AS loan_exposure,
    ROUND(
        100.0 * g.loan_exposure
        / NULLIF(p.total_loan_exposure, 0),
        2
    ) AS exposure_share_pct,
    ROUND(g.status_1_exposure, 2) AS status_1_exposure,
    ROUND(
        100.0 * g.status_1_exposure
        / NULLIF(g.loan_exposure, 0),
        2
    ) AS status_1_exposure_pct
FROM grade_summary AS g
CROSS JOIN portfolio_totals AS p
ORDER BY g.loan_grade;

-- 6.2 Initial outcome pattern by previous-default-on-file status.
-- Business question:
-- Does previous-default-on-file status show an initial descriptive
-- outcome pattern after accounting for segment size and exposure?
WITH previous_default_summary AS (
    SELECT
        cb_person_default_on_file,
        COUNT(*) AS loan_count,
        SUM(loan_status = 0) AS status_0_count,
        SUM(loan_status = 1) AS status_1_count,
        AVG(loan_status = 1) AS status_1_rate,
        SUM(loan_amnt) AS loan_exposure,
        SUM(CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END)
            AS status_1_exposure
    FROM credit_risk_clean
    GROUP BY cb_person_default_on_file
), portfolio_totals AS (
    SELECT
        COUNT(*) AS total_loans,
        SUM(loan_amnt) AS total_loan_exposure
    FROM credit_risk_clean
)
SELECT
    d.cb_person_default_on_file,
    d.loan_count,
    ROUND(
        100.0 * d.loan_count / NULLIF(p.total_loans, 0),
        2
    ) AS portfolio_share_pct,
    d.status_0_count,
    d.status_1_count,
    ROUND(100.0 * d.status_1_rate, 2) AS status_1_rate_pct,
    ROUND(d.loan_exposure, 2) AS loan_exposure,
    ROUND(
        100.0 * d.loan_exposure
        / NULLIF(p.total_loan_exposure, 0),
        2
    ) AS exposure_share_pct,
    ROUND(d.status_1_exposure, 2) AS status_1_exposure,
    ROUND(
        100.0 * d.status_1_exposure
        / NULLIF(d.loan_exposure, 0),
        2
    ) AS status_1_exposure_pct
FROM previous_default_summary AS d
CROSS JOIN portfolio_totals AS p
ORDER BY d.cb_person_default_on_file;


