-- ============================================================
-- RISK CREDIT ANALYTICS PROJECT
-- FILE: 09_geography_and_segmentation.sql
-- PURPOSE:
--   1. Analyze geographic concentration of default risk.
--   2. Combine only EDA-supported strong signals into interpretable
--      multi-factor intersections.
-- MYSQL VERSION: 8.0+
-- ============================================================
-- SOURCE: credit_risk_clean
-- READ-ONLY EDA
--
-- TARGET:
-- loan_status = 0 -> Non-default
-- loan_status = 1 -> Default
--
-- WORKFLOW POSITION:
-- 04 Overall Risk
-- 05 Borrower Profile
-- 06 Loan Analysis
-- 07 Financial Risk
-- 08 Credit & Stability
-- 09 Geography & Multi-factor Segmentation   <-- CURRENT FILE
-- 10 Power BI Views
--
-- IMPORTANT:
-- - This file does NOT create a final credit score.
-- - This file does NOT create lending approval/rejection rules.
-- - All findings are descriptive associations.
-- - Geography must not be used alone as a lending decision rule.
-- - Geographic differences may reflect borrower mix, economic context,
--   sample composition, or other confounding factors.
-- - Minimum sample controls are analytical safeguards only.
-- ============================================================

USE risk_credit_analytics;


-- ============================================================
-- 0. GEOGRAPHIC DATA READINESS
-- ============================================================

-- ------------------------------------------------------------
-- 0.1 Geographic coverage and cardinality
-- ------------------------------------------------------------
-- Business question:
-- How complete and granular is the geographic information available
-- for portfolio analysis and later Power BI mapping?
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS total_loans,

    COUNT(
        NULLIF(TRIM(country), '')
    ) AS valid_country_rows,

    ROUND(
        100.0 * COUNT(NULLIF(TRIM(country), ''))
        / NULLIF(COUNT(*), 0),
        2
    ) AS country_coverage_pct,

    COUNT(
        NULLIF(TRIM(state), '')
    ) AS valid_state_rows,

    ROUND(
        100.0 * COUNT(NULLIF(TRIM(state), ''))
        / NULLIF(COUNT(*), 0),
        2
    ) AS state_coverage_pct,

    COUNT(
        NULLIF(TRIM(city), '')
    ) AS valid_city_rows,

    ROUND(
        100.0 * COUNT(NULLIF(TRIM(city), ''))
        / NULLIF(COUNT(*), 0),
        2
    ) AS city_coverage_pct,

    COUNT(DISTINCT NULLIF(TRIM(country), ''))
        AS distinct_countries,

    COUNT(DISTINCT NULLIF(TRIM(state), ''))
        AS distinct_states,

    COUNT(DISTINCT NULLIF(TRIM(city), ''))
        AS distinct_cities,

    COUNT(
        CASE
            WHEN city_latitude IS NOT NULL
             AND city_longitude IS NOT NULL
            THEN 1
        END
    ) AS valid_coordinate_rows,

    ROUND(
        100.0 * COUNT(
            CASE
                WHEN city_latitude IS NOT NULL
                 AND city_longitude IS NOT NULL
                THEN 1
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS coordinate_coverage_pct

FROM credit_risk_clean;


-- ------------------------------------------------------------
-- 0.2 Geographic hierarchy checkpoint
-- ------------------------------------------------------------
-- Business question:
-- How many unique country-state-city combinations exist?
--
-- This helps determine whether city-level analysis is too fragmented.
-- ------------------------------------------------------------

SELECT
    COUNT(DISTINCT
        NULLIF(TRIM(country), ''),
        NULLIF(TRIM(state), ''),
        NULLIF(TRIM(city), '')
    ) AS distinct_complete_geo_combinations

FROM credit_risk_clean

WHERE NULLIF(TRIM(country), '') IS NOT NULL
  AND NULLIF(TRIM(state), '') IS NOT NULL
  AND NULLIF(TRIM(city), '') IS NOT NULL;


-- ============================================================
-- 1. COUNTRY-LEVEL RISK
-- ============================================================

-- ------------------------------------------------------------
-- 1.1 Portfolio and default behavior by country
-- ------------------------------------------------------------
-- Business question:
-- Which countries carry meaningful portfolio exposure and how do
-- their observed default rates compare with the portfolio baseline?
--
-- Sample controls:
-- >= 500 loans  -> Strong sample
-- >= 100 loans  -> Enough sample
-- < 100 loans   -> Small sample
-- ------------------------------------------------------------

WITH country_summary AS (
    SELECT
        COALESCE(
            NULLIF(TRIM(country), ''),
            'Unknown'
        ) AS country,

        COUNT(*) AS loan_count,

        SUM(
            CASE WHEN loan_status = 0 THEN 1 ELSE 0 END
        ) AS non_default_count,

        SUM(
            CASE WHEN loan_status = 1 THEN 1 ELSE 0 END
        ) AS default_count,

        AVG(
            CASE WHEN loan_status = 1 THEN 1.0 ELSE 0.0 END
        ) AS default_rate,

        SUM(loan_amnt) AS loan_exposure,

        SUM(
            CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END
        ) AS default_exposure

    FROM credit_risk_clean

    GROUP BY
        COALESCE(
            NULLIF(TRIM(country), ''),
            'Unknown'
        )
),

portfolio_totals AS (
    SELECT
        COUNT(*) AS total_loans,

        SUM(loan_amnt) AS total_exposure,

        SUM(
            CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END
        ) AS total_default_exposure,

        AVG(
            CASE WHEN loan_status = 1 THEN 1.0 ELSE 0.0 END
        ) AS portfolio_default_rate

    FROM credit_risk_clean
)

SELECT
    s.country,

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

    ROUND(
        100.0 * (s.default_rate - p.portfolio_default_rate),
        2
    ) AS default_rate_gap_pp,

    ROUND(
        s.loan_exposure,
        2
    ) AS loan_exposure,

    ROUND(
        100.0 * s.loan_exposure
        / NULLIF(p.total_exposure, 0),
        2
    ) AS exposure_share_pct,

    ROUND(
        s.default_exposure,
        2
    ) AS default_exposure,

    ROUND(
        100.0 * s.default_exposure
        / NULLIF(s.loan_exposure, 0),
        2
    ) AS default_exposure_rate_pct,

    ROUND(
        100.0 * s.default_exposure
        / NULLIF(p.total_default_exposure, 0),
        2
    ) AS share_of_total_default_exposure_pct,

    CASE
        WHEN s.loan_count >= 500 THEN 'Strong sample'
        WHEN s.loan_count >= 100 THEN 'Enough sample'
        ELSE 'Small sample'
    END AS sample_size_status

FROM country_summary AS s
CROSS JOIN portfolio_totals AS p

ORDER BY
    s.default_exposure DESC,
    s.loan_count DESC;


-- ============================================================
-- 2. STATE-LEVEL RISK
-- ============================================================

-- ------------------------------------------------------------
-- 2.1 State-level portfolio risk
-- ------------------------------------------------------------
-- Business question:
-- Which country-state combinations show meaningful default rates
-- and default exposure?
--
-- State is grouped together with country to avoid mixing states with
-- identical names across different countries.
-- ------------------------------------------------------------

WITH state_summary AS (
    SELECT
        COALESCE(
            NULLIF(TRIM(country), ''),
            'Unknown'
        ) AS country,

        COALESCE(
            NULLIF(TRIM(state), ''),
            'Unknown'
        ) AS state,

        COUNT(*) AS loan_count,

        SUM(
            CASE WHEN loan_status = 0 THEN 1 ELSE 0 END
        ) AS non_default_count,

        SUM(
            CASE WHEN loan_status = 1 THEN 1 ELSE 0 END
        ) AS default_count,

        AVG(
            CASE WHEN loan_status = 1 THEN 1.0 ELSE 0.0 END
        ) AS default_rate,

        SUM(loan_amnt) AS loan_exposure,

        SUM(
            CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END
        ) AS default_exposure

    FROM credit_risk_clean

    GROUP BY
        COALESCE(NULLIF(TRIM(country), ''), 'Unknown'),
        COALESCE(NULLIF(TRIM(state), ''), 'Unknown')
),

portfolio_totals AS (
    SELECT
        COUNT(*) AS total_loans,

        SUM(loan_amnt) AS total_exposure,

        SUM(
            CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END
        ) AS total_default_exposure,

        AVG(
            CASE WHEN loan_status = 1 THEN 1.0 ELSE 0.0 END
        ) AS portfolio_default_rate

    FROM credit_risk_clean
)

SELECT
    s.country,
    s.state,

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

    ROUND(
        100.0 * (s.default_rate - p.portfolio_default_rate),
        2
    ) AS default_rate_gap_pp,

    ROUND(
        s.loan_exposure,
        2
    ) AS loan_exposure,

    ROUND(
        100.0 * s.loan_exposure
        / NULLIF(p.total_exposure, 0),
        2
    ) AS exposure_share_pct,

    ROUND(
        s.default_exposure,
        2
    ) AS default_exposure,

    ROUND(
        100.0 * s.default_exposure
        / NULLIF(s.loan_exposure, 0),
        2
    ) AS default_exposure_rate_pct,

    ROUND(
        100.0 * s.default_exposure
        / NULLIF(p.total_default_exposure, 0),
        2
    ) AS share_of_total_default_exposure_pct,

    CASE
        WHEN s.loan_count >= 500 THEN 'Strong sample'
        WHEN s.loan_count >= 100 THEN 'Enough sample'
        ELSE 'Small sample'
    END AS sample_size_status

FROM state_summary AS s
CROSS JOIN portfolio_totals AS p

ORDER BY
    s.default_exposure DESC,
    s.loan_count DESC;


-- ------------------------------------------------------------
-- 2.2 Ranked state risk concentrations
-- ------------------------------------------------------------
-- Business question:
-- Among states with at least 100 loans, which locations combine:
-- - meaningful sample size,
-- - high default rate,
-- - and high default exposure?
--
-- This result is designed for business review, not policy action.
-- ------------------------------------------------------------

WITH state_summary AS (
    SELECT
        COALESCE(NULLIF(TRIM(country), ''), 'Unknown')
            AS country,

        COALESCE(NULLIF(TRIM(state), ''), 'Unknown')
            AS state,

        COUNT(*) AS loan_count,

        SUM(
            CASE WHEN loan_status = 1 THEN 1 ELSE 0 END
        ) AS default_count,

        AVG(
            CASE WHEN loan_status = 1 THEN 1.0 ELSE 0.0 END
        ) AS default_rate,

        SUM(loan_amnt) AS loan_exposure,

        SUM(
            CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END
        ) AS default_exposure

    FROM credit_risk_clean

    GROUP BY
        COALESCE(NULLIF(TRIM(country), ''), 'Unknown'),
        COALESCE(NULLIF(TRIM(state), ''), 'Unknown')
),

eligible_states AS (
    SELECT *
    FROM state_summary
    WHERE loan_count >= 100
)

SELECT
    country,
    state,
    loan_count,
    default_count,
    ROUND(100.0 * default_rate, 2) AS default_rate_pct,
    ROUND(loan_exposure, 2) AS loan_exposure,
    ROUND(default_exposure, 2) AS default_exposure,

    DENSE_RANK() OVER (
        ORDER BY default_exposure DESC
    ) AS default_exposure_rank,

    DENSE_RANK() OVER (
        ORDER BY default_rate DESC
    ) AS default_rate_rank

FROM eligible_states

ORDER BY
    default_exposure_rank,
    default_rate_rank;


-- ============================================================
-- 3. CITY-LEVEL RISK
-- ============================================================

-- ------------------------------------------------------------
-- 3.1 City-level portfolio risk
-- ------------------------------------------------------------
-- Business question:
-- Which cities have enough observations to support meaningful
-- default-risk comparison?
--
-- City is grouped with country and state.
-- Coordinates are included for later Power BI map design.
-- ------------------------------------------------------------

WITH city_summary AS (
    SELECT
        COALESCE(
            NULLIF(TRIM(country), ''),
            'Unknown'
        ) AS country,

        COALESCE(
            NULLIF(TRIM(state), ''),
            'Unknown'
        ) AS state,

        COALESCE(
            NULLIF(TRIM(city), ''),
            'Unknown'
        ) AS city,

        COUNT(*) AS loan_count,

        SUM(
            CASE WHEN loan_status = 0 THEN 1 ELSE 0 END
        ) AS non_default_count,

        SUM(
            CASE WHEN loan_status = 1 THEN 1 ELSE 0 END
        ) AS default_count,

        AVG(
            CASE WHEN loan_status = 1 THEN 1.0 ELSE 0.0 END
        ) AS default_rate,

        SUM(loan_amnt) AS loan_exposure,

        SUM(
            CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END
        ) AS default_exposure,

        AVG(city_latitude) AS city_latitude,

        AVG(city_longitude) AS city_longitude

    FROM credit_risk_clean

    GROUP BY
        COALESCE(NULLIF(TRIM(country), ''), 'Unknown'),
        COALESCE(NULLIF(TRIM(state), ''), 'Unknown'),
        COALESCE(NULLIF(TRIM(city), ''), 'Unknown')
),

portfolio_totals AS (
    SELECT
        COUNT(*) AS total_loans,

        SUM(loan_amnt) AS total_exposure,

        SUM(
            CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END
        ) AS total_default_exposure,

        AVG(
            CASE WHEN loan_status = 1 THEN 1.0 ELSE 0.0 END
        ) AS portfolio_default_rate

    FROM credit_risk_clean
)

SELECT
    s.country,
    s.state,
    s.city,

    ROUND(s.city_latitude, 6) AS city_latitude,
    ROUND(s.city_longitude, 6) AS city_longitude,

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

    ROUND(
        100.0 * (s.default_rate - p.portfolio_default_rate),
        2
    ) AS default_rate_gap_pp,

    ROUND(
        s.loan_exposure,
        2
    ) AS loan_exposure,

    ROUND(
        100.0 * s.loan_exposure
        / NULLIF(p.total_exposure, 0),
        2
    ) AS exposure_share_pct,

    ROUND(
        s.default_exposure,
        2
    ) AS default_exposure,

    ROUND(
        100.0 * s.default_exposure
        / NULLIF(s.loan_exposure, 0),
        2
    ) AS default_exposure_rate_pct,

    ROUND(
        100.0 * s.default_exposure
        / NULLIF(p.total_default_exposure, 0),
        2
    ) AS share_of_total_default_exposure_pct,

    CASE
        WHEN s.loan_count >= 500 THEN 'Strong sample'
        WHEN s.loan_count >= 100 THEN 'Enough sample'
        ELSE 'Small sample'
    END AS sample_size_status

FROM city_summary AS s
CROSS JOIN portfolio_totals AS p

ORDER BY
    s.default_exposure DESC,
    s.loan_count DESC;


-- ------------------------------------------------------------
-- 3.2 Ranked city risk concentrations
-- ------------------------------------------------------------
-- Business question:
-- Which cities with at least 100 loans contribute the most default
-- exposure, and which have the highest default rates?
-- ------------------------------------------------------------

WITH city_summary AS (
    SELECT
        COALESCE(NULLIF(TRIM(country), ''), 'Unknown')
            AS country,

        COALESCE(NULLIF(TRIM(state), ''), 'Unknown')
            AS state,

        COALESCE(NULLIF(TRIM(city), ''), 'Unknown')
            AS city,

        COUNT(*) AS loan_count,

        SUM(
            CASE WHEN loan_status = 1 THEN 1 ELSE 0 END
        ) AS default_count,

        AVG(
            CASE WHEN loan_status = 1 THEN 1.0 ELSE 0.0 END
        ) AS default_rate,

        SUM(loan_amnt) AS loan_exposure,

        SUM(
            CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END
        ) AS default_exposure,

        AVG(city_latitude) AS city_latitude,

        AVG(city_longitude) AS city_longitude

    FROM credit_risk_clean

    GROUP BY
        COALESCE(NULLIF(TRIM(country), ''), 'Unknown'),
        COALESCE(NULLIF(TRIM(state), ''), 'Unknown'),
        COALESCE(NULLIF(TRIM(city), ''), 'Unknown')
),

eligible_cities AS (
    SELECT *
    FROM city_summary
    WHERE loan_count >= 100
)

SELECT
    country,
    state,
    city,

    ROUND(city_latitude, 6) AS city_latitude,
    ROUND(city_longitude, 6) AS city_longitude,

    loan_count,
    default_count,

    ROUND(
        100.0 * default_rate,
        2
    ) AS default_rate_pct,

    ROUND(
        loan_exposure,
        2
    ) AS loan_exposure,

    ROUND(
        default_exposure,
        2
    ) AS default_exposure,

    DENSE_RANK() OVER (
        ORDER BY default_exposure DESC
    ) AS default_exposure_rank,

    DENSE_RANK() OVER (
        ORDER BY default_rate DESC
    ) AS default_rate_rank

FROM eligible_cities

ORDER BY
    default_exposure_rank,
    default_rate_rank;


-- ============================================================
-- 4. AFFORDABILITY x LOAN GRADE
-- ============================================================

-- ------------------------------------------------------------
-- 4.1 Multi-factor intersection:
--     affordability condition x loan-grade group
-- ------------------------------------------------------------
-- Why these dimensions?
--
-- File 07:
-- - LTI >= 0.30 was a very strong signal.
-- - DTI >= 0.45 was a strong signal.
--
-- File 06:
-- - Grades D-G showed a major increase in observed default risk.
--
-- This query tests whether loan grade and affordability provide
-- additional separation when considered together.
--
-- Grade groups:
-- A-C = Lower-grade-risk group observed in EDA
-- D-G = Elevated-grade-risk group observed in EDA
--
-- Affordability groups:
-- Neither Elevated
-- Elevated DTI Only
-- Elevated LTI Only
-- Elevated LTI + Elevated DTI
--
-- These labels describe observed analytical conditions only.
-- ------------------------------------------------------------

WITH params AS (
    SELECT 100 AS min_sample_size
),

segment_base AS (
    SELECT
        CASE
            WHEN loan_grade IN ('A', 'B', 'C')
                THEN 'Grade A-C'
            WHEN loan_grade IN ('D', 'E', 'F', 'G')
                THEN 'Grade D-G'
            ELSE 'Grade Unknown'
        END AS grade_group,

        CASE
            WHEN loan_to_income_ratio IS NULL
              OR debt_to_income_ratio IS NULL
                THEN 'Affordability Unknown'

            WHEN loan_to_income_ratio >= 0.30
             AND debt_to_income_ratio >= 0.45
                THEN 'Elevated LTI + Elevated DTI'

            WHEN loan_to_income_ratio >= 0.30
                THEN 'Elevated LTI Only'

            WHEN debt_to_income_ratio >= 0.45
                THEN 'Elevated DTI Only'

            ELSE 'Neither Elevated'
        END AS affordability_group,

        loan_status,
        loan_amnt

    FROM credit_risk_clean
),

segment_summary AS (
    SELECT
        grade_group,
        affordability_group,

        COUNT(*) AS loan_count,

        SUM(
            CASE WHEN loan_status = 0 THEN 1 ELSE 0 END
        ) AS non_default_count,

        SUM(
            CASE WHEN loan_status = 1 THEN 1 ELSE 0 END
        ) AS default_count,

        AVG(
            CASE WHEN loan_status = 1 THEN 1.0 ELSE 0.0 END
        ) AS default_rate,

        SUM(loan_amnt) AS loan_exposure,

        SUM(
            CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END
        ) AS default_exposure

    FROM segment_base

    GROUP BY
        grade_group,
        affordability_group
),

portfolio_totals AS (
    SELECT
        COUNT(*) AS total_loans,

        SUM(loan_amnt) AS total_exposure,

        SUM(
            CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END
        ) AS total_default_exposure

    FROM credit_risk_clean
)

SELECT
    s.grade_group,
    s.affordability_group,

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

    ROUND(
        s.loan_exposure,
        2
    ) AS loan_exposure,

    ROUND(
        100.0 * s.loan_exposure
        / NULLIF(p.total_exposure, 0),
        2
    ) AS exposure_share_pct,

    ROUND(
        s.default_exposure,
        2
    ) AS default_exposure,

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

ORDER BY
    default_rate_pct DESC,
    s.loan_count DESC;


-- ============================================================
-- 5. INCOME x HOME OWNERSHIP
-- ============================================================

-- ------------------------------------------------------------
-- 5.1 Multi-factor intersection:
--     income group x housing group
-- ------------------------------------------------------------
-- Why these dimensions?
--
-- File 05:
-- - Income showed a strong monotonic default pattern.
-- - RENT showed a strong default and exposure concentration.
--
-- Income groups:
-- <50K
-- 50K-100K
-- 100K+
--
-- Housing groups:
-- RENT
-- OWN / MORTGAGE
-- OTHER
--
-- This query checks whether RENT remains risky across income levels
-- and whether higher income materially offsets housing-associated risk.
-- ------------------------------------------------------------

WITH params AS (
    SELECT 100 AS min_sample_size
),

segment_base AS (
    SELECT
        CASE
            WHEN person_income IS NULL
                THEN 'Income Unknown'
            WHEN person_income < 50000
                THEN '<50K'
            WHEN person_income < 100000
                THEN '50K-100K'
            ELSE '100K+'
        END AS income_group,

        CASE
            WHEN person_home_ownership = 'RENT'
                THEN 'RENT'
            WHEN person_home_ownership IN ('OWN', 'MORTGAGE')
                THEN 'OWN / MORTGAGE'
            ELSE 'OTHER / UNKNOWN'
        END AS housing_group,

        loan_status,
        loan_amnt

    FROM credit_risk_clean
),

segment_summary AS (
    SELECT
        income_group,
        housing_group,

        COUNT(*) AS loan_count,

        SUM(
            CASE WHEN loan_status = 0 THEN 1 ELSE 0 END
        ) AS non_default_count,

        SUM(
            CASE WHEN loan_status = 1 THEN 1 ELSE 0 END
        ) AS default_count,

        AVG(
            CASE WHEN loan_status = 1 THEN 1.0 ELSE 0.0 END
        ) AS default_rate,

        SUM(loan_amnt) AS loan_exposure,

        SUM(
            CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END
        ) AS default_exposure

    FROM segment_base

    GROUP BY
        income_group,
        housing_group
),

portfolio_totals AS (
    SELECT
        COUNT(*) AS total_loans,

        SUM(loan_amnt) AS total_exposure,

        SUM(
            CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END
        ) AS total_default_exposure

    FROM credit_risk_clean
)

SELECT
    s.income_group,
    s.housing_group,

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

    ROUND(
        s.loan_exposure,
        2
    ) AS loan_exposure,

    ROUND(
        100.0 * s.loan_exposure
        / NULLIF(p.total_exposure, 0),
        2
    ) AS exposure_share_pct,

    ROUND(
        s.default_exposure,
        2
    ) AS default_exposure,

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

ORDER BY
    default_rate_pct DESC,
    s.loan_count DESC;


-- ============================================================
-- 6. PREVIOUS DEFAULT x HOUSING x AFFORDABILITY
-- ============================================================

-- ------------------------------------------------------------
-- 6.1 Three-factor intersection
-- ------------------------------------------------------------
-- Why these dimensions?
--
-- File 08:
-- - Previous Default = Y was a strong signal.
-- - RENT was a very strong borrower-stability signal.
--
-- File 07:
-- - Elevated affordability conditions were highly associated with
--   default outcomes.
--
-- Affordability Elevated:
-- LTI >= 0.30 OR DTI >= 0.45
--
-- This query tests whether the combination of historical credit risk,
-- housing status, and current affordability creates a much stronger
-- concentration than each factor alone.
--
-- This remains EDA, NOT a final lending segment.
-- ------------------------------------------------------------

WITH params AS (
    SELECT 100 AS min_sample_size
),

segment_base AS (
    SELECT
        CASE
            WHEN TRIM(cb_person_default_on_file) = 'Y'
                THEN 'Previous Default = Y'
            WHEN TRIM(cb_person_default_on_file) = 'N'
                THEN 'Previous Default = N'
            ELSE 'Previous Default Unknown'
        END AS previous_default_group,

        CASE
            WHEN TRIM(person_home_ownership) = 'RENT'
                THEN 'RENT'
            ELSE 'NON-RENT'
        END AS housing_group,

        CASE
            WHEN loan_to_income_ratio IS NULL
              OR debt_to_income_ratio IS NULL
                THEN 'Affordability Unknown'

            WHEN loan_to_income_ratio >= 0.30
              OR debt_to_income_ratio >= 0.45
                THEN 'Affordability Elevated'

            ELSE 'Affordability Not Elevated'
        END AS affordability_group,

        loan_status,
        loan_amnt

    FROM credit_risk_clean
),

segment_summary AS (
    SELECT
        previous_default_group,
        housing_group,
        affordability_group,

        COUNT(*) AS loan_count,

        SUM(
            CASE WHEN loan_status = 0 THEN 1 ELSE 0 END
        ) AS non_default_count,

        SUM(
            CASE WHEN loan_status = 1 THEN 1 ELSE 0 END
        ) AS default_count,

        AVG(
            CASE WHEN loan_status = 1 THEN 1.0 ELSE 0.0 END
        ) AS default_rate,

        SUM(loan_amnt) AS loan_exposure,

        SUM(
            CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END
        ) AS default_exposure

    FROM segment_base

    GROUP BY
        previous_default_group,
        housing_group,
        affordability_group
),

portfolio_totals AS (
    SELECT
        COUNT(*) AS total_loans,

        SUM(loan_amnt) AS total_exposure,

        SUM(
            CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END
        ) AS total_default_exposure

    FROM credit_risk_clean
)

SELECT
    s.previous_default_group,
    s.housing_group,
    s.affordability_group,

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

    ROUND(
        s.loan_exposure,
        2
    ) AS loan_exposure,

    ROUND(
        100.0 * s.loan_exposure
        / NULLIF(p.total_exposure, 0),
        2
    ) AS exposure_share_pct,

    ROUND(
        s.default_exposure,
        2
    ) AS default_exposure,

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

ORDER BY
    default_rate_pct DESC,
    s.loan_count DESC;


-- ============================================================
-- 7. RANKED MULTI-FACTOR SEGMENT CHECKPOINT
-- ============================================================

-- ------------------------------------------------------------
-- 7.1 Rank selected EDA-supported candidate risk concentrations
-- ------------------------------------------------------------
-- Business question:
-- Which interpretable multi-factor conditions combine:
-- - high default rate,
-- - meaningful sample size,
-- - meaningful exposure,
-- - meaningful share of total default exposure?
--
-- IMPORTANT:
-- These conditions OVERLAP.
-- Do NOT add their counts/exposures together.
-- They are candidate concentrations for business review, not mutually
-- exclusive final customer segments.
-- ------------------------------------------------------------

WITH candidate_segments AS (

    -- --------------------------------------------------------
    -- Affordability concentration identified in file 07
    -- --------------------------------------------------------
    SELECT
        'Affordability' AS segment_family,
        'LTI >= 0.30 AND DTI >= 0.45' AS segment_name,
        loan_status,
        loan_amnt
    FROM credit_risk_clean
    WHERE loan_to_income_ratio >= 0.30
      AND debt_to_income_ratio >= 0.45

    UNION ALL

    -- --------------------------------------------------------
    -- Loan quality + affordability
    -- --------------------------------------------------------
    SELECT
        'Loan + Affordability',
        'Grade D-G AND LTI >= 0.30',
        loan_status,
        loan_amnt
    FROM credit_risk_clean
    WHERE loan_grade IN ('D', 'E', 'F', 'G')
      AND loan_to_income_ratio >= 0.30

    UNION ALL

    SELECT
        'Loan + Affordability',
        'Grade D-G AND DTI >= 0.45',
        loan_status,
        loan_amnt
    FROM credit_risk_clean
    WHERE loan_grade IN ('D', 'E', 'F', 'G')
      AND debt_to_income_ratio >= 0.45

    UNION ALL

    -- --------------------------------------------------------
    -- Borrower financial vulnerability
    -- --------------------------------------------------------
    SELECT
        'Borrower Stability',
        'Income <50K AND RENT',
        loan_status,
        loan_amnt
    FROM credit_risk_clean
    WHERE person_income < 50000
      AND TRIM(person_home_ownership) = 'RENT'

    UNION ALL

    SELECT
        'Borrower Stability',
        'Income <50K AND Employment <4 Years',
        loan_status,
        loan_amnt
    FROM credit_risk_clean
    WHERE person_income < 50000
      AND person_emp_length < 4

    UNION ALL

    -- --------------------------------------------------------
    -- Historical credit + housing
    -- --------------------------------------------------------
    SELECT
        'Credit + Stability',
        'Previous Default = Y AND RENT',
        loan_status,
        loan_amnt
    FROM credit_risk_clean
    WHERE TRIM(cb_person_default_on_file) = 'Y'
      AND TRIM(person_home_ownership) = 'RENT'

    UNION ALL

    -- --------------------------------------------------------
    -- Historical credit + affordability
    -- --------------------------------------------------------
    SELECT
        'Credit + Affordability',
        'Previous Default = Y AND Affordability Elevated',
        loan_status,
        loan_amnt
    FROM credit_risk_clean
    WHERE TRIM(cb_person_default_on_file) = 'Y'
      AND (
            loan_to_income_ratio >= 0.30
         OR debt_to_income_ratio >= 0.45
      )

    UNION ALL

    -- --------------------------------------------------------
    -- Three-factor concentration
    -- --------------------------------------------------------
    SELECT
        'Credit + Housing + Affordability',
        'Previous Default = Y AND RENT AND Affordability Elevated',
        loan_status,
        loan_amnt
    FROM credit_risk_clean
    WHERE TRIM(cb_person_default_on_file) = 'Y'
      AND TRIM(person_home_ownership) = 'RENT'
      AND (
            loan_to_income_ratio >= 0.30
         OR debt_to_income_ratio >= 0.45
      )
),

segment_summary AS (
    SELECT
        segment_family,
        segment_name,

        COUNT(*) AS loan_count,

        SUM(
            CASE WHEN loan_status = 1 THEN 1 ELSE 0 END
        ) AS default_count,

        AVG(
            CASE WHEN loan_status = 1 THEN 1.0 ELSE 0.0 END
        ) AS default_rate,

        SUM(loan_amnt) AS loan_exposure,

        SUM(
            CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END
        ) AS default_exposure

    FROM candidate_segments

    GROUP BY
        segment_family,
        segment_name
),

portfolio_totals AS (
    SELECT
        COUNT(*) AS total_loans,

        SUM(loan_amnt) AS total_exposure,

        SUM(
            CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END
        ) AS total_default_exposure

    FROM credit_risk_clean
),

eligible_segments AS (
    SELECT
        s.*,

        ROUND(
            100.0 * s.loan_count
            / NULLIF(p.total_loans, 0),
            2
        ) AS portfolio_share_pct,

        ROUND(
            100.0 * s.loan_exposure
            / NULLIF(p.total_exposure, 0),
            2
        ) AS exposure_share_pct,

        ROUND(
            100.0 * s.default_exposure
            / NULLIF(p.total_default_exposure, 0),
            2
        ) AS share_of_total_default_exposure_pct

    FROM segment_summary AS s
    CROSS JOIN portfolio_totals AS p

    WHERE s.loan_count >= 100
)

SELECT
    segment_family,
    segment_name,

    loan_count,

    portfolio_share_pct,

    default_count,

    ROUND(
        100.0 * default_rate,
        2
    ) AS default_rate_pct,

    ROUND(
        loan_exposure,
        2
    ) AS loan_exposure,

    exposure_share_pct,

    ROUND(
        default_exposure,
        2
    ) AS default_exposure,

    share_of_total_default_exposure_pct,

    DENSE_RANK() OVER (
        ORDER BY default_rate DESC
    ) AS default_rate_rank,

    DENSE_RANK() OVER (
        ORDER BY default_exposure DESC
    ) AS default_exposure_rank

FROM eligible_segments

ORDER BY
    default_exposure_rank,
    default_rate_rank;


-- ============================================================
-- 8. LOWER-OBSERVED-RISK INTERSECTION CHECKPOINT
-- ============================================================

-- ------------------------------------------------------------
-- 8.1 Review interpretable lower-observed-risk intersections
-- ------------------------------------------------------------
-- Business question:
-- Which combinations of favorable observed indicators show lower
-- default rates while retaining meaningful sample size?
--
-- IMPORTANT:
-- "Lower observed risk" is descriptive.
-- It does NOT mean guaranteed repayment or automatic approval.
--
-- Conditions are intentionally simple and based on strong EDA signals:
-- - Grade A-B
-- - LTI < 0.20
-- - DTI < 0.35
-- - Previous Default = N
--
-- Housing is intentionally excluded from the core definition so that
-- this checkpoint does not create an unnecessarily restrictive rule.
-- ------------------------------------------------------------

WITH lower_observed_risk_base AS (
    SELECT
        CASE
            WHEN loan_grade IN ('A', 'B')
             AND loan_to_income_ratio < 0.20
             AND debt_to_income_ratio < 0.35
             AND TRIM(cb_person_default_on_file) = 'N'
                THEN 'Lower Observed Risk Intersection'

            ELSE 'Other Portfolio'
        END AS observed_risk_group,

        loan_status,
        loan_amnt

    FROM credit_risk_clean
),

group_summary AS (
    SELECT
        observed_risk_group,

        COUNT(*) AS loan_count,

        SUM(
            CASE WHEN loan_status = 1 THEN 1 ELSE 0 END
        ) AS default_count,

        AVG(
            CASE WHEN loan_status = 1 THEN 1.0 ELSE 0.0 END
        ) AS default_rate,

        SUM(loan_amnt) AS loan_exposure,

        SUM(
            CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END
        ) AS default_exposure

    FROM lower_observed_risk_base

    GROUP BY observed_risk_group
),

portfolio_totals AS (
    SELECT
        COUNT(*) AS total_loans,

        SUM(loan_amnt) AS total_exposure,

        SUM(
            CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END
        ) AS total_default_exposure

    FROM credit_risk_clean
)

SELECT
    s.observed_risk_group,

    s.loan_count,

    ROUND(
        100.0 * s.loan_count
        / NULLIF(p.total_loans, 0),
        2
    ) AS portfolio_share_pct,

    s.default_count,

    ROUND(
        100.0 * s.default_rate,
        2
    ) AS default_rate_pct,

    ROUND(
        s.loan_exposure,
        2
    ) AS loan_exposure,

    ROUND(
        100.0 * s.loan_exposure
        / NULLIF(p.total_exposure, 0),
        2
    ) AS exposure_share_pct,

    ROUND(
        s.default_exposure,
        2
    ) AS default_exposure,

    ROUND(
        100.0 * s.default_exposure
        / NULLIF(p.total_default_exposure, 0),
        2
    ) AS share_of_total_default_exposure_pct

FROM group_summary AS s
CROSS JOIN portfolio_totals AS p

ORDER BY
    CASE s.observed_risk_group
        WHEN 'Lower Observed Risk Intersection' THEN 1
        ELSE 2
    END;


-- ============================================================
-- 9. SEGMENTATION READINESS CHECKPOINT
-- ============================================================

-- ------------------------------------------------------------
-- 9.1 Compact review of the strongest individual signals found
--     across files 05-08
-- ------------------------------------------------------------
-- Business question:
-- Before publishing Power BI views, which previously validated
-- conditions remain the strongest concentration signals?
--
-- Conditions overlap.
-- This is a checkpoint only.
-- ------------------------------------------------------------

WITH review_conditions AS (

    SELECT
        'Portfolio Baseline' AS review_condition,
        loan_status,
        loan_amnt
    FROM credit_risk_clean

    UNION ALL

    SELECT
        'Income <50K',
        loan_status,
        loan_amnt
    FROM credit_risk_clean
    WHERE person_income < 50000

    UNION ALL

    SELECT
        'Home = RENT',
        loan_status,
        loan_amnt
    FROM credit_risk_clean
    WHERE TRIM(person_home_ownership) = 'RENT'

    UNION ALL

    SELECT
        'Employment <4 Years',
        loan_status,
        loan_amnt
    FROM credit_risk_clean
    WHERE person_emp_length < 4

    UNION ALL

    SELECT
        'Grade D-G',
        loan_status,
        loan_amnt
    FROM credit_risk_clean
    WHERE loan_grade IN ('D', 'E', 'F', 'G')

    UNION ALL

    SELECT
        'Interest Rate >=12%',
        loan_status,
        loan_amnt
    FROM credit_risk_clean
    WHERE loan_int_rate >= 12

    UNION ALL

    SELECT
        'Loan Amount >=15K',
        loan_status,
        loan_amnt
    FROM credit_risk_clean
    WHERE loan_amnt >= 15000

    UNION ALL

    SELECT
        'LTI >=0.30',
        loan_status,
        loan_amnt
    FROM credit_risk_clean
    WHERE loan_to_income_ratio >= 0.30

    UNION ALL

    SELECT
        'DTI >=0.45',
        loan_status,
        loan_amnt
    FROM credit_risk_clean
    WHERE debt_to_income_ratio >= 0.45

    UNION ALL

    SELECT
        'Previous Default = Y',
        loan_status,
        loan_amnt
    FROM credit_risk_clean
    WHERE TRIM(cb_person_default_on_file) = 'Y'
),

condition_summary AS (
    SELECT
        review_condition,

        COUNT(*) AS loan_count,

        SUM(
            CASE WHEN loan_status = 1 THEN 1 ELSE 0 END
        ) AS default_count,

        AVG(
            CASE WHEN loan_status = 1 THEN 1.0 ELSE 0.0 END
        ) AS default_rate,

        SUM(loan_amnt) AS loan_exposure,

        SUM(
            CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END
        ) AS default_exposure

    FROM review_conditions

    GROUP BY review_condition
),

portfolio_totals AS (
    SELECT
        COUNT(*) AS total_loans,

        SUM(loan_amnt) AS total_exposure,

        SUM(
            CASE WHEN loan_status = 1 THEN loan_amnt ELSE 0 END
        ) AS total_default_exposure

    FROM credit_risk_clean
)

SELECT
    s.review_condition,

    s.loan_count,

    ROUND(
        100.0 * s.loan_count
        / NULLIF(p.total_loans, 0),
        2
    ) AS portfolio_share_pct,

    s.default_count,

    ROUND(
        100.0 * s.default_rate,
        2
    ) AS default_rate_pct,

    ROUND(
        s.loan_exposure,
        2
    ) AS loan_exposure,

    ROUND(
        100.0 * s.loan_exposure
        / NULLIF(p.total_exposure, 0),
        2
    ) AS exposure_share_pct,

    ROUND(
        s.default_exposure,
        2
    ) AS default_exposure,

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
        WHEN 'Income <50K' THEN 2
        WHEN 'Home = RENT' THEN 3
        WHEN 'Employment <4 Years' THEN 4
        WHEN 'Grade D-G' THEN 5
        WHEN 'Interest Rate >=12%' THEN 6
        WHEN 'Loan Amount >=15K' THEN 7
        WHEN 'LTI >=0.30' THEN 8
        WHEN 'DTI >=0.45' THEN 9
        WHEN 'Previous Default = Y' THEN 10
        ELSE 99
    END;


-- ============================================================
-- END OF 09_GEOGRAPHY_AND_SEGMENTATION.SQL
-- ============================================================
-- REVIEW CHECKPOINT
--
-- Run one numbered query at a time.
--
-- PRIORITY RESULTS:
-- 0.1 Geographic coverage
-- 1.1 Country-level risk
-- 2.2 Ranked state concentrations
-- 3.2 Ranked city concentrations
-- 4.1 Affordability x Loan Grade
-- 5.1 Income x Home Ownership
-- 6.1 Previous Default x Housing x Affordability
-- 7.1 Ranked multi-factor candidate concentrations
-- 8.1 Lower-observed-risk intersection
-- 9.1 Segmentation readiness checkpoint
--
-- QUESTIONS TO ANSWER BEFORE FILE 10:
--
-- GEOGRAPHY
-- 1. Are geographic differences large enough to be meaningful?
-- 2. Which states/cities have high default rates AND enough sample?
-- 3. Which locations contribute the most default exposure?
-- 4. Are high-rate locations also high-exposure locations?
--
-- MULTI-FACTOR
-- 5. Does Grade D-G remain highly risky when affordability is controlled?
-- 6. Does elevated affordability remain highly risky within Grade A-C?
-- 7. Does RENT remain important across different income levels?
-- 8. How much additional separation appears when Previous Default,
--    RENT, and elevated affordability occur together?
-- 9. Which candidate concentration combines:
--    - high default rate,
--    - meaningful loan count,
--    - meaningful default exposure?
-- 10. Is there a sufficiently large lower-observed-risk intersection?
--
-- POWER BI READINESS
-- 11. Which dimensions have earned a stable place in Power BI views?
-- 12. Which weak dimensions should remain slicers/supporting fields only?
--
-- DO NOT CREATE POWER BI VIEWS IN THIS FILE.
-- Stable views belong to 10_powerbi_views.sql after these results
-- are reviewed.
-- ============================================================
