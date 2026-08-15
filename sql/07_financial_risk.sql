-- ============================================================
-- RISK CREDIT ANALYTICS PROJECT
-- FILE: 07_financial_risk.sql
-- PURPOSE: Analyze borrower affordability and financial-risk indicators
--          associated with default outcomes.
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
-- - Loan-to-Income Ratio (LTI)
-- - Debt-to-Income Ratio (DTI)
-- - Credit Utilization Ratio
-- - Other Debt
-- - LTI x DTI intersections
-- - Exposure concentration in elevated affordability conditions
--
-- IMPORTANT:
-- - All findings are descriptive associations, not causal conclusions.
-- - Band boundaries are analytical review bands, NOT lending-policy
--   approval thresholds.
-- - Final multi-factor risk segmentation belongs to
--   09_geographic_segmentation.sql.
-- - Minimum sample size = 100 is only an analytical warning.
-- ============================================================

USE risk_credit_analytics;


-- ============================================================
-- 1. LOAN-TO-INCOME RATIO
-- ============================================================

-- ------------------------------------------------------------
-- 1.1 LTI distribution checkpoint
-- ------------------------------------------------------------
-- Business question:
-- How is Loan-to-Income Ratio distributed before interpreting
-- affordability bands?
--
-- 04_overall_risk.sql showed:
-- status_0 median LTI = 0.1333
-- status_1 median LTI = 0.2392
-- ------------------------------------------------------------

WITH ranked_lti AS (
    SELECT
        loan_to_income_ratio,
        ROW_NUMBER() OVER (ORDER BY loan_to_income_ratio) AS row_num,
        COUNT(*) OVER () AS total_rows
    FROM credit_risk_clean
    WHERE loan_to_income_ratio IS NOT NULL
)
SELECT
    COUNT(*) AS valid_lti_observations,
    ROUND(MIN(loan_to_income_ratio), 4) AS min_lti,

    ROUND(MAX(
        CASE
            WHEN row_num = CEIL(total_rows * 0.25)
            THEN loan_to_income_ratio
        END
    ), 4) AS p25_lti,

    ROUND(AVG(
        CASE
            WHEN row_num IN (
                FLOOR((total_rows + 1) / 2),
                CEIL((total_rows + 1) / 2)
            )
            THEN loan_to_income_ratio
        END
    ), 4) AS median_lti,

    ROUND(AVG(loan_to_income_ratio), 4) AS average_lti,

    ROUND(MAX(
        CASE
            WHEN row_num = CEIL(total_rows * 0.75)
            THEN loan_to_income_ratio
        END
    ), 4) AS p75_lti,

    ROUND(MAX(loan_to_income_ratio), 4) AS max_lti

FROM ranked_lti;


-- ------------------------------------------------------------
-- 1.2 Default behavior by LTI band
-- ------------------------------------------------------------
-- Business question:
-- Does default rate increase as the loan becomes larger relative
-- to borrower income?
--
-- Bands:
-- <0.10
-- 0.10-0.20
-- 0.20-0.30
-- 0.30+
--
-- These bands are designed for interpretation and are informed by
-- the distribution observed in 04. They are not lending cutoffs.
-- ------------------------------------------------------------

WITH params AS (
    SELECT 100 AS min_sample_size
),

lti_segments AS (
    SELECT
        CASE
            WHEN loan_to_income_ratio IS NULL THEN 'Unknown'
            WHEN loan_to_income_ratio < 0.10 THEN '<0.10'
            WHEN loan_to_income_ratio < 0.20 THEN '0.10-0.20'
            WHEN loan_to_income_ratio < 0.30 THEN '0.20-0.30'
            ELSE '0.30+'
        END AS lti_band,

        CASE
            WHEN loan_to_income_ratio IS NULL THEN 99
            WHEN loan_to_income_ratio < 0.10 THEN 1
            WHEN loan_to_income_ratio < 0.20 THEN 2
            WHEN loan_to_income_ratio < 0.30 THEN 3
            ELSE 4
        END AS band_order,

        loan_status,
        loan_amnt
    FROM credit_risk_clean
),

segment_summary AS (
    SELECT
        lti_band,
        band_order,
        COUNT(*) AS loan_count,
        SUM(CASE WHEN loan_status = 0 THEN 1 ELSE 0 END)
            AS non_default_count,
        SUM(CASE WHEN loan_status = 1 THEN 1 ELSE 0 END)
            AS default_count,
        AVG(CASE WHEN loan_status = 1 THEN 1.0 ELSE 0.0 END)
            AS default_rate,
        SUM(loan_amnt) AS loan_exposure,
        SUM(CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END)
            AS default_exposure
    FROM lti_segments
    GROUP BY lti_band, band_order
),

portfolio_totals AS (
    SELECT
        COUNT(*) AS total_loans,
        SUM(loan_amnt) AS total_exposure,
        SUM(CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END)
            AS total_default_exposure,
        AVG(CASE WHEN loan_status = 1 THEN 1.0 ELSE 0.0 END)
            AS portfolio_default_rate
    FROM credit_risk_clean
)

SELECT
    s.lti_band,
    s.loan_count,

    ROUND(
        100.0 * s.loan_count / NULLIF(p.total_loans, 0),
        2
    ) AS portfolio_share_pct,

    s.non_default_count,
    s.default_count,

    ROUND(100.0 * s.default_rate, 2) AS default_rate_pct,

    ROUND(
        100.0 * (s.default_rate - p.portfolio_default_rate),
        2
    ) AS default_rate_gap_pp,

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

    ROUND(
        100.0 * s.default_exposure
        / NULLIF(p.total_default_exposure, 0),
        2
    ) AS share_of_total_default_exposure_pct,

    CASE
        WHEN s.loan_count >= prm.min_sample_size
        THEN 'Enough sample'
        ELSE 'Small sample'
    END AS sample_size_status

FROM segment_summary AS s
CROSS JOIN portfolio_totals AS p
CROSS JOIN params AS prm
ORDER BY s.band_order;


-- ============================================================
-- 2. DEBT-TO-INCOME RATIO
-- ============================================================

-- ------------------------------------------------------------
-- 2.1 DTI distribution checkpoint
-- ------------------------------------------------------------
-- Business question:
-- How is Debt-to-Income Ratio distributed before interpreting
-- debt-burden bands?
--
-- 04_overall_risk.sql showed:
-- status_0 median DTI = 0.3176
-- status_1 median DTI = 0.4179
-- ------------------------------------------------------------

WITH ranked_dti AS (
    SELECT
        debt_to_income_ratio,
        ROW_NUMBER() OVER (ORDER BY debt_to_income_ratio) AS row_num,
        COUNT(*) OVER () AS total_rows
    FROM credit_risk_clean
    WHERE debt_to_income_ratio IS NOT NULL
)
SELECT
    COUNT(*) AS valid_dti_observations,
    ROUND(MIN(debt_to_income_ratio), 4) AS min_dti,

    ROUND(MAX(
        CASE
            WHEN row_num = CEIL(total_rows * 0.25)
            THEN debt_to_income_ratio
        END
    ), 4) AS p25_dti,

    ROUND(AVG(
        CASE
            WHEN row_num IN (
                FLOOR((total_rows + 1) / 2),
                CEIL((total_rows + 1) / 2)
            )
            THEN debt_to_income_ratio
        END
    ), 4) AS median_dti,

    ROUND(AVG(debt_to_income_ratio), 4) AS average_dti,

    ROUND(MAX(
        CASE
            WHEN row_num = CEIL(total_rows * 0.75)
            THEN debt_to_income_ratio
        END
    ), 4) AS p75_dti,

    ROUND(MAX(debt_to_income_ratio), 4) AS max_dti

FROM ranked_dti;


-- ------------------------------------------------------------
-- 2.2 Default behavior by DTI band
-- ------------------------------------------------------------
-- Business question:
-- Does default rate increase as total debt burden becomes larger
-- relative to borrower income?
--
-- Bands:
-- <0.25
-- 0.25-0.35
-- 0.35-0.45
-- 0.45+
--
-- These are analytical review bands, not policy thresholds.
-- ------------------------------------------------------------

WITH params AS (
    SELECT 100 AS min_sample_size
),

dti_segments AS (
    SELECT
        CASE
            WHEN debt_to_income_ratio IS NULL THEN 'Unknown'
            WHEN debt_to_income_ratio < 0.25 THEN '<0.25'
            WHEN debt_to_income_ratio < 0.35 THEN '0.25-0.35'
            WHEN debt_to_income_ratio < 0.45 THEN '0.35-0.45'
            ELSE '0.45+'
        END AS dti_band,

        CASE
            WHEN debt_to_income_ratio IS NULL THEN 99
            WHEN debt_to_income_ratio < 0.25 THEN 1
            WHEN debt_to_income_ratio < 0.35 THEN 2
            WHEN debt_to_income_ratio < 0.45 THEN 3
            ELSE 4
        END AS band_order,

        loan_status,
        loan_amnt
    FROM credit_risk_clean
),

segment_summary AS (
    SELECT
        dti_band,
        band_order,
        COUNT(*) AS loan_count,
        SUM(CASE WHEN loan_status = 0 THEN 1 ELSE 0 END)
            AS non_default_count,
        SUM(CASE WHEN loan_status = 1 THEN 1 ELSE 0 END)
            AS default_count,
        AVG(CASE WHEN loan_status = 1 THEN 1.0 ELSE 0.0 END)
            AS default_rate,
        SUM(loan_amnt) AS loan_exposure,
        SUM(CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END)
            AS default_exposure
    FROM dti_segments
    GROUP BY dti_band, band_order
),

portfolio_totals AS (
    SELECT
        COUNT(*) AS total_loans,
        SUM(loan_amnt) AS total_exposure,
        SUM(CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END)
            AS total_default_exposure,
        AVG(CASE WHEN loan_status = 1 THEN 1.0 ELSE 0.0 END)
            AS portfolio_default_rate
    FROM credit_risk_clean
)

SELECT
    s.dti_band,
    s.loan_count,

    ROUND(
        100.0 * s.loan_count / NULLIF(p.total_loans, 0),
        2
    ) AS portfolio_share_pct,

    s.non_default_count,
    s.default_count,

    ROUND(100.0 * s.default_rate, 2) AS default_rate_pct,

    ROUND(
        100.0 * (s.default_rate - p.portfolio_default_rate),
        2
    ) AS default_rate_gap_pp,

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

    ROUND(
        100.0 * s.default_exposure
        / NULLIF(p.total_default_exposure, 0),
        2
    ) AS share_of_total_default_exposure_pct,

    CASE
        WHEN s.loan_count >= prm.min_sample_size
        THEN 'Enough sample'
        ELSE 'Small sample'
    END AS sample_size_status

FROM segment_summary AS s
CROSS JOIN portfolio_totals AS p
CROSS JOIN params AS prm
ORDER BY s.band_order;


-- ============================================================
-- 3. CREDIT UTILIZATION
-- ============================================================

-- ------------------------------------------------------------
-- 3.1 Credit-utilization distribution checkpoint
-- ------------------------------------------------------------
-- Business question:
-- How is credit utilization distributed before checking whether
-- higher utilization levels show a non-linear default pattern?
--
-- 04_overall_risk.sql showed very similar aggregate utilization
-- averages between default and non-default groups, so band analysis
-- is needed before concluding that utilization is unimportant.
-- ------------------------------------------------------------

WITH ranked_utilization AS (
    SELECT
        credit_utilization_ratio,
        ROW_NUMBER() OVER (ORDER BY credit_utilization_ratio) AS row_num,
        COUNT(*) OVER () AS total_rows
    FROM credit_risk_clean
    WHERE credit_utilization_ratio IS NOT NULL
)
SELECT
    COUNT(*) AS valid_utilization_observations,
    ROUND(MIN(credit_utilization_ratio), 4) AS min_utilization,

    ROUND(MAX(
        CASE
            WHEN row_num = CEIL(total_rows * 0.25)
            THEN credit_utilization_ratio
        END
    ), 4) AS p25_utilization,

    ROUND(AVG(
        CASE
            WHEN row_num IN (
                FLOOR((total_rows + 1) / 2),
                CEIL((total_rows + 1) / 2)
            )
            THEN credit_utilization_ratio
        END
    ), 4) AS median_utilization,

    ROUND(AVG(credit_utilization_ratio), 4) AS average_utilization,

    ROUND(MAX(
        CASE
            WHEN row_num = CEIL(total_rows * 0.75)
            THEN credit_utilization_ratio
        END
    ), 4) AS p75_utilization,

    ROUND(MAX(credit_utilization_ratio), 4) AS max_utilization

FROM ranked_utilization;


-- ------------------------------------------------------------
-- 3.2 Default behavior by credit-utilization band
-- ------------------------------------------------------------
-- Business question:
-- Does default behavior change materially at higher utilization levels?
--
-- Bands:
-- <0.30
-- 0.30-0.50
-- 0.50-0.70
-- 0.70+
-- ------------------------------------------------------------

WITH params AS (
    SELECT 100 AS min_sample_size
),

utilization_segments AS (
    SELECT
        CASE
            WHEN credit_utilization_ratio IS NULL THEN 'Unknown'
            WHEN credit_utilization_ratio < 0.30 THEN '<0.30'
            WHEN credit_utilization_ratio < 0.50 THEN '0.30-0.50'
            WHEN credit_utilization_ratio < 0.70 THEN '0.50-0.70'
            ELSE '0.70+'
        END AS utilization_band,

        CASE
            WHEN credit_utilization_ratio IS NULL THEN 99
            WHEN credit_utilization_ratio < 0.30 THEN 1
            WHEN credit_utilization_ratio < 0.50 THEN 2
            WHEN credit_utilization_ratio < 0.70 THEN 3
            ELSE 4
        END AS band_order,

        loan_status,
        loan_amnt
    FROM credit_risk_clean
),

segment_summary AS (
    SELECT
        utilization_band,
        band_order,
        COUNT(*) AS loan_count,
        SUM(CASE WHEN loan_status = 0 THEN 1 ELSE 0 END)
            AS non_default_count,
        SUM(CASE WHEN loan_status = 1 THEN 1 ELSE 0 END)
            AS default_count,
        AVG(CASE WHEN loan_status = 1 THEN 1.0 ELSE 0.0 END)
            AS default_rate,
        SUM(loan_amnt) AS loan_exposure,
        SUM(CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END)
            AS default_exposure
    FROM utilization_segments
    GROUP BY utilization_band, band_order
),

portfolio_totals AS (
    SELECT
        COUNT(*) AS total_loans,
        SUM(loan_amnt) AS total_exposure,
        SUM(CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END)
            AS total_default_exposure,
        AVG(CASE WHEN loan_status = 1 THEN 1.0 ELSE 0.0 END)
            AS portfolio_default_rate
    FROM credit_risk_clean
)

SELECT
    s.utilization_band,
    s.loan_count,

    ROUND(
        100.0 * s.loan_count / NULLIF(p.total_loans, 0),
        2
    ) AS portfolio_share_pct,

    s.non_default_count,
    s.default_count,

    ROUND(100.0 * s.default_rate, 2) AS default_rate_pct,

    ROUND(
        100.0 * (s.default_rate - p.portfolio_default_rate),
        2
    ) AS default_rate_gap_pp,

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

    ROUND(
        100.0 * s.default_exposure
        / NULLIF(p.total_default_exposure, 0),
        2
    ) AS share_of_total_default_exposure_pct,

    CASE
        WHEN s.loan_count >= prm.min_sample_size
        THEN 'Enough sample'
        ELSE 'Small sample'
    END AS sample_size_status

FROM segment_summary AS s
CROSS JOIN portfolio_totals AS p
CROSS JOIN params AS prm
ORDER BY s.band_order;


-- ============================================================
-- 4. OTHER DEBT
-- ============================================================

-- ------------------------------------------------------------
-- 4.1 Other-debt distribution checkpoint
-- ------------------------------------------------------------
-- Business question:
-- How is absolute other debt distributed before interpreting
-- debt-amount bands?
--
-- Important:
-- Other Debt is an absolute amount and should not be interpreted
-- as strongly as DTI because borrowers with higher income may carry
-- more debt while remaining financially healthier.
-- ------------------------------------------------------------

WITH ranked_other_debt AS (
    SELECT
        other_debt,
        ROW_NUMBER() OVER (ORDER BY other_debt) AS row_num,
        COUNT(*) OVER () AS total_rows
    FROM credit_risk_clean
    WHERE other_debt IS NOT NULL
)
SELECT
    COUNT(*) AS valid_other_debt_observations,
    ROUND(MIN(other_debt), 2) AS min_other_debt,

    ROUND(MAX(
        CASE
            WHEN row_num = CEIL(total_rows * 0.25)
            THEN other_debt
        END
    ), 2) AS p25_other_debt,

    ROUND(AVG(
        CASE
            WHEN row_num IN (
                FLOOR((total_rows + 1) / 2),
                CEIL((total_rows + 1) / 2)
            )
            THEN other_debt
        END
    ), 2) AS median_other_debt,

    ROUND(AVG(other_debt), 2) AS average_other_debt,

    ROUND(MAX(
        CASE
            WHEN row_num = CEIL(total_rows * 0.75)
            THEN other_debt
        END
    ), 2) AS p75_other_debt,

    ROUND(MAX(other_debt), 2) AS max_other_debt

FROM ranked_other_debt;


-- ------------------------------------------------------------
-- 4.2 Default behavior by other-debt band
-- ------------------------------------------------------------
-- Business question:
-- Does absolute other debt show a useful default pattern once it is
-- grouped into interpretable ranges?
--
-- Bands:
-- <5K
-- 5K-10K
-- 10K-15K
-- 15K+
--
-- Interpret with caution: absolute debt is not affordability by itself.
-- ------------------------------------------------------------

WITH params AS (
    SELECT 100 AS min_sample_size
),

debt_segments AS (
    SELECT
        CASE
            WHEN other_debt IS NULL THEN 'Unknown'
            WHEN other_debt < 5000 THEN '<5K'
            WHEN other_debt < 10000 THEN '5K-10K'
            WHEN other_debt < 15000 THEN '10K-15K'
            ELSE '15K+'
        END AS other_debt_band,

        CASE
            WHEN other_debt IS NULL THEN 99
            WHEN other_debt < 5000 THEN 1
            WHEN other_debt < 10000 THEN 2
            WHEN other_debt < 15000 THEN 3
            ELSE 4
        END AS band_order,

        loan_status,
        loan_amnt
    FROM credit_risk_clean
),

segment_summary AS (
    SELECT
        other_debt_band,
        band_order,
        COUNT(*) AS loan_count,
        SUM(CASE WHEN loan_status = 0 THEN 1 ELSE 0 END)
            AS non_default_count,
        SUM(CASE WHEN loan_status = 1 THEN 1 ELSE 0 END)
            AS default_count,
        AVG(CASE WHEN loan_status = 1 THEN 1.0 ELSE 0.0 END)
            AS default_rate,
        SUM(loan_amnt) AS loan_exposure,
        SUM(CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END)
            AS default_exposure
    FROM debt_segments
    GROUP BY other_debt_band, band_order
),

portfolio_totals AS (
    SELECT
        COUNT(*) AS total_loans,
        SUM(loan_amnt) AS total_exposure,
        SUM(CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END)
            AS total_default_exposure,
        AVG(CASE WHEN loan_status = 1 THEN 1.0 ELSE 0.0 END)
            AS portfolio_default_rate
    FROM credit_risk_clean
)

SELECT
    s.other_debt_band,
    s.loan_count,

    ROUND(
        100.0 * s.loan_count / NULLIF(p.total_loans, 0),
        2
    ) AS portfolio_share_pct,

    s.non_default_count,
    s.default_count,

    ROUND(100.0 * s.default_rate, 2) AS default_rate_pct,

    ROUND(
        100.0 * (s.default_rate - p.portfolio_default_rate),
        2
    ) AS default_rate_gap_pp,

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

    ROUND(
        100.0 * s.default_exposure
        / NULLIF(p.total_default_exposure, 0),
        2
    ) AS share_of_total_default_exposure_pct,

    CASE
        WHEN s.loan_count >= prm.min_sample_size
        THEN 'Enough sample'
        ELSE 'Small sample'
    END AS sample_size_status

FROM segment_summary AS s
CROSS JOIN portfolio_totals AS p
CROSS JOIN params AS prm
ORDER BY s.band_order;


-- ============================================================
-- 5. LTI x DTI INTERSECTION
-- ============================================================

-- ------------------------------------------------------------
-- 5.1 Detailed affordability intersection
-- ------------------------------------------------------------
-- Business question:
-- When LTI and DTI are considered together, which combinations show
-- the highest observed default rates and the largest default exposure?
--
-- This is an interaction analysis, NOT final risk segmentation.
--
-- LTI:
-- <0.10
-- 0.10-0.20
-- 0.20-0.30
-- 0.30+
--
-- DTI:
-- <0.25
-- 0.25-0.35
-- 0.35-0.45
-- 0.45+
-- ------------------------------------------------------------

WITH params AS (
    SELECT 100 AS min_sample_size
),

affordability_base AS (
    SELECT
        CASE
            WHEN loan_to_income_ratio IS NULL THEN 'Unknown'
            WHEN loan_to_income_ratio < 0.10 THEN '<0.10'
            WHEN loan_to_income_ratio < 0.20 THEN '0.10-0.20'
            WHEN loan_to_income_ratio < 0.30 THEN '0.20-0.30'
            ELSE '0.30+'
        END AS lti_band,

        CASE
            WHEN loan_to_income_ratio IS NULL THEN 99
            WHEN loan_to_income_ratio < 0.10 THEN 1
            WHEN loan_to_income_ratio < 0.20 THEN 2
            WHEN loan_to_income_ratio < 0.30 THEN 3
            ELSE 4
        END AS lti_order,

        CASE
            WHEN debt_to_income_ratio IS NULL THEN 'Unknown'
            WHEN debt_to_income_ratio < 0.25 THEN '<0.25'
            WHEN debt_to_income_ratio < 0.35 THEN '0.25-0.35'
            WHEN debt_to_income_ratio < 0.45 THEN '0.35-0.45'
            ELSE '0.45+'
        END AS dti_band,

        CASE
            WHEN debt_to_income_ratio IS NULL THEN 99
            WHEN debt_to_income_ratio < 0.25 THEN 1
            WHEN debt_to_income_ratio < 0.35 THEN 2
            WHEN debt_to_income_ratio < 0.45 THEN 3
            ELSE 4
        END AS dti_order,

        loan_status,
        loan_amnt
    FROM credit_risk_clean
),

intersection_summary AS (
    SELECT
        lti_band,
        lti_order,
        dti_band,
        dti_order,
        COUNT(*) AS loan_count,
        SUM(CASE WHEN loan_status = 0 THEN 1 ELSE 0 END)
            AS non_default_count,
        SUM(CASE WHEN loan_status = 1 THEN 1 ELSE 0 END)
            AS default_count,
        AVG(CASE WHEN loan_status = 1 THEN 1.0 ELSE 0.0 END)
            AS default_rate,
        SUM(loan_amnt) AS loan_exposure,
        SUM(CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END)
            AS default_exposure
    FROM affordability_base
    GROUP BY
        lti_band,
        lti_order,
        dti_band,
        dti_order
),

portfolio_totals AS (
    SELECT
        COUNT(*) AS total_loans,
        SUM(loan_amnt) AS total_exposure,
        SUM(CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END)
            AS total_default_exposure
    FROM credit_risk_clean
)

SELECT
    s.lti_band,
    s.dti_band,
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

    ROUND(
        100.0 * s.default_exposure
        / NULLIF(p.total_default_exposure, 0),
        2
    ) AS share_of_total_default_exposure_pct,

    CASE
        WHEN s.loan_count >= prm.min_sample_size
        THEN 'Enough sample'
        ELSE 'Small sample'
    END AS sample_size_status

FROM intersection_summary AS s
CROSS JOIN portfolio_totals AS p
CROSS JOIN params AS prm

ORDER BY
    s.lti_order,
    s.dti_order;


-- ------------------------------------------------------------
-- 5.2 Simplified elevated-affordability intersection
-- ------------------------------------------------------------
-- Business question:
-- Is default risk materially different when high LTI and high DTI
-- appear separately versus together?
--
-- Review thresholds:
-- Elevated LTI = LTI >= 0.30
-- Elevated DTI = DTI >= 0.45
--
-- These thresholds align with the highest analytical bands above.
-- They are NOT approval/rejection rules.
-- ------------------------------------------------------------

WITH params AS (
    SELECT 100 AS min_sample_size
),

affordability_groups AS (
    SELECT
        CASE
            WHEN loan_to_income_ratio IS NULL
              OR debt_to_income_ratio IS NULL
                THEN 'Unknown'

            WHEN loan_to_income_ratio >= 0.30
             AND debt_to_income_ratio >= 0.45
                THEN 'Elevated LTI + Elevated DTI'

            WHEN loan_to_income_ratio >= 0.30
                THEN 'Elevated LTI Only'

            WHEN debt_to_income_ratio >= 0.45
                THEN 'Elevated DTI Only'

            ELSE 'Neither Elevated'
        END AS affordability_group,

        CASE
            WHEN loan_to_income_ratio IS NULL
              OR debt_to_income_ratio IS NULL THEN 99
            WHEN loan_to_income_ratio >= 0.30
             AND debt_to_income_ratio >= 0.45 THEN 4
            WHEN loan_to_income_ratio >= 0.30 THEN 3
            WHEN debt_to_income_ratio >= 0.45 THEN 2
            ELSE 1
        END AS group_order,

        loan_status,
        loan_amnt
    FROM credit_risk_clean
),

group_summary AS (
    SELECT
        affordability_group,
        group_order,
        COUNT(*) AS loan_count,
        SUM(CASE WHEN loan_status = 0 THEN 1 ELSE 0 END)
            AS non_default_count,
        SUM(CASE WHEN loan_status = 1 THEN 1 ELSE 0 END)
            AS default_count,
        AVG(CASE WHEN loan_status = 1 THEN 1.0 ELSE 0.0 END)
            AS default_rate,
        SUM(loan_amnt) AS loan_exposure,
        SUM(CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END)
            AS default_exposure
    FROM affordability_groups
    GROUP BY affordability_group, group_order
),

portfolio_totals AS (
    SELECT
        COUNT(*) AS total_loans,
        SUM(loan_amnt) AS total_exposure,
        SUM(CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END)
            AS total_default_exposure,
        AVG(CASE WHEN loan_status = 1 THEN 1.0 ELSE 0.0 END)
            AS portfolio_default_rate
    FROM credit_risk_clean
)

SELECT
    s.affordability_group,
    s.loan_count,

    ROUND(
        100.0 * s.loan_count / NULLIF(p.total_loans, 0),
        2
    ) AS portfolio_share_pct,

    s.non_default_count,
    s.default_count,

    ROUND(100.0 * s.default_rate, 2) AS default_rate_pct,

    ROUND(
        100.0 * (s.default_rate - p.portfolio_default_rate),
        2
    ) AS default_rate_gap_pp,

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

    ROUND(
        100.0 * s.default_exposure
        / NULLIF(p.total_default_exposure, 0),
        2
    ) AS share_of_total_default_exposure_pct,

    CASE
        WHEN s.loan_count >= prm.min_sample_size
        THEN 'Enough sample'
        ELSE 'Small sample'
    END AS sample_size_status

FROM group_summary AS s
CROSS JOIN portfolio_totals AS p
CROSS JOIN params AS prm
ORDER BY s.group_order;


-- ============================================================
-- 6. EXISTING HIGH-DTI FLAG REVIEW
-- ============================================================

-- ------------------------------------------------------------
-- 6.1 Review the existing is_high_dti flag
-- ------------------------------------------------------------
-- Business question:
-- Does the existing high-DTI flag represent a material portfolio
-- segment or only a very small number of extreme observations?
--
-- 04_overall_risk.sql found only four rows with this flag, so this
-- query is intended to quantify its practical significance.
-- ------------------------------------------------------------

WITH flag_summary AS (
    SELECT
        CASE
            WHEN is_high_dti = 1 THEN 'High DTI Flag'
            ELSE 'Not High DTI Flag'
        END AS high_dti_flag_group,

        COUNT(*) AS loan_count,
        SUM(CASE WHEN loan_status = 0 THEN 1 ELSE 0 END)
            AS non_default_count,
        SUM(CASE WHEN loan_status = 1 THEN 1 ELSE 0 END)
            AS default_count,
        AVG(CASE WHEN loan_status = 1 THEN 1.0 ELSE 0.0 END)
            AS default_rate,
        SUM(loan_amnt) AS loan_exposure,
        SUM(CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END)
            AS default_exposure

    FROM credit_risk_clean

    GROUP BY
        CASE
            WHEN is_high_dti = 1 THEN 'High DTI Flag'
            ELSE 'Not High DTI Flag'
        END
)

SELECT
    high_dti_flag_group,
    loan_count,
    non_default_count,
    default_count,
    ROUND(100.0 * default_rate, 2) AS default_rate_pct,
    ROUND(loan_exposure, 2) AS loan_exposure,
    ROUND(default_exposure, 2) AS default_exposure,
    CASE
        WHEN loan_count >= 100 THEN 'Enough sample'
        ELSE 'Small sample'
    END AS sample_size_status
FROM flag_summary
ORDER BY default_rate_pct DESC;


-- ============================================================
-- 7. FINANCIAL-RISK CHECKPOINT
-- ============================================================

-- ------------------------------------------------------------
-- 7.1 Compare selected review conditions
-- ------------------------------------------------------------
-- Business question:
-- Which affordability conditions combine meaningful default rates
-- with meaningful portfolio exposure?
--
-- Conditions overlap and should NOT be added together.
-- This is a comparison table, not a segmentation table.
-- ------------------------------------------------------------

WITH review_conditions AS (

    SELECT
        'Portfolio Baseline' AS review_condition,
        loan_status,
        loan_amnt
    FROM credit_risk_clean

    UNION ALL

    SELECT
        'LTI >= 0.30',
        loan_status,
        loan_amnt
    FROM credit_risk_clean
    WHERE loan_to_income_ratio >= 0.30

    UNION ALL

    SELECT
        'DTI >= 0.45',
        loan_status,
        loan_amnt
    FROM credit_risk_clean
    WHERE debt_to_income_ratio >= 0.45

    UNION ALL

    SELECT
        'Utilization >= 0.70',
        loan_status,
        loan_amnt
    FROM credit_risk_clean
    WHERE credit_utilization_ratio >= 0.70

    UNION ALL

    SELECT
        'LTI >= 0.30 AND DTI >= 0.45',
        loan_status,
        loan_amnt
    FROM credit_risk_clean
    WHERE loan_to_income_ratio >= 0.30
      AND debt_to_income_ratio >= 0.45
),

condition_summary AS (
    SELECT
        review_condition,
        COUNT(*) AS loan_count,
        SUM(CASE WHEN loan_status = 1 THEN 1 ELSE 0 END)
            AS default_count,
        AVG(CASE WHEN loan_status = 1 THEN 1.0 ELSE 0.0 END)
            AS default_rate,
        SUM(loan_amnt) AS loan_exposure,
        SUM(CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END)
            AS default_exposure
    FROM review_conditions
    GROUP BY review_condition
),

portfolio_totals AS (
    SELECT
        COUNT(*) AS total_loans,
        SUM(loan_amnt) AS total_exposure,
        SUM(CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END)
            AS total_default_exposure
    FROM credit_risk_clean
)

SELECT
    s.review_condition,
    s.loan_count,

    ROUND(
        100.0 * s.loan_count / NULLIF(p.total_loans, 0),
        2
    ) AS portfolio_share_pct,

    s.default_count,
    ROUND(100.0 * s.default_rate, 2) AS default_rate_pct,

    ROUND(s.loan_exposure, 2) AS loan_exposure,

    ROUND(
        100.0 * s.loan_exposure / NULLIF(p.total_exposure, 0),
        2
    ) AS exposure_share_pct,

    ROUND(s.default_exposure, 2) AS default_exposure,

    ROUND(
        100.0 * s.default_exposure
        / NULLIF(p.total_default_exposure, 0),
        2
    ) AS share_of_total_default_exposure_pct

FROM condition_summary AS s
CROSS JOIN portfolio_totals AS p

ORDER BY
    CASE s.review_condition
        WHEN 'Portfolio Baseline' THEN 1
        WHEN 'LTI >= 0.30' THEN 2
        WHEN 'DTI >= 0.45' THEN 3
        WHEN 'Utilization >= 0.70' THEN 4
        WHEN 'LTI >= 0.30 AND DTI >= 0.45' THEN 5
        ELSE 99
    END;


-- ============================================================
-- END OF 07_FINANCIAL_RISK.SQL
-- ============================================================
-- REVIEW CHECKPOINT
--
-- Run one numbered query at a time and review the result grids before
-- proceeding to 08_credit_stability.sql.
--
-- Priority outputs:
-- 1.2 LTI bands
-- 2.2 DTI bands
-- 3.2 Credit-utilization bands
-- 4.2 Other-debt bands
-- 5.1 LTI x DTI intersection
-- 5.2 Simplified elevated-affordability groups
-- 6.1 Existing high-DTI flag review
-- 7.1 Financial-risk checkpoint
--
-- Questions to answer:
-- 1. Does default rate rise consistently as LTI increases?
-- 2. Does default rate rise consistently as DTI increases?
-- 3. Does credit utilization show a hidden non-linear pattern that
--    was not visible in aggregate averages?
-- 4. Is absolute Other Debt useful after considering that it is not
--    normalized by income?
-- 5. Does the combination of elevated LTI and DTI identify a much
--    higher-risk group than either measure alone?
-- 6. Where is default exposure most concentrated?
-- 7. Is the existing is_high_dti flag analytically meaningful or too
--    rare to be useful for portfolio segmentation?
--
-- Do not build final risk scores or approval rules yet.
-- ============================================================
