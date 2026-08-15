-- ============================================================
-- RISK CREDIT ANALYTICS PROJECT
-- FILE: 08_credit_and_stability.sql
-- PURPOSE: Analyze credit-history and borrower-stability indicators
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
-- - Previous default history
-- - Credit history length
-- - Open accounts
-- - Past delinquencies
-- - Previous default x employment stability
-- - Previous default x home ownership
-- - Previous default x delinquency history
-- - Credit / stability checkpoint
--
-- IMPORTANT:
-- - Findings are descriptive associations, not causal conclusions.
-- - Bands are analytical review bands, NOT lending-policy thresholds.
-- - Minimum sample size = 100 is an analytical warning only.
-- - Final multi-factor segmentation belongs to file 09.
-- ============================================================

USE risk_credit_analytics;


-- ============================================================
-- 1. PREVIOUS DEFAULT HISTORY
-- ============================================================

-- ------------------------------------------------------------
-- 1.1 Default behavior by previous-default-on-file status
-- ------------------------------------------------------------
-- Business question:
-- Do borrowers with a previous default on file show materially
-- different current loan outcomes?
--
-- This factor was initially reviewed in 04_overall_risk.sql.
-- Here it is analyzed as a dedicated credit-history dimension.
-- ------------------------------------------------------------

WITH params AS (
    SELECT 100 AS min_sample_size
),

previous_default_summary AS (
    SELECT
        COALESCE(
            NULLIF(TRIM(cb_person_default_on_file), ''),
            'Unknown'
        ) AS previous_default_status,

        COUNT(*) AS loan_count,

        SUM(CASE WHEN loan_status = 0 THEN 1 ELSE 0 END)
            AS non_default_count,

        SUM(CASE WHEN loan_status = 1 THEN 1 ELSE 0 END)
            AS default_count,

        AVG(CASE WHEN loan_status = 1 THEN 1.0 ELSE 0.0 END)
            AS default_rate,

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
            NULLIF(TRIM(cb_person_default_on_file), ''),
            'Unknown'
        )
),

portfolio_totals AS (
    SELECT
        COUNT(*) AS total_loans,

        SUM(loan_amnt) AS total_exposure,

        SUM(
            CASE
                WHEN loan_status = 1 THEN loan_amnt
                ELSE 0
            END
        ) AS total_default_exposure,

        AVG(
            CASE
                WHEN loan_status = 1 THEN 1.0
                ELSE 0.0
            END
        ) AS portfolio_default_rate

    FROM credit_risk_clean
)

SELECT
    s.previous_default_status,

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
        WHEN s.loan_count >= prm.min_sample_size
        THEN 'Enough sample'
        ELSE 'Small sample'
    END AS sample_size_status

FROM previous_default_summary AS s
CROSS JOIN portfolio_totals AS p
CROSS JOIN params AS prm

ORDER BY
    CASE s.previous_default_status
        WHEN 'N' THEN 1
        WHEN 'Y' THEN 2
        ELSE 99
    END;


-- ============================================================
-- 2. CREDIT HISTORY LENGTH
-- ============================================================

-- ------------------------------------------------------------
-- 2.1 Credit-history-length distribution checkpoint
-- ------------------------------------------------------------
-- Business question:
-- How long is the borrower's recorded credit history before
-- analytical bands are interpreted?
-- ------------------------------------------------------------

WITH ranked_credit_history AS (
    SELECT
        cb_person_cred_hist_length,

        ROW_NUMBER() OVER (
            ORDER BY cb_person_cred_hist_length
        ) AS row_num,

        COUNT(*) OVER () AS total_rows

    FROM credit_risk_clean

    WHERE cb_person_cred_hist_length IS NOT NULL
)

SELECT
    COUNT(*) AS valid_credit_history_observations,

    ROUND(
        MIN(cb_person_cred_hist_length),
        2
    ) AS min_credit_history_years,

    ROUND(
        MAX(
            CASE
                WHEN row_num = CEIL(total_rows * 0.25)
                THEN cb_person_cred_hist_length
            END
        ),
        2
    ) AS p25_credit_history_years,

    ROUND(
        AVG(
            CASE
                WHEN row_num IN (
                    FLOOR((total_rows + 1) / 2),
                    CEIL((total_rows + 1) / 2)
                )
                THEN cb_person_cred_hist_length
            END
        ),
        2
    ) AS median_credit_history_years,

    ROUND(
        AVG(cb_person_cred_hist_length),
        2
    ) AS average_credit_history_years,

    ROUND(
        MAX(
            CASE
                WHEN row_num = CEIL(total_rows * 0.75)
                THEN cb_person_cred_hist_length
            END
        ),
        2
    ) AS p75_credit_history_years,

    ROUND(
        MAX(cb_person_cred_hist_length),
        2
    ) AS max_credit_history_years

FROM ranked_credit_history;


-- ------------------------------------------------------------
-- 2.2 Default behavior by credit-history-length band
-- ------------------------------------------------------------
-- Business question:
-- Does a longer credit history correspond to a materially different
-- observed default rate?
--
-- Analytical bands:
-- <3 years
-- 3-5 years
-- 6-10 years
-- 10+ years
--
-- These are review bands, not approval thresholds.
-- ------------------------------------------------------------

WITH params AS (
    SELECT 100 AS min_sample_size
),

credit_history_segments AS (
    SELECT
        CASE
            WHEN cb_person_cred_hist_length IS NULL
                THEN 'Unknown'
            WHEN cb_person_cred_hist_length < 3
                THEN '<3 years'
            WHEN cb_person_cred_hist_length <= 5
                THEN '3-5 years'
            WHEN cb_person_cred_hist_length <= 10
                THEN '6-10 years'
            ELSE '10+ years'
        END AS credit_history_band,

        CASE
            WHEN cb_person_cred_hist_length IS NULL THEN 99
            WHEN cb_person_cred_hist_length < 3 THEN 1
            WHEN cb_person_cred_hist_length <= 5 THEN 2
            WHEN cb_person_cred_hist_length <= 10 THEN 3
            ELSE 4
        END AS band_order,

        loan_status,
        loan_amnt

    FROM credit_risk_clean
),

segment_summary AS (
    SELECT
        credit_history_band,
        band_order,

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

    FROM credit_history_segments

    GROUP BY
        credit_history_band,
        band_order
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
    s.credit_history_band,

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
        WHEN s.loan_count >= prm.min_sample_size
        THEN 'Enough sample'
        ELSE 'Small sample'
    END AS sample_size_status

FROM segment_summary AS s
CROSS JOIN portfolio_totals AS p
CROSS JOIN params AS prm

ORDER BY s.band_order;


-- ============================================================
-- 3. OPEN ACCOUNTS
-- ============================================================

-- ------------------------------------------------------------
-- 3.1 Open-accounts distribution checkpoint
-- ------------------------------------------------------------
-- Business question:
-- How many active/open credit accounts do borrowers typically have?
-- ------------------------------------------------------------

WITH ranked_open_accounts AS (
    SELECT
        open_accounts,

        ROW_NUMBER() OVER (
            ORDER BY open_accounts
        ) AS row_num,

        COUNT(*) OVER () AS total_rows

    FROM credit_risk_clean

    WHERE open_accounts IS NOT NULL
)

SELECT
    COUNT(*) AS valid_open_account_observations,

    MIN(open_accounts) AS min_open_accounts,

    MAX(
        CASE
            WHEN row_num = CEIL(total_rows * 0.25)
            THEN open_accounts
        END
    ) AS p25_open_accounts,

    AVG(
        CASE
            WHEN row_num IN (
                FLOOR((total_rows + 1) / 2),
                CEIL((total_rows + 1) / 2)
            )
            THEN open_accounts
        END
    ) AS median_open_accounts,

    ROUND(
        AVG(open_accounts),
        2
    ) AS average_open_accounts,

    MAX(
        CASE
            WHEN row_num = CEIL(total_rows * 0.75)
            THEN open_accounts
        END
    ) AS p75_open_accounts,

    MAX(open_accounts) AS max_open_accounts

FROM ranked_open_accounts;


-- ------------------------------------------------------------
-- 3.2 Default behavior by open-account band
-- ------------------------------------------------------------
-- Business question:
-- Does the number of open accounts show a meaningful default pattern?
--
-- Analytical bands:
-- <5
-- 5-9
-- 10-14
-- 15+
-- ------------------------------------------------------------

WITH params AS (
    SELECT 100 AS min_sample_size
),

open_account_segments AS (
    SELECT
        CASE
            WHEN open_accounts IS NULL THEN 'Unknown'
            WHEN open_accounts < 5 THEN '<5'
            WHEN open_accounts < 10 THEN '5-9'
            WHEN open_accounts < 15 THEN '10-14'
            ELSE '15+'
        END AS open_account_band,

        CASE
            WHEN open_accounts IS NULL THEN 99
            WHEN open_accounts < 5 THEN 1
            WHEN open_accounts < 10 THEN 2
            WHEN open_accounts < 15 THEN 3
            ELSE 4
        END AS band_order,

        loan_status,
        loan_amnt

    FROM credit_risk_clean
),

segment_summary AS (
    SELECT
        open_account_band,
        band_order,

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

    FROM open_account_segments

    GROUP BY
        open_account_band,
        band_order
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
    s.open_account_band,

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
        WHEN s.loan_count >= prm.min_sample_size
        THEN 'Enough sample'
        ELSE 'Small sample'
    END AS sample_size_status

FROM segment_summary AS s
CROSS JOIN portfolio_totals AS p
CROSS JOIN params AS prm

ORDER BY s.band_order;


-- ============================================================
-- 4. PAST DELINQUENCIES
-- ============================================================

-- ------------------------------------------------------------
-- 4.1 Past-delinquency distribution checkpoint
-- ------------------------------------------------------------
-- Business question:
-- How concentrated are borrowers at zero, one, or multiple
-- past delinquency events?
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS valid_delinquency_observations,

    MIN(past_delinquencies) AS min_past_delinquencies,

    ROUND(
        AVG(past_delinquencies),
        4
    ) AS average_past_delinquencies,

    MAX(past_delinquencies) AS max_past_delinquencies,

    SUM(
        CASE
            WHEN past_delinquencies = 0 THEN 1
            ELSE 0
        END
    ) AS zero_delinquency_loans,

    SUM(
        CASE
            WHEN past_delinquencies = 1 THEN 1
            ELSE 0
        END
    ) AS one_delinquency_loans,

    SUM(
        CASE
            WHEN past_delinquencies >= 2 THEN 1
            ELSE 0
        END
    ) AS multiple_delinquency_loans

FROM credit_risk_clean

WHERE past_delinquencies IS NOT NULL;


-- ------------------------------------------------------------
-- 4.2 Default behavior by past-delinquency band
-- ------------------------------------------------------------
-- Business question:
-- Is current default behavior materially different between borrowers
-- with no, one, or multiple past delinquencies?
-- ------------------------------------------------------------

WITH params AS (
    SELECT 100 AS min_sample_size
),

delinquency_segments AS (
    SELECT
        CASE
            WHEN past_delinquencies IS NULL THEN 'Unknown'
            WHEN past_delinquencies = 0 THEN '0'
            WHEN past_delinquencies = 1 THEN '1'
            ELSE '2+'
        END AS delinquency_band,

        CASE
            WHEN past_delinquencies IS NULL THEN 99
            WHEN past_delinquencies = 0 THEN 1
            WHEN past_delinquencies = 1 THEN 2
            ELSE 3
        END AS band_order,

        loan_status,
        loan_amnt

    FROM credit_risk_clean
),

segment_summary AS (
    SELECT
        delinquency_band,
        band_order,

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

    FROM delinquency_segments

    GROUP BY
        delinquency_band,
        band_order
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
    s.delinquency_band,

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
        WHEN s.loan_count >= prm.min_sample_size
        THEN 'Enough sample'
        ELSE 'Small sample'
    END AS sample_size_status

FROM segment_summary AS s
CROSS JOIN portfolio_totals AS p
CROSS JOIN params AS prm

ORDER BY s.band_order;


-- ============================================================
-- 5. PREVIOUS DEFAULT x EMPLOYMENT STABILITY
-- ============================================================

-- ------------------------------------------------------------
-- 5.1 Previous default combined with employment stability
-- ------------------------------------------------------------
-- Business question:
-- Does previous default become more informative when combined with
-- short employment tenure?
--
-- Employment groups:
-- <4 years
-- 4+ years
-- Unknown
--
-- The <4-year split is consistent with the finding in file 05 that
-- shorter employment tenure had a higher observed default rate.
--
-- This is an interaction analysis, NOT a final risk segment.
-- ------------------------------------------------------------

WITH params AS (
    SELECT 100 AS min_sample_size
),

stability_base AS (
    SELECT
        COALESCE(
            NULLIF(TRIM(cb_person_default_on_file), ''),
            'Unknown'
        ) AS previous_default_status,

        CASE
            WHEN person_emp_length IS NULL THEN 'Unknown'
            WHEN person_emp_length < 4 THEN '<4 years'
            ELSE '4+ years'
        END AS employment_stability_group,

        CASE
            WHEN person_emp_length IS NULL THEN 99
            WHEN person_emp_length < 4 THEN 1
            ELSE 2
        END AS employment_order,

        loan_status,
        loan_amnt

    FROM credit_risk_clean
),

segment_summary AS (
    SELECT
        previous_default_status,
        employment_stability_group,
        employment_order,

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

    FROM stability_base

    GROUP BY
        previous_default_status,
        employment_stability_group,
        employment_order
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
    s.previous_default_status,
    s.employment_stability_group,

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
    CASE s.previous_default_status
        WHEN 'N' THEN 1
        WHEN 'Y' THEN 2
        ELSE 99
    END,
    s.employment_order;


-- ============================================================
-- 6. PREVIOUS DEFAULT x HOME OWNERSHIP
-- ============================================================

-- ------------------------------------------------------------
-- 6.1 Previous default combined with home ownership
-- ------------------------------------------------------------
-- Business question:
-- Does previous-default history show a different risk pattern across
-- housing-stability groups?
--
-- File 05 showed strong differences by home ownership.
-- This query checks whether previous default adds further separation.
--
-- This is an interaction analysis, NOT a final risk segment.
-- ------------------------------------------------------------

WITH params AS (
    SELECT 100 AS min_sample_size
),

housing_base AS (
    SELECT
        COALESCE(
            NULLIF(TRIM(cb_person_default_on_file), ''),
            'Unknown'
        ) AS previous_default_status,

        COALESCE(
            NULLIF(TRIM(person_home_ownership), ''),
            'Unknown'
        ) AS home_ownership,

        loan_status,
        loan_amnt

    FROM credit_risk_clean
),

segment_summary AS (
    SELECT
        previous_default_status,
        home_ownership,

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

    FROM housing_base

    GROUP BY
        previous_default_status,
        home_ownership
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
    s.previous_default_status,
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
    CASE s.previous_default_status
        WHEN 'N' THEN 1
        WHEN 'Y' THEN 2
        ELSE 99
    END,
    default_rate_pct DESC,
    s.loan_count DESC;


-- ============================================================
-- 7. PREVIOUS DEFAULT x DELINQUENCY HISTORY
-- ============================================================

-- ------------------------------------------------------------
-- 7.1 Previous default combined with past delinquency history
-- ------------------------------------------------------------
-- Business question:
-- Does combining two credit-behavior indicators produce stronger
-- separation than either characteristic alone?
--
-- Delinquency grouping:
-- No Past Delinquency = 0
-- Past Delinquency = 1+
--
-- This is an interaction check, not final segmentation.
-- ------------------------------------------------------------

WITH params AS (
    SELECT 100 AS min_sample_size
),

credit_behavior_base AS (
    SELECT
        COALESCE(
            NULLIF(TRIM(cb_person_default_on_file), ''),
            'Unknown'
        ) AS previous_default_status,

        CASE
            WHEN past_delinquencies IS NULL
                THEN 'Unknown'
            WHEN past_delinquencies = 0
                THEN 'No Past Delinquency'
            ELSE 'Past Delinquency'
        END AS delinquency_history_group,

        CASE
            WHEN past_delinquencies IS NULL THEN 99
            WHEN past_delinquencies = 0 THEN 1
            ELSE 2
        END AS delinquency_order,

        loan_status,
        loan_amnt

    FROM credit_risk_clean
),

segment_summary AS (
    SELECT
        previous_default_status,
        delinquency_history_group,
        delinquency_order,

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

    FROM credit_behavior_base

    GROUP BY
        previous_default_status,
        delinquency_history_group,
        delinquency_order
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
    s.previous_default_status,
    s.delinquency_history_group,

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
    CASE s.previous_default_status
        WHEN 'N' THEN 1
        WHEN 'Y' THEN 2
        ELSE 99
    END,
    s.delinquency_order;


-- ============================================================
-- 8. CREDIT AND STABILITY CHECKPOINT
-- ============================================================

-- ------------------------------------------------------------
-- 8.1 Compare selected credit/stability review conditions
-- ------------------------------------------------------------
-- Business question:
-- Which credit-history or borrower-stability conditions combine
-- meaningful default rates with meaningful portfolio exposure?
--
-- IMPORTANT:
-- These conditions overlap.
-- Do NOT add their loan counts or exposure values together.
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
        'Previous Default = Y',
        loan_status,
        loan_amnt
    FROM credit_risk_clean
    WHERE TRIM(cb_person_default_on_file) = 'Y'

    UNION ALL

    SELECT
        'Credit History < 3 Years',
        loan_status,
        loan_amnt
    FROM credit_risk_clean
    WHERE cb_person_cred_hist_length < 3

    UNION ALL

    SELECT
        'Past Delinquency >= 1',
        loan_status,
        loan_amnt
    FROM credit_risk_clean
    WHERE past_delinquencies >= 1

    UNION ALL

    SELECT
        'Employment Length < 4 Years',
        loan_status,
        loan_amnt
    FROM credit_risk_clean
    WHERE person_emp_length < 4

    UNION ALL

    SELECT
        'Home Ownership = RENT',
        loan_status,
        loan_amnt
    FROM credit_risk_clean
    WHERE TRIM(person_home_ownership) = 'RENT'

    UNION ALL

    SELECT
        'Previous Default = Y AND Employment < 4 Years',
        loan_status,
        loan_amnt
    FROM credit_risk_clean
    WHERE TRIM(cb_person_default_on_file) = 'Y'
      AND person_emp_length < 4

    UNION ALL

    SELECT
        'Previous Default = Y AND Home = RENT',
        loan_status,
        loan_amnt
    FROM credit_risk_clean
    WHERE TRIM(cb_person_default_on_file) = 'Y'
      AND TRIM(person_home_ownership) = 'RENT'

    UNION ALL

    SELECT
        'Previous Default = Y AND Past Delinquency >= 1',
        loan_status,
        loan_amnt
    FROM credit_risk_clean
    WHERE TRIM(cb_person_default_on_file) = 'Y'
      AND past_delinquencies >= 1
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
        WHEN 'Previous Default = Y' THEN 2
        WHEN 'Credit History < 3 Years' THEN 3
        WHEN 'Past Delinquency >= 1' THEN 4
        WHEN 'Employment Length < 4 Years' THEN 5
        WHEN 'Home Ownership = RENT' THEN 6
        WHEN 'Previous Default = Y AND Employment < 4 Years' THEN 7
        WHEN 'Previous Default = Y AND Home = RENT' THEN 8
        WHEN 'Previous Default = Y AND Past Delinquency >= 1' THEN 9
        ELSE 99
    END;


-- ============================================================
-- END OF 08_CREDIT_AND_STABILITY.SQL
-- ============================================================
-- REVIEW CHECKPOINT
--
-- Run one numbered query at a time.
--
-- Priority outputs for interpretation:
-- 1.1 Previous default
-- 2.2 Credit-history bands
-- 3.2 Open-account bands
-- 4.2 Past-delinquency bands
-- 5.1 Previous default x employment stability
-- 6.1 Previous default x home ownership
-- 7.1 Previous default x delinquency history
-- 8.1 Credit and stability checkpoint
--
-- Questions to answer before file 09:
--
-- 1. Does previous default remain a strong historical risk signal?
--
-- 2. Does a longer credit history materially reduce observed
--    default risk, or is the relationship weak?
--
-- 3. Does the number of open accounts provide useful separation?
--
-- 4. Do past delinquencies provide a stronger signal after banding,
--    even though their aggregate averages were nearly identical in 04?
--
-- 5. Does previous default become substantially more informative
--    when combined with short employment tenure?
--
-- 6. Does previous default become more concentrated among RENT
--    borrowers?
--
-- 7. Does combining previous default and delinquency history create
--    a materially higher-risk credit-behavior group?
--
-- 8. Which conditions combine:
--    - high default rate,
--    - meaningful loan count,
--    - meaningful loan exposure,
--    - and meaningful share of total default exposure?
--
-- Do NOT build final risk scores or approval rules in this file.
-- Final geographic and multi-factor segmentation belongs to file 09.
-- ============================================================
