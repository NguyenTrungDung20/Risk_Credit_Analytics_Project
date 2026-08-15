-- ============================================================
-- RISK CREDIT ANALYTICS PROJECT
-- FILE: 01_data_profiling.sql
-- PURPOSE: Profile credit_risk_raw before defining cleaning rules.
-- MYSQL VERSION: 8.0+
-- ============================================================
-- Run one numbered query at a time in MySQL Workbench.
-- This file is read-only: it does not change credit_risk_raw.
-- Raw columns were imported as VARCHAR, so numeric calculations use
-- guarded CAST expressions. Do not use MIN/MAX directly on raw text.
-- ============================================================

USE risk_credit_analytics;

-- ============================================================
-- 1. DATASET OVERVIEW
-- ============================================================

-- 1.1 Confirm that the expected database objects exist.
SHOW TABLES;

-- 1.2 Inspect raw column names, types, and nullability.
DESCRIBE credit_risk_raw;

-- 1.3 Confirm row count after import.
SELECT COUNT(*) AS total_rows
FROM credit_risk_raw;

-- 1.4 Inspect a small sample without changing source order or values.
SELECT *
FROM credit_risk_raw
LIMIT 10;

-- ============================================================
-- 2. GRAIN, CLIENT ID, AND DUPLICATES
-- ============================================================

-- 2.1 Compare row count with populated and distinct client IDs.
-- Do not conclude that one client equals one loan until 2.2 is reviewed.
SELECT
    COUNT(*) AS total_rows,
    COUNT(NULLIF(TRIM(client_ID), '')) AS populated_client_id_rows,
    COUNT(DISTINCT NULLIF(TRIM(client_ID), '')) AS distinct_client_ids,
    SUM(CASE WHEN client_ID IS NULL THEN 1 ELSE 0 END) AS null_client_ids,
    SUM(CASE WHEN client_ID IS NOT NULL AND TRIM(client_ID) = ''
             THEN 1 ELSE 0 END) AS blank_client_ids,
    COUNT(*) - COUNT(DISTINCT NULLIF(TRIM(client_ID), ''))
        AS rows_above_distinct_client_count
FROM credit_risk_raw;

-- 2.2 List client IDs that occur more than once.
-- A repeated ID may be a duplicate or a borrower with multiple loans.
SELECT
    client_ID,
    COUNT(*) AS row_count
FROM credit_risk_raw
WHERE NULLIF(TRIM(client_ID), '') IS NOT NULL
GROUP BY client_ID, HEX(client_ID)
HAVING COUNT(*) > 1
ORDER BY row_count DESC, client_ID;

-- 2.3 Show all records for repeated client IDs for grain inspection.
-- Compare loan amount, intent, rate, term, and status across each ID.
WITH duplicate_clients AS (
    SELECT client_ID
    FROM credit_risk_raw
    WHERE NULLIF(TRIM(client_ID), '') IS NOT NULL
    GROUP BY client_ID, HEX(client_ID)
    HAVING COUNT(*) > 1
)
SELECT r.*
FROM credit_risk_raw AS r
JOIN duplicate_clients AS d
  ON BINARY r.client_ID = BINARY d.client_ID
ORDER BY r.client_ID
LIMIT 200;

-- 2.4 Count byte-for-byte duplicate rows, including client_ID.
-- Case and surrounding spaces remain distinct because BINARY is used.
WITH exact_duplicate_groups AS (
    SELECT COUNT(*) AS group_size
    FROM credit_risk_raw
    GROUP BY
        BINARY client_ID,
        BINARY person_age,
        BINARY person_income,
        BINARY person_home_ownership,
        BINARY person_emp_length,
        BINARY loan_intent,
        BINARY loan_grade,
        BINARY loan_amnt,
        BINARY loan_int_rate,
        BINARY loan_status,
        BINARY loan_percent_income,
        BINARY cb_person_default_on_file,
        BINARY cb_person_cred_hist_length,
        BINARY gender,
        BINARY marital_status,
        BINARY education_level,
        BINARY country,
        BINARY state,
        BINARY city,
        BINARY city_latitude,
        BINARY city_longitude,
        BINARY employment_type,
        BINARY loan_term_months,
        BINARY loan_to_income_ratio,
        BINARY other_debt,
        BINARY debt_to_income_ratio,
        BINARY open_accounts,
        BINARY credit_utilization_ratio,
        BINARY past_delinquencies
    HAVING COUNT(*) > 1
)
SELECT
    COUNT(*) AS exact_duplicate_groups,
    COALESCE(SUM(group_size), 0) AS rows_in_duplicate_groups,
    COALESCE(SUM(group_size - 1), 0) AS exact_extra_rows
FROM exact_duplicate_groups;

-- 2.5 Find records that are identical on every field except client_ID.
-- These are review candidates, not rows to delete automatically.
SELECT
    MIN(person_age) AS person_age,
    MIN(person_income) AS person_income,
    MIN(loan_intent) AS loan_intent,
    MIN(loan_grade) AS loan_grade,
    MIN(loan_amnt) AS loan_amnt,
    MIN(loan_int_rate) AS loan_int_rate,
    MIN(loan_term_months) AS loan_term_months,
    COUNT(*) AS matching_rows,
    COUNT(DISTINCT HEX(client_ID)) AS distinct_client_ids,
    GROUP_CONCAT(DISTINCT client_ID ORDER BY client_ID SEPARATOR ', ')
        AS client_ids
FROM credit_risk_raw
GROUP BY
    BINARY person_age,
    BINARY person_income,
    BINARY person_home_ownership,
    BINARY person_emp_length,
    BINARY loan_intent,
    BINARY loan_grade,
    BINARY loan_amnt,
    BINARY loan_int_rate,
    BINARY loan_status,
    BINARY loan_percent_income,
    BINARY cb_person_default_on_file,
    BINARY cb_person_cred_hist_length,
    BINARY gender,
    BINARY marital_status,
    BINARY education_level,
    BINARY country,
    BINARY state,
    BINARY city,
    BINARY city_latitude,
    BINARY city_longitude,
    BINARY employment_type,
    BINARY loan_term_months,
    BINARY loan_to_income_ratio,
    BINARY other_debt,
    BINARY debt_to_income_ratio,
    BINARY open_accounts,
    BINARY credit_utilization_ratio,
    BINARY past_delinquencies
HAVING COUNT(DISTINCT HEX(client_ID)) > 1
ORDER BY matching_rows DESC
LIMIT 100;

-- ============================================================
-- 3. MISSING VALUE PROFILE
-- ============================================================

-- 3.1 Return one row per column and distinguish NULL, empty strings,
-- and strings containing only whitespace.
WITH all_column_values AS (
    SELECT 'client_ID' AS column_name, client_ID AS raw_value FROM credit_risk_raw
    UNION ALL SELECT 'person_age', person_age FROM credit_risk_raw
    UNION ALL SELECT 'person_income', person_income FROM credit_risk_raw
    UNION ALL SELECT 'person_home_ownership', person_home_ownership FROM credit_risk_raw
    UNION ALL SELECT 'person_emp_length', person_emp_length FROM credit_risk_raw
    UNION ALL SELECT 'loan_intent', loan_intent FROM credit_risk_raw
    UNION ALL SELECT 'loan_grade', loan_grade FROM credit_risk_raw
    UNION ALL SELECT 'loan_amnt', loan_amnt FROM credit_risk_raw
    UNION ALL SELECT 'loan_int_rate', loan_int_rate FROM credit_risk_raw
    UNION ALL SELECT 'loan_status', loan_status FROM credit_risk_raw
    UNION ALL SELECT 'loan_percent_income', loan_percent_income FROM credit_risk_raw
    UNION ALL SELECT 'cb_person_default_on_file', cb_person_default_on_file FROM credit_risk_raw
    UNION ALL SELECT 'cb_person_cred_hist_length', cb_person_cred_hist_length FROM credit_risk_raw
    UNION ALL SELECT 'gender', gender FROM credit_risk_raw
    UNION ALL SELECT 'marital_status', marital_status FROM credit_risk_raw
    UNION ALL SELECT 'education_level', education_level FROM credit_risk_raw
    UNION ALL SELECT 'country', country FROM credit_risk_raw
    UNION ALL SELECT 'state', state FROM credit_risk_raw
    UNION ALL SELECT 'city', city FROM credit_risk_raw
    UNION ALL SELECT 'city_latitude', city_latitude FROM credit_risk_raw
    UNION ALL SELECT 'city_longitude', city_longitude FROM credit_risk_raw
    UNION ALL SELECT 'employment_type', employment_type FROM credit_risk_raw
    UNION ALL SELECT 'loan_term_months', loan_term_months FROM credit_risk_raw
    UNION ALL SELECT 'loan_to_income_ratio', loan_to_income_ratio FROM credit_risk_raw
    UNION ALL SELECT 'other_debt', other_debt FROM credit_risk_raw
    UNION ALL SELECT 'debt_to_income_ratio', debt_to_income_ratio FROM credit_risk_raw
    UNION ALL SELECT 'open_accounts', open_accounts FROM credit_risk_raw
    UNION ALL SELECT 'credit_utilization_ratio', credit_utilization_ratio FROM credit_risk_raw
    UNION ALL SELECT 'past_delinquencies', past_delinquencies FROM credit_risk_raw
)
SELECT
    column_name,
    SUM(CASE WHEN raw_value IS NULL THEN 1 ELSE 0 END) AS null_count,
    SUM(CASE WHEN raw_value = '' THEN 1 ELSE 0 END) AS empty_string_count,
    SUM(CASE WHEN raw_value IS NOT NULL
              AND raw_value <> ''
              AND TRIM(raw_value) = '' THEN 1 ELSE 0 END)
        AS whitespace_only_count,
    SUM(CASE WHEN raw_value IS NULL OR TRIM(raw_value) = ''
             THEN 1 ELSE 0 END) AS missing_count,
    ROUND(
        100.0 * SUM(CASE WHEN raw_value IS NULL OR TRIM(raw_value) = ''
                         THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS missing_pct
FROM all_column_values
GROUP BY column_name
ORDER BY missing_count DESC, column_name;

-- ============================================================
-- 4. CATEGORICAL DOMAINS AND TARGET DISTRIBUTION
-- ============================================================

-- 4.1 Profile loan_status without assigning business meaning to its values.
-- The mapping of each value must be confirmed before calculating default rate.
SELECT
    loan_status AS raw_loan_status,
    HEX(loan_status) AS value_hex,
    COUNT(*) AS row_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_rows
FROM credit_risk_raw
GROUP BY loan_status, HEX(loan_status)
ORDER BY row_count DESC, raw_loan_status;

-- 4.2 Check class count and the size of the largest target class.
WITH target_counts AS (
    SELECT
        loan_status,
        COUNT(*) AS row_count
    FROM credit_risk_raw
    GROUP BY loan_status, HEX(loan_status)
)
SELECT
    COUNT(*) AS distinct_target_values_including_missing,
    SUM(row_count) AS total_rows,
    MAX(row_count) AS largest_class_rows,
    ROUND(100.0 * MAX(row_count) / SUM(row_count), 2)
        AS largest_class_pct
FROM target_counts;

-- 4.3 Profile important categorical fields in one consistent result grid.
-- HEX exposes case, hidden spaces, and byte-level differences.
WITH categorical_values AS (
    SELECT 'person_home_ownership' AS column_name,
           person_home_ownership AS raw_value FROM credit_risk_raw
    UNION ALL SELECT 'loan_intent', loan_intent FROM credit_risk_raw
    UNION ALL SELECT 'loan_grade', loan_grade FROM credit_risk_raw
    UNION ALL SELECT 'cb_person_default_on_file', cb_person_default_on_file FROM credit_risk_raw
    UNION ALL SELECT 'gender', gender FROM credit_risk_raw
    UNION ALL SELECT 'marital_status', marital_status FROM credit_risk_raw
    UNION ALL SELECT 'education_level', education_level FROM credit_risk_raw
    UNION ALL SELECT 'country', country FROM credit_risk_raw
    UNION ALL SELECT 'employment_type', employment_type FROM credit_risk_raw
)
SELECT
    column_name,
    CASE
        WHEN raw_value IS NULL THEN '<NULL>'
        WHEN raw_value = '' THEN '<EMPTY>'
        WHEN TRIM(raw_value) = '' THEN '<WHITESPACE>'
        ELSE CONCAT('>', raw_value, '<')
    END AS displayed_value,
    HEX(raw_value) AS value_hex,
    COUNT(*) AS row_count,
    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (PARTITION BY column_name),
        2
    ) AS pct_within_column
FROM categorical_values
GROUP BY column_name, raw_value, HEX(raw_value)
ORDER BY column_name, row_count DESC, displayed_value;

-- 4.4 Measure geographic cardinality before any Power BI model design.
SELECT
    COUNT(DISTINCT NULLIF(TRIM(country), '')) AS distinct_countries,
    COUNT(DISTINCT NULLIF(TRIM(state), '')) AS distinct_states,
    COUNT(DISTINCT NULLIF(TRIM(city), '')) AS distinct_cities,
    COUNT(DISTINCT
        NULLIF(TRIM(country), ''),
        NULLIF(TRIM(state), ''),
        NULLIF(TRIM(city), '')
    ) AS distinct_complete_geo_combinations
FROM credit_risk_raw;

-- ============================================================
-- 5. NUMERIC TYPE READINESS AND DISTRIBUTIONS
-- ============================================================

-- 5.1 Validate numeric text, then calculate MIN, MAX, AVG, and STDDEV.
-- Signed patterns are intentional: negative values must remain numeric so
-- section 6 can flag them instead of silently turning them into NULL.
WITH numeric_values AS (
    SELECT 'person_age' AS column_name, person_age AS raw_value,
           CASE WHEN TRIM(person_age) REGEXP '^[+-]?[0-9]+$'
                THEN CAST(TRIM(person_age) AS DECIMAL(30,10)) END AS numeric_value
    FROM credit_risk_raw
    UNION ALL
    SELECT 'person_income', person_income,
           CASE WHEN TRIM(person_income) REGEXP '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
                THEN CAST(TRIM(person_income) AS DECIMAL(30,10)) END
    FROM credit_risk_raw
    UNION ALL
    SELECT 'person_emp_length', person_emp_length,
           CASE WHEN TRIM(person_emp_length) REGEXP '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
                THEN CAST(TRIM(person_emp_length) AS DECIMAL(30,10)) END
    FROM credit_risk_raw
    UNION ALL
    SELECT 'loan_amnt', loan_amnt,
           CASE WHEN TRIM(loan_amnt) REGEXP '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
                THEN CAST(TRIM(loan_amnt) AS DECIMAL(30,10)) END
    FROM credit_risk_raw
    UNION ALL
    SELECT 'loan_int_rate', loan_int_rate,
           CASE WHEN TRIM(loan_int_rate) REGEXP '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
                THEN CAST(TRIM(loan_int_rate) AS DECIMAL(30,10)) END
    FROM credit_risk_raw
    UNION ALL
    SELECT 'loan_percent_income', loan_percent_income,
           CASE WHEN TRIM(loan_percent_income) REGEXP '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
                THEN CAST(TRIM(loan_percent_income) AS DECIMAL(30,10)) END
    FROM credit_risk_raw
    UNION ALL
    SELECT 'cb_person_cred_hist_length', cb_person_cred_hist_length,
           CASE WHEN TRIM(cb_person_cred_hist_length) REGEXP '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
                THEN CAST(TRIM(cb_person_cred_hist_length) AS DECIMAL(30,10)) END
    FROM credit_risk_raw
    UNION ALL
    SELECT 'city_latitude', city_latitude,
           CASE WHEN TRIM(city_latitude) REGEXP '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
                THEN CAST(TRIM(city_latitude) AS DECIMAL(30,10)) END
    FROM credit_risk_raw
    UNION ALL
    SELECT 'city_longitude', city_longitude,
           CASE WHEN TRIM(city_longitude) REGEXP '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
                THEN CAST(TRIM(city_longitude) AS DECIMAL(30,10)) END
    FROM credit_risk_raw
    UNION ALL
    SELECT 'loan_term_months', loan_term_months,
           CASE WHEN TRIM(loan_term_months) REGEXP '^[+-]?[0-9]+$'
                THEN CAST(TRIM(loan_term_months) AS DECIMAL(30,10)) END
    FROM credit_risk_raw
    UNION ALL
    SELECT 'loan_to_income_ratio', loan_to_income_ratio,
           CASE WHEN TRIM(loan_to_income_ratio) REGEXP '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
                THEN CAST(TRIM(loan_to_income_ratio) AS DECIMAL(30,10)) END
    FROM credit_risk_raw
    UNION ALL
    SELECT 'other_debt', other_debt,
           CASE WHEN TRIM(other_debt) REGEXP '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
                THEN CAST(TRIM(other_debt) AS DECIMAL(30,10)) END
    FROM credit_risk_raw
    UNION ALL
    SELECT 'debt_to_income_ratio', debt_to_income_ratio,
           CASE WHEN TRIM(debt_to_income_ratio) REGEXP '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
                THEN CAST(TRIM(debt_to_income_ratio) AS DECIMAL(30,10)) END
    FROM credit_risk_raw
    UNION ALL
    SELECT 'open_accounts', open_accounts,
           CASE WHEN TRIM(open_accounts) REGEXP '^[+-]?[0-9]+$'
                THEN CAST(TRIM(open_accounts) AS DECIMAL(30,10)) END
    FROM credit_risk_raw
    UNION ALL
    SELECT 'credit_utilization_ratio', credit_utilization_ratio,
           CASE WHEN TRIM(credit_utilization_ratio) REGEXP '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
                THEN CAST(TRIM(credit_utilization_ratio) AS DECIMAL(30,10)) END
    FROM credit_risk_raw
    UNION ALL
    SELECT 'past_delinquencies', past_delinquencies,
           CASE WHEN TRIM(past_delinquencies) REGEXP '^[+-]?[0-9]+$'
                THEN CAST(TRIM(past_delinquencies) AS DECIMAL(30,10)) END
    FROM credit_risk_raw
)
SELECT
    column_name,
    COUNT(*) AS total_rows,
    SUM(CASE WHEN raw_value IS NULL OR TRIM(raw_value) = ''
             THEN 1 ELSE 0 END) AS missing_count,
    SUM(CASE WHEN NULLIF(TRIM(raw_value), '') IS NOT NULL
              AND numeric_value IS NULL THEN 1 ELSE 0 END)
        AS non_numeric_count,
    COUNT(numeric_value) AS valid_numeric_count,
    MIN(numeric_value) AS min_value,
    MAX(numeric_value) AS max_value,
    ROUND(AVG(numeric_value), 4) AS avg_value,
    ROUND(STDDEV_SAMP(numeric_value), 4) AS stddev_value
FROM numeric_values
GROUP BY column_name
ORDER BY column_name;

-- ============================================================
-- 6. RANGE AND CROSS-FIELD QUALITY FLAGS
-- ============================================================

-- 6.1 Count suspicious values using transparent review conditions.
-- A nonzero result is evidence for investigation, not a cleaning decision.
WITH typed_raw AS (
    SELECT
        client_ID,
        CASE WHEN TRIM(person_age) REGEXP '^[+-]?[0-9]+$'
             THEN CAST(TRIM(person_age) AS DECIMAL(30,10)) END AS age_num,
        CASE WHEN TRIM(person_income) REGEXP '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
             THEN CAST(TRIM(person_income) AS DECIMAL(30,10)) END AS income_num,
        CASE WHEN TRIM(person_emp_length) REGEXP '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
             THEN CAST(TRIM(person_emp_length) AS DECIMAL(30,10)) END AS emp_length_num,
        CASE WHEN TRIM(loan_amnt) REGEXP '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
             THEN CAST(TRIM(loan_amnt) AS DECIMAL(30,10)) END AS loan_amnt_num,
        CASE WHEN TRIM(loan_int_rate) REGEXP '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
             THEN CAST(TRIM(loan_int_rate) AS DECIMAL(30,10)) END AS int_rate_num,
        CASE WHEN TRIM(loan_percent_income) REGEXP '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
             THEN CAST(TRIM(loan_percent_income) AS DECIMAL(30,10)) END AS loan_pct_income_num,
        CASE WHEN TRIM(cb_person_cred_hist_length) REGEXP '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
             THEN CAST(TRIM(cb_person_cred_hist_length) AS DECIMAL(30,10)) END AS cred_hist_num,
        CASE WHEN TRIM(city_latitude) REGEXP '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
             THEN CAST(TRIM(city_latitude) AS DECIMAL(30,10)) END AS latitude_num,
        CASE WHEN TRIM(city_longitude) REGEXP '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
             THEN CAST(TRIM(city_longitude) AS DECIMAL(30,10)) END AS longitude_num,
        CASE WHEN TRIM(loan_term_months) REGEXP '^[+-]?[0-9]+$'
             THEN CAST(TRIM(loan_term_months) AS DECIMAL(30,10)) END AS term_num,
        CASE WHEN TRIM(loan_to_income_ratio) REGEXP '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
             THEN CAST(TRIM(loan_to_income_ratio) AS DECIMAL(30,10)) END AS lti_num,
        CASE WHEN TRIM(other_debt) REGEXP '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
             THEN CAST(TRIM(other_debt) AS DECIMAL(30,10)) END AS other_debt_num,
        CASE WHEN TRIM(debt_to_income_ratio) REGEXP '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
             THEN CAST(TRIM(debt_to_income_ratio) AS DECIMAL(30,10)) END AS dti_num,
        CASE WHEN TRIM(open_accounts) REGEXP '^[+-]?[0-9]+$'
             THEN CAST(TRIM(open_accounts) AS DECIMAL(30,10)) END AS open_accounts_num,
        CASE WHEN TRIM(credit_utilization_ratio) REGEXP '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
             THEN CAST(TRIM(credit_utilization_ratio) AS DECIMAL(30,10)) END AS utilization_num,
        CASE WHEN TRIM(past_delinquencies) REGEXP '^[+-]?[0-9]+$'
             THEN CAST(TRIM(past_delinquencies) AS DECIMAL(30,10)) END AS delinquencies_num
    FROM credit_risk_raw
), quality_flags AS (
    SELECT 'age_below_18' AS issue,
           SUM(CASE WHEN age_num < 18 THEN 1 ELSE 0 END) AS flagged_rows
    FROM typed_raw
    UNION ALL SELECT 'age_above_100',
           SUM(CASE WHEN age_num > 100 THEN 1 ELSE 0 END) FROM typed_raw
    UNION ALL SELECT 'employment_length_negative',
           SUM(CASE WHEN emp_length_num < 0 THEN 1 ELSE 0 END) FROM typed_raw
    UNION ALL SELECT 'employment_length_above_age',
           SUM(CASE WHEN emp_length_num > age_num THEN 1 ELSE 0 END) FROM typed_raw
    UNION ALL SELECT 'income_zero_or_negative',
           SUM(CASE WHEN income_num <= 0 THEN 1 ELSE 0 END) FROM typed_raw
    UNION ALL SELECT 'positive_loan_with_nonpositive_income',
           SUM(CASE WHEN loan_amnt_num > 0 AND income_num <= 0 THEN 1 ELSE 0 END) FROM typed_raw
    UNION ALL SELECT 'loan_amount_zero_or_negative',
           SUM(CASE WHEN loan_amnt_num <= 0 THEN 1 ELSE 0 END) FROM typed_raw
    UNION ALL SELECT 'interest_rate_negative',
           SUM(CASE WHEN int_rate_num < 0 THEN 1 ELSE 0 END) FROM typed_raw
    UNION ALL SELECT 'interest_rate_above_100_review',
           SUM(CASE WHEN int_rate_num > 100 THEN 1 ELSE 0 END) FROM typed_raw
    UNION ALL SELECT 'loan_percent_income_negative',
           SUM(CASE WHEN loan_pct_income_num < 0 THEN 1 ELSE 0 END) FROM typed_raw
    UNION ALL SELECT 'loan_percent_income_above_1_review',
           SUM(CASE WHEN loan_pct_income_num > 1 THEN 1 ELSE 0 END) FROM typed_raw
    UNION ALL SELECT 'loan_to_income_negative',
           SUM(CASE WHEN lti_num < 0 THEN 1 ELSE 0 END) FROM typed_raw
    UNION ALL SELECT 'loan_to_income_above_1_review',
           SUM(CASE WHEN lti_num > 1 THEN 1 ELSE 0 END) FROM typed_raw
    UNION ALL SELECT 'debt_to_income_negative',
           SUM(CASE WHEN dti_num < 0 THEN 1 ELSE 0 END) FROM typed_raw
    UNION ALL SELECT 'debt_to_income_above_1_review',
           SUM(CASE WHEN dti_num > 1 THEN 1 ELSE 0 END) FROM typed_raw
    UNION ALL SELECT 'other_debt_negative',
           SUM(CASE WHEN other_debt_num < 0 THEN 1 ELSE 0 END) FROM typed_raw
    UNION ALL SELECT 'credit_history_above_age',
           SUM(CASE WHEN cred_hist_num > age_num THEN 1 ELSE 0 END) FROM typed_raw
    UNION ALL SELECT 'loan_term_zero_or_negative',
           SUM(CASE WHEN term_num <= 0 THEN 1 ELSE 0 END) FROM typed_raw
    UNION ALL SELECT 'open_accounts_negative',
           SUM(CASE WHEN open_accounts_num < 0 THEN 1 ELSE 0 END) FROM typed_raw
    UNION ALL SELECT 'credit_utilization_negative',
           SUM(CASE WHEN utilization_num < 0 THEN 1 ELSE 0 END) FROM typed_raw
    UNION ALL SELECT 'credit_utilization_above_1_review',
           SUM(CASE WHEN utilization_num > 1 THEN 1 ELSE 0 END) FROM typed_raw
    UNION ALL SELECT 'past_delinquencies_negative',
           SUM(CASE WHEN delinquencies_num < 0 THEN 1 ELSE 0 END) FROM typed_raw
    UNION ALL SELECT 'latitude_outside_valid_range',
           SUM(CASE WHEN latitude_num < -90 OR latitude_num > 90 THEN 1 ELSE 0 END) FROM typed_raw
    UNION ALL SELECT 'longitude_outside_valid_range',
           SUM(CASE WHEN longitude_num < -180 OR longitude_num > 180 THEN 1 ELSE 0 END) FROM typed_raw
)
SELECT issue, flagged_rows
FROM quality_flags
ORDER BY flagged_rows DESC, issue;

-- 6.2 Test candidate formulas for the three affordability fields.
-- The tolerances allow for source rounding; results do not authorize cleaning.
WITH typed_raw AS (
    SELECT
        CASE WHEN TRIM(person_income) REGEXP '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
             THEN CAST(TRIM(person_income) AS DECIMAL(30,10)) END AS income_num,
        CASE WHEN TRIM(loan_amnt) REGEXP '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
             THEN CAST(TRIM(loan_amnt) AS DECIMAL(30,10)) END AS loan_amnt_num,
        CASE WHEN TRIM(loan_percent_income) REGEXP '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
             THEN CAST(TRIM(loan_percent_income) AS DECIMAL(30,10)) END AS loan_pct_income_num,
        CASE WHEN TRIM(loan_to_income_ratio) REGEXP '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
             THEN CAST(TRIM(loan_to_income_ratio) AS DECIMAL(30,10)) END AS lti_num,
        CASE WHEN TRIM(other_debt) REGEXP '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
             THEN CAST(TRIM(other_debt) AS DECIMAL(30,10)) END AS other_debt_num,
        CASE WHEN TRIM(debt_to_income_ratio) REGEXP '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
             THEN CAST(TRIM(debt_to_income_ratio) AS DECIMAL(30,10)) END AS dti_num
    FROM credit_risk_raw
)
SELECT
    SUM(CASE WHEN income_num > 0
              AND loan_amnt_num IS NOT NULL
              AND loan_pct_income_num IS NOT NULL
             THEN 1 ELSE 0 END) AS loan_percent_income_comparable_rows,
    SUM(CASE WHEN income_num > 0
              AND loan_amnt_num IS NOT NULL
              AND loan_pct_income_num IS NOT NULL
              AND ABS(loan_pct_income_num - loan_amnt_num / income_num) > 0.01
             THEN 1 ELSE 0 END) AS loan_percent_income_mismatch_rows,
    SUM(CASE WHEN income_num > 0
              AND loan_amnt_num IS NOT NULL
              AND lti_num IS NOT NULL
             THEN 1 ELSE 0 END) AS loan_to_income_comparable_rows,
    SUM(CASE WHEN income_num > 0
              AND loan_amnt_num IS NOT NULL
              AND lti_num IS NOT NULL
              AND ABS(lti_num - loan_amnt_num / income_num) > 0.001
             THEN 1 ELSE 0 END) AS loan_to_income_mismatch_rows,
    SUM(CASE WHEN income_num > 0
              AND loan_amnt_num IS NOT NULL
              AND dti_num IS NOT NULL
              AND other_debt_num IS NOT NULL
             THEN 1 ELSE 0 END) AS debt_to_income_comparable_rows,
    SUM(CASE WHEN income_num > 0
              AND loan_amnt_num IS NOT NULL
              AND dti_num IS NOT NULL
              AND other_debt_num IS NOT NULL
              AND ABS(dti_num - (loan_amnt_num + other_debt_num) / income_num) > 0.001
             THEN 1 ELSE 0 END) AS debt_to_income_mismatch_rows
FROM typed_raw;

-- 6.3 Inspect loan_percent_income rows that exceed the rounding tolerance.
-- Compare the raw value with both the exact ratio and its two-decimal form.
WITH ratio_check AS (
    SELECT
        client_ID,
        person_income,
        loan_amnt,
        loan_percent_income,
        loan_to_income_ratio,
        CAST(TRIM(person_income) AS DECIMAL(30,10)) AS income_num,
        CAST(TRIM(loan_amnt) AS DECIMAL(30,10)) AS loan_amnt_num,
        CAST(TRIM(loan_percent_income) AS DECIMAL(30,10)) AS loan_pct_income_num,
        CAST(TRIM(loan_to_income_ratio) AS DECIMAL(30,10)) AS lti_num
    FROM credit_risk_raw
    WHERE TRIM(person_income) REGEXP '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
      AND TRIM(loan_amnt) REGEXP '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
      AND TRIM(loan_percent_income) REGEXP '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
      AND TRIM(loan_to_income_ratio) REGEXP '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
), mismatches AS (
    SELECT
        *,
        loan_amnt_num / NULLIF(income_num, 0) AS calculated_ratio,
        ROUND(loan_amnt_num / NULLIF(income_num, 0), 2)
            AS calculated_ratio_2dp,
        ABS(
            loan_pct_income_num
            - loan_amnt_num / NULLIF(income_num, 0)
        ) AS absolute_difference
    FROM ratio_check
)
SELECT
    client_ID,
    person_income,
    loan_amnt,
    loan_percent_income AS recorded_loan_percent_income,
    loan_to_income_ratio,
    calculated_ratio_2dp AS expected_loan_percent_income_2dp,
    ROUND(absolute_difference, 6) AS absolute_difference
FROM mismatches
WHERE absolute_difference > 0.01
ORDER BY absolute_difference DESC, client_ID
LIMIT 100;

-- 6.4 Summarize agreement with the expected two-decimal representation.
-- Direction counts only include material differences above 0.01.
WITH ratio_comparison AS (
    SELECT
        CAST(TRIM(loan_percent_income) AS DECIMAL(30,10))
            AS recorded_ratio,
        CAST(TRIM(loan_to_income_ratio) AS DECIMAL(30,10))
            AS exact_ratio
    FROM credit_risk_raw
    WHERE TRIM(loan_percent_income)
              REGEXP '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
      AND TRIM(loan_to_income_ratio)
              REGEXP '^[+-]?([0-9]+([.][0-9]*)?|[.][0-9]+)$'
), differences AS (
    SELECT
        recorded_ratio,
        exact_ratio,
        ROUND(exact_ratio, 2) AS expected_ratio_2dp,
        recorded_ratio - exact_ratio AS signed_difference,
        ABS(recorded_ratio - exact_ratio) AS absolute_difference
    FROM ratio_comparison
)
SELECT
    COUNT(*) AS comparable_rows,
    SUM(CASE WHEN ABS(recorded_ratio - expected_ratio_2dp) < 0.000001
             THEN 1 ELSE 0 END) AS matches_expected_2dp_rows,
    SUM(CASE WHEN ABS(recorded_ratio - expected_ratio_2dp) >= 0.000001
             THEN 1 ELSE 0 END) AS mismatches_expected_2dp_rows,
    SUM(CASE WHEN absolute_difference > 0.01
             THEN 1 ELSE 0 END) AS material_mismatch_rows,
    SUM(CASE WHEN absolute_difference > 0.01
              AND signed_difference < 0 THEN 1 ELSE 0 END)
        AS material_recorded_below_expected_rows,
    SUM(CASE WHEN absolute_difference > 0.01
              AND signed_difference > 0 THEN 1 ELSE 0 END)
        AS material_recorded_above_expected_rows,
    ROUND(AVG(CASE WHEN absolute_difference > 0.01
                   THEN signed_difference END), 6)
        AS avg_signed_difference_material,
    ROUND(MAX(absolute_difference), 6) AS max_absolute_difference
FROM differences;

-- 6.5 Inspect every row flagged by the range and cross-field checks.
-- DTI above 1 is a review condition and may represent genuine high debt.
WITH flagged_detail AS (
    SELECT
        client_ID,
        person_age,
        person_emp_length,
        person_income,
        loan_amnt,
        other_debt,
        debt_to_income_ratio,
        loan_status,
        CAST(TRIM(person_age) AS DECIMAL(30,10)) AS age_num,
        CAST(NULLIF(TRIM(person_emp_length), '') AS DECIMAL(30,10))
            AS emp_length_num,
        CAST(TRIM(debt_to_income_ratio) AS DECIMAL(30,10)) AS dti_num
    FROM credit_risk_raw
)
SELECT
    client_ID,
    CONCAT_WS(
        ', ',
        CASE WHEN age_num > 100 THEN 'age_above_100' END,
        CASE WHEN emp_length_num > age_num
             THEN 'employment_length_above_age' END,
        CASE WHEN dti_num > 1 THEN 'debt_to_income_above_1_review' END
    ) AS triggered_flags,
    person_age,
    person_emp_length,
    person_income,
    loan_amnt,
    other_debt,
    debt_to_income_ratio,
    loan_status
FROM flagged_detail
WHERE age_num > 100
   OR emp_length_num > age_num
   OR dti_num > 1
ORDER BY client_ID;

-- 6.6 Inspect the 20 largest income and other-debt values.
-- Large values are not errors unless row context provides contrary evidence.
WITH numeric_tails AS (
    SELECT
        client_ID,
        person_age,
        person_income,
        loan_amnt,
        other_debt,
        debt_to_income_ratio,
        loan_status,
        CAST(TRIM(person_income) AS DECIMAL(30,10)) AS income_num,
        CAST(TRIM(other_debt) AS DECIMAL(30,10)) AS other_debt_num
    FROM credit_risk_raw
), ranked_tails AS (
    SELECT
        *,
        ROW_NUMBER() OVER (ORDER BY income_num DESC, client_ID)
            AS income_rank,
        ROW_NUMBER() OVER (ORDER BY other_debt_num DESC, client_ID)
            AS other_debt_rank
    FROM numeric_tails
)
SELECT
    client_ID,
    person_age,
    person_income,
    loan_amnt,
    other_debt,
    debt_to_income_ratio,
    loan_status,
    income_rank,
    other_debt_rank
FROM ranked_tails
WHERE income_rank <= 20
   OR other_debt_rank <= 20
ORDER BY LEAST(income_rank, other_debt_rank), client_ID;

-- 6.7 Profile missing values within relevant categorical groups.
-- This checks whether missingness is concentrated before treatment is chosen.
WITH missingness_by_group AS (
    SELECT
        'loan_int_rate' AS missing_field,
        'loan_grade' AS dimension_name,
        loan_grade AS dimension_value,
        COUNT(*) AS group_rows,
        SUM(CASE WHEN NULLIF(TRIM(loan_int_rate), '') IS NULL
                 THEN 1 ELSE 0 END) AS missing_rows
    FROM credit_risk_raw
    GROUP BY loan_grade

    UNION ALL
    SELECT
        'loan_int_rate', 'loan_status', loan_status, COUNT(*),
        SUM(CASE WHEN NULLIF(TRIM(loan_int_rate), '') IS NULL
                 THEN 1 ELSE 0 END)
    FROM credit_risk_raw
    GROUP BY loan_status

    UNION ALL
    SELECT
        'loan_int_rate', 'country', country, COUNT(*),
        SUM(CASE WHEN NULLIF(TRIM(loan_int_rate), '') IS NULL
                 THEN 1 ELSE 0 END)
    FROM credit_risk_raw
    GROUP BY country

    UNION ALL
    SELECT
        'person_emp_length', 'employment_type', employment_type, COUNT(*),
        SUM(CASE WHEN NULLIF(TRIM(person_emp_length), '') IS NULL
                 THEN 1 ELSE 0 END)
    FROM credit_risk_raw
    GROUP BY employment_type

    UNION ALL
    SELECT
        'person_emp_length', 'loan_status', loan_status, COUNT(*),
        SUM(CASE WHEN NULLIF(TRIM(person_emp_length), '') IS NULL
                 THEN 1 ELSE 0 END)
    FROM credit_risk_raw
    GROUP BY loan_status

    UNION ALL
    SELECT
        'person_emp_length', 'country', country, COUNT(*),
        SUM(CASE WHEN NULLIF(TRIM(person_emp_length), '') IS NULL
                 THEN 1 ELSE 0 END)
    FROM credit_risk_raw
    GROUP BY country
)
SELECT
    missing_field,
    dimension_name,
    dimension_value,
    group_rows,
    missing_rows,
    ROUND(100.0 * missing_rows / group_rows, 2) AS missing_pct
FROM missingness_by_group
WHERE missing_rows > 0
ORDER BY missing_field, dimension_name, dimension_value;

-- ============================================================
-- 7. INITIAL TARGET ASSOCIATION - RUN ONLY AFTER SECTIONS 1-6
-- ============================================================

-- 7.1 Cross-tab target values with core dimensions without assuming that
-- any target value means default. This is descriptive, not causal.
WITH target_dimensions AS (
    SELECT loan_status AS target_value,
           'loan_grade' AS dimension_name,
           loan_grade AS dimension_value
    FROM credit_risk_raw
    UNION ALL
    SELECT loan_status, 'loan_intent', loan_intent FROM credit_risk_raw
    UNION ALL
    SELECT loan_status, 'person_home_ownership', person_home_ownership FROM credit_risk_raw
    UNION ALL
    SELECT loan_status, 'employment_type', employment_type FROM credit_risk_raw
    UNION ALL
    SELECT loan_status, 'country', country FROM credit_risk_raw
    UNION ALL
    SELECT loan_status, 'cb_person_default_on_file', cb_person_default_on_file FROM credit_risk_raw
)
SELECT
    dimension_name,
    dimension_value,
    target_value,
    COUNT(*) AS row_count,
    ROUND(
        100.0 * COUNT(*)
        / SUM(COUNT(*)) OVER (
            PARTITION BY dimension_name, dimension_value
        ),
        2
    ) AS pct_within_dimension_value
FROM target_dimensions
GROUP BY dimension_name, dimension_value, target_value
ORDER BY dimension_name, dimension_value, target_value;

-- ============================================================
-- PROFILING CHECKPOINT
-- ============================================================
-- Do not define cleaning rules until the observed outputs are reviewed.
-- First execution batch: 1.2, 1.3, 2.1, 2.2, 2.4, 2.5, 3.1, 4.1, 4.2.
-- Run 2.3 only if 2.2 returns at least one repeated client ID.
-- Send those result grids for review before running deeper diagnostics.
