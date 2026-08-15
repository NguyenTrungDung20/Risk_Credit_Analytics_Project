-- ============================================================
-- RISK CREDIT ANALYTICS PROJECT
-- FILE: 06_loan_analysis.sql
-- PURPOSE: Analyze loan characteristics associated with default outcomes.
-- MYSQL VERSION: 8.0+
-- ============================================================
-- SOURCE: credit_risk_clean
-- READ-ONLY EDA
--
-- TARGET:
-- loan_status = 0 -> Non-default
-- loan_status = 1 -> Default
--
-- ANALYTICAL SCOPE:
-- - Loan purpose
-- - Loan grade
-- - Loan term
-- - Loan amount
-- - Interest rate
-- - Pricing coverage / missing interest-rate behavior
--
-- IMPORTANT:
-- - All findings are descriptive associations, not causal conclusions.
-- - LTI, DTI, utilization, and affordability intersections belong to
--   07_financial_risk.sql and are intentionally excluded here.
-- - A minimum sample-size flag of 100 loans is used only as an
--   analytical warning. It is NOT a lending-policy threshold.
-- ============================================================

USE risk_credit_analytics;


-- ============================================================
-- 1. LOAN PURPOSE
-- ============================================================

-- ------------------------------------------------------------
-- 1.1 Default behavior by loan purpose
-- ------------------------------------------------------------
-- Business question:
-- Do certain loan purposes show materially higher or lower default rates?
--
-- Review default rate together with segment size and exposure.
-- A high rate in a very small segment should not automatically be
-- treated as a major portfolio risk.
-- ------------------------------------------------------------

WITH params AS (
    SELECT 100 AS min_sample_size
),
purpose_summary AS (
    SELECT
        COALESCE(NULLIF(TRIM(loan_intent), ''), 'Unknown') AS loan_purpose,
        COUNT(*) AS loan_count,
        SUM(loan_status = 0) AS non_default_count,
        SUM(loan_status = 1) AS default_count,
        AVG(loan_status = 1) AS default_rate,
        SUM(loan_amnt) AS loan_exposure,
        SUM(CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END)
            AS default_exposure,
        AVG(loan_amnt) AS average_loan_amount,
        AVG(loan_int_rate) AS average_interest_rate,
        COUNT(loan_int_rate) AS valid_interest_rate_loans
    FROM credit_risk_clean
    GROUP BY COALESCE(NULLIF(TRIM(loan_intent), ''), 'Unknown')
),
portfolio_totals AS (
    SELECT
        COUNT(*) AS total_loans,
        SUM(loan_amnt) AS total_exposure
    FROM credit_risk_clean
)
SELECT
    s.loan_purpose,
    s.loan_count,
    ROUND(
        100.0 * s.loan_count / NULLIF(p.total_loans, 0),
        2
    ) AS portfolio_share_pct,
    s.non_default_count,
    s.default_count,
    ROUND(100.0 * s.default_rate, 2) AS default_rate_pct,
    ROUND(s.loan_exposure, 2) AS loan_exposure,
    ROUND(
        100.0 * s.loan_exposure / NULLIF(p.total_exposure, 0),
        2
    ) AS exposure_share_pct,
    ROUND(s.default_exposure, 2) AS default_exposure,
    ROUND(
        100.0 * s.default_exposure / NULLIF(s.loan_exposure, 0),
        2
    ) AS default_exposure_rate_pct,
    ROUND(s.average_loan_amount, 2) AS average_loan_amount,
    ROUND(s.average_interest_rate, 2) AS average_interest_rate,
    ROUND(
        100.0 * s.valid_interest_rate_loans / NULLIF(s.loan_count, 0),
        2
    ) AS interest_rate_coverage_pct,
    CASE
        WHEN s.loan_count >= prm.min_sample_size
        THEN 'Enough sample'
        ELSE 'Small sample'
    END AS sample_size_status
FROM purpose_summary AS s
CROSS JOIN portfolio_totals AS p
CROSS JOIN params AS prm
ORDER BY
    default_rate_pct DESC,
    s.loan_count DESC;


-- ============================================================
-- 2. LOAN GRADE
-- ============================================================

-- ------------------------------------------------------------
-- 2.1 Default behavior by loan grade
-- ------------------------------------------------------------
-- Business question:
-- How strongly does loan grade separate observed loan outcomes,
-- and where is default exposure concentrated?
--
-- 04_overall_risk.sql already identified a strong grade pattern.
-- This query retains grade in the dedicated loan-analysis layer and
-- adds pricing context for later Power BI design.
-- ------------------------------------------------------------

WITH params AS (
    SELECT 100 AS min_sample_size
),
grade_summary AS (
    SELECT
        COALESCE(NULLIF(TRIM(loan_grade), ''), 'Unknown') AS loan_grade,
        COUNT(*) AS loan_count,
        SUM(loan_status = 0) AS non_default_count,
        SUM(loan_status = 1) AS default_count,
        AVG(loan_status = 1) AS default_rate,
        SUM(loan_amnt) AS loan_exposure,
        SUM(CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END)
            AS default_exposure,
        AVG(loan_amnt) AS average_loan_amount,
        AVG(loan_int_rate) AS average_interest_rate,
        COUNT(loan_int_rate) AS valid_interest_rate_loans
    FROM credit_risk_clean
    GROUP BY COALESCE(NULLIF(TRIM(loan_grade), ''), 'Unknown')
),
portfolio_totals AS (
    SELECT
        COUNT(*) AS total_loans,
        SUM(loan_amnt) AS total_exposure
    FROM credit_risk_clean
)
SELECT
    s.loan_grade,
    s.loan_count,
    ROUND(
        100.0 * s.loan_count / NULLIF(p.total_loans, 0),
        2
    ) AS portfolio_share_pct,
    s.non_default_count,
    s.default_count,
    ROUND(100.0 * s.default_rate, 2) AS default_rate_pct,
    ROUND(s.loan_exposure, 2) AS loan_exposure,
    ROUND(
        100.0 * s.loan_exposure / NULLIF(p.total_exposure, 0),
        2
    ) AS exposure_share_pct,
    ROUND(s.default_exposure, 2) AS default_exposure,
    ROUND(
        100.0 * s.default_exposure / NULLIF(s.loan_exposure, 0),
        2
    ) AS default_exposure_rate_pct,
    ROUND(s.average_loan_amount, 2) AS average_loan_amount,
    ROUND(s.average_interest_rate, 2) AS average_interest_rate,
    ROUND(
        100.0 * s.valid_interest_rate_loans / NULLIF(s.loan_count, 0),
        2
    ) AS interest_rate_coverage_pct,
    CASE
        WHEN s.loan_count >= prm.min_sample_size
        THEN 'Enough sample'
        ELSE 'Small sample'
    END AS sample_size_status
FROM grade_summary AS s
CROSS JOIN portfolio_totals AS p
CROSS JOIN params AS prm
ORDER BY
    CASE s.loan_grade
        WHEN 'A' THEN 1
        WHEN 'B' THEN 2
        WHEN 'C' THEN 3
        WHEN 'D' THEN 4
        WHEN 'E' THEN 5
        WHEN 'F' THEN 6
        WHEN 'G' THEN 7
        ELSE 99
    END,
    s.loan_grade;


-- ============================================================
-- 3. LOAN TERM
-- ============================================================

-- ------------------------------------------------------------
-- 3.1 Default behavior by loan term
-- ------------------------------------------------------------
-- Business question:
-- Do different repayment terms show meaningful differences in
-- default rate or exposure?
--
-- Use actual term values rather than arbitrary term bands.
-- ------------------------------------------------------------

WITH params AS (
    SELECT 100 AS min_sample_size
),
term_summary AS (
    SELECT
        loan_term_months,
        COUNT(*) AS loan_count,
        SUM(loan_status = 0) AS non_default_count,
        SUM(loan_status = 1) AS default_count,
        AVG(loan_status = 1) AS default_rate,
        SUM(loan_amnt) AS loan_exposure,
        SUM(CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END)
            AS default_exposure,
        AVG(loan_amnt) AS average_loan_amount,
        AVG(loan_int_rate) AS average_interest_rate,
        COUNT(loan_int_rate) AS valid_interest_rate_loans
    FROM credit_risk_clean
    GROUP BY loan_term_months
),
portfolio_totals AS (
    SELECT
        COUNT(*) AS total_loans,
        SUM(loan_amnt) AS total_exposure
    FROM credit_risk_clean
)
SELECT
    s.loan_term_months,
    s.loan_count,
    ROUND(
        100.0 * s.loan_count / NULLIF(p.total_loans, 0),
        2
    ) AS portfolio_share_pct,
    s.non_default_count,
    s.default_count,
    ROUND(100.0 * s.default_rate, 2) AS default_rate_pct,
    ROUND(s.loan_exposure, 2) AS loan_exposure,
    ROUND(
        100.0 * s.loan_exposure / NULLIF(p.total_exposure, 0),
        2
    ) AS exposure_share_pct,
    ROUND(s.default_exposure, 2) AS default_exposure,
    ROUND(
        100.0 * s.default_exposure / NULLIF(s.loan_exposure, 0),
        2
    ) AS default_exposure_rate_pct,
    ROUND(s.average_loan_amount, 2) AS average_loan_amount,
    ROUND(s.average_interest_rate, 2) AS average_interest_rate,
    ROUND(
        100.0 * s.valid_interest_rate_loans / NULLIF(s.loan_count, 0),
        2
    ) AS interest_rate_coverage_pct,
    CASE
        WHEN s.loan_count >= prm.min_sample_size
        THEN 'Enough sample'
        ELSE 'Small sample'
    END AS sample_size_status
FROM term_summary AS s
CROSS JOIN portfolio_totals AS p
CROSS JOIN params AS prm
ORDER BY s.loan_term_months;


-- ============================================================
-- 4. LOAN AMOUNT
-- ============================================================

-- ------------------------------------------------------------
-- 4.1 Loan amount distribution checkpoint
-- ------------------------------------------------------------
-- Business question:
-- How is loan amount distributed before interpreting amount bands?
--
-- The output validates whether the band definitions used in 4.2
-- remain sensible for this portfolio.
-- ------------------------------------------------------------

WITH amount_ranked AS (
    SELECT
        loan_amnt,
        ROW_NUMBER() OVER (ORDER BY loan_amnt) AS row_num,
        COUNT(*) OVER () AS total_rows
    FROM credit_risk_clean
    WHERE loan_amnt IS NOT NULL
)
SELECT
    COUNT(*) AS valid_loan_amount_observations,
    ROUND(MIN(loan_amnt), 2) AS min_loan_amount,
    ROUND(MAX(
        CASE
            WHEN row_num = CEIL(total_rows * 0.25)
            THEN loan_amnt
        END
    ), 2) AS p25_loan_amount,
    ROUND(AVG(
        CASE
            WHEN row_num IN (
                FLOOR((total_rows + 1) / 2),
                CEIL((total_rows + 1) / 2)
            )
            THEN loan_amnt
        END
    ), 2) AS median_loan_amount,
    ROUND(AVG(loan_amnt), 2) AS average_loan_amount,
    ROUND(MAX(
        CASE
            WHEN row_num = CEIL(total_rows * 0.75)
            THEN loan_amnt
        END
    ), 2) AS p75_loan_amount,
    ROUND(MAX(loan_amnt), 2) AS max_loan_amount
FROM amount_ranked;


-- ------------------------------------------------------------
-- 4.2 Default behavior by loan amount band
-- ------------------------------------------------------------
-- Business question:
-- Does observed default rate increase as the amount borrowed rises?
--
-- Bands are business-readable and are based on the observed portfolio
-- distribution from the Overall Risk stage. They are analytical bands,
-- NOT lending-policy cutoffs.
--
-- <5K
-- 5K-10K
-- 10K-15K
-- 15K-20K
-- 20K+
-- ------------------------------------------------------------

WITH params AS (
    SELECT 100 AS min_sample_size
),
amount_segments AS (
    SELECT
        CASE
            WHEN loan_amnt IS NULL THEN 'Unknown'
            WHEN loan_amnt < 5000 THEN '<5K'
            WHEN loan_amnt < 10000 THEN '5K-10K'
            WHEN loan_amnt < 15000 THEN '10K-15K'
            WHEN loan_amnt < 20000 THEN '15K-20K'
            ELSE '20K+'
        END AS loan_amount_band,
        CASE
            WHEN loan_amnt IS NULL THEN 99
            WHEN loan_amnt < 5000 THEN 1
            WHEN loan_amnt < 10000 THEN 2
            WHEN loan_amnt < 15000 THEN 3
            WHEN loan_amnt < 20000 THEN 4
            ELSE 5
        END AS band_order,
        loan_status,
        loan_amnt,
        loan_int_rate
    FROM credit_risk_clean
),
amount_summary AS (
    SELECT
        loan_amount_band,
        band_order,
        COUNT(*) AS loan_count,
        SUM(loan_status = 0) AS non_default_count,
        SUM(loan_status = 1) AS default_count,
        AVG(loan_status = 1) AS default_rate,
        SUM(loan_amnt) AS loan_exposure,
        SUM(CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END)
            AS default_exposure,
        AVG(loan_amnt) AS average_loan_amount,
        AVG(loan_int_rate) AS average_interest_rate,
        COUNT(loan_int_rate) AS valid_interest_rate_loans
    FROM amount_segments
    GROUP BY loan_amount_band, band_order
),
portfolio_totals AS (
    SELECT
        COUNT(*) AS total_loans,
        SUM(loan_amnt) AS total_exposure
    FROM credit_risk_clean
)
SELECT
    s.loan_amount_band,
    s.loan_count,
    ROUND(
        100.0 * s.loan_count / NULLIF(p.total_loans, 0),
        2
    ) AS portfolio_share_pct,
    s.non_default_count,
    s.default_count,
    ROUND(100.0 * s.default_rate, 2) AS default_rate_pct,
    ROUND(s.loan_exposure, 2) AS loan_exposure,
    ROUND(
        100.0 * s.loan_exposure / NULLIF(p.total_exposure, 0),
        2
    ) AS exposure_share_pct,
    ROUND(s.default_exposure, 2) AS default_exposure,
    ROUND(
        100.0 * s.default_exposure / NULLIF(s.loan_exposure, 0),
        2
    ) AS default_exposure_rate_pct,
    ROUND(s.average_loan_amount, 2) AS average_loan_amount,
    ROUND(s.average_interest_rate, 2) AS average_interest_rate,
    ROUND(
        100.0 * s.valid_interest_rate_loans / NULLIF(s.loan_count, 0),
        2
    ) AS interest_rate_coverage_pct,
    CASE
        WHEN s.loan_count >= prm.min_sample_size
        THEN 'Enough sample'
        ELSE 'Small sample'
    END AS sample_size_status
FROM amount_summary AS s
CROSS JOIN portfolio_totals AS p
CROSS JOIN params AS prm
ORDER BY s.band_order;


-- ============================================================
-- 5. INTEREST RATE
-- ============================================================

-- ------------------------------------------------------------
-- 5.1 Interest-rate distribution checkpoint
-- ------------------------------------------------------------
-- Business question:
-- How is available loan pricing distributed before rate bands
-- are interpreted?
--
-- Only non-null interest rates are included.
-- ------------------------------------------------------------

WITH rate_ranked AS (
    SELECT
        loan_int_rate,
        ROW_NUMBER() OVER (ORDER BY loan_int_rate) AS row_num,
        COUNT(*) OVER () AS total_rows
    FROM credit_risk_clean
    WHERE loan_int_rate IS NOT NULL
)
SELECT
    COUNT(*) AS valid_interest_rate_observations,
    ROUND(MIN(loan_int_rate), 2) AS min_interest_rate,
    ROUND(MAX(
        CASE
            WHEN row_num = CEIL(total_rows * 0.25)
            THEN loan_int_rate
        END
    ), 2) AS p25_interest_rate,
    ROUND(AVG(
        CASE
            WHEN row_num IN (
                FLOOR((total_rows + 1) / 2),
                CEIL((total_rows + 1) / 2)
            )
            THEN loan_int_rate
        END
    ), 2) AS median_interest_rate,
    ROUND(AVG(loan_int_rate), 2) AS average_interest_rate,
    ROUND(MAX(
        CASE
            WHEN row_num = CEIL(total_rows * 0.75)
            THEN loan_int_rate
        END
    ), 2) AS p75_interest_rate,
    ROUND(MAX(loan_int_rate), 2) AS max_interest_rate
FROM rate_ranked;


-- ------------------------------------------------------------
-- 5.2 Default behavior by interest-rate band
-- ------------------------------------------------------------
-- Business question:
-- How does observed default rate change across loan-pricing levels?
--
-- Bands are informed by the distribution observed in 04_overall_risk:
-- status_0 and status_1 showed materially different quartiles.
--
-- <8%
-- 8%-10%
-- 10%-12%
-- 12%-15%
-- 15%+
-- Unknown is retained separately because 9.56% of the portfolio
-- has no usable interest-rate value.
--
-- These are analytical bands, NOT pricing-policy thresholds.
-- ------------------------------------------------------------

WITH params AS (
    SELECT 100 AS min_sample_size
),
rate_segments AS (
    SELECT
        CASE
            WHEN loan_int_rate IS NULL THEN 'Unknown'
            WHEN loan_int_rate < 8 THEN '<8%'
            WHEN loan_int_rate < 10 THEN '8%-10%'
            WHEN loan_int_rate < 12 THEN '10%-12%'
            WHEN loan_int_rate < 15 THEN '12%-15%'
            ELSE '15%+'
        END AS interest_rate_band,
        CASE
            WHEN loan_int_rate IS NULL THEN 99
            WHEN loan_int_rate < 8 THEN 1
            WHEN loan_int_rate < 10 THEN 2
            WHEN loan_int_rate < 12 THEN 3
            WHEN loan_int_rate < 15 THEN 4
            ELSE 5
        END AS band_order,
        loan_status,
        loan_amnt,
        loan_int_rate
    FROM credit_risk_clean
),
rate_summary AS (
    SELECT
        interest_rate_band,
        band_order,
        COUNT(*) AS loan_count,
        SUM(loan_status = 0) AS non_default_count,
        SUM(loan_status = 1) AS default_count,
        AVG(loan_status = 1) AS default_rate,
        SUM(loan_amnt) AS loan_exposure,
        SUM(CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END)
            AS default_exposure,
        AVG(loan_amnt) AS average_loan_amount,
        AVG(loan_int_rate) AS average_interest_rate
    FROM rate_segments
    GROUP BY interest_rate_band, band_order
),
portfolio_totals AS (
    SELECT
        COUNT(*) AS total_loans,
        SUM(loan_amnt) AS total_exposure
    FROM credit_risk_clean
)
SELECT
    s.interest_rate_band,
    s.loan_count,
    ROUND(
        100.0 * s.loan_count / NULLIF(p.total_loans, 0),
        2
    ) AS portfolio_share_pct,
    s.non_default_count,
    s.default_count,
    ROUND(100.0 * s.default_rate, 2) AS default_rate_pct,
    ROUND(s.loan_exposure, 2) AS loan_exposure,
    ROUND(
        100.0 * s.loan_exposure / NULLIF(p.total_exposure, 0),
        2
    ) AS exposure_share_pct,
    ROUND(s.default_exposure, 2) AS default_exposure,
    ROUND(
        100.0 * s.default_exposure / NULLIF(s.loan_exposure, 0),
        2
    ) AS default_exposure_rate_pct,
    ROUND(s.average_loan_amount, 2) AS average_loan_amount,
    ROUND(s.average_interest_rate, 2) AS average_interest_rate,
    CASE
        WHEN s.loan_count >= prm.min_sample_size
        THEN 'Enough sample'
        ELSE 'Small sample'
    END AS sample_size_status
FROM rate_summary AS s
CROSS JOIN portfolio_totals AS p
CROSS JOIN params AS prm
ORDER BY s.band_order;


-- ============================================================
-- 6. PRICING COVERAGE AND MISSING INTEREST RATE
-- ============================================================

-- ------------------------------------------------------------
-- 6.1 Outcome behavior when interest-rate data is available vs missing
-- ------------------------------------------------------------
-- Business question:
-- Do loans with missing pricing information show materially different
-- default behavior from loans with available pricing?
--
-- Missing pricing is treated as a data/process signal, not as a cause
-- of default.
-- ------------------------------------------------------------

WITH pricing_status AS (
    SELECT
        CASE
            WHEN loan_int_rate IS NULL
            THEN 'Interest Rate Missing'
            ELSE 'Interest Rate Available'
        END AS pricing_data_status,
        loan_status,
        loan_amnt
    FROM credit_risk_clean
),
pricing_summary AS (
    SELECT
        pricing_data_status,
        COUNT(*) AS loan_count,
        SUM(loan_status = 0) AS non_default_count,
        SUM(loan_status = 1) AS default_count,
        AVG(loan_status = 1) AS default_rate,
        SUM(loan_amnt) AS loan_exposure,
        SUM(CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END)
            AS default_exposure,
        AVG(loan_amnt) AS average_loan_amount
    FROM pricing_status
    GROUP BY pricing_data_status
),
portfolio_totals AS (
    SELECT
        COUNT(*) AS total_loans,
        SUM(loan_amnt) AS total_exposure
    FROM credit_risk_clean
)
SELECT
    s.pricing_data_status,
    s.loan_count,
    ROUND(
        100.0 * s.loan_count / NULLIF(p.total_loans, 0),
        2
    ) AS portfolio_share_pct,
    s.non_default_count,
    s.default_count,
    ROUND(100.0 * s.default_rate, 2) AS default_rate_pct,
    ROUND(s.loan_exposure, 2) AS loan_exposure,
    ROUND(
        100.0 * s.loan_exposure / NULLIF(p.total_exposure, 0),
        2
    ) AS exposure_share_pct,
    ROUND(s.default_exposure, 2) AS default_exposure,
    ROUND(
        100.0 * s.default_exposure / NULLIF(s.loan_exposure, 0),
        2
    ) AS default_exposure_rate_pct,
    ROUND(s.average_loan_amount, 2) AS average_loan_amount
FROM pricing_summary AS s
CROSS JOIN portfolio_totals AS p
ORDER BY default_rate_pct DESC;


-- ------------------------------------------------------------
-- 6.2 Interest-rate coverage by loan grade
-- ------------------------------------------------------------
-- Business question:
-- Is missing pricing information concentrated in particular loan grades?
--
-- This check is important before interpreting the relationship between
-- loan grade, interest rate, and default.
-- ------------------------------------------------------------

WITH grade_pricing_coverage AS (
    SELECT
        COALESCE(NULLIF(TRIM(loan_grade), ''), 'Unknown') AS loan_grade,
        COUNT(*) AS loan_count,
        COUNT(loan_int_rate) AS valid_interest_rate_loans,

        SUM(
            CASE
                WHEN loan_int_rate IS NULL THEN 1
                ELSE 0
            END
        ) AS missing_interest_rate_loans,

        ROUND(
            100.0 * COUNT(loan_int_rate)
            / NULLIF(COUNT(*), 0),
            2
        ) AS interest_rate_coverage_pct,

        ROUND(
            100.0 * SUM(
                CASE
                    WHEN loan_int_rate IS NULL THEN 1
                    ELSE 0
                END
            )
            / NULLIF(COUNT(*), 0),
            2
        ) AS missing_interest_rate_pct

    FROM credit_risk_clean

    GROUP BY
        COALESCE(NULLIF(TRIM(loan_grade), ''), 'Unknown')
)

SELECT *
FROM grade_pricing_coverage

ORDER BY
    CASE loan_grade
        WHEN 'A' THEN 1
        WHEN 'B' THEN 2
        WHEN 'C' THEN 3
        WHEN 'D' THEN 4
        WHEN 'E' THEN 5
        WHEN 'F' THEN 6
        WHEN 'G' THEN 7
        ELSE 99
    END;


-- ============================================================
-- 7. LOAN ANALYSIS CHECKPOINT
-- ============================================================

-- ------------------------------------------------------------
-- 7.1 Compare average loan size and pricing between default outcomes
-- ------------------------------------------------------------
-- Business question:
-- After segment-level analysis, do the broad loan-level differences
-- observed in 04_overall_risk still provide a consistent checkpoint?
--
-- This query is intentionally compact and does not replace the
-- detailed segment analyses above.
-- ------------------------------------------------------------

SELECT
    CASE
        WHEN loan_status = 0 THEN 'Non-default'
        WHEN loan_status = 1 THEN 'Default'
        ELSE 'Unknown'
    END AS loan_outcome,
    COUNT(*) AS loan_count,
    ROUND(AVG(loan_amnt), 2) AS average_loan_amount,
    ROUND(AVG(loan_int_rate), 2) AS average_interest_rate,
    ROUND(
        100.0 * COUNT(loan_int_rate) / NULLIF(COUNT(*), 0),
        2
    ) AS interest_rate_coverage_pct,
    ROUND(SUM(loan_amnt), 2) AS loan_exposure
FROM credit_risk_clean
GROUP BY loan_status
ORDER BY loan_status;


-- ============================================================
-- END OF 06_LOAN_ANALYSIS.SQL
-- ============================================================
-- REVIEW CHECKPOINT
--
-- Review the result grids before proceeding to 07_financial_risk.sql.
--
-- Priority outputs for interpretation:
-- 1.1 Loan purpose
-- 2.1 Loan grade
-- 3.1 Loan term
-- 4.2 Loan amount bands
-- 5.2 Interest-rate bands
-- 6.1 Missing vs available interest-rate behavior
-- 6.2 Interest-rate coverage by grade
--
-- Questions to answer before 07:
-- 1. Which loan purposes have materially higher default rates?
-- 2. Does the grade pattern remain monotonic and material after
--    considering segment size and exposure?
-- 3. Does default rate increase with loan amount?
-- 4. Does default rate increase with interest rate?
-- 5. Does term materially differentiate default risk?
-- 6. Are missing interest rates associated with a different outcome
--    profile or concentrated in specific grades?
--
-- Do not build final risk segmentation yet.
-- ============================================================