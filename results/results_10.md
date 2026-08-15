[
  {
    "TABLE_SCHEMA": "risk_credit_analytics",
    "TABLE_NAME": "credit_risk_clean",
    "TABLE_TYPE": "BASE TABLE"
  }
]

[
  {
    "COLUMN_NAME": "cb_person_cred_hist_length",
    "DATA_TYPE": "decimal"
  },
  {
    "COLUMN_NAME": "cb_person_default_on_file",
    "DATA_TYPE": "varchar"
  },
  {
    "COLUMN_NAME": "city",
    "DATA_TYPE": "varchar"
  },
  {
    "COLUMN_NAME": "city_latitude",
    "DATA_TYPE": "decimal"
  },
  {
    "COLUMN_NAME": "city_longitude",
    "DATA_TYPE": "decimal"
  },
  {
    "COLUMN_NAME": "client_ID",
    "DATA_TYPE": "varchar"
  },
  {
    "COLUMN_NAME": "country",
    "DATA_TYPE": "varchar"
  },
  {
    "COLUMN_NAME": "credit_utilization_ratio",
    "DATA_TYPE": "decimal"
  },
  {
    "COLUMN_NAME": "debt_to_income_ratio",
    "DATA_TYPE": "decimal"
  },
  {
    "COLUMN_NAME": "loan_amnt",
    "DATA_TYPE": "decimal"
  },
  {
    "COLUMN_NAME": "loan_grade",
    "DATA_TYPE": "varchar"
  },
  {
    "COLUMN_NAME": "loan_int_rate",
    "DATA_TYPE": "decimal"
  },
  {
    "COLUMN_NAME": "loan_intent",
    "DATA_TYPE": "varchar"
  },
  {
    "COLUMN_NAME": "loan_status",
    "DATA_TYPE": "tinyint"
  },
  {
    "COLUMN_NAME": "loan_term_months",
    "DATA_TYPE": "smallint"
  },
  {
    "COLUMN_NAME": "loan_to_income_ratio",
    "DATA_TYPE": "decimal"
  },
  {
    "COLUMN_NAME": "open_accounts",
    "DATA_TYPE": "smallint"
  },
  {
    "COLUMN_NAME": "other_debt",
    "DATA_TYPE": "decimal"
  },
  {
    "COLUMN_NAME": "past_delinquencies",
    "DATA_TYPE": "smallint"
  },
  {
    "COLUMN_NAME": "person_age",
    "DATA_TYPE": "smallint"
  },
  {
    "COLUMN_NAME": "person_emp_length",
    "DATA_TYPE": "decimal"
  },
  {
    "COLUMN_NAME": "person_home_ownership",
    "DATA_TYPE": "varchar"
  },
  {
    "COLUMN_NAME": "person_income",
    "DATA_TYPE": "decimal"
  },
  {
    "COLUMN_NAME": "state",
    "DATA_TYPE": "varchar"
  }
]

[
  {
    "TABLE_NAME": "vw_credit_risk_detail",
    "TABLE_TYPE": "VIEW"
  },
  {
    "TABLE_NAME": "vw_geography",
    "TABLE_TYPE": "VIEW"
  },
  {
    "TABLE_NAME": "vw_powerbi_qa",
    "TABLE_TYPE": "VIEW"
  },
  {
    "TABLE_NAME": "vw_segment_candidates",
    "TABLE_TYPE": "VIEW"
  }
]

[
  {
    "total_loans": "32581",
    "distinct_clients": "32581",
    "non_default_loans": "25473",
    "default_loans": "7108",
    "default_rate_pct": "21.82",
    "loan_exposure": "312431300.00",
    "default_exposure": "77125375.00",
    "average_loan_amount": "9589.37",
    "average_interest_rate": "11.01",
    "valid_interest_rate_loans": "29465",
    "interest_rate_coverage_pct": "90.44",
    "complete_geography_coverage_pct": "100.00",
    "coordinate_coverage_pct": "100.00",
    "grain_check_status": "PASS - One row per client/loan"
  }
]

[
  {
    "detail_rows": "32581",
    "distinct_clients": "32581",
    "duplicate_rows": "0"
  }
]

[
  {
    "geography_rows": "18",
    "distinct_geo_keys": "18"
  }
]

[
  {
    "segment_sort": "1",
    "segment_family": "Loan + Affordability",
    "segment_type": "Observed Risk Concentration",
    "segment_name": "Grade D-G AND LTI >= 0.30",
    "loan_count": "892",
    "default_count": "736",
    "default_rate_pct": "82.51",
    "loan_exposure": "16042000.00",
    "default_exposure": "12957250.00"
  },
  {
    "segment_sort": "2",
    "segment_family": "Credit + Housing + Affordability",
    "segment_type": "Observed Risk Concentration",
    "segment_name": "Previous Default = Y AND RENT AND Affordability Elevated",
    "loan_count": "833",
    "default_count": "645",
    "default_rate_pct": "77.43",
    "loan_exposure": "11650400.00",
    "default_exposure": "9321025.00"
  },
  {
    "segment_sort": "3",
    "segment_family": "Loan + Affordability",
    "segment_type": "Observed Risk Concentration",
    "segment_name": "Grade D-G AND DTI >= 0.45",
    "loan_count": "1281",
    "default_count": "930",
    "default_rate_pct": "72.60",
    "loan_exposure": "21202125.00",
    "default_exposure": "15301325.00"
  },
  {
    "segment_sort": "4",
    "segment_family": "Affordability",
    "segment_type": "Observed Risk Concentration",
    "segment_name": "LTI >= 0.30 AND DTI >= 0.45",
    "loan_count": "3453",
    "default_count": "2367",
    "default_rate_pct": "68.55",
    "loan_exposure": "55056950.00",
    "default_exposure": "36040850.00"
  },
  {
    "segment_sort": "5",
    "segment_family": "Credit + Affordability",
    "segment_type": "Observed Risk Concentration",
    "segment_name": "Previous Default = Y AND Affordability Elevated",
    "loan_count": "1385",
    "default_count": "836",
    "default_rate_pct": "60.36",
    "loan_exposure": "21080100.00",
    "default_exposure": "12627075.00"
  },
  {
    "segment_sort": "6",
    "segment_family": "Credit + Stability",
    "segment_type": "Observed Risk Concentration",
    "segment_name": "Previous Default = Y AND RENT",
    "loan_count": "3278",
    "default_count": "1536",
    "default_rate_pct": "46.86",
    "loan_exposure": "29752075.00",
    "default_exposure": "15732400.00"
  },
  {
    "segment_sort": "7",
    "segment_family": "Borrower Stability",
    "segment_type": "Observed Risk Concentration",
    "segment_name": "Income <50K AND RENT",
    "loan_count": "8657",
    "default_count": "3639",
    "default_rate_pct": "42.04",
    "loan_exposure": "60128475.00",
    "default_exposure": "31593325.00"
  },
  {
    "segment_sort": "8",
    "segment_family": "Borrower Stability",
    "segment_type": "Observed Risk Concentration",
    "segment_name": "Income <50K AND Employment <4 Years",
    "loan_count": "6894",
    "default_count": "2492",
    "default_rate_pct": "36.15",
    "loan_exposure": "46726900.00",
    "default_exposure": "19963950.00"
  },
  {
    "segment_sort": "9",
    "segment_family": "Portfolio Quality",
    "segment_type": "Lower Observed Risk",
    "segment_name": "Grade A-B AND LTI <0.20 AND DTI <0.35 AND Previous Default = N",
    "loan_count": "11234",
    "default_count": "621",
    "default_rate_pct": "5.53",
    "loan_exposure": "76523175.00",
    "default_exposure": "3242550.00"
  }
]

