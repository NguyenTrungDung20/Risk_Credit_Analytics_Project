# Risk Credit Analytics - Data Dictionary

Raw table: `credit_risk_raw`

Current import policy: all columns are stored as `VARCHAR` in the raw table so profiling can detect blanks, invalid text, and type issues before cleaning.

| Column | Business meaning | Target type after cleaning | Profiling focus |
|---|---|---:|---|
| `client_ID` | Unique borrower/customer identifier | VARCHAR | Blank IDs, duplicate IDs |
| `person_age` | Borrower age | INT | Non-numeric values, unrealistic ages |
| `person_income` | Borrower annual income | DECIMAL | Non-positive income, outliers |
| `person_home_ownership` | Housing/ownership status | VARCHAR/category | Valid category set, default rate by category |
| `person_emp_length` | Employment length in years | DECIMAL | Blanks, impossible employment length vs age |
| `loan_intent` | Loan purpose | VARCHAR/category | Valid category set, default rate by purpose |
| `loan_grade` | Loan risk grade | VARCHAR/category | Valid grade order, default rate by grade |
| `loan_amnt` | Loan amount | DECIMAL | Non-positive values, outliers |
| `loan_int_rate` | Interest rate | DECIMAL | Blanks, non-positive values, risk bands |
| `loan_status` | Binary loan outcome; business mapping of `0` and `1` must be source-confirmed | TINYINT | Only values `0` and `1`, class balance |
| `loan_percent_income` | Loan amount as percent of income, rounded | DECIMAL | Consistency with loan-to-income ratio |
| `cb_person_default_on_file` | Previous default flag on credit bureau file | VARCHAR/category | Only expected flags, default rate by flag |
| `cb_person_cred_hist_length` | Credit history length in years | DECIMAL | Range and relationship with age |
| `gender` | Borrower gender | VARCHAR/category | Category completeness |
| `marital_status` | Borrower marital status | VARCHAR/category | Category completeness |
| `education_level` | Borrower education level | VARCHAR/category | Category completeness |
| `country` | Borrower country | VARCHAR/category | Country coverage: USA, UK, Canada |
| `state` | Borrower state/province/region | VARCHAR/category | Geographic completeness |
| `city` | Borrower city | VARCHAR/category | Geographic completeness |
| `city_latitude` | City latitude | DECIMAL | Coordinate validity |
| `city_longitude` | City longitude | DECIMAL | Coordinate validity |
| `employment_type` | Employment category | VARCHAR/category | Category set, default rate by employment |
| `loan_term_months` | Loan term in months | INT | Valid term values and risk by term |
| `loan_to_income_ratio` | Loan amount divided by income | DECIMAL | Consistency with `loan_amnt / person_income` |
| `other_debt` | Borrower's other debt amount | DECIMAL | Range and DTI consistency |
| `debt_to_income_ratio` | Total debt burden divided by income | DECIMAL | Consistency with `(loan_amnt + other_debt) / person_income` |
| `open_accounts` | Number of open credit accounts | INT | Negative/non-integer values, range |
| `credit_utilization_ratio` | Utilized credit share | DECIMAL | Expected range `0` to `1` |
| `past_delinquencies` | Number of previous delinquencies | INT | Negative/non-integer values, relationship with default |

## Clean-Layer Audit Fields

`credit_risk_clean` adds the following fields without changing
`credit_risk_raw`:

| Column | Meaning |
|---|---|
| `source_loan_percent_income` | Original raw ratio retained for audit |
| `is_age_invalid` | Source age was outside 18-100 |
| `is_emp_length_missing` | Source employment length was blank |
| `is_emp_length_invalid` | Source employment length was negative or greater than age |
| `is_loan_int_rate_missing` | Source interest rate was blank |
| `is_loan_percent_income_mismatch` | Source ratio differed from canonical two-decimal value |
| `is_loan_percent_income_material_mismatch` | Absolute source ratio difference exceeded 0.01 |
| `is_high_dti` | Source DTI exceeded 1; retained as a review flag |
