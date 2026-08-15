# Power BI Dashboard Mindset Guide

**Project:** Risk_Credit_Analytics_Project  
**Giai đoạn:** Chuyển từ EDA sang Power BI  
**Workflow:** MySQL → Semantic Layer → Power BI  
**Mục tiêu:** Chuẩn hóa tư duy trước khi viết `10_powerbi_views.sql` và thiết kế Dashboard.

---

# 1. Điểm chuyển giai đoạn quan trọng

Sau khi hoàn thành:

```text
04_overall_risk.sql
05_borrower_profile.sql
06_loan_analysis.sql
07_financial_risk.sql
08_credit_and_stability.sql
09_geography_and_segmentation.sql
```

giai đoạn EDA có thể xem như đã hoàn thành.

Từ đây, mindset cần chuyển từ:

> “Dữ liệu còn điều gì để khám phá?”

sang:

> “Những gì đã khám phá được cần được đóng gói như thế nào để Power BI sử dụng ổn định, dễ hiểu và hỗ trợ ra quyết định?”

Có thể hình dung:

```text
04-09
=
Discovery Layer

10_powerbi_views.sql
=
Publishing / Semantic Layer

Power BI
=
Presentation + Interaction Layer
```

---

# 2. Vai trò của `10_powerbi_views.sql`

`10_powerbi_views.sql` không phải nơi tiếp tục EDA.

Nó không nên tạo thêm hàng chục query phân tích mới.

Vai trò chính là:

```text
EDA Findings
      ↓
Chuẩn hóa business logic
      ↓
Tạo Views ổn định
      ↓
Power BI Data Model
```

Nói cách khác:

> `10_powerbi_views.sql` phải biến những findings đã được xác nhận thành một lớp dữ liệu ổn định dành riêng cho Power BI.

---

# 3. Không biến từng query EDA thành một View

Một lỗi phổ biến là tạo:

```text
vw_income_analysis
vw_home_analysis
vw_lti_analysis
vw_dti_analysis
vw_grade_analysis
vw_interest_analysis
vw_city_analysis
...
```

Điều này khiến Power BI:

- Có quá nhiều bảng.
- Khó thiết lập relationship.
- Khó dùng slicer.
- Dễ sai tổng.
- Khó bảo trì.
- Khó giải thích cho stakeholder.

Mindset tốt hơn là:

> Phần lớn dashboard phải chạy từ một bảng chi tiết trung tâm.

---

# 4. View quan trọng nhất: `vw_credit_risk_detail`

Đây nên là Fact View chính của Power BI.

Nguyên tắc:

```text
1 row
=
1 loan
```

Với dataset hiện tại:

```text
32,581 rows
```

Power BI hoàn toàn có thể xử lý trực tiếp ở mức chi tiết.

View này nên chứa dữ liệu sạch từ:

```text
credit_risk_clean
```

và bổ sung các business bands đã được kiểm tra trong EDA.

---

# 5. Cấu trúc tư duy của `vw_credit_risk_detail`

```text
vw_credit_risk_detail
│
├── ID
│   └── client_id
│
├── Outcome
│   ├── loan_status
│   └── loan_outcome
│
├── Borrower
│   ├── person_age
│   ├── age_band
│   ├── person_income
│   ├── income_band
│   ├── person_emp_length
│   ├── employment_length_band
│   └── person_home_ownership
│
├── Loan
│   ├── loan_intent
│   ├── loan_grade
│   ├── grade_group
│   ├── loan_amnt
│   ├── loan_amount_band
│   ├── loan_int_rate
│   ├── interest_rate_band
│   └── loan_term_months
│
├── Financial Risk
│   ├── loan_to_income_ratio
│   ├── lti_band
│   ├── debt_to_income_ratio
│   ├── dti_band
│   ├── affordability_group
│   └── credit_utilization_ratio
│
├── Credit History
│   ├── cb_person_default_on_file
│   ├── cb_person_cred_hist_length
│   ├── open_accounts
│   └── past_delinquencies
│
├── Geography
│   ├── country
│   ├── state
│   ├── city
│   ├── city_latitude
│   └── city_longitude
│
└── Analytical Flags
    ├── is_grade_dg
    ├── is_lti_elevated
    ├── is_dti_elevated
    ├── is_affordability_elevated
    ├── is_rent
    └── is_previous_default
```

---

# 6. Những Band nên được đóng băng trong SQL

Sau khi đã kiểm tra ở file 04-09, các band nên được chuẩn hóa trong SQL để Power BI không phải định nghĩa lại.

## Income Band

```text
<30K
30K-50K
50K-75K
75K-100K
100K+
```

## Loan Amount Band

```text
<5K
5K-10K
10K-15K
15K-20K
20K+
```

## Interest Rate Band

```text
<8%
8%-10%
10%-12%
12%-15%
15%+
Unknown
```

## LTI Band

```text
<0.10
0.10-0.20
0.20-0.30
0.30+
```

## DTI Band

```text
<0.25
0.25-0.35
0.35-0.45
0.45+
```

## Employment Length Band

```text
<1 year
1-3 years
4-6 years
7-10 years
10+ years
Unknown
```

## Affordability Group

```text
Neither Elevated
Elevated DTI Only
Elevated LTI Only
Elevated LTI + Elevated DTI
```

---

# 7. Vì sao nên tạo Band trong SQL?

Nếu SQL định nghĩa:

```text
LTI >= 0.30
=
Elevated LTI
```

nhưng Power BI lại dùng:

```text
LTI > 0.30
```

hoặc:

```text
LTI >= 0.25
```

thì hai lớp dữ liệu sẽ nói hai ngôn ngữ khác nhau.

Nguyên tắc nên dùng:

> **Business classification ổn định → SQL**

> **Aggregation phụ thuộc filter/slicer → DAX**

Đây là một trong những nguyên tắc quan trọng nhất của semantic layer.

---

# 8. KPI nên tính bằng DAX, không nên hard-code trong một bảng aggregate cố định

Ví dụ baseline hiện tại:

```text
Total Loans       = 32,581
Default Rate      = 21.82%
Loan Exposure     = $312.43M
```

Nếu tạo một view chỉ có một dòng KPI, khi người dùng chọn:

```text
Country = USA
```

KPI sẽ không tự phản ánh đúng ngữ cảnh nếu bảng đó không hỗ trợ filter phù hợp.

Do đó KPI động nên được tính từ:

```text
vw_credit_risk_detail
```

bằng DAX.

---

# 9. Ví dụ DAX Measures nền tảng

## Total Loans

```DAX
Total Loans =
COUNTROWS(vw_credit_risk_detail)
```

## Default Loans

```DAX
Default Loans =
CALCULATE(
    [Total Loans],
    vw_credit_risk_detail[loan_status] = 1
)
```

## Default Rate

```DAX
Default Rate =
DIVIDE(
    [Default Loans],
    [Total Loans]
)
```

## Loan Exposure

```DAX
Loan Exposure =
SUM(vw_credit_risk_detail[loan_amnt])
```

## Default Exposure

```DAX
Default Exposure =
CALCULATE(
    [Loan Exposure],
    vw_credit_risk_detail[loan_status] = 1
)
```

Khi đó slicer như:

```text
USA
RENT
Grade D
Income <50K
```

sẽ tự động làm KPI thay đổi.

---

# 10. Cấu trúc View nên giữ gọn

`10_powerbi_views.sql` không cần 15-20 views.

Một cấu trúc hợp lý:

```text
10_powerbi_views.sql
│
├── vw_credit_risk_detail
├── vw_geography
├── vw_segment_candidates
└── vw_powerbi_qa
```

Trong đó:

### `vw_credit_risk_detail`

Fact View chính.

### `vw_geography`

Dimension địa lý.

### `vw_segment_candidates`

Hỗ trợ các candidate risk concentrations từ file 09.

### `vw_powerbi_qa`

Dùng để đối chiếu số liệu giữa MySQL và Power BI.

---

# 11. Candidate Segments phải xử lý cẩn thận

File 09 đã tìm được các nhóm như:

```text
Grade D-G + LTI >=0.30
LTI >=0.30 + DTI >=0.45
Income <50K + RENT
Previous Default = Y + RENT
Previous Default = Y + RENT + Affordability Elevated
```

Các nhóm này có thể chồng lấn.

Một người vay có thể đồng thời:

```text
Grade D
LTI = 0.40
DTI = 0.60
Income = 35K
RENT
Previous Default = Y
```

và thuộc nhiều candidate segments cùng lúc.

Do đó không nên ép tất cả vào một cột:

```text
risk_segment
```

nếu chưa có logic priority chính thức.

---

# 12. Nên dùng independent flags

Ví dụ:

```text
flag_grade_dg_high_lti
flag_high_lti_high_dti
flag_low_income_rent
flag_prev_default_rent
flag_prev_default_rent_affordability
flag_lower_observed_risk
```

Điều này giúp Power BI:

- Phân tích từng concentration đúng bản chất.
- Không tạo thứ tự ưu tiên tùy ý.
- Không làm mất thông tin khi một borrower thuộc nhiều điều kiện.

---

# 13. Không nên gọi ngay là “High Risk Customer”

Tên nên dùng:

```text
Observed Risk Concentration
Elevated Risk Condition
Lower Observed Risk
```

Không nên dùng:

```text
Bad Customer
Reject
Safe Customer
High Risk Customer
```

vì EDA chỉ cho thấy association.

Ví dụ:

```text
LTI >= 0.30
```

có tỷ lệ vỡ nợ rất cao trong dataset, nhưng chưa phải policy rule chính thức.

---

# 14. `vw_geography`

View địa lý có thể gồm:

```text
geo_key
country
state
city
city_latitude
city_longitude
```

Có thể tạo relationship:

```text
vw_geography[geo_key]
        1
        │
        │
        *
vw_credit_risk_detail[geo_key]
```

Đây là bước đầu của Star Schema.

---

# 15. `vw_powerbi_qa`

View này không dùng để vẽ dashboard.

Nó dùng để xác minh Power BI load đúng dữ liệu.

Baseline cần đối chiếu:

```text
Total Loans        = 32,581
Default Loans      = 7,108
Default Rate       = 21.82%
Loan Exposure      = $312,431,300
Default Exposure   = $77,125,375
```

Nếu Power BI trả đúng các con số trên:

```text
SQL = Power BI
```

thì model đang hoạt động đúng.

Nếu Power BI trả:

```text
65,162 loans
```

thì có khả năng relationship làm nhân đôi dữ liệu.

---

# 16. Mindset khi thiết kế Dashboard

Không hỏi:

> “Dataset còn cột nào để vẽ không?”

Hãy hỏi:

> **“Insight nào đủ quan trọng để stakeholder phải nhìn thấy?”**

Không hỏi:

> “Có thể tạo thêm chart gì?”

Hãy hỏi:

> **“Chart này giúp stakeholder ra quyết định gì?”**

Không hỏi:

> “Biến này có correlation cao không?”

Hãy hỏi:

> **“Nhóm này có Default Rate cao không, quy mô có đủ lớn không, và nó đang đóng góp bao nhiêu Default Exposure?”**

---

# 17. Dashboard không phải bộ sưu tập biểu đồ

Dashboard nên kể một business story:

```text
1. Portfolio đang có vấn đề lớn đến mức nào?
        ↓
2. Rủi ro tập trung ở borrower nào?
        ↓
3. Đặc điểm khoản vay nào liên quan mạnh?
        ↓
4. Khả năng chi trả ảnh hưởng như thế nào?
        ↓
5. Khi nhiều tín hiệu kết hợp thì chuyện gì xảy ra?
        ↓
6. Exposure tập trung ở đâu?
        ↓
7. Nova Bank nên ưu tiên giám sát nhóm nào?
```

---

# 18. Page 1 — Portfolio Overview

Mục tiêu:

> Cho quản lý nhìn 10-20 giây là hiểu quy mô và chất lượng toàn portfolio.

## KPI Cards

```text
Total Loans
32,581

Loan Exposure
$312.43M

Default Loans
7,108

Default Rate
21.82%

Default Exposure
$77.13M
```

Có thể thêm:

```text
Average Loan Amount
$9,589
```

## Visual nên có

### Default vs Non-default

Cho biết portfolio outcome balance.

### Default Rate by Loan Grade

Một trong những chart mạnh nhất:

```text
A   9.96%
B  16.28%
C  20.73%
D  59.05%
E  64.42%
F  70.54%
G  98.44%
```

### Default Exposure Contribution

Có thể xem theo:

```text
Loan Grade
LTI Band
DTI Band
```

---

# 19. Page 2 — Borrower & Loan Risk

Trang này trả lời:

> Borrower profile và loan characteristics nào có liên hệ mạnh với default?

## Visual nên ưu tiên

### Income Band

Default Rate giảm mạnh khi Income tăng.

### Home Ownership

```text
RENT
MORTGAGE
OWN
```

### Employment Length

Phản ánh stability.

### Previous Default

```text
Y vs N
```

### Loan Purpose

Đặc biệt:

```text
DEBTCONSOLIDATION
MEDICAL
```

### Interest Rate Band

```text
<8%       9.40%
8%-10%   13.74%
10%-12%  16.71%
12%-15%  27.07%
15%+     58.01%
```

---

# 20. Page 3 — Financial Risk

Đây nên là một trong những page quan trọng nhất.

## LTI Band

```text
<0.10       11.50%
0.10-0.20   14.60%
0.20-0.30   21.34%
0.30+       67.31%
```

## DTI Band

```text
<0.25       11.48%
0.25-0.35   14.63%
0.35-0.45   21.42%
0.45+       46.72%
```

---

# 21. LTI × DTI Heatmap

Đây là một visual rất nên có.

Dùng Matrix:

```text
Rows    = LTI Band
Columns = DTI Band
Values  = Default Rate
```

Có thể dùng Conditional Formatting để làm heatmap.

Ý nghĩa:

> Cho stakeholder thấy rủi ro tăng như thế nào khi khả năng chi trả xấu đi đồng thời trên cả LTI và DTI.

---

# 22. Page 4 — Risk Segmentation

Trang này khai thác kết quả file 09.

Một visual rất phù hợp là Scatter Plot.

## Trục X

```text
Portfolio Share
```

## Trục Y

```text
Default Rate
```

## Bubble Size

```text
Default Exposure
```

Mỗi bubble đại diện một candidate segment:

```text
Grade D-G + LTI >=0.30

LTI >=0.30 + DTI >=0.45

Income <50K + RENT

Previous Default = Y + RENT

Previous Default = Y + RENT + Affordability Elevated
```

Visual này trả lời đồng thời:

> Nhóm nào rủi ro cao?

và:

> Nhóm nào thực sự quan trọng về tài chính?

---

# 23. Lower Observed Risk cũng nên xuất hiện

Dashboard không nên chỉ tập trung vào nhóm xấu.

Một finding quan trọng:

```text
Grade A-B
+
LTI <0.20
+
DTI <0.35
+
Previous Default = N
```

có:

```text
34.48% Portfolio
5.53% Default Rate
4.20% Total Default Exposure
```

Có thể dùng card:

```text
Lower Observed Risk Group
34.48% of Loans
5.53% Default Rate
```

Điều này giúp dashboard thể hiện cả:

```text
Risk concentration
và
Healthy portfolio concentration
```

---

# 24. Geography nên là trang phụ

Geography có dữ liệu tốt nhưng signal yếu.

Có thể tạo:

```text
Page 5 — Geographic Portfolio
```

hoặc một section phụ.

Map:

```text
Latitude  = city_latitude
Longitude = city_longitude
Bubble Size = Loan Exposure
Tooltip:
    Loan Count
    Default Rate
    Default Exposure
```

Không nên truyền tải thông điệp kiểu:

```text
Vancouver = High Risk City
Swansea = Safe City
```

vì geographic variation nhỏ hơn nhiều so với LTI, DTI và Loan Grade.

---

# 25. Không có Date thì không tạo Trend giả

Nếu dataset không có:

```text
Loan Date
Application Date
Issue Date
```

thì không nên tạo:

```text
Monthly Trend
YoY
MoM
```

chỉ để dashboard trông đầy đủ.

Một dashboard tốt phải trung thực với dữ liệu.

---

# 26. Slicer nên vừa đủ

Nên ưu tiên:

```text
Country
State
City

Loan Grade
Loan Purpose

Income Band
Home Ownership

Previous Default

LTI Band
DTI Band
```

Không cần đặt tất cả các biến lên slicer.

Quá nhiều slicer sẽ làm dashboard khó sử dụng.

---

# 27. Các biến không cần visual riêng

Dựa trên EDA, các biến sau không cần chiếm nhiều không gian dashboard:

```text
Gender
Marital Status
Education
Employment Type
Loan Term
Credit Utilization
Open Accounts
Past Delinquencies
Credit History Length
```

Có thể giữ trong detail table hoặc slicer phụ nếu cần.

---

# 28. Kiến trúc Power BI nên hướng tới

```text
MYSQL
│
├── credit_risk_raw
├── credit_risk_clean
│
└── POWER BI LAYER
    │
    ├── vw_credit_risk_detail
    ├── vw_geography
    ├── vw_segment_candidates
    └── vw_powerbi_qa
            ↓
          POWER BI
            │
            ├── Relationships
            ├── Measures
            ├── Slicers
            └── Dashboard
```

---

# 29. Nguyên tắc phân tích quan trọng nhất

Không nên nhìn Default Rate một mình.

Luôn xem bộ ba:

```text
Risk Rate
+
Population Size
+
Financial Exposure
```

Ví dụ:

```text
Grade D-G + LTI >=0.30
```

có Default Rate rất cao.

Nhưng:

```text
LTI >=0.30 + DTI >=0.45
```

có thể quan trọng hơn về mặt tài chính vì Default Exposure lớn hơn.

Do đó stakeholder cần biết:

1. Nhóm có rủi ro cao bao nhiêu?
2. Nhóm lớn bao nhiêu?
3. Bao nhiêu vốn đang nằm trong nhóm?
4. Bao nhiêu Default Exposure đang tập trung ở đó?

---

# 30. Mindset cuối cùng cần giữ

Từ thời điểm này trở đi:

## Không hỏi

> Dataset còn gì để vẽ?

## Hãy hỏi

> Insight nào xứng đáng xuất hiện trên dashboard?

---

## Không hỏi

> Có thể thêm chart nào nữa?

## Hãy hỏi

> Chart này giúp stakeholder đưa ra quyết định gì?

---

## Không hỏi

> Biến này có khác nhau không?

## Hãy hỏi

> Mức khác biệt có đủ lớn, sample có đủ lớn và exposure có đủ quan trọng để hành động không?

---

# 31. Vai trò cuối cùng của `10_powerbi_views.sql`

File này nên được xây như **semantic layer chính thức của dự án**.

Nguyên tắc:

```text
Một Fact View chi tiết
+
Các Business Bands đã chốt
+
Các Analytical Flags đã được EDA kiểm chứng
+
Geography Dimension
+
QA Reconciliation
```

Sau khi chạy `10_powerbi_views.sql`, cần đối chiếu lại:

```text
Total Loans        = 32,581
Default Loans      = 7,108
Default Rate       = 21.82%
Loan Exposure      = $312.43M
Default Exposure   = $77.13M
```

Nếu MySQL và Power BI khớp các baseline này, SQL phase có thể xem như hoàn thành.

---

# 32. Workflow sau cùng

```text
01 Data Profiling
        ✅

02 Data Cleaning
        ✅

03 Data Validation
        ✅

04-09 EDA
        ✅

10 Power BI Views
        ⏭ NEXT

Power BI Data Model
        ⏳

DAX Measures
        ⏳

Dashboard Pages
        ⏳

Business Recommendations
        ⏳
```

---

# 33. Kết luận

Sau file 09, câu hỏi không còn là:

> “Dữ liệu nói gì?”

Mà chuyển thành:

> **“Làm thế nào để những gì dữ liệu đã nói được thể hiện rõ ràng, nhất quán và hữu ích cho người ra quyết định?”**

Đây chính là mindset cần có khi chuyển từ EDA sang Power BI.

Một dashboard tốt không phải dashboard có nhiều chart nhất.

Một dashboard tốt là dashboard:

- Chỉ hiển thị những insight quan trọng.
- Sử dụng business logic nhất quán.
- Cho phép stakeholder lọc và drill-down.
- Luôn đặt Risk Rate trong bối cảnh Population và Exposure.
- Không biến association thành causation.
- Không dùng biến yếu chỉ vì dataset có sẵn.
- Không tạo metric hoặc trend mà dữ liệu không hỗ trợ.
- Có semantic layer và QA rõ ràng phía sau.

Đây sẽ là nguyên tắc nền tảng để viết `10_powerbi_views.sql` và xây toàn bộ Dashboard của dự án.
