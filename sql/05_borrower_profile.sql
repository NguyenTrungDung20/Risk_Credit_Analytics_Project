-- ============================================================
-- RISK CREDIT ANALYTICS PROJECT
-- FILE: 05_borrower_profile.sql
-- PURPOSE: Analyze borrower characteristics associated with loan default.
-- MYSQL VERSION: 8.0+
-- ============================================================
-- SOURCE: credit_risk_clean
-- READ-ONLY EDA
--
-- TARGET:
-- loan_status = 0 -> Non-default
-- loan_status = 1 -> Default
--
-- IMPORTANT:
-- All findings are descriptive associations.
-- Do not interpret them as causal relationships.
-- ============================================================

USE risk_credit_analytics;


-- ============================================================
-- 1. AGE PROFILE
-- ============================================================

-- ------------------------------------------------------------
-- 1.1 Age distribution checkpoint
-- ------------------------------------------------------------
-- Business question:
-- What does the overall borrower age distribution look like before
-- creating age groups?
--
-- This query helps confirm whether the proposed age bands are sensible.
-- ------------------------------------------------------------

WITH age_ranked AS (
    SELECT
        person_age,
        ROW_NUMBER() OVER (ORDER BY person_age) AS row_num,
        COUNT(*) OVER () AS total_rows
    FROM credit_risk_clean
    WHERE person_age IS NOT NULL
)
SELECT
    COUNT(*) AS valid_age_observations,
    MIN(person_age) AS min_age,

    MAX(
        CASE
            WHEN row_num = CEIL(total_rows * 0.25)
            THEN person_age
        END
    ) AS p25_age,

    AVG(
        CASE
            WHEN row_num IN (
                FLOOR((total_rows + 1) / 2),
                CEIL((total_rows + 1) / 2)
            )
            THEN person_age
        END
    ) AS median_age,

    ROUND(AVG(person_age), 2) AS average_age,

    MAX(
        CASE
            WHEN row_num = CEIL(total_rows * 0.75)
            THEN person_age
        END
    ) AS p75_age,

    MAX(person_age) AS max_age
FROM age_ranked;


-- ------------------------------------------------------------
-- 1.2 Default risk by age band
-- ------------------------------------------------------------
-- Business question:
-- Which age groups have higher or lower observed default rates?
--
-- Proposed business-readable bands:
-- <25
-- 25-34
-- 35-44
-- 45-54
-- 55+
--
-- Missing/invalid ages are retained as a separate group.
-- ------------------------------------------------------------

WITH params AS (
    SELECT 100 AS min_sample_size
),

age_segments AS (
    SELECT
        CASE
            WHEN person_age IS NULL THEN 'Unknown'
            WHEN person_age < 25 THEN '<25'
            WHEN person_age < 35 THEN '25-34'
            WHEN person_age < 45 THEN '35-44'
            WHEN person_age < 55 THEN '45-54'
            ELSE '55+'
        END AS age_band,

        CASE
            WHEN person_age IS NULL THEN 99
            WHEN person_age < 25 THEN 1
            WHEN person_age < 35 THEN 2
            WHEN person_age < 45 THEN 3
            WHEN person_age < 55 THEN 4
            ELSE 5
        END AS band_order,

        loan_status,
        loan_amnt
    FROM credit_risk_clean
),

segment_summary AS (
    SELECT
        age_band,
        band_order,
        COUNT(*) AS loan_count,
        SUM(loan_status = 0) AS non_default_count,
        SUM(loan_status = 1) AS default_count,
        AVG(loan_status = 1) AS default_rate,
        SUM(loan_amnt) AS loan_exposure,
        SUM(
            CASE
                WHEN loan_status = 1 THEN loan_amnt
                ELSE 0
            END
        ) AS default_exposure
    FROM age_segments
    GROUP BY age_band, band_order
),

portfolio_totals AS (
    SELECT
        COUNT(*) AS total_loans,
        SUM(loan_amnt) AS total_exposure
    FROM credit_risk_clean
)

SELECT
    s.age_band,
    s.loan_count,

    ROUND(
        100.0 * s.loan_count
        / NULLIF(p.total_loans, 0),
        2
    ) AS portfolio_share_pct,

    s.non_default_count,
    s.default_count,

    ROUND(
        100.0 * s.default_rate,
        2
    ) AS default_rate_pct,

    ROUND(s.loan_exposure, 2) AS loan_exposure,

    ROUND(
        100.0 * s.loan_exposure
        / NULLIF(p.total_exposure, 0),
        2
    ) AS exposure_share_pct,

    ROUND(s.default_exposure, 2) AS default_exposure,

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
-- 2. INCOME PROFILE
-- ============================================================

-- ------------------------------------------------------------
-- 2.1 Income distribution checkpoint
-- ------------------------------------------------------------
-- Business question:
-- How is borrower income distributed before income bands are analyzed?
-- ------------------------------------------------------------

WITH income_ranked AS (
    SELECT
        person_income,
        ROW_NUMBER() OVER (ORDER BY person_income) AS row_num,
        COUNT(*) OVER () AS total_rows
    FROM credit_risk_clean
    WHERE person_income IS NOT NULL
)
SELECT
    COUNT(*) AS valid_income_observations,

    ROUND(MIN(person_income), 2) AS min_income,

    ROUND(MAX(
        CASE
            WHEN row_num = CEIL(total_rows * 0.25)
            THEN person_income
        END
    ), 2) AS p25_income,

    ROUND(AVG(
        CASE
            WHEN row_num IN (
                FLOOR((total_rows + 1) / 2),
                CEIL((total_rows + 1) / 2)
            )
            THEN person_income
        END
    ), 2) AS median_income,

    ROUND(AVG(person_income), 2) AS average_income,

    ROUND(MAX(
        CASE
            WHEN row_num = CEIL(total_rows * 0.75)
            THEN person_income
        END
    ), 2) AS p75_income,

    ROUND(MAX(person_income), 2) AS max_income
FROM income_ranked;


-- ------------------------------------------------------------
-- 2.2 Default risk by income band
-- ------------------------------------------------------------
-- Business question:
-- Does the observed default rate change as borrower income increases?
--
-- Initial income bands:
-- < $30K
-- $30K-$50K
-- $50K-$75K
-- $75K-$100K
-- $100K+
--
-- These are descriptive analytical bands, not lending thresholds.
-- ------------------------------------------------------------

WITH params AS (
    SELECT 100 AS min_sample_size
),

income_segments AS (
    SELECT
        CASE
            WHEN person_income IS NULL THEN 'Unknown'
            WHEN person_income < 30000 THEN '<30K'
            WHEN person_income < 50000 THEN '30K-50K'
            WHEN person_income < 75000 THEN '50K-75K'
            WHEN person_income < 100000 THEN '75K-100K'
            ELSE '100K+'
        END AS income_band,

        CASE
            WHEN person_income IS NULL THEN 99
            WHEN person_income < 30000 THEN 1
            WHEN person_income < 50000 THEN 2
            WHEN person_income < 75000 THEN 3
            WHEN person_income < 100000 THEN 4
            ELSE 5
        END AS band_order,

        loan_status,
        loan_amnt
    FROM credit_risk_clean
),

segment_summary AS (
    SELECT
        income_band,
        band_order,
        COUNT(*) AS loan_count,
        SUM(loan_status = 0) AS non_default_count,
        SUM(loan_status = 1) AS default_count,
        AVG(loan_status = 1) AS default_rate,
        SUM(loan_amnt) AS loan_exposure,
        SUM(
            CASE
                WHEN loan_status = 1 THEN loan_amnt
                ELSE 0
            END
        ) AS default_exposure
    FROM income_segments
    GROUP BY income_band, band_order
),

portfolio_totals AS (
    SELECT
        COUNT(*) AS total_loans,
        SUM(loan_amnt) AS total_exposure
    FROM credit_risk_clean
)

SELECT
    s.income_band,
    s.loan_count,

    ROUND(
        100.0 * s.loan_count
        / NULLIF(p.total_loans, 0),
        2
    ) AS portfolio_share_pct,

    s.non_default_count,
    s.default_count,

    ROUND(
        100.0 * s.default_rate,
        2
    ) AS default_rate_pct,

    ROUND(s.loan_exposure, 2) AS loan_exposure,

    ROUND(
        100.0 * s.loan_exposure
        / NULLIF(p.total_exposure, 0),
        2
    ) AS exposure_share_pct,

    ROUND(s.default_exposure, 2) AS default_exposure,

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
-- 3. DEMOGRAPHIC PROFILE
-- ============================================================

-- ------------------------------------------------------------
-- 3.1 Gender, marital status, and education
-- ------------------------------------------------------------
-- Business question:
-- Do demographic groups show meaningful differences in observed
-- default rates?
--
-- IMPORTANT:
-- These fields should be interpreted carefully because lending
-- decisions must remain fair and should not automatically use
-- demographic characteristics as approval rules.
-- ------------------------------------------------------------

WITH params AS (
    SELECT 100 AS min_sample_size
),

demographic_values AS (

    SELECT
        'gender' AS dimension_name,
        COALESCE(NULLIF(TRIM(gender), ''), 'Unknown') AS segment_name,
        loan_status,
        loan_amnt
    FROM credit_risk_clean

    UNION ALL

    SELECT
        'marital_status',
        COALESCE(NULLIF(TRIM(marital_status), ''), 'Unknown'),
        loan_status,
        loan_amnt
    FROM credit_risk_clean

    UNION ALL

    SELECT
        'education_level',
        COALESCE(NULLIF(TRIM(education_level), ''), 'Unknown'),
        loan_status,
        loan_amnt
    FROM credit_risk_clean
),

segment_summary AS (
    SELECT
        dimension_name,
        segment_name,
        COUNT(*) AS loan_count,
        SUM(loan_status = 0) AS non_default_count,
        SUM(loan_status = 1) AS default_count,
        AVG(loan_status = 1) AS default_rate,
        SUM(loan_amnt) AS loan_exposure,
        SUM(
            CASE
                WHEN loan_status = 1 THEN loan_amnt
                ELSE 0
            END
        ) AS default_exposure
    FROM demographic_values
    GROUP BY dimension_name, segment_name
),

dimension_totals AS (
    SELECT
        dimension_name,
        COUNT(*) AS total_loans,
        SUM(loan_amnt) AS total_exposure
    FROM demographic_values
    GROUP BY dimension_name
)

SELECT
    s.dimension_name,
    s.segment_name,
    s.loan_count,

    ROUND(
        100.0 * s.loan_count
        / NULLIF(d.total_loans, 0),
        2
    ) AS dimension_share_pct,

    s.non_default_count,
    s.default_count,

    ROUND(
        100.0 * s.default_rate,
        2
    ) AS default_rate_pct,

    ROUND(s.loan_exposure, 2) AS loan_exposure,

    ROUND(
        100.0 * s.loan_exposure
        / NULLIF(d.total_exposure, 0),
        2
    ) AS exposure_share_pct,

    ROUND(s.default_exposure, 2) AS default_exposure,

    CASE
        WHEN s.loan_count >= prm.min_sample_size
        THEN 'Enough sample'
        ELSE 'Small sample'
    END AS sample_size_status

FROM segment_summary AS s
JOIN dimension_totals AS d
    ON s.dimension_name = d.dimension_name
CROSS JOIN params AS prm
ORDER BY
    s.dimension_name,
    default_rate_pct DESC,
    s.loan_count DESC;


-- ============================================================
-- 4. EMPLOYMENT TYPE
-- ============================================================

-- ------------------------------------------------------------
-- 4.1 Default risk by employment type
-- ------------------------------------------------------------
-- Business question:
-- Does employment type show a meaningful difference in loan outcome?
-- ------------------------------------------------------------

WITH params AS (
    SELECT 100 AS min_sample_size
),

segment_summary AS (
    SELECT
        COALESCE(
            NULLIF(TRIM(employment_type), ''),
            'Unknown'
        ) AS employment_type,

        COUNT(*) AS loan_count,

        SUM(loan_status = 0) AS non_default_count,
        SUM(loan_status = 1) AS default_count,

        AVG(loan_status = 1) AS default_rate,

        SUM(loan_amnt) AS loan_exposure,

        SUM(
            CASE
                WHEN loan_status = 1 THEN loan_amnt
                ELSE 0
            END
        ) AS default_exposure

    FROM credit_risk_clean

    GROUP BY
        COALESCE(
            NULLIF(TRIM(employment_type), ''),
            'Unknown'
        )
),

portfolio_totals AS (
    SELECT
        COUNT(*) AS total_loans,
        SUM(loan_amnt) AS total_exposure
    FROM credit_risk_clean
)

SELECT
    s.employment_type,
    s.loan_count,

    ROUND(
        100.0 * s.loan_count
        / NULLIF(p.total_loans, 0),
        2
    ) AS portfolio_share_pct,

    s.non_default_count,
    s.default_count,

    ROUND(
        100.0 * s.default_rate,
        2
    ) AS default_rate_pct,

    ROUND(s.loan_exposure, 2) AS loan_exposure,

    ROUND(
        100.0 * s.loan_exposure
        / NULLIF(p.total_exposure, 0),
        2
    ) AS exposure_share_pct,

    ROUND(s.default_exposure, 2) AS default_exposure,

    CASE
        WHEN s.loan_count >= prm.min_sample_size
        THEN 'Enough sample'
        ELSE 'Small sample'
    END AS sample_size_status

FROM segment_summary AS s
CROSS JOIN portfolio_totals AS p
CROSS JOIN params AS prm

ORDER BY
    default_rate_pct DESC,
    s.loan_count DESC;


-- ============================================================
-- 5. EMPLOYMENT LENGTH
-- ============================================================

-- ------------------------------------------------------------
-- 5.1 Default risk by employment-length band
-- ------------------------------------------------------------
-- Business question:
-- Does longer employment tenure appear to be associated with
-- lower observed default rates?
--
-- Missing/invalid employment length is retained as Unknown.
-- ------------------------------------------------------------

WITH params AS (
    SELECT 100 AS min_sample_size
),

employment_segments AS (
    SELECT
        CASE
            WHEN person_emp_length IS NULL THEN 'Unknown'
            WHEN person_emp_length < 1 THEN '<1 year'
            WHEN person_emp_length < 4 THEN '1-3 years'
            WHEN person_emp_length < 7 THEN '4-6 years'
            WHEN person_emp_length <= 10 THEN '7-10 years'
            ELSE '10+ years'
        END AS employment_length_band,

        CASE
            WHEN person_emp_length IS NULL THEN 99
            WHEN person_emp_length < 1 THEN 1
            WHEN person_emp_length < 4 THEN 2
            WHEN person_emp_length < 7 THEN 3
            WHEN person_emp_length <= 10 THEN 4
            ELSE 5
        END AS band_order,

        loan_status,
        loan_amnt

    FROM credit_risk_clean
),

segment_summary AS (
    SELECT
        employment_length_band,
        band_order,

        COUNT(*) AS loan_count,
        SUM(loan_status = 0) AS non_default_count,
        SUM(loan_status = 1) AS default_count,

        AVG(loan_status = 1) AS default_rate,

        SUM(loan_amnt) AS loan_exposure,

        SUM(
            CASE
                WHEN loan_status = 1 THEN loan_amnt
                ELSE 0
            END
        ) AS default_exposure

    FROM employment_segments

    GROUP BY
        employment_length_band,
        band_order
),

portfolio_totals AS (
    SELECT
        COUNT(*) AS total_loans,
        SUM(loan_amnt) AS total_exposure
    FROM credit_risk_clean
)

SELECT
    s.employment_length_band,
    s.loan_count,

    ROUND(
        100.0 * s.loan_count
        / NULLIF(p.total_loans, 0),
        2
    ) AS portfolio_share_pct,

    s.non_default_count,
    s.default_count,

    ROUND(
        100.0 * s.default_rate,
        2
    ) AS default_rate_pct,

    ROUND(s.loan_exposure, 2) AS loan_exposure,

    ROUND(
        100.0 * s.loan_exposure
        / NULLIF(p.total_exposure, 0),
        2
    ) AS exposure_share_pct,

    ROUND(s.default_exposure, 2) AS default_exposure,

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
-- 6. HOME OWNERSHIP
-- ============================================================

-- ------------------------------------------------------------
-- 6.1 Default risk by home ownership
-- ------------------------------------------------------------
-- Business question:
-- Does housing situation show a meaningful difference in loan outcome?
-- ------------------------------------------------------------

WITH params AS (
    SELECT 100 AS min_sample_size
),

segment_summary AS (
    SELECT
        COALESCE(
            NULLIF(TRIM(person_home_ownership), ''),
            'Unknown'
        ) AS home_ownership,

        COUNT(*) AS loan_count,

        SUM(loan_status = 0) AS non_default_count,
        SUM(loan_status = 1) AS default_count,

        AVG(loan_status = 1) AS default_rate,

        SUM(loan_amnt) AS loan_exposure,

        SUM(
            CASE
                WHEN loan_status = 1 THEN loan_amnt
                ELSE 0
            END
        ) AS default_exposure

    FROM credit_risk_clean

    GROUP BY
        COALESCE(
            NULLIF(TRIM(person_home_ownership), ''),
            'Unknown'
        )
),

portfolio_totals AS (
    SELECT
        COUNT(*) AS total_loans,
        SUM(loan_amnt) AS total_exposure
    FROM credit_risk_clean
)

SELECT
    s.home_ownership,
    s.loan_count,

    ROUND(
        100.0 * s.loan_count
        / NULLIF(p.total_loans, 0),
        2
    ) AS portfolio_share_pct,

    s.non_default_count,
    s.default_count,

    ROUND(
        100.0 * s.default_rate,
        2
    ) AS default_rate_pct,

    ROUND(s.loan_exposure, 2) AS loan_exposure,

    ROUND(
        100.0 * s.loan_exposure
        / NULLIF(p.total_exposure, 0),
        2
    ) AS exposure_share_pct,

    ROUND(s.default_exposure, 2) AS default_exposure,

    CASE
        WHEN s.loan_count >= prm.min_sample_size
        THEN 'Enough sample'
        ELSE 'Small sample'
    END AS sample_size_status

FROM segment_summary AS s
CROSS JOIN portfolio_totals AS p
CROSS JOIN params AS prm

ORDER BY
    default_rate_pct DESC,
    s.loan_count DESC;


-- ============================================================
-- 7. BORROWER PROFILE CHECKPOINT
-- ============================================================

-- ------------------------------------------------------------
-- 7.1 Compare missing employment-length borrowers with borrowers
--     having valid employment-length information.
-- ------------------------------------------------------------
-- Business question:
-- Does missing employment-length information itself correspond to
-- a materially different observed default rate?
--
-- This is important because 897 observations do not have usable
-- employment-length data.
-- ------------------------------------------------------------

SELECT
    CASE
        WHEN person_emp_length IS NULL
        THEN 'Employment Length Missing'
        ELSE 'Employment Length Available'
    END AS employment_length_data_status,

    COUNT(*) AS loan_count,

    SUM(loan_status = 0) AS non_default_count,
    SUM(loan_status = 1) AS default_count,

    ROUND(
        100.0 * AVG(loan_status = 1),
        2
    ) AS default_rate_pct,

    ROUND(
        SUM(loan_amnt),
        2
    ) AS loan_exposure,

    ROUND(
        SUM(
            CASE
                WHEN loan_status = 1 THEN loan_amnt
                ELSE 0
            END
        ),
        2
    ) AS default_exposure

FROM credit_risk_clean

GROUP BY
    CASE
        WHEN person_emp_length IS NULL
        THEN 'Employment Length Missing'
        ELSE 'Employment Length Available'
    END

ORDER BY default_rate_pct DESC;