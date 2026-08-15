# Data Directory

Raw and processed CSV files are intentionally excluded from git.

Expected local files:

```text
data/raw/Credit_Risk_Dataset.csv
data/processed/Credit_Risk_Dataset.csv
```

Reason: the dataset contains loan-level borrower records, demographic fields, geography, and client identifiers. Keep those files local unless you intentionally publish a sanitized sample.
