# 09 - Geography and Segmentation: Business Insights

**Project:** Risk_Credit_Analytics_Project  
**Source SQL:** `sql/09_geography_and_segmentation.sql`  
**Source table:** `credit_risk_clean`  
**Mục tiêu:** Phân tích mức độ tập trung rủi ro theo địa lý và kết hợp các tín hiệu mạnh từ các bước EDA trước để xác định những phân khúc đa yếu tố có ý nghĩa kinh doanh.

---

# 1. Tóm tắt điều hành

Kết quả của `09_geography_and_segmentation.sql` cho thấy hai kết luận rất rõ:

## Kết luận 1 — Địa lý không phải tín hiệu rủi ro mạnh

Dữ liệu địa lý có chất lượng rất tốt:

- Country coverage: **100%**
- State coverage: **100%**
- City coverage: **100%**
- Coordinate coverage: **100%**

Tuy nhiên, tỷ lệ vỡ nợ theo quốc gia, bang/tỉnh và thành phố **không chênh lệch nhiều**.

Ví dụ theo quốc gia:

```text
USA     21.86%
Canada  21.86%
UK      21.73%
```

Gần như giống nhau hoàn toàn.

Ở cấp thành phố, tỷ lệ vỡ nợ cao nhất là Vancouver **24.19%**, thấp nhất là Swansea **20.43%**.

Khoảng cách chỉ khoảng **3.76 điểm phần trăm**.

Điều này cho thấy geography phù hợp để:

- Mô tả danh mục.
- Làm bản đồ trên Power BI.
- Theo dõi exposure theo khu vực.

Nhưng **không nên xem geography là một risk driver chính**.

---

## Kết luận 2 — Phân khúc đa yếu tố tạo ra sức phân tách rất mạnh

Khi kết hợp các tín hiệu đã được xác nhận từ file 05-08, tỷ lệ vỡ nợ tăng mạnh ở một số nhóm:

```text
Grade D-G + LTI >= 0.30
→ 82.51% Default Rate

Previous Default = Y
+ RENT
+ Affordability Elevated
→ 77.43%

Grade D-G + DTI >= 0.45
→ 72.60%

LTI >= 0.30 + DTI >= 0.45
→ 68.55%

Income <50K + RENT
→ 42.04%
```

Ngược lại, một nhóm có đặc điểm thuận lợi:

```text
Grade A-B
+ LTI <0.20
+ DTI <0.35
+ Previous Default = N
```

có tỷ lệ vỡ nợ chỉ:

**5.53%**

và chiếm tới:

**34.48% tổng số khoản vay**.

Đây là bằng chứng rất rõ rằng **phân khúc đa yếu tố hiệu quả hơn rất nhiều so với nhìn một biến riêng lẻ**.

---

# 2. Chất lượng dữ liệu địa lý

## 2.1 Coverage

| Chỉ số | Kết quả |
|---|---:|
| Total Loans | 32,581 |
| Country Coverage | 100% |
| State Coverage | 100% |
| City Coverage | 100% |
| Coordinate Coverage | 100% |
| Countries | 3 |
| States | 9 |
| Cities | 18 |
| Country-State-City Combinations | 18 |

## Ý nghĩa

Dữ liệu địa lý hoàn chỉnh.

Không có vấn đề missing data đáng kể làm ảnh hưởng đến phân tích geographic risk.

Việc có đầy đủ latitude và longitude cũng giúp dữ liệu sẵn sàng để tạo bản đồ trên Power BI.

## Business Insight

> Geography là một dimension có chất lượng dữ liệu rất tốt nhưng chất lượng dữ liệu tốt không đồng nghĩa với khả năng phân tách rủi ro mạnh.

Đây là điểm quan trọng cần phân biệt.

---

# 3. Rủi ro theo quốc gia

## 3.1 Kết quả

| Country | Portfolio Share | Default Rate | Default Exposure Share |
|---|---:|---:|---:|
| USA | 33.31% | 21.86% | 33.76% |
| Canada | 33.10% | 21.86% | 33.12% |
| UK | 33.59% | 21.73% | 33.12% |

Portfolio Default Rate:

**21.82%**

## Ý nghĩa

Ba quốc gia có tỷ lệ vỡ nợ gần như giống nhau:

```text
USA     +0.04 điểm % so với danh mục
Canada  +0.05 điểm %
UK      -0.09 điểm %
```

Mức chênh này gần như không có ý nghĩa thực tế.

## Business Insight

> Country không có khả năng phân tách rủi ro đáng kể.

Tỷ trọng số khoản vay, exposure và default exposure cũng được phân bố khá đồng đều giữa ba quốc gia.

Không có quốc gia nào tạo ra một concentration risk rõ ràng.

### Kết luận

**Country = yếu về risk segmentation, tốt cho portfolio monitoring.**

---

# 4. Rủi ro theo State

## 4.1 Kết quả tổng quát

Tỷ lệ vỡ nợ theo State dao động từ:

```text
Wales       20.87%
New York    20.98%
Quebec      21.19%
England     21.81%
Ontario     21.90%
Texas       22.23%
California  22.34%
BC          22.48%
Scotland    22.51%
```

Khoảng cách từ thấp nhất đến cao nhất chỉ khoảng:

**1.64 điểm phần trăm**.

## Ý nghĩa

Ngay cả State có tỷ lệ cao nhất là Scotland:

**22.51%**

cũng chỉ cao hơn mức danh mục:

**0.69 điểm phần trăm**.

Wales có tỷ lệ thấp nhất:

**20.87%**

chỉ thấp hơn portfolio:

**0.95 điểm phần trăm**.

## Business Insight

> State cũng không phải strong risk signal.

Các State có default exposure cao chủ yếu do quy mô exposure tương đối lớn, không phải vì default rate vượt trội.

---

# 5. Texas có Default Exposure cao nhất nhưng không có Default Rate cao nhất

Texas:

```text
Default Rate     = 22.23%
Default Exposure = $8.97M
Exposure Rank    = 1
Default Rate Rank = 4
```

Scotland:

```text
Default Rate     = 22.51%
Default Exposure = $8.88M
Exposure Rank    = 2
Default Rate Rank = 1
```

## Business Insight

Điều này tiếp tục cho thấy:

```text
Default Rate cao
≠
Default Exposure cao nhất
```

Texas đứng đầu về default exposure do quy mô danh mục, còn Scotland đứng đầu về default rate.

Power BI nên cho phép xem đồng thời:

- Default Rate.
- Loan Exposure.
- Default Exposure.

---

# 6. Rủi ro theo City

## 6.1 Các thành phố có tỷ lệ cao nhất

| City | Default Rate |
|---|---:|
| Vancouver | **24.19%** |
| Dallas | **23.60%** |
| Edinburgh | **23.46%** |
| Los Angeles | 22.85% |
| Manchester | 22.52% |

## Các thành phố có tỷ lệ thấp nhất

| City | Default Rate |
|---|---:|
| Swansea | **20.43%** |
| Quebec City | **20.47%** |
| Buffalo | 20.55% |
| Victoria | 20.79% |
| Houston | 20.87% |

## Ý nghĩa

City tạo ra khác biệt lớn hơn Country và State một chút.

Tuy nhiên range vẫn chỉ:

```text
24.19% - 20.43%
= 3.76 điểm phần trăm
```

Vancouver cao hơn portfolio khoảng:

**2.38 điểm phần trăm**.

Swansea thấp hơn khoảng:

**1.39 điểm phần trăm**.

## Business Insight

> Geographic variation tồn tại ở cấp thành phố nhưng vẫn yếu hơn rất nhiều so với các biến tài chính và tín dụng.

Ví dụ:

```text
Vancouver Default Rate = 24.19%

LTI >= 0.30 = 67.31%
Grade D-G   = 61.19%
```

Khoảng cách này cho thấy geography không nên được đặt ngang mức với LTI hoặc Loan Grade trong đánh giá rủi ro.

---

# 7. Hàm ý về Geography

Dựa trên toàn bộ kết quả:

```text
Country → gần như không khác biệt
State   → khác biệt rất nhỏ
City    → có variation nhẹ
```

## Business Insight

Geography nên được sử dụng để:

- Theo dõi phân bổ danh mục.
- Theo dõi exposure.
- Hiển thị bản đồ.
- Drill-down từ Country → State → City.

Geography **không nên** được dùng như:

```text
City X = High Risk
→ Reject Loan
```

Địa lý có thể phản ánh:

- Cơ cấu khách hàng.
- Thu nhập.
- Loan Grade.
- Loan size.
- Nhà ở.
- Các yếu tố kinh tế chưa có trong dataset.

---

# 8. Loan Grade × Affordability

Đây là một trong những phần quan trọng nhất của file 09.

## 8.1 Kết quả

| Grade Group | Affordability Group | Default Rate |
|---|---|---:|
| Grade D-G | Elevated LTI + DTI | **83.65%** |
| Grade D-G | Elevated LTI Only | **77.22%** |
| Grade A-C | Elevated LTI + DTI | **64.47%** |
| Grade D-G | Elevated DTI Only | **57.77%** |
| Grade A-C | Elevated LTI Only | **56.59%** |
| Grade D-G | Neither Elevated | **56.22%** |
| Grade A-C | Elevated DTI Only | 12.05% |
| Grade A-C | Neither Elevated | **8.01%** |

---

# 9. Grade D-G + Elevated LTI + DTI

Nhóm này:

```text
Loan Count                = 734
Portfolio Share           = 2.25%
Default Rate              = 83.65%
Default Exposure          = $11.02M
Share of Default Exposure = 14.29%
```

## Business Insight

> Chỉ 2.25% danh mục nhưng tạo ra 14.29% tổng dư nợ vỡ nợ.

Đây là một concentration rất mạnh.

Kết hợp:

```text
Loan Grade xấu hơn
+
Khoản vay lớn so với thu nhập
+
Gánh nặng nợ cao
```

tạo ra một nhóm có tỷ lệ vỡ nợ trên 80%.

---

# 10. Affordability vẫn cực kỳ quan trọng ngay cả trong Grade A-C

Một finding rất quan trọng:

```text
Grade A-C + Neither Elevated
Default Rate = 8.01%

Grade A-C + Elevated LTI + DTI
Default Rate = 64.47%
```

## Business Insight

> Loan Grade tốt không đủ để bảo đảm rủi ro thấp nếu affordability xấu.

Đây là một insight rất mạnh.

Nếu chỉ nhìn Loan Grade A-C, ngân hàng có thể bỏ sót những khách hàng có:

- LTI cao.
- DTI cao.
- Khả năng chi trả yếu.

Điều này cho thấy Loan Grade và Affordability cung cấp thông tin bổ sung cho nhau.

---

# 11. Grade D-G vẫn rủi ro ngay cả khi Affordability chưa Elevated

Grade D-G + Neither Elevated:

```text
Loan Count   = 3,456
Default Rate = 56.22%
```

## Business Insight

Ngược lại:

> Loan Grade thấp vẫn là một tín hiệu rất mạnh ngay cả khi LTI và DTI chưa vượt các ngưỡng elevated.

Điều này có nghĩa:

```text
Loan Grade
và
Affordability
```

đều chứa thông tin rủi ro riêng.

Không nên dùng một yếu tố thay thế hoàn toàn yếu tố còn lại.

---

# 12. Income × Home Ownership

## 12.1 Kết quả

| Income | Housing | Default Rate |
|---|---|---:|
| <50K | RENT | **42.04%** |
| <50K | OWN / MORTGAGE | **16.93%** |
| 50K-100K | RENT | 21.03% |
| 50K-100K | OWN / MORTGAGE | 10.67% |
| 100K+ | RENT | 13.80% |
| 100K+ | OWN / MORTGAGE | **7.25%** |

## Ý nghĩa

Income và Home Ownership kết hợp tạo ra sự phân tách rất rõ.

Trong cùng nhóm thu nhập thấp:

```text
<50K + RENT
42.04%

<50K + OWN/MORTGAGE
16.93%
```

Chênh hơn:

**25 điểm phần trăm**.

---

# 13. Income cao làm giảm mạnh rủi ro trong nhóm RENT

Trong nhóm RENT:

```text
Income <50K      42.04%
Income 50K-100K  21.03%
Income 100K+     13.80%
```

## Business Insight

> RENT không có nghĩa mọi renter đều rủi ro cao như nhau.

Income thay đổi rất mạnh mức rủi ro bên trong nhóm RENT.

Điều này củng cố quan điểm:

```text
Không nên dùng Home Ownership riêng lẻ.
```

Nhóm:

```text
Income <50K + RENT
```

mới là concentration đáng chú ý nhất.

---

# 14. Income <50K + RENT

Nhóm này:

```text
Loan Count                = 8,657
Portfolio Share           = 26.57%
Default Rate              = 42.04%
Default Exposure          = $31.59M
Share of Default Exposure = 40.96%
```

## Business Insight

> Khoảng 26.6% danh mục tạo ra gần 41% tổng dư nợ vỡ nợ.

Đây là một nhóm lớn, không chỉ là một nhóm tỷ lệ cao nhưng sample nhỏ.

Nó có ý nghĩa kinh doanh rất lớn.

---

# 15. Previous Default × Housing × Affordability

Đây là một trong những giao điểm mạnh nhất toàn bộ EDA.

## 15.1 Kết quả

| Previous Default | Housing | Affordability | Default Rate |
|---|---|---|---:|
| Y | RENT | Elevated | **77.43%** |
| N | RENT | Elevated | **66.59%** |
| Y | RENT | Not Elevated | 36.44% |
| Y | NON-RENT | Elevated | 34.60% |
| Y | NON-RENT | Not Elevated | 23.24% |
| N | NON-RENT | Elevated | 16.11% |
| N | RENT | Not Elevated | 14.97% |
| N | NON-RENT | Not Elevated | **7.93%** |

---

# 16. Previous Default = Y + RENT + Affordability Elevated

Kết quả:

```text
Loan Count                = 833
Portfolio Share           = 2.56%
Default Rate              = 77.43%
Default Exposure          = $9.32M
Share of Default Exposure = 12.09%
```

## Business Insight

> Chỉ 2.56% danh mục nhưng tạo ra hơn 12% tổng dư nợ vỡ nợ.

Đây là một risk concentration rất mạnh.

Ba yếu tố cùng xuất hiện:

```text
Lịch sử default
+
RENT
+
Affordability yếu
```

tạo ra một nhóm có tỷ lệ vỡ nợ gần 80%.

---

# 17. Affordability mạnh đến mức nào?

Một finding đặc biệt quan trọng:

```text
Previous Default = N
RENT
Affordability Elevated
→ 66.59%
```

Trong khi:

```text
Previous Default = Y
RENT
Affordability Not Elevated
→ 36.44%
```

## Business Insight

> Affordability có thể tạo ra sức phân tách mạnh hơn Previous Default trong một số giao điểm.

Một người chưa từng default nhưng có khả năng chi trả yếu vẫn có thể nằm trong nhóm observed risk rất cao.

Điều này củng cố kết quả file 07:

**LTI và DTI là các biến cốt lõi trong đánh giá rủi ro.**

---

# 18. Nhóm tốt nhất trong giao điểm này

Nhóm:

```text
Previous Default = N
NON-RENT
Affordability Not Elevated
```

có:

```text
Loan Count      = 11,266
Portfolio Share = 34.58%
Default Rate    = 7.93%
```

## Business Insight

> Một nhóm rất lớn của portfolio có observed risk thấp khi đồng thời không có lịch sử default, không thuộc RENT và không có dấu hiệu affordability elevated.

Điều này cho thấy segmentation không chỉ giúp tìm high-risk concentrations mà còn giúp tìm nhóm có chất lượng tín dụng tốt.

---

# 19. Xếp hạng các Candidate Risk Concentrations

| Segment | Default Rate | Share of Default Exposure |
|---|---:|---:|
| Grade D-G + LTI >=0.30 | **82.51%** | 16.80% |
| Previous Default Y + RENT + Affordability Elevated | **77.43%** | 12.09% |
| Grade D-G + DTI >=0.45 | **72.60%** | 19.84% |
| LTI >=0.30 + DTI >=0.45 | **68.55%** | **46.73%** |
| Previous Default Y + Affordability Elevated | 60.36% | 16.37% |
| Previous Default Y + RENT | 46.86% | 20.40% |
| Income <50K + RENT | 42.04% | **40.96%** |
| Income <50K + Employment <4 years | 36.15% | 25.89% |

---

# 20. Default Rate cao nhất không phải Default Exposure lớn nhất

Ví dụ:

## Grade D-G + LTI >=0.30

```text
Default Rate = 82.51%
Portfolio Share = 2.74%
Default Exposure Share = 16.80%
```

## LTI >=0.30 + DTI >=0.45

```text
Default Rate = 68.55%
Portfolio Share = 10.60%
Default Exposure Share = 46.73%
```

## Business Insight

Segment đầu tiên có tỷ lệ vỡ nợ cao hơn.

Nhưng segment thứ hai có tác động tài chính lớn hơn rất nhiều do quy mô lớn hơn.

Vì vậy:

```text
Risk Rate
+
Segment Size
+
Default Exposure
```

phải luôn được xem cùng nhau.

---

# 21. Nhóm có tác động tài chính lớn nhất

Trong các candidate segment:

### LTI >=0.30 + DTI >=0.45

```text
Default Exposure Share = 46.73%
```

### Income <50K + RENT

```text
Default Exposure Share = 40.96%
```

### Income <50K + Employment <4 Years

```text
Default Exposure Share = 25.89%
```

## Business Insight

Đây là ba concentration đáng ưu tiên nhất nếu mục tiêu là giảm **giá trị dư nợ vỡ nợ**, thay vì chỉ săn tìm nhóm có Default Rate cao nhất.

---

# 22. Lower Observed Risk Intersection

Điều kiện:

```text
Grade A-B
+
LTI <0.20
+
DTI <0.35
+
Previous Default = N
```

Kết quả:

```text
Loan Count                = 11,234
Portfolio Share           = 34.48%
Default Rate              = 5.53%
Loan Exposure             = $76.52M
Exposure Share            = 24.49%
Default Exposure          = $3.24M
Share of Default Exposure = 4.20%
```

## Business Insight

> Hơn một phần ba số khoản vay chỉ tạo ra 4.20% tổng dư nợ vỡ nợ.

Đây là một lower-observed-risk group rất mạnh.

Default Rate:

**5.53%**

so với portfolio:

**21.82%**

tức thấp hơn khoảng:

**16.29 điểm phần trăm**.

---

# 23. So sánh Lower Observed Risk với phần còn lại

| Nhóm | Portfolio Share | Default Rate | Share of Default Exposure |
|---|---:|---:|---:|
| Lower Observed Risk | 34.48% | **5.53%** | **4.20%** |
| Other Portfolio | 65.52% | **30.39%** | **95.80%** |

## Business Insight

Đây là một trong những kết quả phân khúc rõ nhất của toàn bộ dự án.

Một nhóm lớn:

```text
34.48% số khoản vay
```

có chất lượng vượt trội:

```text
5.53% Default Rate
```

Trong khi phần còn lại có:

```text
30.39% Default Rate
```

cao hơn khoảng **5.5 lần**.

Tuy nhiên đây vẫn là **lower observed risk**, không phải nhóm “an toàn tuyệt đối”.

---

# 24. Segmentation Readiness Checkpoint

| Điều kiện | Portfolio Share | Default Rate | Share of Default Exposure |
|---|---:|---:|---:|
| Portfolio | 100% | 21.82% | 100% |
| Income <50K | 40.83% | 33.37% | 48.31% |
| RENT | 50.48% | 31.57% | 72.44% |
| Employment <4 Years | 43.97% | 25.38% | 47.92% |
| Grade D-G | 15.02% | **61.19%** | 44.37% |
| Interest Rate >=12% | 34.21% | 36.62% | 58.71% |
| Loan Amount >=15K | 19.74% | 30.87% | 52.40% |
| LTI >=0.30 | 12.76% | **67.31%** | 54.48% |
| DTI >=0.45 | 19.48% | **46.72%** | 55.50% |
| Previous Default = Y | 17.63% | 37.81% | 30.70% |

---

# 25. Các tín hiệu mạnh nhất sau toàn bộ EDA

Dựa trên file 05-09:

## Nhóm rất mạnh

```text
LTI
Loan Grade
DTI
Home Ownership
Income
Interest Rate
Previous Default
```

## Nhóm mạnh vừa

```text
Loan Amount
Employment Length
Loan Purpose
```

## Nhóm yếu

```text
Age
Loan Term
Credit History Length
```

## Nhóm rất yếu / gần như không phân tách

```text
Gender
Marital Status
Education
Employment Type
Credit Utilization
Open Accounts
Past Delinquencies
Geography
```

---

# 26. Geography vs Financial Risk

Một comparison đơn giản:

```text
Country default range
≈ 21.73% - 21.86%

City default range
≈ 20.43% - 24.19%

LTI band range
≈ 11.50% - 67.31%

Loan Grade range
≈ 9.96% - 98.44%
```

## Business Insight

> Sự khác biệt theo geography nhỏ hơn rất nhiều so với sự khác biệt theo khả năng chi trả và chất lượng khoản vay.

Do đó Power BI nên ưu tiên financial risk visuals trước geographic visuals.

---

# 27. Business Story của toàn bộ Segmentation

Sau khi kết hợp kết quả từ file 04 đến 09, một câu chuyện rất rõ xuất hiện:

```text
Thu nhập thấp
        +
Khoản vay lớn so với thu nhập
        +
DTI cao
        +
Loan Grade thấp
        +
RENT
        +
Previous Default
        ↓
Observed Default Risk tăng mạnh
```

Không phải tất cả các yếu tố đều cần xuất hiện cùng lúc.

Nhưng khi nhiều tín hiệu mạnh cùng xuất hiện, tỷ lệ vỡ nợ tăng rất rõ.

---

# 28. Candidate High-Risk Concentrations

Không nên gọi đây là final risk score, nhưng các nhóm dưới đây có thể được xem là **candidate high-risk concentrations**:

## Nhóm 1

```text
Grade D-G
+
LTI >=0.30
```

Default Rate:

**82.51%**

---

## Nhóm 2

```text
Previous Default = Y
+
RENT
+
Affordability Elevated
```

Default Rate:

**77.43%**

---

## Nhóm 3

```text
Grade D-G
+
DTI >=0.45
```

Default Rate:

**72.60%**

---

## Nhóm 4

```text
LTI >=0.30
+
DTI >=0.45
```

Default Rate:

**68.55%**

Default Exposure Share:

**46.73%**

---

## Nhóm 5

```text
Income <50K
+
RENT
```

Default Rate:

**42.04%**

Default Exposure Share:

**40.96%**

---

# 29. Candidate Lower-Observed-Risk Group

Một candidate lower-observed-risk group rất rõ:

```text
Grade A-B
+
LTI <0.20
+
DTI <0.35
+
Previous Default = N
```

Kết quả:

```text
34.48% Portfolio
5.53% Default Rate
4.20% Total Default Exposure
```

## Business Insight

Đây có thể là nhóm phù hợp để Nova Bank nghiên cứu thêm cho:

- Chính sách pricing cạnh tranh hơn.
- Quy trình xét duyệt nhanh hơn.
- Customer retention.
- Cross-sell.

Tuy nhiên những đề xuất này cần được đánh giá thêm về profitability và policy trước khi triển khai.

---

# 30. Hàm ý cho Power BI

Sau toàn bộ EDA, Power BI nên ưu tiên các visual sau.

## 30.1 Executive KPIs

```text
Total Loans
Total Loan Exposure
Default Count
Default Rate
Default Exposure
Default Exposure Share
```

---

## 30.2 Financial Risk

### LTI Band

Một visual chính.

### DTI Band

Một visual chính.

### LTI × DTI Matrix

Rất quan trọng.

### Loan Grade

Một visual chính.

---

## 30.3 Borrower Profile

Ưu tiên:

```text
Income Band
Home Ownership
Employment Length
Previous Default
```

---

## 30.4 Multi-factor Segmentation

Có thể dùng bảng hoặc matrix:

```text
Segment
Loan Count
Portfolio Share
Default Rate
Loan Exposure
Default Exposure
```

Candidate segments từ file 09 có thể được sử dụng để làm phần này.

---

## 30.5 Geography

Nên dùng Map:

```text
Location = City
Latitude = city_latitude
Longitude = city_longitude
Bubble Size = Loan Exposure
Color = Default Rate
Tooltip:
    Loan Count
    Default Rate
    Default Exposure
```

Tuy nhiên geography nên là phần **portfolio distribution**, không phải risk-driver page chính.

---

# 31. Các biến không cần visual riêng

Nếu dashboard có giới hạn không gian, các biến sau chỉ nên giữ làm slicer hoặc supporting table:

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

Không cần mỗi biến một biểu đồ.

---

# 32. Hàm ý cho file 10 - Power BI Views

Sau kết quả file 09, dự án đã đủ cơ sở để chuyển sang:

```text
10_powerbi_views.sql
```

Các view nên ưu tiên:

## Detailed View

```text
vw_credit_risk_detail
```

Dùng cho:

- Slicer.
- Drill-down.
- Custom visuals.

---

## Portfolio KPI View

```text
vw_portfolio_kpi
```

---

## Risk Segment Summary

```text
vw_risk_segment_summary
```

Nên chứa các dimension mạnh:

```text
Income Band
Home Ownership
Employment Length
Loan Grade
Loan Amount Band
Interest Rate Band
LTI Band
DTI Band
Previous Default
```

---

## Geographic View

```text
vw_geographic_risk
```

Nên có:

```text
Country
State
City
Latitude
Longitude
Loan Count
Default Rate
Loan Exposure
Default Exposure
```

---

## Multi-factor Segment View

Có thể cân nhắc:

```text
vw_risk_segment_candidates
```

nhưng chỉ nên xây sau khi quyết định tên segment cuối cùng.

---

# 33. Lưu ý quan trọng khi diễn giải

1. Geography không nên dùng đơn lẻ làm lending rule.
2. Candidate segments hiện là EDA-based segments, chưa phải credit score.
3. Các segment trong bảng ranking có thể chồng lấn nhau.
4. Không được cộng tổng Loan Count hoặc Exposure của các segment chồng lấn.
5. Ngưỡng LTI và DTI là analytical thresholds, chưa phải policy thresholds.
6. Loan Grade và Interest Rate có thể liên quan đến quá trình pricing/risk assessment hiện tại.
7. RENT là association, không phải nguyên nhân gây default.
8. Lower Observed Risk không có nghĩa zero risk.
9. Final policy recommendation cần kết hợp business constraints và fairness.
10. Power BI nên phản ánh cả Default Rate và Default Exposure.

---

# 34. Kết luận cuối cùng

`09_geography_and_segmentation.sql` hoàn thành hai nhiệm vụ quan trọng.

## Thứ nhất: Geography

Geography có dữ liệu hoàn chỉnh nhưng **không phân tách rủi ro mạnh**.

```text
Country:
21.73% - 21.86%

State:
20.87% - 22.51%

City:
20.43% - 24.19%
```

Do đó geography phù hợp cho monitoring và mapping hơn là risk scoring.

---

## Thứ hai: Multi-factor Segmentation

Việc kết hợp các tín hiệu mạnh tạo ra sự phân tách rất rõ.

Ví dụ:

```text
Grade D-G + LTI >=0.30
→ 82.51%

Previous Default Y
+ RENT
+ Affordability Elevated
→ 77.43%

LTI >=0.30 + DTI >=0.45
→ 68.55%

Income <50K + RENT
→ 42.04%
```

Ngược lại:

```text
Grade A-B
+ LTI <0.20
+ DTI <0.35
+ Previous Default = N
→ 5.53%
```

và nhóm này chiếm tới:

**34.48% danh mục**.

Finding quan trọng nhất của file 09 là:

> **Rủi ro tín dụng không được giải thích tốt bởi một biến đơn lẻ hay bởi geography. Rủi ro được phân tách rõ nhất khi kết hợp khả năng chi trả, chất lượng khoản vay, tình trạng kinh tế của người vay và lịch sử tín dụng.**

Đây là cơ sở cuối cùng để chuyển sang `10_powerbi_views.sql`, nơi các findings đã được xác nhận từ `04-09` sẽ được chuẩn hóa thành các view ổn định phục vụ Power BI.
