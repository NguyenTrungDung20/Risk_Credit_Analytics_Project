# Risk Credit Analytics Project

Credit risk analytics project covering data profiling, cleaning, EDA, risk segmentation, semantic Power BI views, and dashboard layout preparation.

## Repository Contents

- `sql/`: MySQL scripts for profiling, cleaning, validation, EDA, segmentation, and Power BI semantic views.
- `insights/`: Business insight summaries derived from the SQL analysis.
- `results/`: Aggregated query outputs used during analysis.
- `docs/`: Data dictionary, cleaning rules, EDA plan, and workflow notes.
- `ingestion/`: Notebook for importing the local CSV into MySQL.
- `powerbi/`: Power BI dashboard guidance and layout-generation script.

## Security Notes

The repository intentionally excludes:

- raw and processed CSV files in `data/`
- `.pbix` / `.pbit` files, because they can embed data and local metadata
- local virtual environments, editor settings, temp PBIX extracts, and credentials

Use `.env.example` as a template for local configuration. Do not commit real passwords or tokens.

## Local Setup

1. Place the dataset locally at `data/raw/Credit_Risk_Dataset.csv`.
2. Set `MYSQL_PASSWORD` in your local environment.
3. Run the ingestion notebook in `ingestion/`.
4. Execute SQL scripts in order.
5. Rebuild Power BI visuals locally from the semantic views and dashboard scripts.

## Power BI

The completed `.pbix` is kept local for privacy. The script below documents/recreates the report layout work:

```text
powerbi/complete_dashboard_layout.py
```
