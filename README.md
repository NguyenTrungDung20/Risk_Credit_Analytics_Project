# Risk Credit Analytics Project

Dự án phân tích rủi ro tín dụng end-to-end, đi từ nhập dữ liệu khoản vay, kiểm tra chất lượng dữ liệu, làm sạch, phân tích EDA bằng SQL, xây dựng semantic layer cho Power BI và hoàn thiện dashboard tương tác.

Mục tiêu chính của dự án là giúp theo dõi danh mục tín dụng, nhận diện các nhóm khách hàng/khoản vay có tỷ lệ default cao, đo mức độ tập trung default exposure và cung cấp nền tảng phân tích để hỗ trợ quyết định quản trị rủi ro.

## Tổng Quan Dự Án

Dự án phân tích một danh mục gồm **32,581 khoản vay**, tương ứng **32,581 khách hàng duy nhất**. Trong semantic layer của dự án, `loan_status = 1` được quy ước là **Default** và `loan_status = 0` là **Non-default**.

Các chỉ số baseline chính:

| Chỉ số | Giá trị |
|---|---:|
| Total Loans | 32,581 |
| Distinct Clients | 32,581 |
| Default Loans | 7,108 |
| Default Rate | 21.82% |
| Loan Exposure | 312,431,300 |
| Default Exposure | 77,125,375 |
| Interest Rate Coverage | 90.44% |
| Geography Coverage | 100% |

Phân tích tập trung vào các nhóm biến chính:

- Thông tin người vay: tuổi, thu nhập, tình trạng nhà ở, thâm niên làm việc, giới tính, hôn nhân, học vấn.
- Đặc điểm khoản vay: mục đích vay, loan grade, số tiền vay, lãi suất, kỳ hạn.
- Khả năng chi trả: loan-to-income ratio, debt-to-income ratio, other debt, credit utilization.
- Lịch sử tín dụng và độ ổn định: previous default, credit history length, open accounts, past delinquencies.
- Địa lý: country, state, city, latitude, longitude.
- Phân khúc rủi ro đa yếu tố phục vụ dashboard và business monitoring.

## Dashboard Power BI

File dashboard chính đã được đưa vào repository:

```text
powerbi/Risk_Credit_Analytics_Project.pbix
```

Dashboard được thiết kế để xem nhanh tình hình danh mục và drill-down theo các trục rủi ro quan trọng. Các trang chính gồm:

- **Credit Risk Overview**: KPI tổng quan, default rate, loan exposure, default exposure và bức tranh danh mục.
- **Borrower Profile**: phân tích thu nhập, tình trạng nhà ở, thâm niên làm việc và các đặc điểm người vay.
- **Loan & Affordability Risk**: phân tích loan grade, loan amount, interest rate, LTI, DTI và affordability group.
- **Credit Profile & Geography**: theo dõi previous default, lịch sử tín dụng, geography map và ranking theo khu vực.
- **Risk Segmentation & Recommendations**: phân tích các candidate segments có default rate hoặc default exposure đáng chú ý.

Semantic model trong Power BI được xây dựng từ các view ở `sql/10_powerbi_views.sql`, gồm:

- `vw_credit_risk_detail`: fact view chính, grain là 1 dòng cho 1 khoản vay/1 khách hàng.
- `vw_geography`: dimension địa lý theo country, state, city.
- `vw_segment_candidates`: bảng membership dạng long format cho các phân khúc rủi ro có thể chồng lấn.
- `vw_powerbi_qa`: view kiểm tra baseline, dùng để đối soát sau khi load dữ liệu vào Power BI.

## Insight Chính

Các kết quả dưới đây là finding mô tả từ EDA, không phải quy tắc phê duyệt/từ chối khoản vay.

### 1. Khả năng chi trả là trục rủi ro nổi bật

LTI và DTI là hai tín hiệu mạnh nhất trong nhóm financial risk:

- `LTI >= 0.30` chiếm **12.76%** số khoản vay nhưng tạo ra **54.48%** default exposure.
- `DTI >= 0.45` chiếm **19.48%** số khoản vay nhưng tạo ra **55.50%** default exposure.
- Nhóm `LTI >= 0.30` và `DTI >= 0.45` chỉ chiếm **10.60%** danh mục nhưng có default rate **68.55%** và tạo ra **46.73%** default exposure.

Điều này cho thấy rủi ro không chỉ nằm ở việc khách hàng vay nhiều tiền, mà nằm ở việc khoản vay và tổng nghĩa vụ nợ lớn đến mức nào so với thu nhập.

### 2. Loan Grade và lãi suất phân tách rủi ro rất rõ

Loan grade cho thấy default rate tăng mạnh từ nhóm grade tốt sang grade thấp:

- Grade A: **9.96%**
- Grade D: **59.05%**
- Grade F: **70.54%**
- Grade G: **98.44%**, nhưng sample size rất nhỏ.

Các khoản vay có lãi suất từ `12%` trở lên chiếm **34.21%** số khoản vay nhưng tạo ra **58.71%** default exposure. Tuy nhiên, interest rate có thể phản ánh risk-based pricing nên không nên diễn giải là nguyên nhân trực tiếp gây default.

### 3. Thu nhập, tình trạng nhà ở và thâm niên làm việc là các borrower signal quan trọng

Borrower profile cho thấy:

- Default rate giảm từ **47.07%** ở nhóm thu nhập `<30K` xuống **8.93%** ở nhóm `100K+`.
- Nhóm `RENT` có default rate **31.57%** và tạo ra hơn **72%** default exposure.
- Employment length càng dài thì default rate càng giảm, từ **27.94%** ở nhóm `<1 year` xuống **16.23%** ở nhóm `10+ years`.

Ngược lại, gender, marital status, education và employment type gần như không tạo ra khác biệt đáng kể trong EDA hiện tại.

### 4. Previous Default mạnh, nhưng không đủ để dùng đơn lẻ

Khách hàng có previous default (`cb_person_default_on_file = Y`) có default rate **37.81%**, cao hơn khoảng **2.06 lần** nhóm không có previous default.

Tuy vậy, nhóm không có previous default vẫn chiếm phần lớn số default tuyệt đối vì quy mô danh mục lớn. Do đó, dashboard luôn theo dõi đồng thời default rate, loan count, loan exposure và default exposure.

### 5. Phân khúc đa yếu tố hiệu quả hơn một biến đơn lẻ

Một số candidate risk concentrations nổi bật:

| Segment | Default Rate | Default Exposure Share |
|---|---:|---:|
| Grade D-G AND LTI >= 0.30 | 82.51% | 16.80% |
| Previous Default = Y AND RENT AND Affordability Elevated | 77.43% | 12.09% |
| Grade D-G AND DTI >= 0.45 | 72.60% | 19.84% |
| LTI >= 0.30 AND DTI >= 0.45 | 68.55% | 46.73% |
| Income <50K AND RENT | 42.04% | 40.96% |

Một nhóm lower-observed-risk cũng được xác định:

```text
Grade A-B
+ LTI < 0.20
+ DTI < 0.35
+ Previous Default = N
```

Nhóm này chiếm **34.48%** danh mục, có default rate **5.53%** và chỉ tạo ra **4.20%** default exposure.

### 6. Geography phù hợp để monitoring hơn là risk scoring

Dữ liệu địa lý có coverage đầy đủ 100%, nhưng khác biệt về default rate theo country, state và city thấp hơn nhiều so với các biến tài chính:

- Country default rate dao động khoảng **21.73% - 21.86%**.
- City default rate dao động khoảng **20.43% - 24.19%**.
- Trong khi LTI band dao động từ **11.50% - 67.31%** và loan grade dao động từ **9.96% - 98.44%**.

Vì vậy, geography được dùng để monitoring, mapping và phân bổ exposure, không dùng như rule tín dụng độc lập.

## Quy Trình Phân Tích

```text
data/raw/Credit_Risk_Dataset.csv
        |
        v
ingestion/01_import_csv.ipynb
        |
        v
credit_risk_raw
        |
        v
sql/01_data_profiling.sql
        |
        v
sql/02_data_cleaning.sql
        |
        v
credit_risk_clean
        |
        v
sql/03_data_validation.sql
        |
        v
sql/04 - 09 EDA scripts
        |
        v
sql/10_powerbi_views.sql
        |
        v
Power BI dashboard
```

## Cấu Trúc Repository

```text
Risk_Credit_Analytics_Project/
|
|-- data/
|   |-- README.md
|   |-- raw/                 # Không commit raw dataset
|   `-- processed/           # Không commit processed dataset
|
|-- docs/
|   |-- data_dictionary.md
|   |-- cleaning_rules.md
|   |-- eda_plan.md
|   `-- project_workflow.md
|
|-- ingestion/
|   `-- 01_import_csv.ipynb
|
|-- sql/
|   |-- 01_data_profiling.sql
|   |-- 02_data_cleaning.sql
|   |-- 03_data_validation.sql
|   |-- 04_overall_risk.sql
|   |-- 05_borrower_profile.sql
|   |-- 06_loan_analysis.sql
|   |-- 07_financial_risk.sql
|   |-- 08_credit_and_stability.sql
|   |-- 09_geography_and_segmentation.sql
|   `-- 10_powerbi_views.sql
|
|-- insights/
|   `-- Business insight summaries cho từng bước EDA
|
|-- results/
|   `-- Query outputs và bảng kết quả tổng hợp
|
|-- powerbi/
|   |-- Risk_Credit_Analytics_Project.pbix
|   |-- complete_dashboard_layout.py
|   |-- dashboard_completion_notes.md
|   `-- powerbi_dashboard_mindset_guide.md
|
|-- .env.example
|-- .gitignore
`-- README.md
```

## Cách Chạy Lại Dự Án

### 1. Chuẩn bị dữ liệu

Đặt file CSV nguồn tại:

```text
data/raw/Credit_Risk_Dataset.csv
```

Raw và processed CSV không được commit vì chứa dữ liệu cấp khoản vay, thông tin địa lý, nhân khẩu học và client identifier.

### 2. Cấu hình môi trường

Tạo cấu hình local dựa trên:

```text
.env.example
```

Biến quan trọng:

```text
MYSQL_PASSWORD=your_password_here
```

Không commit `.env`, password, token hoặc credential thật.

### 3. Import dữ liệu vào MySQL

Chạy notebook:

```text
ingestion/01_import_csv.ipynb
```

Notebook import CSV vào bảng raw với policy lưu các cột dưới dạng text trước, nhằm phục vụ profiling và kiểm tra lỗi kiểu dữ liệu.

### 4. Chạy SQL theo thứ tự

Chạy các script trong thư mục `sql/` theo đúng thứ tự:

```text
01_data_profiling.sql
02_data_cleaning.sql
03_data_validation.sql
04_overall_risk.sql
05_borrower_profile.sql
06_loan_analysis.sql
07_financial_risk.sql
08_credit_and_stability.sql
09_geography_and_segmentation.sql
10_powerbi_views.sql
```

Sau bước 10, kiểm tra `vw_powerbi_qa` để đối soát baseline trước khi refresh Power BI.

### 5. Mở dashboard Power BI

Mở file:

```text
powerbi/Risk_Credit_Analytics_Project.pbix
```

Sau khi refresh dữ liệu, kiểm tra lại:

- Tổng số khoản vay, default loans, default rate và exposure trên dashboard.
- Quan hệ giữa fact view, geography dimension và segment membership table.
- Map visual ở trang geography.
- Segment table ở trang risk segmentation.

## Data Cleaning Notes

Quy trình cleaning giữ nguyên raw layer để đảm bảo auditability. Bảng clean được xây dựng lại từ raw table với các xử lý chính:

- Trim text, convert blank strings thành `NULL`.
- Cast numeric fields sang kiểu dữ liệu phù hợp.
- Giữ nguyên dòng dữ liệu, không xóa row trong clean layer.
- Đánh dấu tuổi không hợp lệ ngoài khoảng 18-100.
- Chuyển employment length bị thiếu hoặc lớn hơn tuổi thành `NULL` và tạo flag.
- Giữ missing interest rate là `NULL`, không impute.
- Recalculate `loan_percent_income`, LTI và DTI từ các trường gốc.
- Giữ lại các extreme values có thể hợp lệ và tạo flag cho DTI cao bất thường.

## Lưu Ý Diễn Giải

Dự án này là phân tích mô tả và business intelligence, không phải mô hình credit scoring sản xuất.

Các segment như `Grade D-G AND LTI >= 0.30` hoặc `Income <50K AND RENT` là observed-risk concentrations dựa trên EDA. Chúng không nên được dùng trực tiếp làm quy tắc phê duyệt, từ chối hoặc pricing nếu chưa có kiểm định bổ sung, review chính sách, đánh giá fairness và xác nhận nghiệp vụ.

## Bảo Mật Và Git Tracking

Repository cố ý không commit:

- Raw CSV và processed CSV trong `data/`.
- File `.env` hoặc credential.
- Virtual environment, cache, temp PBIX extracts.
- Các bản PBIX/PBIT phát sinh ngoài file dashboard chính.

File Power BI chính `powerbi/Risk_Credit_Analytics_Project.pbix` được commit để reviewer có thể mở dashboard hoàn chỉnh. Trước khi publish hoặc chia sẻ rộng hơn, cần đảm bảo PBIX không chứa credential nhúng hoặc thông tin nhạy cảm ngoài phạm vi được phép.
