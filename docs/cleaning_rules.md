# Risk Credit Analytics - Cleaning Rules Log

Source table: `credit_risk_raw`

Target table: `credit_risk_clean`

The raw table remains unchanged. Cleaning is implemented only in
`sql/02_data_cleaning.sql`.

## Profiling Baseline

| Check | Observed result |
|---|---:|
| Raw rows | 32,581 |
| Populated and distinct `client_ID` values | 32,581 |
| Duplicate IDs / exact duplicates / business duplicates | 0 / 0 / 0 |
| Non-numeric populated values in numeric fields | 0 |
| Blank `person_emp_length` | 895 (2.75%) |
| Blank `loan_int_rate` | 3,116 (9.56%) |
| Age above 100 | 5 |
| Employment length above age | 2 |
| DTI above 1 | 4 |
| Invalid coordinates | 0 |
| Source `loan_percent_income` not equal to rounded LTI | 651 |
| Material `loan_percent_income` mismatch above 0.01 | 388 |

## Rule 1 - Preserve Raw Data and Row Grain

**Observed issue:** Cleaning must not destroy source evidence or alter the
observed one-row-per-`client_ID` grain.

**Evidence from profiling:** All 32,581 IDs are populated and unique. No
duplicate rows were found.

**Business/data rationale:** Auditability requires the imported layer to remain
reproducible.

**Proposed treatment:** Rebuild `credit_risk_clean` from the raw table. Do not
update or delete raw rows. Add `client_ID` as the clean primary key.

**Impact:** Expected clean row count remains 32,581.

**Validation query:** `02_data_cleaning.sql`, sections 3.1 and 3.2.

## Rule 2 - Trim Text, Convert Blanks, and Cast Types

**Observed issue:** All raw columns are `VARCHAR`; two numeric fields use empty
strings for missing values.

**Evidence from profiling:** Every populated numeric value passed numeric
type-readiness. `person_emp_length` has 895 blanks and `loan_int_rate` has
3,116 blanks.

**Business/data rationale:** Numeric types are required for SQL aggregation and
Power BI measures. Missing values must not be represented as zero.

**Proposed treatment:** Apply `TRIM` to text, convert empty strings to `NULL`,
and cast numeric fields to explicit integer or decimal types. Do not impute
employment length or interest rate at this stage.

**Impact:** No rows are removed. Interest rate has 3,116 SQL `NULL` values;
employment length has at least 895 SQL `NULL` values.

**Validation query:** `02_data_cleaning.sql`, sections 3.4 and 3.6.

## Rule 3 - Invalid Age

**Observed issue:** Some ages are outside the review range.

**Evidence from profiling:** Five rows have `person_age > 100`; no row has age
below 18. The observed maximum is 144.

**Business/data rationale:** These values are implausible for the lending
population and can distort age-based analysis. The correct replacement age is
unknown.

**Proposed treatment:** Set age outside 18-100 to `NULL` in the clean table and
set `is_age_invalid = 1`. Keep the row.

**Impact:** Five cleaned ages are expected to become `NULL`.

**Validation query:** `02_data_cleaning.sql`, sections 3.3 and 3.4.

## Rule 4 - Missing or Impossible Employment Length

**Observed issue:** Employment length is missing or greater than borrower age.

**Evidence from profiling:** There are 895 blanks and two values greater than
age. The maximum employment length is 123.

**Business/data rationale:** Employment length greater than age is logically
invalid. No reliable replacement value is available.

**Proposed treatment:** Convert blanks and values greater than age to `NULL`.
Use separate missing and invalid flags. Do not delete or impute rows.

**Impact:** The 895 missing and two invalid groups are disjoint, so 897
employment-length values are expected to be `NULL`.

**Validation query:** `02_data_cleaning.sql`, sections 3.3 and 3.4.

## Rule 5 - Missing Interest Rate

**Observed issue:** Interest rate is absent for part of the portfolio.

**Evidence from profiling:** 3,116 rows (9.56%) contain an empty interest-rate
string. Populated rates range from 5.42 to 23.22 and are numeric.

**Business/data rationale:** Imputation could create artificial pricing and
risk relationships.

**Proposed treatment:** Convert blanks to SQL `NULL` and set
`is_loan_int_rate_missing = 1`. Do not impute in the base clean table.

**Impact:** Interest-rate analyses must report the valid observation count or
include a missing category.

**Validation query:** `02_data_cleaning.sql`, sections 3.3 and 3.4.

## Rule 6 - Inconsistent Loan Percent Income

**Observed issue:** The recorded rounded affordability field is not always
consistent with the current loan amount and income.

**Evidence from profiling:** 651 rows differ from rounded LTI; 388 differ by
more than 0.01. All 388 material mismatches are below the calculated value,
with average signed difference -0.033059 and maximum absolute difference
0.093382.

**Business/data rationale:** `loan_percent_income` is a derived field and must
be consistent with the validated base fields used for affordability analysis.

**Proposed treatment:** Preserve the source value as
`source_loan_percent_income`. Recalculate clean `loan_percent_income` as
`ROUND(loan_amnt / person_income, 2)`. Add mismatch flags.

**Impact:** 651 clean values may differ from their recorded source value; 388
are material changes under the profiling threshold.

**Validation query:** `02_data_cleaning.sql`, sections 3.3 and 3.5.

## Rule 7 - Canonical LTI and DTI

**Observed issue:** LTI and DTI are derived measures duplicated in the source.

**Evidence from profiling:** No LTI mismatch above 0.001 and no DTI mismatch
above 0.001 were found across 32,581 comparable rows.

**Business/data rationale:** Recalculation establishes one transparent formula
and prevents future drift between base and derived fields.

**Proposed treatment:** Calculate LTI as `loan_amnt / person_income` and DTI as
`(loan_amnt + other_debt) / person_income`, rounded to nine decimal places.

**Impact:** Expected analytical values remain within the validated source
tolerance.

**Validation query:** `02_data_cleaning.sql`, section 3.5.

## Rule 8 - High DTI and Extreme Monetary Values

**Observed issue:** Four DTI values exceed 1; income and other debt contain
large upper-tail values.

**Evidence from profiling:** Maximum DTI is 1.053888087, maximum income is
6,000,000, and maximum other debt is 1,187,998.914.

**Business/data rationale:** These values can represent genuine high-income or
high-debt borrowers. Profiling does not prove they are data-entry errors.

**Proposed treatment:** Retain the values without capping, winsorizing, or row
deletion. Set `is_high_dti = 1` when DTI exceeds 1.

**Impact:** Distribution summaries remain sensitive to real upper-tail values;
median and percentile measures should accompany averages during EDA.

**Validation query:** `02_data_cleaning.sql`, section 3.3.

## Rule 9 - Target Preservation

**Observed issue:** `loan_status` is stored as text in raw data.

**Evidence from profiling:** The only values are `0` and `1`, with shares
78.18% and 21.82% respectively.

**Business/data rationale:** A numeric binary outcome is appropriate for later
aggregation, but profiling alone does not establish the business meaning of
each value.

**Proposed treatment:** Cast the values to `TINYINT` and preserve them without
recoding. Confirm the 0/1 business mapping from source documentation before
labeling either class as default.

**Impact:** No target values or rows are changed.

**Validation query:** `02_data_cleaning.sql`, sections 3.2 and 3.6.
