-- ============================================================
-- RISK CREDIT ANALYTICS PROJECT
-- FILE: 02_data_cleaning.sql
-- PURPOSE: Build a typed, analysis-ready table from credit_risk_raw.
-- MYSQL VERSION: 8.0+
-- ============================================================
-- This script never updates or deletes rows from credit_risk_raw.
-- It rebuilds only the derived table credit_risk_clean.
-- Run section 1, then section 2, then review section 3 results.
-- ============================================================

USE risk_credit_analytics;

-- ============================================================
-- 1. CREATE THE CLEAN TABLE
-- ============================================================

DROP TABLE IF EXISTS credit_risk_clean;

CREATE TABLE credit_risk_clean (
    client_ID VARCHAR(50) NOT NULL,
    person_age SMALLINT UNSIGNED NULL,
    person_income DECIMAL(18,2) NOT NULL,
    person_home_ownership VARCHAR(50) NOT NULL,
    person_emp_length DECIMAL(8,2) NULL,
    loan_intent VARCHAR(50) NOT NULL,
    loan_grade VARCHAR(10) NOT NULL,
    loan_amnt DECIMAL(18,2) NOT NULL,
    loan_int_rate DECIMAL(8,4) NULL,
    loan_status TINYINT UNSIGNED NOT NULL,
    source_loan_percent_income DECIMAL(14,9) NOT NULL,
    loan_percent_income DECIMAL(14,9) NOT NULL,
    cb_person_default_on_file VARCHAR(10) NOT NULL,
    cb_person_cred_hist_length DECIMAL(8,2) NOT NULL,
    gender VARCHAR(20) NOT NULL,
    marital_status VARCHAR(30) NOT NULL,
    education_level VARCHAR(50) NOT NULL,
    country VARCHAR(50) NOT NULL,
    state VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL,
    city_latitude DECIMAL(9,6) NOT NULL,
    city_longitude DECIMAL(10,6) NOT NULL,
    employment_type VARCHAR(50) NOT NULL,
    loan_term_months SMALLINT UNSIGNED NOT NULL,
    loan_to_income_ratio DECIMAL(14,9) NOT NULL,
    other_debt DECIMAL(20,10) NOT NULL,
    debt_to_income_ratio DECIMAL(14,9) NOT NULL,
    open_accounts SMALLINT UNSIGNED NOT NULL,
    credit_utilization_ratio DECIMAL(14,9) NOT NULL,
    past_delinquencies SMALLINT UNSIGNED NOT NULL,

    is_age_invalid TINYINT UNSIGNED NOT NULL,
    is_emp_length_missing TINYINT UNSIGNED NOT NULL,
    is_emp_length_invalid TINYINT UNSIGNED NOT NULL,
    is_loan_int_rate_missing TINYINT UNSIGNED NOT NULL,
    is_loan_percent_income_mismatch TINYINT UNSIGNED NOT NULL,
    is_loan_percent_income_material_mismatch TINYINT UNSIGNED NOT NULL,
    is_high_dti TINYINT UNSIGNED NOT NULL,

    PRIMARY KEY (client_ID),
    CONSTRAINT chk_clean_age
        CHECK (person_age IS NULL OR person_age BETWEEN 18 AND 100),
    CONSTRAINT chk_clean_income
        CHECK (person_income > 0),
    CONSTRAINT chk_clean_emp_length
        CHECK (person_emp_length IS NULL OR person_emp_length >= 0),
    CONSTRAINT chk_clean_loan_amount
        CHECK (loan_amnt > 0),
    CONSTRAINT chk_clean_interest_rate
        CHECK (loan_int_rate IS NULL OR loan_int_rate >= 0),
    CONSTRAINT chk_clean_loan_status
        CHECK (loan_status IN (0, 1)),
    CONSTRAINT chk_clean_loan_percent_income
        CHECK (loan_percent_income >= 0),
    CONSTRAINT chk_clean_lti
        CHECK (loan_to_income_ratio >= 0),
    CONSTRAINT chk_clean_other_debt
        CHECK (other_debt >= 0),
    CONSTRAINT chk_clean_dti
        CHECK (debt_to_income_ratio >= 0),
    CONSTRAINT chk_clean_credit_utilization
        CHECK (credit_utilization_ratio BETWEEN 0 AND 1),
    CONSTRAINT chk_clean_latitude
        CHECK (city_latitude BETWEEN -90 AND 90),
    CONSTRAINT chk_clean_longitude
        CHECK (city_longitude BETWEEN -180 AND 180)
) ENGINE = InnoDB;

-- ============================================================
-- 2. LOAD CLEANED DATA
-- ============================================================

INSERT INTO credit_risk_clean (
    client_ID,
    person_age,
    person_income,
    person_home_ownership,
    person_emp_length,
    loan_intent,
    loan_grade,
    loan_amnt,
    loan_int_rate,
    loan_status,
    source_loan_percent_income,
    loan_percent_income,
    cb_person_default_on_file,
    cb_person_cred_hist_length,
    gender,
    marital_status,
    education_level,
    country,
    state,
    city,
    city_latitude,
    city_longitude,
    employment_type,
    loan_term_months,
    loan_to_income_ratio,
    other_debt,
    debt_to_income_ratio,
    open_accounts,
    credit_utilization_ratio,
    past_delinquencies,
    is_age_invalid,
    is_emp_length_missing,
    is_emp_length_invalid,
    is_loan_int_rate_missing,
    is_loan_percent_income_mismatch,
    is_loan_percent_income_material_mismatch,
    is_high_dti
)
SELECT
    NULLIF(TRIM(client_ID), '') AS client_ID,

    CASE
        WHEN age_num < 18 OR age_num > 100 THEN NULL
        ELSE age_num
    END AS person_age,

    income_num AS person_income,
    NULLIF(TRIM(person_home_ownership), '') AS person_home_ownership,

    CASE
        WHEN emp_length_num IS NULL THEN NULL
        WHEN emp_length_num < 0 OR emp_length_num > age_num THEN NULL
        ELSE emp_length_num
    END AS person_emp_length,

    NULLIF(TRIM(loan_intent), '') AS loan_intent,
    NULLIF(TRIM(loan_grade), '') AS loan_grade,
    loan_amnt_num AS loan_amnt,
    loan_int_rate_num AS loan_int_rate,
    loan_status_num AS loan_status,
    source_loan_pct_num AS source_loan_percent_income,

    ROUND(loan_amnt_num / NULLIF(income_num, 0), 2)
        AS loan_percent_income,

    NULLIF(TRIM(cb_person_default_on_file), '')
        AS cb_person_default_on_file,
    credit_history_num AS cb_person_cred_hist_length,
    NULLIF(TRIM(gender), '') AS gender,
    NULLIF(TRIM(marital_status), '') AS marital_status,
    NULLIF(TRIM(education_level), '') AS education_level,
    NULLIF(TRIM(country), '') AS country,
    NULLIF(TRIM(state), '') AS state,
    NULLIF(TRIM(city), '') AS city,
    latitude_num AS city_latitude,
    longitude_num AS city_longitude,
    NULLIF(TRIM(employment_type), '') AS employment_type,
    loan_term_num AS loan_term_months,

    ROUND(loan_amnt_num / NULLIF(income_num, 0), 9)
        AS loan_to_income_ratio,
    other_debt_num AS other_debt,
    ROUND(
        (loan_amnt_num + other_debt_num) / NULLIF(income_num, 0),
        9
    ) AS debt_to_income_ratio,

    open_accounts_num AS open_accounts,
    utilization_num AS credit_utilization_ratio,
    delinquencies_num AS past_delinquencies,

    CASE WHEN age_num < 18 OR age_num > 100 THEN 1 ELSE 0 END
        AS is_age_invalid,
    CASE WHEN emp_length_num IS NULL THEN 1 ELSE 0 END
        AS is_emp_length_missing,
    CASE WHEN emp_length_num IS NOT NULL
               AND (emp_length_num < 0 OR emp_length_num > age_num)
         THEN 1 ELSE 0 END AS is_emp_length_invalid,
    CASE WHEN loan_int_rate_num IS NULL THEN 1 ELSE 0 END
        AS is_loan_int_rate_missing,
    CASE WHEN ABS(
                   source_loan_pct_num
                   - ROUND(loan_amnt_num / NULLIF(income_num, 0), 2)
               ) >= 0.000001
         THEN 1 ELSE 0 END AS is_loan_percent_income_mismatch,
    CASE WHEN ABS(
                   source_loan_pct_num
                   - loan_amnt_num / NULLIF(income_num, 0)
               ) > 0.01
         THEN 1 ELSE 0 END AS is_loan_percent_income_material_mismatch,
    CASE WHEN (loan_amnt_num + other_debt_num) / NULLIF(income_num, 0) > 1
         THEN 1 ELSE 0 END AS is_high_dti
FROM (
    SELECT
        r.*,
        CAST(TRIM(person_age) AS DECIMAL(30,10)) AS age_num,
        CAST(TRIM(person_income) AS DECIMAL(30,10)) AS income_num,
        CAST(NULLIF(TRIM(person_emp_length), '') AS DECIMAL(30,10))
            AS emp_length_num,
        CAST(TRIM(loan_amnt) AS DECIMAL(30,10)) AS loan_amnt_num,
        CAST(NULLIF(TRIM(loan_int_rate), '') AS DECIMAL(30,10))
            AS loan_int_rate_num,
        CAST(TRIM(loan_status) AS UNSIGNED) AS loan_status_num,
        CAST(TRIM(loan_percent_income) AS DECIMAL(30,10))
            AS source_loan_pct_num,
        CAST(TRIM(cb_person_cred_hist_length) AS DECIMAL(30,10))
            AS credit_history_num,
        CAST(TRIM(city_latitude) AS DECIMAL(30,10)) AS latitude_num,
        CAST(TRIM(city_longitude) AS DECIMAL(30,10)) AS longitude_num,
        CAST(TRIM(loan_term_months) AS UNSIGNED) AS loan_term_num,
        CAST(TRIM(other_debt) AS DECIMAL(30,10)) AS other_debt_num,
        CAST(TRIM(open_accounts) AS UNSIGNED) AS open_accounts_num,
        CAST(TRIM(credit_utilization_ratio) AS DECIMAL(30,10))
            AS utilization_num,
        CAST(TRIM(past_delinquencies) AS UNSIGNED)
            AS delinquencies_num
    FROM credit_risk_raw AS r
) AS typed_source;

-- ============================================================
-- 3. POST-LOAD SMOKE CHECKS
-- ============================================================

-- 3.1 Row preservation: these counts must be equal.
SELECT
    (SELECT COUNT(*) FROM credit_risk_raw) AS raw_rows,
    (SELECT COUNT(*) FROM credit_risk_clean) AS clean_rows;

-- 3.2 Confirm clean key uniqueness and completeness.
SELECT
    COUNT(*) AS total_rows,
    COUNT(client_ID) AS populated_client_ids,
    COUNT(DISTINCT client_ID) AS distinct_client_ids
FROM credit_risk_clean;

-- 3.3 Reconcile cleaning flags with profiling evidence.
SELECT
    SUM(is_age_invalid) AS invalid_age_rows,
    SUM(is_emp_length_missing) AS missing_emp_length_rows,
    SUM(is_emp_length_invalid) AS invalid_emp_length_rows,
    SUM(is_loan_int_rate_missing) AS missing_interest_rate_rows,
    SUM(is_loan_percent_income_mismatch) AS loan_pct_mismatch_rows,
    SUM(is_loan_percent_income_material_mismatch)
        AS loan_pct_material_mismatch_rows,
    SUM(is_high_dti) AS high_dti_rows
FROM credit_risk_clean;

-- 3.4 Confirm expected NULL counts after cleaning.
SELECT
    SUM(person_age IS NULL) AS null_age_rows,
    SUM(person_emp_length IS NULL) AS null_emp_length_rows,
    SUM(loan_int_rate IS NULL) AS null_interest_rate_rows
FROM credit_risk_clean;

-- 3.5 Confirm canonical ratio formulas after cleaning.
SELECT
    SUM(
        loan_percent_income <>
        ROUND(
            CAST(loan_amnt AS DECIMAL(30,10))
            / NULLIF(CAST(person_income AS DECIMAL(30,10)), 0),
            2
        )
    ) AS invalid_loan_percent_income_rows,
    SUM(
        loan_to_income_ratio <>
        ROUND(
            CAST(loan_amnt AS DECIMAL(30,10))
            / NULLIF(CAST(person_income AS DECIMAL(30,10)), 0),
            9
        )
    ) AS invalid_lti_rows,
    SUM(
        debt_to_income_ratio <>
        ROUND(
            (
                CAST(loan_amnt AS DECIMAL(30,10))
                + CAST(other_debt AS DECIMAL(30,10))
            ) / NULLIF(CAST(person_income AS DECIMAL(30,10)), 0),
            9
        )
    ) AS invalid_dti_rows
FROM credit_risk_clean;

-- 3.6 Inspect the clean schema and a small sample.
DESCRIBE credit_risk_clean;

SELECT *
FROM credit_risk_clean
ORDER BY client_ID
LIMIT 10;
