# Dashboard Completion Notes

Generated file:

```text
powerbi/Risk_Credit_Analytics_Project_completed.pbix
```

The completed copy is repackaged without the optional `SecurityBindings` entry so Power BI Desktop can regenerate it on save.

Original file is unchanged:

```text
powerbi/Risk_Credit_Analytics_Project.pbix
```

## What Was Added

- `Credit Risk Overview`: added Default Rate by Affordability Group and a business insight text block.
- `Borrower Profile`: added slicers, KPI cards, borrower risk charts, and income by outcome comparison.
- `Loan & Affordability Risk`: added slicers, KPI cards, grade/rate/LTI/DTI/affordability charts, and LTI x DTI detail table.
- `Credit Profile & Geography`: added slicers, KPI cards, credit history/utilization/delinquency charts, map visual, and geography ranking table.
- `Risk Segmentation & Recommendations`: added segment slicers, segment KPI cards, segment risk charts, risk scatter, and segment detail table.

## Model Mapping Used

- Main fact table: `Fact_loans`
- Geography table: `Dim_Geography`
- Segment membership table: `Fact_SegmentMembership`
- Existing measure table: `_Measures`

The model currently has 9 core DAX measures:

- `Total Loans`
- `Distinct Clients`
- `Default Loans`
- `Non-Default Loans`
- `Default Rate`
- `Loan Exposure`
- `Default Exposure`
- `Avg Loan Amount`
- `Avg Interest Rate`

Other KPI cards use Power BI implicit aggregations such as Average Income, Average Age, Average LTI, Average DTI, and segment exposure sums.

## Check After Opening

Open the completed PBIX copy and check these visuals first:

- Geography map on `Credit Profile & Geography`
- Risk scatter on `Risk Segmentation & Recommendations`
- Segment Count card

Those use generated layout JSON for visual types that were not present in the original first page. All referenced fields exist in the model, but Power BI Desktop should still be used for final visual rendering QA.
