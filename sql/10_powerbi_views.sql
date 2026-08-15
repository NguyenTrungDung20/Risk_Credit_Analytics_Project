-- ============================================================
-- RISK CREDIT ANALYTICS PROJECT
-- FILE: 10_powerbi_views.sql
-- PURPOSE: Publish a stable semantic layer for Power BI.
-- MYSQL VERSION: 8.0+
-- ============================================================
-- SOURCE OF TRUTH
-- credit_risk_clean
--
-- GRAIN OF CLEAN TABLE
-- Validation confirmed:
-- - 32,581 rows
-- - 32,581 distinct client_ID values
-- - 1 row = 1 loan = 1 distinct client in this snapshot
--
-- TARGET INTERPRETATION
-- loan_status = 0 -> Non-default
-- loan_status = 1 -> Default
--
-- DESIGN PRINCIPLES
-- 1. Do not create one view for every EDA query.
-- 2. Keep one detailed Fact View as the main Power BI table.
-- 3. Freeze stable business bands in SQL.
-- 4. Keep dynamic aggregation/KPIs in DAX.
-- 5. Candidate risk concentrations are overlapping conditions.
--    They are NOT mutually exclusive risk classes.
-- 6. Do not create an arbitrary credit score in this file.
-- 7. Geography is for monitoring and drill-down, not a lending rule.
-- 8. QA metrics must reconcile with the EDA baseline before dashboarding.
--
-- EXPECTED BASELINE FROM 04-09
-- Total Loans       = 32,581
-- Default Loans     = 7,108
-- Default Rate      = 21.82%
-- Loan Exposure     = 312,431,300
-- Default Exposure  = 77,125,375
-- ============================================================

USE risk_credit_analytics;


-- ============================================================
-- 0. PRE-FLIGHT CHECK
-- ============================================================

-- ------------------------------------------------------------
-- 0.1 Confirm that the semantic-layer source exists.
-- ------------------------------------------------------------

SELECT
    TABLE_SCHEMA,
    TABLE_NAME,
    TABLE_TYPE
FROM information_schema.tables
WHERE TABLE_SCHEMA = 'risk_credit_analytics'
  AND TABLE_NAME = 'credit_risk_clean';


-- ------------------------------------------------------------
-- 0.2 Confirm key columns used by the Power BI views.
-- ------------------------------------------------------------

SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM information_schema.columns
WHERE TABLE_SCHEMA = 'risk_credit_analytics'
  AND TABLE_NAME = 'credit_risk_clean'
  AND COLUMN_NAME IN (
        'client_ID',
        'loan_status',
        'person_age',
        'person_income',
        'person_emp_length',
        'person_home_ownership',
        'loan_intent',
        'loan_grade',
        'loan_amnt',
        'loan_int_rate',
        'loan_term_months',
        'loan_to_income_ratio',
        'debt_to_income_ratio',
        'credit_utilization_ratio',
        'other_debt',
        'cb_person_default_on_file',
        'cb_person_cred_hist_length',
        'open_accounts',
        'past_delinquencies',
        'country',
        'state',
        'city',
        'city_latitude',
        'city_longitude'
  )
ORDER BY COLUMN_NAME;


-- ============================================================
-- 1. DROP EXISTING POWER BI VIEWS
-- ============================================================
-- Drop dependent views first.
-- This section makes the script safely re-runnable.
-- ============================================================

DROP VIEW IF EXISTS vw_segment_candidates;
DROP VIEW IF EXISTS vw_geography;
DROP VIEW IF EXISTS vw_powerbi_qa;
DROP VIEW IF EXISTS vw_credit_risk_detail;


-- ============================================================
-- 2. MAIN FACT VIEW
--    vw_credit_risk_detail
-- ============================================================
--
-- PURPOSE
-- Main Power BI table.
--
-- GRAIN
-- 1 row = 1 loan / 1 client_ID.
--
-- WHY c.*
-- The clean table already contains the validated source fields.
-- We preserve them for slicers and drill-down, then append stable
-- Power BI semantic fields prefixed with pbi_.
--
-- IMPORTANT
-- pbi_* bands are based on the EDA definitions already reviewed in
-- files 05-09. Do not redefine them independently in Power BI.
-- ============================================================

CREATE VIEW vw_credit_risk_detail AS

SELECT
    c.*,

    -- ========================================================
    -- 2.1 Row-level additive fields
    -- ========================================================

    1 AS pbi_loan_count,

    CASE
        WHEN c.loan_status = 1 THEN 1
        ELSE 0
    END AS pbi_default_count,

    CASE
        WHEN c.loan_status = 1 THEN c.loan_amnt
        ELSE 0
    END AS pbi_default_exposure_amount,

    CASE
        WHEN c.loan_status = 0 THEN 'Non-default'
        WHEN c.loan_status = 1 THEN 'Default'
        ELSE 'Unknown'
    END AS pbi_loan_outcome,


    -- ========================================================
    -- 2.2 Geography key
    -- ========================================================

    CONCAT_WS(
        '|',
        COALESCE(NULLIF(TRIM(c.country), ''), 'Unknown'),
        COALESCE(NULLIF(TRIM(c.state), ''), 'Unknown'),
        COALESCE(NULLIF(TRIM(c.city), ''), 'Unknown')
    ) AS pbi_geo_key,


    -- ========================================================
    -- 2.3 AGE BAND
    -- EDA file 05
    -- ========================================================

    CASE
        WHEN c.person_age IS NULL THEN 'Unknown'
        WHEN c.person_age < 25 THEN '<25'
        WHEN c.person_age < 35 THEN '25-34'
        WHEN c.person_age < 45 THEN '35-44'
        WHEN c.person_age < 55 THEN '45-54'
        ELSE '55+'
    END AS pbi_age_band,

    CASE
        WHEN c.person_age IS NULL THEN 99
        WHEN c.person_age < 25 THEN 1
        WHEN c.person_age < 35 THEN 2
        WHEN c.person_age < 45 THEN 3
        WHEN c.person_age < 55 THEN 4
        ELSE 5
    END AS pbi_age_band_sort,


    -- ========================================================
    -- 2.4 INCOME BAND
    -- EDA file 05
    -- ========================================================

    CASE
        WHEN c.person_income IS NULL THEN 'Unknown'
        WHEN c.person_income < 30000 THEN '<30K'
        WHEN c.person_income < 50000 THEN '30K-50K'
        WHEN c.person_income < 75000 THEN '50K-75K'
        WHEN c.person_income < 100000 THEN '75K-100K'
        ELSE '100K+'
    END AS pbi_income_band,

    CASE
        WHEN c.person_income IS NULL THEN 99
        WHEN c.person_income < 30000 THEN 1
        WHEN c.person_income < 50000 THEN 2
        WHEN c.person_income < 75000 THEN 3
        WHEN c.person_income < 100000 THEN 4
        ELSE 5
    END AS pbi_income_band_sort,

    -- Broader grouping used in file 09 interaction analysis.
    CASE
        WHEN c.person_income IS NULL THEN 'Income Unknown'
        WHEN c.person_income < 50000 THEN '<50K'
        WHEN c.person_income < 100000 THEN '50K-100K'
        ELSE '100K+'
    END AS pbi_income_group_3,

    CASE
        WHEN c.person_income IS NULL THEN 99
        WHEN c.person_income < 50000 THEN 1
        WHEN c.person_income < 100000 THEN 2
        ELSE 3
    END AS pbi_income_group_3_sort,


    -- ========================================================
    -- 2.5 EMPLOYMENT LENGTH BAND
    -- EDA file 05
    -- ========================================================

    CASE
        WHEN c.person_emp_length IS NULL THEN 'Unknown'
        WHEN c.person_emp_length < 1 THEN '<1 year'
        WHEN c.person_emp_length < 4 THEN '1-3 years'
        WHEN c.person_emp_length < 7 THEN '4-6 years'
        WHEN c.person_emp_length <= 10 THEN '7-10 years'
        ELSE '10+ years'
    END AS pbi_employment_length_band,

    CASE
        WHEN c.person_emp_length IS NULL THEN 99
        WHEN c.person_emp_length < 1 THEN 1
        WHEN c.person_emp_length < 4 THEN 2
        WHEN c.person_emp_length < 7 THEN 3
        WHEN c.person_emp_length <= 10 THEN 4
        ELSE 5
    END AS pbi_employment_length_band_sort,

    -- Stability grouping used in file 08.
    CASE
        WHEN c.person_emp_length IS NULL THEN 'Unknown'
        WHEN c.person_emp_length < 4 THEN '<4 years'
        ELSE '4+ years'
    END AS pbi_employment_stability_group,

    CASE
        WHEN c.person_emp_length IS NULL THEN 99
        WHEN c.person_emp_length < 4 THEN 1
        ELSE 2
    END AS pbi_employment_stability_sort,


    -- ========================================================
    -- 2.6 HOME OWNERSHIP GROUP
    -- ========================================================

    CASE
        WHEN NULLIF(TRIM(c.person_home_ownership), '') IS NULL
            THEN 'UNKNOWN'
        WHEN TRIM(c.person_home_ownership) = 'RENT'
            THEN 'RENT'
        WHEN TRIM(c.person_home_ownership) IN ('OWN', 'MORTGAGE')
            THEN 'OWN / MORTGAGE'
        ELSE 'OTHER'
    END AS pbi_housing_group,


    -- ========================================================
    -- 2.7 LOAN GRADE
    -- EDA files 04, 06, 09
    -- ========================================================

    CASE
        WHEN TRIM(c.loan_grade) IN ('A', 'B', 'C')
            THEN 'Grade A-C'
        WHEN TRIM(c.loan_grade) IN ('D', 'E', 'F', 'G')
            THEN 'Grade D-G'
        ELSE 'Grade Unknown'
    END AS pbi_grade_group,

    CASE
        WHEN TRIM(c.loan_grade) = 'A' THEN 1
        WHEN TRIM(c.loan_grade) = 'B' THEN 2
        WHEN TRIM(c.loan_grade) = 'C' THEN 3
        WHEN TRIM(c.loan_grade) = 'D' THEN 4
        WHEN TRIM(c.loan_grade) = 'E' THEN 5
        WHEN TRIM(c.loan_grade) = 'F' THEN 6
        WHEN TRIM(c.loan_grade) = 'G' THEN 7
        ELSE 99
    END AS pbi_loan_grade_sort,


    -- ========================================================
    -- 2.8 LOAN AMOUNT BAND
    -- EDA file 06
    -- ========================================================

    CASE
        WHEN c.loan_amnt IS NULL THEN 'Unknown'
        WHEN c.loan_amnt < 5000 THEN '<5K'
        WHEN c.loan_amnt < 10000 THEN '5K-10K'
        WHEN c.loan_amnt < 15000 THEN '10K-15K'
        WHEN c.loan_amnt < 20000 THEN '15K-20K'
        ELSE '20K+'
    END AS pbi_loan_amount_band,

    CASE
        WHEN c.loan_amnt IS NULL THEN 99
        WHEN c.loan_amnt < 5000 THEN 1
        WHEN c.loan_amnt < 10000 THEN 2
        WHEN c.loan_amnt < 15000 THEN 3
        WHEN c.loan_amnt < 20000 THEN 4
        ELSE 5
    END AS pbi_loan_amount_band_sort,


    -- ========================================================
    -- 2.9 INTEREST RATE BAND
    -- EDA file 06
    -- loan_int_rate is stored as percentage points, e.g. 11.00.
    -- ========================================================

    CASE
        WHEN c.loan_int_rate IS NULL THEN 'Unknown'
        WHEN c.loan_int_rate < 8 THEN '<8%'
        WHEN c.loan_int_rate < 10 THEN '8%-10%'
        WHEN c.loan_int_rate < 12 THEN '10%-12%'
        WHEN c.loan_int_rate < 15 THEN '12%-15%'
        ELSE '15%+'
    END AS pbi_interest_rate_band,

    CASE
        WHEN c.loan_int_rate IS NULL THEN 99
        WHEN c.loan_int_rate < 8 THEN 1
        WHEN c.loan_int_rate < 10 THEN 2
        WHEN c.loan_int_rate < 12 THEN 3
        WHEN c.loan_int_rate < 15 THEN 4
        ELSE 5
    END AS pbi_interest_rate_band_sort,

    CASE
        WHEN c.loan_int_rate IS NULL
            THEN 'Interest Rate Missing'
        ELSE 'Interest Rate Available'
    END AS pbi_interest_rate_data_status,


    -- ========================================================
    -- 2.10 LTI BAND
    -- EDA file 07
    -- ========================================================

    CASE
        WHEN c.loan_to_income_ratio IS NULL THEN 'Unknown'
        WHEN c.loan_to_income_ratio < 0.10 THEN '<0.10'
        WHEN c.loan_to_income_ratio < 0.20 THEN '0.10-0.20'
        WHEN c.loan_to_income_ratio < 0.30 THEN '0.20-0.30'
        ELSE '0.30+'
    END AS pbi_lti_band,

    CASE
        WHEN c.loan_to_income_ratio IS NULL THEN 99
        WHEN c.loan_to_income_ratio < 0.10 THEN 1
        WHEN c.loan_to_income_ratio < 0.20 THEN 2
        WHEN c.loan_to_income_ratio < 0.30 THEN 3
        ELSE 4
    END AS pbi_lti_band_sort,


    -- ========================================================
    -- 2.11 DTI BAND
    -- EDA file 07
    -- ========================================================

    CASE
        WHEN c.debt_to_income_ratio IS NULL THEN 'Unknown'
        WHEN c.debt_to_income_ratio < 0.25 THEN '<0.25'
        WHEN c.debt_to_income_ratio < 0.35 THEN '0.25-0.35'
        WHEN c.debt_to_income_ratio < 0.45 THEN '0.35-0.45'
        ELSE '0.45+'
    END AS pbi_dti_band,

    CASE
        WHEN c.debt_to_income_ratio IS NULL THEN 99
        WHEN c.debt_to_income_ratio < 0.25 THEN 1
        WHEN c.debt_to_income_ratio < 0.35 THEN 2
        WHEN c.debt_to_income_ratio < 0.45 THEN 3
        ELSE 4
    END AS pbi_dti_band_sort,


    -- ========================================================
    -- 2.12 AFFORDABILITY GROUP
    -- EDA file 07
    --
    -- IMPORTANT:
    -- These are analytical labels, not loan approval rules.
    -- ========================================================

    CASE
        WHEN c.loan_to_income_ratio IS NULL
          OR c.debt_to_income_ratio IS NULL
            THEN 'Affordability Unknown'

        WHEN c.loan_to_income_ratio >= 0.30
         AND c.debt_to_income_ratio >= 0.45
            THEN 'Elevated LTI + Elevated DTI'

        WHEN c.loan_to_income_ratio >= 0.30
            THEN 'Elevated LTI Only'

        WHEN c.debt_to_income_ratio >= 0.45
            THEN 'Elevated DTI Only'

        ELSE 'Neither Elevated'
    END AS pbi_affordability_group,

    CASE
        WHEN c.loan_to_income_ratio IS NULL
          OR c.debt_to_income_ratio IS NULL THEN 99

        WHEN c.loan_to_income_ratio >= 0.30
         AND c.debt_to_income_ratio >= 0.45 THEN 4

        WHEN c.loan_to_income_ratio >= 0.30 THEN 3

        WHEN c.debt_to_income_ratio >= 0.45 THEN 2

        ELSE 1
    END AS pbi_affordability_group_sort,


    -- ========================================================
    -- 2.13 CREDIT UTILIZATION BAND
    -- Supporting field. EDA file 07 found weak separation.
    -- ========================================================

    CASE
        WHEN c.credit_utilization_ratio IS NULL THEN 'Unknown'
        WHEN c.credit_utilization_ratio < 0.30 THEN '<0.30'
        WHEN c.credit_utilization_ratio < 0.50 THEN '0.30-0.50'
        WHEN c.credit_utilization_ratio < 0.70 THEN '0.50-0.70'
        ELSE '0.70+'
    END AS pbi_utilization_band,

    CASE
        WHEN c.credit_utilization_ratio IS NULL THEN 99
        WHEN c.credit_utilization_ratio < 0.30 THEN 1
        WHEN c.credit_utilization_ratio < 0.50 THEN 2
        WHEN c.credit_utilization_ratio < 0.70 THEN 3
        ELSE 4
    END AS pbi_utilization_band_sort,


    -- ========================================================
    -- 2.14 CREDIT HISTORY LENGTH BAND
    -- Supporting field. EDA file 08 found weak separation.
    -- ========================================================

    CASE
        WHEN c.cb_person_cred_hist_length IS NULL THEN 'Unknown'
        WHEN c.cb_person_cred_hist_length < 3 THEN '<3 years'
        WHEN c.cb_person_cred_hist_length <= 5 THEN '3-5 years'
        WHEN c.cb_person_cred_hist_length <= 10 THEN '6-10 years'
        ELSE '10+ years'
    END AS pbi_credit_history_band,

    CASE
        WHEN c.cb_person_cred_hist_length IS NULL THEN 99
        WHEN c.cb_person_cred_hist_length < 3 THEN 1
        WHEN c.cb_person_cred_hist_length <= 5 THEN 2
        WHEN c.cb_person_cred_hist_length <= 10 THEN 3
        ELSE 4
    END AS pbi_credit_history_band_sort,


    -- ========================================================
    -- 2.15 OPEN ACCOUNT BAND
    -- Supporting field. EDA file 08 found very weak separation.
    -- ========================================================

    CASE
        WHEN c.open_accounts IS NULL THEN 'Unknown'
        WHEN c.open_accounts < 5 THEN '<5'
        WHEN c.open_accounts < 10 THEN '5-9'
        WHEN c.open_accounts < 15 THEN '10-14'
        ELSE '15+'
    END AS pbi_open_account_band,

    CASE
        WHEN c.open_accounts IS NULL THEN 99
        WHEN c.open_accounts < 5 THEN 1
        WHEN c.open_accounts < 10 THEN 2
        WHEN c.open_accounts < 15 THEN 3
        ELSE 4
    END AS pbi_open_account_band_sort,


    -- ========================================================
    -- 2.16 PAST DELINQUENCY BAND
    -- Supporting field. EDA file 08 found very weak separation.
    -- ========================================================

    CASE
        WHEN c.past_delinquencies IS NULL THEN 'Unknown'
        WHEN c.past_delinquencies = 0 THEN '0'
        WHEN c.past_delinquencies = 1 THEN '1'
        ELSE '2+'
    END AS pbi_delinquency_band,

    CASE
        WHEN c.past_delinquencies IS NULL THEN 99
        WHEN c.past_delinquencies = 0 THEN 1
        WHEN c.past_delinquencies = 1 THEN 2
        ELSE 3
    END AS pbi_delinquency_band_sort,


    -- ========================================================
    -- 2.17 PREVIOUS DEFAULT LABEL
    -- ========================================================

    CASE
        WHEN TRIM(c.cb_person_default_on_file) = 'Y'
            THEN 'Previous Default'
        WHEN TRIM(c.cb_person_default_on_file) = 'N'
            THEN 'No Previous Default'
        ELSE 'Unknown'
    END AS pbi_previous_default_label,

    CASE
        WHEN TRIM(c.cb_person_default_on_file) = 'N' THEN 1
        WHEN TRIM(c.cb_person_default_on_file) = 'Y' THEN 2
        ELSE 99
    END AS pbi_previous_default_sort,


    -- ========================================================
    -- 2.18 INDIVIDUAL ANALYTICAL FLAGS
    -- These flags reproduce strong EDA conditions.
    -- ========================================================

    CASE
        WHEN TRIM(c.loan_grade) IN ('D', 'E', 'F', 'G')
            THEN 1 ELSE 0
    END AS pbi_flag_grade_dg,

    CASE
        WHEN c.loan_to_income_ratio >= 0.30
            THEN 1 ELSE 0
    END AS pbi_flag_lti_elevated,

    CASE
        WHEN c.debt_to_income_ratio >= 0.45
            THEN 1 ELSE 0
    END AS pbi_flag_dti_elevated,

    CASE
        WHEN c.loan_to_income_ratio >= 0.30
          OR c.debt_to_income_ratio >= 0.45
            THEN 1 ELSE 0
    END AS pbi_flag_affordability_elevated,

    CASE
        WHEN TRIM(c.person_home_ownership) = 'RENT'
            THEN 1 ELSE 0
    END AS pbi_flag_rent,

    CASE
        WHEN TRIM(c.cb_person_default_on_file) = 'Y'
            THEN 1 ELSE 0
    END AS pbi_flag_previous_default,

    CASE
        WHEN c.person_income < 50000
            THEN 1 ELSE 0
    END AS pbi_flag_income_below_50k,

    CASE
        WHEN c.person_emp_length < 4
            THEN 1 ELSE 0
    END AS pbi_flag_employment_below_4_years,


    -- ========================================================
    -- 2.19 MULTI-FACTOR CANDIDATE FLAGS
    -- EDA file 09
    --
    -- IMPORTANT:
    -- A loan may have multiple flags = 1 at the same time.
    -- These are overlapping observed-risk conditions.
    -- ========================================================

    CASE
        WHEN c.loan_to_income_ratio >= 0.30
         AND c.debt_to_income_ratio >= 0.45
            THEN 1 ELSE 0
    END AS pbi_flag_high_lti_high_dti,

    CASE
        WHEN TRIM(c.loan_grade) IN ('D', 'E', 'F', 'G')
         AND c.loan_to_income_ratio >= 0.30
            THEN 1 ELSE 0
    END AS pbi_flag_grade_dg_high_lti,

    CASE
        WHEN TRIM(c.loan_grade) IN ('D', 'E', 'F', 'G')
         AND c.debt_to_income_ratio >= 0.45
            THEN 1 ELSE 0
    END AS pbi_flag_grade_dg_high_dti,

    CASE
        WHEN c.person_income < 50000
         AND TRIM(c.person_home_ownership) = 'RENT'
            THEN 1 ELSE 0
    END AS pbi_flag_low_income_rent,

    CASE
        WHEN c.person_income < 50000
         AND c.person_emp_length < 4
            THEN 1 ELSE 0
    END AS pbi_flag_low_income_short_employment,

    CASE
        WHEN TRIM(c.cb_person_default_on_file) = 'Y'
         AND TRIM(c.person_home_ownership) = 'RENT'
            THEN 1 ELSE 0
    END AS pbi_flag_previous_default_rent,

    CASE
        WHEN TRIM(c.cb_person_default_on_file) = 'Y'
         AND (
                c.loan_to_income_ratio >= 0.30
             OR c.debt_to_income_ratio >= 0.45
         )
            THEN 1 ELSE 0
    END AS pbi_flag_previous_default_affordability,

    CASE
        WHEN TRIM(c.cb_person_default_on_file) = 'Y'
         AND TRIM(c.person_home_ownership) = 'RENT'
         AND (
                c.loan_to_income_ratio >= 0.30
             OR c.debt_to_income_ratio >= 0.45
         )
            THEN 1 ELSE 0
    END AS pbi_flag_previous_default_rent_affordability,


    -- ========================================================
    -- 2.20 LOWER OBSERVED RISK INTERSECTION
    -- EDA file 09
    --
    -- Descriptive only. Not automatic approval.
    -- ========================================================

    CASE
        WHEN TRIM(c.loan_grade) IN ('A', 'B')
         AND c.loan_to_income_ratio < 0.20
         AND c.debt_to_income_ratio < 0.35
         AND TRIM(c.cb_person_default_on_file) = 'N'
            THEN 1 ELSE 0
    END AS pbi_flag_lower_observed_risk

FROM credit_risk_clean AS c;


-- ============================================================
-- 3. GEOGRAPHY DIMENSION
--    vw_geography
-- ============================================================
--
-- PURPOSE
-- One row per Country-State-City combination.
--
-- POWER BI RELATIONSHIP
-- vw_geography[pbi_geo_key]  1
--             ↓
-- vw_credit_risk_detail[pbi_geo_key]  *
--
-- Geography was a weak risk driver in EDA, but is useful for:
-- - portfolio distribution
-- - map visuals
-- - Country > State > City drill-down
-- ============================================================

CREATE VIEW vw_geography AS

SELECT
    CONCAT_WS(
        '|',
        COALESCE(NULLIF(TRIM(country), ''), 'Unknown'),
        COALESCE(NULLIF(TRIM(state), ''), 'Unknown'),
        COALESCE(NULLIF(TRIM(city), ''), 'Unknown')
    ) AS pbi_geo_key,

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

    ROUND(
        AVG(city_latitude),
        6
    ) AS city_latitude,

    ROUND(
        AVG(city_longitude),
        6
    ) AS city_longitude

FROM credit_risk_clean

GROUP BY
    COALESCE(NULLIF(TRIM(country), ''), 'Unknown'),
    COALESCE(NULLIF(TRIM(state), ''), 'Unknown'),
    COALESCE(NULLIF(TRIM(city), ''), 'Unknown');


-- ============================================================
-- 4. CANDIDATE SEGMENT MEMBERSHIP VIEW
--    vw_segment_candidates
-- ============================================================
--
-- PURPOSE
-- Long-format membership table for overlapping EDA-supported
-- candidate segments.
--
-- GRAIN
-- 1 row = 1 loan membership in 1 candidate segment.
--
-- IMPORTANT
-- The same client_ID can appear in multiple segment rows because
-- candidate segments overlap by design.
--
-- POWER BI RELATIONSHIP
-- vw_credit_risk_detail[client_ID]  1
--             ↓
-- vw_segment_candidates[client_ID] *
--
-- Keep cross-filter direction SINGLE from detail -> candidates.
--
-- Recommended measures for this table:
-- Segment Loans            = COUNTROWS(vw_segment_candidates)
-- Segment Default Loans    = SUM(vw_segment_candidates[default_count])
-- Segment Default Rate     = DIVIDE([Segment Default Loans],[Segment Loans])
-- Segment Exposure         = SUM(vw_segment_candidates[loan_exposure])
-- Segment Default Exposure = SUM(vw_segment_candidates[default_exposure])
--
-- Do not sum all segments together because a loan can belong to
-- more than one candidate segment.
-- ============================================================

CREATE VIEW vw_segment_candidates AS

SELECT
    1 AS segment_sort,
    'Loan + Affordability' AS segment_family,
    'Observed Risk Concentration' AS segment_type,
    'Grade D-G AND LTI >= 0.30' AS segment_name,
    d.client_ID,
    d.loan_status,
    d.pbi_loan_outcome,
    1 AS loan_count,
    d.pbi_default_count AS default_count,
    d.loan_amnt AS loan_exposure,
    d.pbi_default_exposure_amount AS default_exposure
FROM vw_credit_risk_detail AS d
WHERE d.pbi_flag_grade_dg_high_lti = 1

UNION ALL

SELECT
    2,
    'Credit + Housing + Affordability',
    'Observed Risk Concentration',
    'Previous Default = Y AND RENT AND Affordability Elevated',
    d.client_ID,
    d.loan_status,
    d.pbi_loan_outcome,
    1,
    d.pbi_default_count,
    d.loan_amnt,
    d.pbi_default_exposure_amount
FROM vw_credit_risk_detail AS d
WHERE d.pbi_flag_previous_default_rent_affordability = 1

UNION ALL

SELECT
    3,
    'Loan + Affordability',
    'Observed Risk Concentration',
    'Grade D-G AND DTI >= 0.45',
    d.client_ID,
    d.loan_status,
    d.pbi_loan_outcome,
    1,
    d.pbi_default_count,
    d.loan_amnt,
    d.pbi_default_exposure_amount
FROM vw_credit_risk_detail AS d
WHERE d.pbi_flag_grade_dg_high_dti = 1

UNION ALL

SELECT
    4,
    'Affordability',
    'Observed Risk Concentration',
    'LTI >= 0.30 AND DTI >= 0.45',
    d.client_ID,
    d.loan_status,
    d.pbi_loan_outcome,
    1,
    d.pbi_default_count,
    d.loan_amnt,
    d.pbi_default_exposure_amount
FROM vw_credit_risk_detail AS d
WHERE d.pbi_flag_high_lti_high_dti = 1

UNION ALL

SELECT
    5,
    'Credit + Affordability',
    'Observed Risk Concentration',
    'Previous Default = Y AND Affordability Elevated',
    d.client_ID,
    d.loan_status,
    d.pbi_loan_outcome,
    1,
    d.pbi_default_count,
    d.loan_amnt,
    d.pbi_default_exposure_amount
FROM vw_credit_risk_detail AS d
WHERE d.pbi_flag_previous_default_affordability = 1

UNION ALL

SELECT
    6,
    'Credit + Stability',
    'Observed Risk Concentration',
    'Previous Default = Y AND RENT',
    d.client_ID,
    d.loan_status,
    d.pbi_loan_outcome,
    1,
    d.pbi_default_count,
    d.loan_amnt,
    d.pbi_default_exposure_amount
FROM vw_credit_risk_detail AS d
WHERE d.pbi_flag_previous_default_rent = 1

UNION ALL

SELECT
    7,
    'Borrower Stability',
    'Observed Risk Concentration',
    'Income <50K AND RENT',
    d.client_ID,
    d.loan_status,
    d.pbi_loan_outcome,
    1,
    d.pbi_default_count,
    d.loan_amnt,
    d.pbi_default_exposure_amount
FROM vw_credit_risk_detail AS d
WHERE d.pbi_flag_low_income_rent = 1

UNION ALL

SELECT
    8,
    'Borrower Stability',
    'Observed Risk Concentration',
    'Income <50K AND Employment <4 Years',
    d.client_ID,
    d.loan_status,
    d.pbi_loan_outcome,
    1,
    d.pbi_default_count,
    d.loan_amnt,
    d.pbi_default_exposure_amount
FROM vw_credit_risk_detail AS d
WHERE d.pbi_flag_low_income_short_employment = 1

UNION ALL

SELECT
    9,
    'Portfolio Quality',
    'Lower Observed Risk',
    'Grade A-B AND LTI <0.20 AND DTI <0.35 AND Previous Default = N',
    d.client_ID,
    d.loan_status,
    d.pbi_loan_outcome,
    1,
    d.pbi_default_count,
    d.loan_amnt,
    d.pbi_default_exposure_amount
FROM vw_credit_risk_detail AS d
WHERE d.pbi_flag_lower_observed_risk = 1;


-- ============================================================
-- 5. POWER BI QA VIEW
--    vw_powerbi_qa
-- ============================================================
--
-- PURPOSE
-- Reconciliation table. Not intended as a dashboard fact table.
--
-- Use this view to verify Power BI measures after loading the model.
--
-- Expected baseline:
-- Total Loans        32,581
-- Distinct Clients   32,581
-- Default Loans       7,108
-- Default Rate        21.82%
-- Loan Exposure      312,431,300
-- Default Exposure    77,125,375
-- Interest coverage   90.44%
-- Geography coverage 100%
-- ============================================================

CREATE VIEW vw_powerbi_qa AS

SELECT
    COUNT(*) AS total_loans,

    COUNT(
        DISTINCT client_ID
    ) AS distinct_clients,

    SUM(
        CASE
            WHEN loan_status = 0 THEN 1
            ELSE 0
        END
    ) AS non_default_loans,

    SUM(
        CASE
            WHEN loan_status = 1 THEN 1
            ELSE 0
        END
    ) AS default_loans,

    ROUND(
        100.0 * AVG(
            CASE
                WHEN loan_status = 1 THEN 1.0
                ELSE 0.0
            END
        ),
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
    ) AS default_exposure,

    ROUND(
        AVG(loan_amnt),
        2
    ) AS average_loan_amount,

    ROUND(
        AVG(loan_int_rate),
        2
    ) AS average_interest_rate,

    COUNT(loan_int_rate)
        AS valid_interest_rate_loans,

    ROUND(
        100.0 * COUNT(loan_int_rate)
        / NULLIF(COUNT(*), 0),
        2
    ) AS interest_rate_coverage_pct,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN NULLIF(TRIM(country), '') IS NOT NULL
                 AND NULLIF(TRIM(state), '') IS NOT NULL
                 AND NULLIF(TRIM(city), '') IS NOT NULL
                THEN 1
                ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS complete_geography_coverage_pct,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN city_latitude IS NOT NULL
                 AND city_longitude IS NOT NULL
                THEN 1
                ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS coordinate_coverage_pct,

    CASE
        WHEN COUNT(*) = COUNT(DISTINCT client_ID)
            THEN 'PASS - One row per client/loan'
        ELSE 'FAIL - Duplicate client_ID detected'
    END AS grain_check_status

FROM vw_credit_risk_detail;


-- ============================================================
-- 6. POST-CREATION VALIDATION
-- ============================================================
-- Run these queries after creating the views.
-- They do not create additional tables.
-- ============================================================


-- ------------------------------------------------------------
-- 6.1 List the Power BI views.
-- ------------------------------------------------------------

SELECT
    TABLE_NAME,
    TABLE_TYPE
FROM information_schema.tables
WHERE TABLE_SCHEMA = 'risk_credit_analytics'
  AND TABLE_NAME IN (
        'vw_credit_risk_detail',
        'vw_geography',
        'vw_segment_candidates',
        'vw_powerbi_qa'
  )
ORDER BY TABLE_NAME;


-- ------------------------------------------------------------
-- 6.2 Main QA baseline.
-- EXPECTED:
-- total_loans       = 32581
-- distinct_clients  = 32581
-- default_loans     = 7108
-- default_rate_pct  = 21.82
-- loan_exposure     = 312431300.00
-- default_exposure  = 77125375.00
-- ------------------------------------------------------------

SELECT *
FROM vw_powerbi_qa;


-- ------------------------------------------------------------
-- 6.3 Detail-view grain validation.
-- EXPECTED:
-- detail_rows      = 32581
-- distinct_clients = 32581
-- duplicate_rows   = 0
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS detail_rows,
    COUNT(DISTINCT client_ID) AS distinct_clients,
    COUNT(*) - COUNT(DISTINCT client_ID) AS duplicate_rows
FROM vw_credit_risk_detail;


-- ------------------------------------------------------------
-- 6.4 Geography dimension validation.
-- EXPECTED:
-- geography_rows = 18
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS geography_rows,
    COUNT(DISTINCT pbi_geo_key) AS distinct_geo_keys
FROM vw_geography;


-- ------------------------------------------------------------
-- 6.5 Candidate segment reconciliation.
--
-- EXPECTED EDA RESULTS FROM FILE 09:
--
-- Grade D-G AND LTI >=0.30
-- loan_count = 892
-- default_count = 736
-- default_rate = 82.51%
-- default_exposure = 12,957,250
--
-- Previous Default = Y AND RENT AND Affordability Elevated
-- loan_count = 833
-- default_count = 645
-- default_rate = 77.43%
-- default_exposure = 9,321,025
--
-- Grade D-G AND DTI >=0.45
-- loan_count = 1,281
-- default_count = 930
-- default_rate = 72.60%
-- default_exposure = 15,301,325
--
-- LTI >=0.30 AND DTI >=0.45
-- loan_count = 3,453
-- default_count = 2,367
-- default_rate = 68.55%
-- default_exposure = 36,040,850
--
-- Income <50K AND RENT
-- loan_count = 8,657
-- default_count = 3,639
-- default_rate = 42.04%
-- default_exposure = 31,593,325
--
-- Lower Observed Risk
-- loan_count = 11,234
-- default_count = 621
-- default_rate = 5.53%
-- default_exposure = 3,242,550
-- ------------------------------------------------------------

SELECT
    segment_sort,
    segment_family,
    segment_type,
    segment_name,

    COUNT(*) AS loan_count,

    SUM(default_count) AS default_count,

    ROUND(
        100.0 * SUM(default_count)
        / NULLIF(COUNT(*), 0),
        2
    ) AS default_rate_pct,

    ROUND(
        SUM(loan_exposure),
        2
    ) AS loan_exposure,

    ROUND(
        SUM(default_exposure),
        2
    ) AS default_exposure

FROM vw_segment_candidates

GROUP BY
    segment_sort,
    segment_family,
    segment_type,
    segment_name

ORDER BY segment_sort;


-- ============================================================
-- 7. POWER BI MODEL GUIDANCE
-- ============================================================
--
-- IMPORT INTO POWER BI
--
-- 1. vw_credit_risk_detail
--    Main Fact View.
--
-- 2. vw_geography
--    Geography dimension.
--
-- 3. vw_segment_candidates
--    Overlapping candidate-segment membership table.
--
-- 4. vw_powerbi_qa
--    QA only. Keep hidden or do not load into report visuals.
--
--
-- RELATIONSHIPS
--
-- vw_geography[pbi_geo_key]
--      1  ->  *
-- vw_credit_risk_detail[pbi_geo_key]
--
-- vw_credit_risk_detail[client_ID]
--      1  ->  *
-- vw_segment_candidates[client_ID]
--
-- Keep relationship filter direction SINGLE.
--
--
-- SORT-BY-COLUMN SETTINGS IN POWER BI
--
-- pbi_age_band
--   sort by pbi_age_band_sort
--
-- pbi_income_band
--   sort by pbi_income_band_sort
--
-- pbi_income_group_3
--   sort by pbi_income_group_3_sort
--
-- pbi_employment_length_band
--   sort by pbi_employment_length_band_sort
--
-- loan_grade
--   sort by pbi_loan_grade_sort
--
-- pbi_loan_amount_band
--   sort by pbi_loan_amount_band_sort
--
-- pbi_interest_rate_band
--   sort by pbi_interest_rate_band_sort
--
-- pbi_lti_band
--   sort by pbi_lti_band_sort
--
-- pbi_dti_band
--   sort by pbi_dti_band_sort
--
-- pbi_affordability_group
--   sort by pbi_affordability_group_sort
--
-- pbi_credit_history_band
--   sort by pbi_credit_history_band_sort
--
-- pbi_utilization_band
--   sort by pbi_utilization_band_sort
--
--
-- CORE DAX MEASURES TO CREATE AFTER IMPORT
--
-- Total Loans
-- Default Loans
-- Non-default Loans
-- Default Rate
-- Loan Exposure
-- Default Exposure
-- Default Exposure Rate
-- Average Loan Amount
-- Average Interest Rate
--
-- SEGMENT-TABLE DAX
--
-- Segment Loans
-- Segment Default Loans
-- Segment Default Rate
-- Segment Loan Exposure
-- Segment Default Exposure
-- Segment Portfolio Share
-- Segment Default Exposure Share
--
--
-- DO NOT CREATE IN SQL
--
-- Dynamic KPI totals
-- Dynamic portfolio shares under slicers
-- Dynamic rankings under report filters
-- Visual titles
-- Tooltip text
-- Final lending approval/rejection rules
--
-- ============================================================
-- END OF 10_POWERBI_VIEWS.SQL
-- ============================================================
