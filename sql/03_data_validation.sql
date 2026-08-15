-- ============================================================
-- RISK CREDIT ANALYTICS PROJECT
-- FILE: 03_data_validation.sql
-- PURPOSE: Validate credit_risk_clean before SQL EDA.
-- MYSQL VERSION: 8.0+
-- ============================================================
-- This file is read-only. Run one numbered query at a time.
-- A validation passes when its mismatch or failed-row count is zero.
-- No target value is interpreted as default in this file.
-- ============================================================

USE risk_credit_analytics;

-- ============================================================
-- 1. TABLE, ROW COUNT, AND KEY VALIDATION
-- ============================================================

-- 1.1 Confirm row preservation and key cardinality.
SELECT
    (SELECT COUNT(*) FROM credit_risk_raw) AS raw_rows,
    (SELECT COUNT(*) FROM credit_risk_clean) AS clean_rows,
    (SELECT COUNT(DISTINCT NULLIF(TRIM(client_ID), ''))
     FROM credit_risk_raw) AS raw_distinct_client_ids,
    (SELECT COUNT(DISTINCT client_ID)
     FROM credit_risk_clean) AS clean_distinct_client_ids;

-- 1.2 Confirm clean table column count and primary key definition.
SELECT
    COUNT(*) AS clean_column_count,
    SUM(CASE WHEN column_name = 'client_ID'
                  AND column_key = 'PRI'
             THEN 1 ELSE 0 END) AS client_id_primary_key_columns
FROM information_schema.columns
WHERE table_schema = DATABASE()
  AND table_name = 'credit_risk_clean';

-- 1.3 Confirm that neither layer has unmatched client IDs.
SELECT
    'raw_id_missing_in_clean' AS validation_check,
    COUNT(*) AS failed_rows
FROM credit_risk_raw AS r
LEFT JOIN credit_risk_clean AS c
  ON BINARY TRIM(r.client_ID) = BINARY c.client_ID
WHERE c.client_ID IS NULL

UNION ALL

SELECT
    'clean_id_missing_in_raw',
    COUNT(*)
FROM credit_risk_clean AS c
LEFT JOIN credit_risk_raw AS r
  ON BINARY c.client_ID = BINARY TRIM(r.client_ID)
WHERE r.client_ID IS NULL;

-- ============================================================
-- 2. BASE-FIELD PRESERVATION
-- ============================================================

-- 2.1 Confirm that non-derived numeric values were preserved after casting.
SELECT
    SUM(CASE WHEN NOT (
        c.person_income <=> CAST(TRIM(r.person_income) AS DECIMAL(18,2))
    ) THEN 1 ELSE 0 END) AS income_mismatches,
    SUM(CASE WHEN NOT (
        c.loan_amnt <=> CAST(TRIM(r.loan_amnt) AS DECIMAL(18,2))
    ) THEN 1 ELSE 0 END) AS loan_amount_mismatches,
    SUM(CASE WHEN NOT (
        c.loan_int_rate <=>
        CAST(NULLIF(TRIM(r.loan_int_rate), '') AS DECIMAL(8,4))
    ) THEN 1 ELSE 0 END) AS interest_rate_mismatches,
    SUM(CASE WHEN NOT (
        c.loan_status <=> CAST(TRIM(r.loan_status) AS UNSIGNED)
    ) THEN 1 ELSE 0 END) AS loan_status_mismatches,
    SUM(CASE WHEN NOT (
        c.source_loan_percent_income <=>
        CAST(TRIM(r.loan_percent_income) AS DECIMAL(14,9))
    ) THEN 1 ELSE 0 END) AS source_loan_pct_mismatches,
    SUM(CASE WHEN NOT (
        c.cb_person_cred_hist_length <=>
        CAST(TRIM(r.cb_person_cred_hist_length) AS DECIMAL(8,2))
    ) THEN 1 ELSE 0 END) AS credit_history_mismatches,
    SUM(CASE WHEN NOT (
        c.city_latitude <=>
        CAST(TRIM(r.city_latitude) AS DECIMAL(9,6))
    ) THEN 1 ELSE 0 END) AS latitude_mismatches,
    SUM(CASE WHEN NOT (
        c.city_longitude <=>
        CAST(TRIM(r.city_longitude) AS DECIMAL(10,6))
    ) THEN 1 ELSE 0 END) AS longitude_mismatches,
    SUM(CASE WHEN NOT (
        c.loan_term_months <=> CAST(TRIM(r.loan_term_months) AS UNSIGNED)
    ) THEN 1 ELSE 0 END) AS loan_term_mismatches,
    SUM(CASE WHEN NOT (
        c.other_debt <=> CAST(TRIM(r.other_debt) AS DECIMAL(20,10))
    ) THEN 1 ELSE 0 END) AS other_debt_mismatches,
    SUM(CASE WHEN NOT (
        c.open_accounts <=> CAST(TRIM(r.open_accounts) AS UNSIGNED)
    ) THEN 1 ELSE 0 END) AS open_account_mismatches,
    SUM(CASE WHEN NOT (
        c.credit_utilization_ratio <=>
        CAST(TRIM(r.credit_utilization_ratio) AS DECIMAL(14,9))
    ) THEN 1 ELSE 0 END) AS utilization_mismatches,
    SUM(CASE WHEN NOT (
        c.past_delinquencies <=>
        CAST(TRIM(r.past_delinquencies) AS UNSIGNED)
    ) THEN 1 ELSE 0 END) AS delinquency_mismatches
FROM credit_risk_raw AS r
JOIN credit_risk_clean AS c
  ON BINARY TRIM(r.client_ID) = BINARY c.client_ID;

-- 2.2 Confirm that categorical fields equal their trimmed raw values.
SELECT
    SUM(CASE WHEN NOT (
        CAST(c.person_home_ownership AS BINARY) <=>
        CAST(NULLIF(TRIM(r.person_home_ownership), '') AS BINARY)
    ) THEN 1 ELSE 0 END) AS home_ownership_mismatches,
    SUM(CASE WHEN NOT (
        CAST(c.loan_intent AS BINARY) <=>
        CAST(NULLIF(TRIM(r.loan_intent), '') AS BINARY)
    ) THEN 1 ELSE 0 END) AS loan_intent_mismatches,
    SUM(CASE WHEN NOT (
        CAST(c.loan_grade AS BINARY) <=>
        CAST(NULLIF(TRIM(r.loan_grade), '') AS BINARY)
    ) THEN 1 ELSE 0 END) AS loan_grade_mismatches,
    SUM(CASE WHEN NOT (
        CAST(c.cb_person_default_on_file AS BINARY) <=>
        CAST(NULLIF(TRIM(r.cb_person_default_on_file), '') AS BINARY)
    ) THEN 1 ELSE 0 END) AS previous_default_mismatches,
    SUM(CASE WHEN NOT (
        CAST(c.gender AS BINARY) <=>
        CAST(NULLIF(TRIM(r.gender), '') AS BINARY)
    ) THEN 1 ELSE 0 END) AS gender_mismatches,
    SUM(CASE WHEN NOT (
        CAST(c.marital_status AS BINARY) <=>
        CAST(NULLIF(TRIM(r.marital_status), '') AS BINARY)
    ) THEN 1 ELSE 0 END) AS marital_status_mismatches,
    SUM(CASE WHEN NOT (
        CAST(c.education_level AS BINARY) <=>
        CAST(NULLIF(TRIM(r.education_level), '') AS BINARY)
    ) THEN 1 ELSE 0 END) AS education_mismatches,
    SUM(CASE WHEN NOT (
        CAST(c.country AS BINARY) <=>
        CAST(NULLIF(TRIM(r.country), '') AS BINARY)
    ) THEN 1 ELSE 0 END) AS country_mismatches,
    SUM(CASE WHEN NOT (
        CAST(c.state AS BINARY) <=>
        CAST(NULLIF(TRIM(r.state), '') AS BINARY)
    ) THEN 1 ELSE 0 END) AS state_mismatches,
    SUM(CASE WHEN NOT (
        CAST(c.city AS BINARY) <=>
        CAST(NULLIF(TRIM(r.city), '') AS BINARY)
    ) THEN 1 ELSE 0 END) AS city_mismatches,
    SUM(CASE WHEN NOT (
        CAST(c.employment_type AS BINARY) <=>
        CAST(NULLIF(TRIM(r.employment_type), '') AS BINARY)
    ) THEN 1 ELSE 0 END) AS employment_type_mismatches
FROM credit_risk_raw AS r
JOIN credit_risk_clean AS c
  ON BINARY TRIM(r.client_ID) = BINARY c.client_ID;

-- ============================================================
-- 3. CLEANING TRANSFORMATION VALIDATION
-- ============================================================

-- 3.1 Recompute expected values and flags directly from raw data.
WITH typed_raw AS (
    SELECT
        client_ID,
        CAST(TRIM(person_age) AS DECIMAL(30,10)) AS age_num,
        CAST(TRIM(person_income) AS DECIMAL(30,10)) AS income_num,
        CAST(NULLIF(TRIM(person_emp_length), '') AS DECIMAL(30,10))
            AS emp_length_num,
        CAST(TRIM(loan_amnt) AS DECIMAL(30,10)) AS loan_amnt_num,
        CAST(NULLIF(TRIM(loan_int_rate), '') AS DECIMAL(30,10))
            AS interest_rate_num,
        CAST(TRIM(loan_percent_income) AS DECIMAL(30,10))
            AS source_loan_pct_num,
        CAST(TRIM(other_debt) AS DECIMAL(30,10)) AS other_debt_num
    FROM credit_risk_raw
), expected AS (
    SELECT
        *,
        CASE WHEN age_num BETWEEN 18 AND 100
             THEN age_num END AS expected_age,
        CASE
            WHEN emp_length_num IS NULL THEN NULL
            WHEN emp_length_num < 0 OR emp_length_num > age_num THEN NULL
            ELSE emp_length_num
        END AS expected_emp_length,
        ROUND(loan_amnt_num / NULLIF(income_num, 0), 2)
            AS expected_loan_pct,
        ROUND(loan_amnt_num / NULLIF(income_num, 0), 9)
            AS expected_lti,
        ROUND(
            (loan_amnt_num + other_debt_num) / NULLIF(income_num, 0),
            9
        ) AS expected_dti
    FROM typed_raw
)
SELECT
    SUM(CASE WHEN NOT (c.person_age <=> e.expected_age)
             THEN 1 ELSE 0 END) AS age_value_mismatches,
    SUM(CASE WHEN c.is_age_invalid <>
                       CASE WHEN e.age_num < 18 OR e.age_num > 100
                            THEN 1 ELSE 0 END
             THEN 1 ELSE 0 END) AS age_flag_mismatches,
    SUM(CASE WHEN NOT (c.person_emp_length <=> e.expected_emp_length)
             THEN 1 ELSE 0 END) AS emp_length_value_mismatches,
    SUM(CASE WHEN c.is_emp_length_missing <>
                       CASE WHEN e.emp_length_num IS NULL THEN 1 ELSE 0 END
             THEN 1 ELSE 0 END) AS emp_missing_flag_mismatches,
    SUM(CASE WHEN c.is_emp_length_invalid <>
                       CASE WHEN e.emp_length_num IS NOT NULL
                                  AND (e.emp_length_num < 0
                                       OR e.emp_length_num > e.age_num)
                            THEN 1 ELSE 0 END
             THEN 1 ELSE 0 END) AS emp_invalid_flag_mismatches,
    SUM(CASE WHEN NOT (c.loan_int_rate <=> e.interest_rate_num)
             THEN 1 ELSE 0 END) AS interest_value_mismatches,
    SUM(CASE WHEN c.is_loan_int_rate_missing <>
                       CASE WHEN e.interest_rate_num IS NULL THEN 1 ELSE 0 END
             THEN 1 ELSE 0 END) AS interest_flag_mismatches,
    SUM(CASE WHEN c.loan_percent_income <> e.expected_loan_pct
             THEN 1 ELSE 0 END) AS loan_pct_value_mismatches,
    SUM(CASE WHEN c.is_loan_percent_income_mismatch <>
                       CASE WHEN ABS(e.source_loan_pct_num
                                          - e.expected_loan_pct) >= 0.000001
                            THEN 1 ELSE 0 END
             THEN 1 ELSE 0 END) AS loan_pct_flag_mismatches,
    SUM(CASE WHEN c.is_loan_percent_income_material_mismatch <>
                       CASE WHEN ABS(
                                          e.source_loan_pct_num
                                          - e.loan_amnt_num
                                            / NULLIF(e.income_num, 0)
                                      ) > 0.01
                            THEN 1 ELSE 0 END
             THEN 1 ELSE 0 END) AS loan_pct_material_flag_mismatches,
    SUM(CASE WHEN c.loan_to_income_ratio <> e.expected_lti
             THEN 1 ELSE 0 END) AS lti_value_mismatches,
    SUM(CASE WHEN c.debt_to_income_ratio <> e.expected_dti
             THEN 1 ELSE 0 END) AS dti_value_mismatches,
    SUM(CASE WHEN c.is_high_dti <>
                       CASE WHEN (
                                      e.loan_amnt_num + e.other_debt_num
                                  ) / NULLIF(e.income_num, 0) > 1
                            THEN 1 ELSE 0 END
             THEN 1 ELSE 0 END) AS high_dti_flag_mismatches
FROM expected AS e
JOIN credit_risk_clean AS c
  ON BINARY TRIM(e.client_ID) = BINARY c.client_ID;

-- ============================================================
-- 4. NULL, DOMAIN, AND RANGE VALIDATION
-- ============================================================

-- 4.1 Reconcile allowed NULLs with their audit flags.
SELECT
    SUM(person_age IS NULL) AS null_age_rows,
    SUM(person_emp_length IS NULL) AS null_emp_length_rows,
    SUM(loan_int_rate IS NULL) AS null_interest_rate_rows,
    SUM(CASE WHEN (person_age IS NULL) <> (is_age_invalid = 1)
             THEN 1 ELSE 0 END) AS age_null_flag_mismatches,
    SUM(CASE WHEN (person_emp_length IS NULL) <>
                       (is_emp_length_missing = 1
                        OR is_emp_length_invalid = 1)
             THEN 1 ELSE 0 END) AS emp_null_flag_mismatches,
    SUM(CASE WHEN (loan_int_rate IS NULL) <>
                       (is_loan_int_rate_missing = 1)
             THEN 1 ELSE 0 END) AS interest_null_flag_mismatches
FROM credit_risk_clean;

-- 4.2 Return one row per invalid domain or range condition.
SELECT 'unexpected_loan_status' AS validation_check,
       SUM(CASE WHEN loan_status NOT IN (0, 1) THEN 1 ELSE 0 END)
           AS failed_rows
FROM credit_risk_clean
UNION ALL
SELECT 'unexpected_loan_grade',
       SUM(CASE WHEN loan_grade NOT IN ('A', 'B', 'C', 'D', 'E', 'F', 'G')
                THEN 1 ELSE 0 END)
FROM credit_risk_clean
UNION ALL
SELECT 'unexpected_home_ownership',
       SUM(CASE WHEN person_home_ownership NOT IN
                     ('RENT', 'MORTGAGE', 'OWN', 'OTHER')
                THEN 1 ELSE 0 END)
FROM credit_risk_clean
UNION ALL
SELECT 'unexpected_previous_default_flag',
       SUM(CASE WHEN cb_person_default_on_file NOT IN ('N', 'Y')
                THEN 1 ELSE 0 END)
FROM credit_risk_clean
UNION ALL
SELECT 'unexpected_country',
       SUM(CASE WHEN country NOT IN ('USA', 'UK', 'Canada')
                THEN 1 ELSE 0 END)
FROM credit_risk_clean
UNION ALL
SELECT 'age_outside_clean_range',
       SUM(CASE WHEN person_age IS NOT NULL
                      AND person_age NOT BETWEEN 18 AND 100
                THEN 1 ELSE 0 END)
FROM credit_risk_clean
UNION ALL
SELECT 'employment_length_negative_or_above_age',
       SUM(CASE WHEN person_emp_length < 0
                      OR (person_age IS NOT NULL
                          AND person_emp_length > person_age)
                THEN 1 ELSE 0 END)
FROM credit_risk_clean
UNION ALL
SELECT 'income_zero_or_negative',
       SUM(CASE WHEN person_income <= 0 THEN 1 ELSE 0 END)
FROM credit_risk_clean
UNION ALL
SELECT 'loan_amount_zero_or_negative',
       SUM(CASE WHEN loan_amnt <= 0 THEN 1 ELSE 0 END)
FROM credit_risk_clean
UNION ALL
SELECT 'interest_rate_negative',
       SUM(CASE WHEN loan_int_rate < 0 THEN 1 ELSE 0 END)
FROM credit_risk_clean
UNION ALL
SELECT 'negative_affordability_ratio',
       SUM(CASE WHEN loan_percent_income < 0
                      OR loan_to_income_ratio < 0
                      OR debt_to_income_ratio < 0
                THEN 1 ELSE 0 END)
FROM credit_risk_clean
UNION ALL
SELECT 'negative_other_debt',
       SUM(CASE WHEN other_debt < 0 THEN 1 ELSE 0 END)
FROM credit_risk_clean
UNION ALL
SELECT 'credit_utilization_outside_0_1',
       SUM(CASE WHEN credit_utilization_ratio NOT BETWEEN 0 AND 1
                THEN 1 ELSE 0 END)
FROM credit_risk_clean
UNION ALL
SELECT 'negative_account_or_delinquency_count',
       SUM(CASE WHEN open_accounts < 0 OR past_delinquencies < 0
                THEN 1 ELSE 0 END)
FROM credit_risk_clean
UNION ALL
SELECT 'invalid_coordinates',
       SUM(CASE WHEN city_latitude NOT BETWEEN -90 AND 90
                      OR city_longitude NOT BETWEEN -180 AND 180
                THEN 1 ELSE 0 END)
FROM credit_risk_clean;

-- 4.3 Inspect discrete loan terms without imposing a new domain rule.
SELECT
    loan_term_months,
    COUNT(*) AS row_count
FROM credit_risk_clean
GROUP BY loan_term_months
ORDER BY loan_term_months;

-- ============================================================
-- 5. AGGREGATE AND DISTRIBUTION RECONCILIATION
-- ============================================================

-- 5.1 Confirm that base monetary totals were preserved exactly.
WITH raw_totals AS (
    SELECT
        SUM(CAST(TRIM(person_income) AS DECIMAL(30,10))) AS income_total,
        SUM(CAST(TRIM(loan_amnt) AS DECIMAL(30,10))) AS loan_total,
        SUM(CAST(TRIM(other_debt) AS DECIMAL(30,10))) AS other_debt_total
    FROM credit_risk_raw
), clean_totals AS (
    SELECT
        SUM(CAST(person_income AS DECIMAL(30,10))) AS income_total,
        SUM(CAST(loan_amnt AS DECIMAL(30,10))) AS loan_total,
        SUM(CAST(other_debt AS DECIMAL(30,10))) AS other_debt_total
    FROM credit_risk_clean
)
SELECT
    c.income_total - r.income_total AS income_total_difference,
    c.loan_total - r.loan_total AS loan_total_difference,
    c.other_debt_total - r.other_debt_total AS other_debt_total_difference
FROM raw_totals AS r
CROSS JOIN clean_totals AS c;

-- 5.2 Return only category or target distributions changed by cleaning.
-- An empty result grid means all listed distributions were preserved.
WITH raw_distribution AS (
    SELECT 'loan_status' AS dimension_name,
           HEX(TRIM(loan_status)) AS dimension_value_hex,
           COUNT(*) AS row_count
    FROM credit_risk_raw GROUP BY HEX(TRIM(loan_status))
    UNION ALL
    SELECT 'loan_grade', HEX(TRIM(loan_grade)), COUNT(*)
    FROM credit_risk_raw GROUP BY HEX(TRIM(loan_grade))
    UNION ALL
    SELECT 'loan_intent', HEX(TRIM(loan_intent)), COUNT(*)
    FROM credit_risk_raw GROUP BY HEX(TRIM(loan_intent))
    UNION ALL
    SELECT 'person_home_ownership', HEX(TRIM(person_home_ownership)), COUNT(*)
    FROM credit_risk_raw GROUP BY HEX(TRIM(person_home_ownership))
    UNION ALL
    SELECT 'employment_type', HEX(TRIM(employment_type)), COUNT(*)
    FROM credit_risk_raw GROUP BY HEX(TRIM(employment_type))
    UNION ALL
    SELECT 'country', HEX(TRIM(country)), COUNT(*)
    FROM credit_risk_raw GROUP BY HEX(TRIM(country))
), clean_distribution AS (
    SELECT 'loan_status' AS dimension_name,
           HEX(CAST(loan_status AS CHAR)) AS dimension_value_hex,
           COUNT(*) AS row_count
    FROM credit_risk_clean GROUP BY HEX(CAST(loan_status AS CHAR))
    UNION ALL
    SELECT 'loan_grade', HEX(loan_grade), COUNT(*)
    FROM credit_risk_clean GROUP BY HEX(loan_grade)
    UNION ALL
    SELECT 'loan_intent', HEX(loan_intent), COUNT(*)
    FROM credit_risk_clean GROUP BY HEX(loan_intent)
    UNION ALL
    SELECT 'person_home_ownership', HEX(person_home_ownership), COUNT(*)
    FROM credit_risk_clean GROUP BY HEX(person_home_ownership)
    UNION ALL
    SELECT 'employment_type', HEX(employment_type), COUNT(*)
    FROM credit_risk_clean GROUP BY HEX(employment_type)
    UNION ALL
    SELECT 'country', HEX(country), COUNT(*)
    FROM credit_risk_clean GROUP BY HEX(country)
), distribution_differences AS (
    SELECT
        r.dimension_name,
        r.dimension_value_hex,
        r.row_count AS raw_rows,
        c.row_count AS clean_rows
    FROM raw_distribution AS r
    LEFT JOIN clean_distribution AS c
      ON r.dimension_name = c.dimension_name
     AND r.dimension_value_hex = c.dimension_value_hex
    WHERE c.row_count IS NULL OR r.row_count <> c.row_count

    UNION ALL

    SELECT
        c.dimension_name,
        c.dimension_value_hex,
        r.row_count,
        c.row_count
    FROM clean_distribution AS c
    LEFT JOIN raw_distribution AS r
      ON c.dimension_name = r.dimension_name
     AND c.dimension_value_hex = r.dimension_value_hex
    WHERE r.row_count IS NULL
)
SELECT
    dimension_name,
    CONVERT(UNHEX(dimension_value_hex) USING utf8mb4) AS dimension_value,
    raw_rows,
    clean_rows
FROM distribution_differences
ORDER BY dimension_name, dimension_value_hex;

-- ============================================================
-- 6. FINAL ACCEPTANCE CHECKPOINT
-- ============================================================

-- 6.1 Compact pass/fail checks for the conditions required before EDA.
WITH validation_checks AS (
    SELECT
        'row_count_difference' AS validation_check,
        ABS(
            (SELECT COUNT(*) FROM credit_risk_raw)
            - (SELECT COUNT(*) FROM credit_risk_clean)
        ) AS failed_rows

    UNION ALL
    SELECT
        'duplicate_clean_client_ids',
        COUNT(*) - COUNT(DISTINCT client_ID)
    FROM credit_risk_clean

    UNION ALL
    SELECT
        'raw_ids_missing_in_clean',
        COUNT(*)
    FROM credit_risk_raw AS r
    LEFT JOIN credit_risk_clean AS c
      ON BINARY TRIM(r.client_ID) = BINARY c.client_ID
    WHERE c.client_ID IS NULL

    UNION ALL
    SELECT
        'age_null_flag_mismatches',
        SUM(CASE WHEN (person_age IS NULL) <> (is_age_invalid = 1)
                 THEN 1 ELSE 0 END)
    FROM credit_risk_clean

    UNION ALL
    SELECT
        'emp_null_flag_mismatches',
        SUM(CASE WHEN (person_emp_length IS NULL) <>
                           (is_emp_length_missing = 1
                            OR is_emp_length_invalid = 1)
                 THEN 1 ELSE 0 END)
    FROM credit_risk_clean

    UNION ALL
    SELECT
        'interest_null_flag_mismatches',
        SUM(CASE WHEN (loan_int_rate IS NULL) <>
                           (is_loan_int_rate_missing = 1)
                 THEN 1 ELSE 0 END)
    FROM credit_risk_clean

    UNION ALL
    SELECT
        'invalid_loan_percent_income_formula',
        SUM(
            loan_percent_income <>
            ROUND(
                CAST(loan_amnt AS DECIMAL(30,10))
                / NULLIF(CAST(person_income AS DECIMAL(30,10)), 0),
                2
            )
        )
    FROM credit_risk_clean

    UNION ALL
    SELECT
        'invalid_lti_formula',
        SUM(
            loan_to_income_ratio <>
            ROUND(
                CAST(loan_amnt AS DECIMAL(30,10))
                / NULLIF(CAST(person_income AS DECIMAL(30,10)), 0),
                9
            )
        )
    FROM credit_risk_clean

    UNION ALL
    SELECT
        'invalid_dti_formula',
        SUM(
            debt_to_income_ratio <>
            ROUND(
                (
                    CAST(loan_amnt AS DECIMAL(30,10))
                    + CAST(other_debt AS DECIMAL(30,10))
                ) / NULLIF(CAST(person_income AS DECIMAL(30,10)), 0),
                9
            )
        )
    FROM credit_risk_clean

    UNION ALL
    SELECT
        'invalid_clean_numeric_ranges',
        SUM(CASE WHEN person_income <= 0
                       OR loan_amnt <= 0
                       OR loan_to_income_ratio < 0
                       OR debt_to_income_ratio < 0
                       OR credit_utilization_ratio NOT BETWEEN 0 AND 1
                 THEN 1 ELSE 0 END)
    FROM credit_risk_clean
)
SELECT
    validation_check,
    failed_rows,
    CASE WHEN failed_rows = 0 THEN 'PASS' ELSE 'FAIL' END AS status
FROM validation_checks
ORDER BY validation_check;

-- EDA may begin only when section 6.1 returns PASS for every row and
-- sections 2.1, 2.2, 3.1, 4.2, 5.1, and 5.2 show no unexplained changes.
