# 07 - Financial Risk: Business Insights

**Project:** Risk_Credit_Analytics_Project  
**Source SQL:** `sql/07_financial_risk.sql`  
**Source table:** `credit_risk_clean`  
**Mục tiêu:** Phân tích khả năng chi trả và mức độ gánh nặng tài chính có liên quan như thế nào đến tỷ lệ vỡ nợ và dư nợ vỡ nợ.

---

# 1. Tóm tắt điều hành

Kết quả của `07_financial_risk.sql` cho thấy **LTI và DTI là hai tín hiệu tài chính mạnh nhất**, nhưng mức độ phân tách của chúng không hoàn toàn giống nhau.

Các finding quan trọng nhất:

1. **LTI tăng thì tỷ lệ vỡ nợ tăng rất mạnh**, đặc biệt ở nhóm `LTI >= 0.30`.
2. **DTI cũng tăng cùng tỷ lệ vỡ nợ**, đặc biệt từ `DTI >= 0.45`.
3. **Nhóm đồng thời có LTI cao và DTI cao là một cụm rủi ro rất rõ**, chỉ chiếm 10.60% danh mục nhưng tạo ra 46.73% tổng dư nợ vỡ nợ.
4. **Credit Utilization gần như không phân tách rủi ro**, bất kể chia thành các dải thấp hay cao.
5. **Other Debt tuyệt đối cho pattern ngược chiều kỳ vọng**: nhóm nợ khác thấp lại có tỷ lệ vỡ nợ cao hơn. Điều này cho thấy không nên dùng số nợ tuyệt đối để đánh giá khả năng chi trả nếu không đặt trong tương quan với thu nhập.
6. Flag `is_high_dti` hiện tại chỉ có **4 khoản vay**, quá nhỏ để có ý nghĩa phân khúc.
7. Trong các điều kiện được kiểm tra, **LTI >= 0.30 là tín hiệu đặc biệt mạnh**, vì chỉ chiếm 12.76% số khoản vay nhưng tạo ra 54.48% tổng dư nợ vỡ nợ.

Một affordability pattern rất rõ đang xuất hiện:

```text
Loan Amount lớn so với Income
        ↓
LTI cao
        ↓
Tỷ lệ vỡ nợ tăng mạnh

Tổng gánh nặng nợ cao so với Income
        ↓
DTI cao
        ↓
Tỷ lệ vỡ nợ tăng

LTI cao + DTI cao
        ↓
Rủi ro tập trung rất mạnh
```

---

# 2. Phân bố LTI

## 2.1 Kết quả tổng thể

| Chỉ số | Giá trị |
|---|---:|
| Số quan sát hợp lệ | 32,581 |
| Min | 0.0008 |
| P25 | 0.0897 |
| Median | 0.1481 |
| Average | 0.1706 |
| P75 | 0.2292 |
| Max | 0.8300 |

## Ý nghĩa

Median LTI là **0.1481**, tức khoản vay điển hình tương đương khoảng **14.81% thu nhập** của người vay.

Average là **0.1706**, cao hơn Median, cho thấy một số khoản vay có LTI cao kéo mức trung bình lên.

P75 là **0.2292**, nghĩa là khoảng 75% người vay có LTI không vượt quá khoảng 22.92%.

---

# 3. Tỷ lệ vỡ nợ theo LTI

| LTI | Tỷ trọng danh mục | Tỷ lệ vỡ nợ | Chênh so với danh mục |
|---|---:|---:|---:|
| <0.10 | 29.08% | **11.50%** | -10.31 điểm % |
| 0.10-0.20 | 37.51% | **14.60%** | -7.22 điểm % |
| 0.20-0.30 | 20.65% | **21.34%** | -0.47 điểm % |
| 0.30+ | 12.76% | **67.31%** | +45.49 điểm % |

## 3.1 Ý nghĩa

Tỷ lệ vỡ nợ tăng theo LTI:

```text
<0.10       11.50%
0.10-0.20   14.60%
0.20-0.30   21.34%
0.30+       67.31%
```

Điểm đáng chú ý nhất nằm tại vùng:

```text
LTI < 0.30   → tỷ lệ vỡ nợ tối đa ~21%
LTI >= 0.30  → tỷ lệ vỡ nợ 67.31%
```

Đây là một bước nhảy rất lớn.

Nhóm `LTI >= 0.30` có tỷ lệ vỡ nợ cao hơn khoảng **3.1 lần** mức trung bình toàn danh mục 21.82%.

## Business Insight

> LTI là một trong những tín hiệu rủi ro tài chính mạnh nhất của toàn bộ dự án.

Nhóm `LTI >= 0.30`:

- Chỉ có **4,157 khoản vay**.
- Chiếm **12.76% tổng số khoản vay**.
- Nhưng có **2,798 khoản vỡ nợ**.
- Chiếm khoảng **39.36% tổng số khoản vỡ nợ**.
- Chỉ chiếm **20.91% tổng dư nợ**.
- Nhưng tạo ra **54.48% tổng dư nợ vỡ nợ**.

Đây là một mức tập trung rủi ro rất mạnh.

### Diễn giải dễ hiểu

Nếu một khách hàng có LTI = 0.30, có thể hiểu đơn giản:

```text
Khoản vay = khoảng 30% thu nhập
```

Khi tỷ lệ khoản vay so với thu nhập tăng lên quá cao, khả năng chi trả trở nên căng hơn.

Tuy nhiên, kết quả này vẫn chỉ cho thấy mối liên hệ, không chứng minh LTI cao tự nó gây ra vỡ nợ.

---

# 4. Phân bố DTI

## 4.1 Kết quả tổng thể

| Chỉ số | Giá trị |
|---|---:|
| Số quan sát hợp lệ | 32,581 |
| Min | 0.0645 |
| P25 | 0.2512 |
| Median | 0.3332 |
| Average | 0.3452 |
| P75 | 0.4231 |
| Max | 1.0539 |

## Ý nghĩa

Median DTI là **0.3332**, nghĩa là mức gánh nặng nợ điển hình khoảng 33.32% so với thu nhập.

P75 là **0.4231**, cho thấy khoảng 25% danh mục nằm trên mức DTI khoảng 42%.

---

# 5. Tỷ lệ vỡ nợ theo DTI

| DTI | Tỷ trọng danh mục | Tỷ lệ vỡ nợ | Chênh so với danh mục |
|---|---:|---:|---:|
| <0.25 | 24.66% | **11.48%** | -10.34 điểm % |
| 0.25-0.35 | 30.69% | **14.63%** | -7.18 điểm % |
| 0.35-0.45 | 25.17% | **21.42%** | -0.39 điểm % |
| 0.45+ | 19.48% | **46.72%** | +24.91 điểm % |

## 5.1 Ý nghĩa

DTI cũng cho xu hướng tăng khá rõ:

```text
<0.25       11.48%
0.25-0.35   14.63%
0.35-0.45   21.42%
0.45+       46.72%
```

Nhóm `DTI >= 0.45` có tỷ lệ vỡ nợ hơn gấp đôi mức trung bình danh mục.

## Business Insight

> DTI là một tín hiệu affordability mạnh.

Nhóm `DTI >= 0.45`:

- Chiếm **19.48% số khoản vay**.
- Có tỷ lệ vỡ nợ **46.72%**.
- Tạo ra **2,966 khoản vỡ nợ**.
- Chiếm khoảng **41.73% tổng số khoản vỡ nợ**.
- Chiếm **29.35% tổng dư nợ**.
- Nhưng tạo ra **55.50% tổng dư nợ vỡ nợ**.

Điều này cho thấy gánh nặng nợ cao so với thu nhập đang tập trung một lượng lớn rủi ro tài chính.

---

# 6. So sánh LTI và DTI

Cả LTI và DTI đều mạnh, nhưng kết quả cho thấy LTI tạo ra sự phân tách mạnh hơn tại band cao nhất.

```text
LTI >= 0.30
Default Rate = 67.31%

DTI >= 0.45
Default Rate = 46.72%
```

## Business Insight

> Trong cách chia band hiện tại, LTI có khả năng phân tách nhóm rủi ro cao mạnh hơn DTI.

Điều này hợp lý về mặt phân tích vì LTI trực tiếp cho biết **khoản vay mới lớn đến mức nào so với thu nhập**, trong khi DTI phản ánh gánh nặng nợ tổng thể.

Tuy nhiên, không nên xem LTI và DTI là hai yếu tố hoàn toàn độc lập vì chúng đều liên quan đến Income và nghĩa vụ nợ.

---

# 7. Credit Utilization

## 7.1 Phân bố

| Chỉ số | Giá trị |
|---|---:|
| Min | 0.0500 |
| P25 | 0.2754 |
| Median | 0.5003 |
| Average | 0.4999 |
| P75 | 0.7251 |
| Max | 0.9500 |

Median và Average gần như bằng nhau.

---

# 8. Tỷ lệ vỡ nợ theo Credit Utilization

| Credit Utilization | Tỷ lệ vỡ nợ | Chênh so với danh mục |
|---|---:|---:|
| <0.30 | 21.65% | -0.17 điểm % |
| 0.30-0.50 | 21.61% | -0.20 điểm % |
| 0.50-0.70 | 21.45% | -0.37 điểm % |
| 0.70+ | 22.44% | +0.63 điểm % |

## Ý nghĩa

Tỷ lệ vỡ nợ gần như không thay đổi giữa các mức Credit Utilization.

Khoảng cách giữa nhóm thấp nhất và cao nhất chưa tới **1 điểm phần trăm**.

Ngay cả nhóm `0.70+` cũng chỉ có tỷ lệ vỡ nợ 22.44%, rất gần mức danh mục 21.82%.

## Business Insight

> Credit Utilization gần như không có sức phân tách rủi ro trong dữ liệu hiện tại.

Kết quả banding xác nhận lại finding ở `04_overall_risk.sql`, nơi median và average Credit Utilization giữa Default và Non-default gần như giống nhau.

### Kết luận

**Credit Utilization = tín hiệu yếu.**

Không nên dành một visual chính cho biến này trên dashboard Risk nếu không gian hạn chế.

---

# 9. Other Debt

## 9.1 Phân bố

| Chỉ số | Giá trị |
|---|---:|
| Min | $225.21 |
| P25 | $5,387.17 |
| Median | $8,995.07 |
| Average | $11,567.96 |
| P75 | $14,562.93 |
| Max | $1,187,998.91 |

Average cao hơn Median khá nhiều và Max rất lớn, cho thấy phân phối Other Debt bị lệch phải mạnh.

---

# 10. Tỷ lệ vỡ nợ theo Other Debt

| Other Debt | Tỷ lệ vỡ nợ | Chênh so với danh mục |
|---|---:|---:|
| <5K | **35.08%** | +13.27 điểm % |
| 5K-10K | 22.79% | +0.98 điểm % |
| 10K-15K | 17.22% | -4.60 điểm % |
| 15K+ | **11.95%** | -9.87 điểm % |

## Ý nghĩa

Kết quả đi ngược kỳ vọng đơn giản:

```text
Other Debt thấp  → Default Rate cao
Other Debt cao   → Default Rate thấp
```

Nhóm `<5K` có tỷ lệ vỡ nợ 35.08%, trong khi nhóm `15K+` chỉ 11.95%.

## Business Insight

> Other Debt tuyệt đối không phải là một chỉ báo khả năng chi trả tốt khi đứng riêng.

Một người có $20K nợ khác nhưng thu nhập $150K có thể khỏe hơn người chỉ có $5K nợ nhưng thu nhập $25K.

Điều này giải thích vì sao DTI có giá trị hơn Other Debt tuyệt đối.

### Kết luận

Không nên sử dụng:

```text
Other Debt cao = Rủi ro cao
```

như một quy tắc đơn giản.

Other Debt nên được hiểu trong tương quan với Income.

---

# 11. LTI × DTI Intersection

Đây là phần quan trọng nhất của bước 07.

Một số nhóm chính:

| LTI | DTI | Tỷ lệ vỡ nợ |
|---|---|---:|
| <0.10 | <0.25 | **10.71%** |
| 0.10-0.20 | 0.25-0.35 | 14.30% |
| 0.20-0.30 | 0.35-0.45 | 21.48% |
| 0.30+ | 0.35-0.45 | **61.22%** |
| 0.30+ | 0.45+ | **68.55%** |

## Ý nghĩa

Khi LTI tăng lên 0.30+, tỷ lệ vỡ nợ tăng rất mạnh ngay cả khi DTI mới ở vùng 0.35-0.45.

Nhóm:

```text
LTI >= 0.30
DTI >= 0.45
```

có tỷ lệ vỡ nợ:

**68.55%**

Đây là mức cao nhất trong các nhóm có quy mô lớn.

## Business Insight

> LTI cao kết hợp DTI cao tạo ra một cụm affordability risk rất rõ.

Nhóm này:

- Có **3,453 khoản vay**.
- Chỉ chiếm **10.60% danh mục**.
- Có **2,367 khoản vỡ nợ**.
- Chiếm khoảng **33.30% tổng số khoản vỡ nợ**.
- Chỉ chiếm **17.62% tổng dư nợ**.
- Nhưng tạo ra **46.73% tổng dư nợ vỡ nợ**.

Đây là một trong những concentration signals mạnh nhất của toàn bộ dự án.

---

# 12. Simplified Affordability Groups

| Nhóm | Tỷ trọng danh mục | Tỷ lệ vỡ nợ |
|---|---:|---:|
| Neither Elevated | 78.36% | **14.54%** |
| Elevated DTI Only | 8.89% | **20.69%** |
| Elevated LTI Only | 2.16% | **61.22%** |
| Elevated LTI + Elevated DTI | 10.60% | **68.55%** |

## 12.1 Ý nghĩa

Đây là một kết quả rất quan trọng.

### Neither Elevated

Chiếm phần lớn danh mục:

**78.36%**

nhưng tỷ lệ vỡ nợ chỉ:

**14.54%**

### Elevated DTI Only

Có tỷ lệ vỡ nợ:

**20.69%**

gần với mức danh mục:

**21.82%**

### Elevated LTI Only

Tỷ lệ vỡ nợ tăng lên:

**61.22%**

### Elevated LTI + Elevated DTI

Tỷ lệ vỡ nợ:

**68.55%**

## Business Insight

> Trong cách chia hiện tại, LTI là yếu tố phân tách rất mạnh.

Một finding đặc biệt đáng chú ý là:

```text
DTI cao nhưng LTI chưa cao
→ Default Rate = 20.69%

LTI cao nhưng DTI chưa quá cao
→ Default Rate = 61.22%
```

Điều này cho thấy **LTI cao có vẻ là tín hiệu mạnh hơn DTI cao đứng riêng** trong dataset hiện tại.

Tuy nhiên không nên chuyển ngay thành lending rule. Đây mới là EDA và các ngưỡng trên là ngưỡng phân tích.

---

# 13. Cụm LTI cao + DTI cao là rủi ro tập trung lớn

Nhóm `Elevated LTI + Elevated DTI`:

```text
Portfolio Share            = 10.60%
Default Rate               = 68.55%
Exposure Share             = 17.62%
Share of Default Exposure  = 46.73%
```

## Business Insight

> Chỉ khoảng 1 trong 10 khoản vay nhưng tạo ra gần một nửa tổng dư nợ vỡ nợ.

Đây là nhóm có ý nghĩa kinh doanh rất lớn.

Nếu Power BI cần một nhóm affordability để giám sát, đây là một candidate rất mạnh.

Tuy nhiên nên dùng tên như:

```text
Elevated Affordability Risk
```

thay vì gọi trực tiếp là “High Risk Customer” trước khi hoàn thành toàn bộ EDA và segmentation.

---

# 14. Existing `is_high_dti` Flag

Kết quả:

| Nhóm | Số khoản vay | Tỷ lệ vỡ nợ |
|---|---:|---:|
| High DTI Flag | 4 | 50.00% |
| Not High DTI Flag | 32,577 | 21.81% |

## Ý nghĩa

Flag `is_high_dti` chỉ đánh dấu **4 khoản vay**.

Mặc dù tỷ lệ vỡ nợ là 50%, sample size quá nhỏ để có giá trị phân khúc danh mục.

## Business Insight

> `is_high_dti` hiện không phù hợp để dùng làm một risk segment chính.

Nó có thể được giữ như một flag phát hiện trường hợp cực đoan hoặc anomaly, nhưng không nên đưa lên dashboard như một nhóm rủi ro quan trọng.

Các DTI Bands có giá trị hơn nhiều.

---

# 15. Financial Risk Checkpoint

| Điều kiện | Tỷ trọng danh mục | Tỷ lệ vỡ nợ | Tỷ trọng tổng dư nợ vỡ nợ |
|---|---:|---:|---:|
| Portfolio | 100% | 21.82% | 100% |
| LTI >= 0.30 | 12.76% | **67.31%** | **54.48%** |
| DTI >= 0.45 | 19.48% | **46.72%** | **55.50%** |
| Utilization >= 0.70 | 27.89% | 22.44% | 28.48% |
| LTI >= 0.30 AND DTI >= 0.45 | 10.60% | **68.55%** | **46.73%** |

## Business Insight

Bảng này làm rõ mức độ ưu tiên:

### 1. LTI >= 0.30

Rất mạnh:

```text
12.76% danh mục
→ 54.48% dư nợ vỡ nợ
```

### 2. DTI >= 0.45

Cũng rất mạnh:

```text
19.48% danh mục
→ 55.50% dư nợ vỡ nợ
```

### 3. LTI >= 0.30 + DTI >= 0.45

Cụm tập trung nhất:

```text
10.60% danh mục
→ 46.73% dư nợ vỡ nợ
```

### 4. Utilization >= 0.70

Không đáng chú ý:

```text
27.89% danh mục
→ Default Rate 22.44%
```

gần như mức trung bình 21.82%.

---

# 16. Xếp hạng Financial Risk Signals

| Biến | Mức độ tín hiệu |
|---|---|
| LTI | 🔴 Rất mạnh |
| LTI × DTI | 🔴 Rất mạnh |
| DTI | 🔴 Mạnh |
| Other Debt | 🟠 Có pattern nhưng dễ gây hiểu sai |
| Credit Utilization | ⚪ Rất yếu |
| Existing is_high_dti flag | ⚪ Không đủ mẫu |

> Đây là xếp hạng ưu tiên EDA, không phải feature importance của mô hình dự báo.

---

# 17. Business Story của Financial Risk

Kết quả có thể được tóm tắt như sau:

> Rủi ro vỡ nợ trong danh mục có liên hệ rất mạnh với khả năng chi trả của người vay. Khi số tiền vay trở nên lớn so với thu nhập, thể hiện qua LTI cao, tỷ lệ vỡ nợ tăng mạnh. DTI cũng cho thấy xu hướng tương tự, đặc biệt ở nhóm từ 0.45 trở lên. Khi cả LTI và DTI cùng cao, rủi ro tập trung rất mạnh: chỉ 10.60% số khoản vay nhưng tạo ra 46.73% tổng dư nợ vỡ nợ. Ngược lại, Credit Utilization gần như không tạo ra khác biệt. Other Debt tuyệt đối cho pattern ngược chiều, củng cố quan điểm rằng nợ phải được đánh giá tương đối so với thu nhập thay vì chỉ nhìn số tiền tuyệt đối.

---

# 18. Kết nối với kết quả 04-06

Các bước trước đã chỉ ra:

```text
Lower Income
+
Higher Loan Amount
+
Higher Interest Rate
+
Lower Loan Grade
```

Bước 07 giải thích sâu hơn mối quan hệ giữa Income và Loan Amount:

```text
Lower Income
      +
Higher Loan Amount
      ↓
Higher LTI
      ↓
Much Higher Default Rate
```

Đây là một trong những business stories nhất quán nhất từ đầu dự án đến hiện tại.

---

# 19. Hàm ý cho Power BI

## Nên ưu tiên visual chính

### LTI Band vs Default Rate

Nên có:

- LTI Band.
- Default Rate.
- Loan Count.
- Default Exposure.

### DTI Band vs Default Rate

Tương tự LTI nhưng ưu tiên thấp hơn một chút.

### LTI × DTI Matrix

Đây có thể là một visual heatmap rất mạnh:

```text
Rows    = LTI Band
Columns = DTI Band
Value   = Default Rate
Tooltip = Loan Count + Default Exposure
```

### Affordability Group

Nên có bốn nhóm:

```text
Neither Elevated
Elevated DTI Only
Elevated LTI Only
Elevated LTI + Elevated DTI
```

Đây sẽ là một visual rất dễ hiểu cho stakeholder.

---

## Có thể giảm ưu tiên

- Credit Utilization.
- Other Debt.
- is_high_dti.

Credit Utilization không có signal mạnh.

Other Debt cần giải thích nhiều và dễ gây hiểu sai nếu đứng riêng.

`is_high_dti` chỉ có 4 observations.

---

# 20. Hướng sang 08 - Credit And Stability

Sau khi hoàn thành Financial Risk, bước tiếp theo nên trả lời:

> **Ngoài khả năng chi trả hiện tại, lịch sử tín dụng và độ ổn định của người vay có giúp phân tách rủi ro thêm không?**

`08_credit_stability.sql` nên ưu tiên:

1. Previous Default.
2. Credit History Length.
3. Past Delinquencies.
4. Open Accounts.
5. Employment stability.
6. Housing stability.
7. Previous Default × Employment Stability.
8. Previous Default × affordability indicators ở mức kiểm tra, chưa phải final segmentation.

---

# 21. Lưu ý khi diễn giải

1. Các ngưỡng `LTI >= 0.30` và `DTI >= 0.45` hiện chỉ là **ngưỡng phân tích**, chưa phải lending policy.
2. LTI và DTI có thể có quan hệ với nhau, không nên xem như hai nguyên nhân độc lập.
3. High Default Rate không đồng nghĩa với causation.
4. Other Debt tuyệt đối không nên dùng một mình.
5. Credit Utilization hiện không cho thấy signal nhưng không có nghĩa biến này vô dụng trong mọi interaction.
6. `is_high_dti` quá hiếm để dùng làm segment.
7. Final segmentation chỉ nên thực hiện sau khi hoàn thành 08 và 09.

---

# 22. Kết luận cuối cùng

`07_financial_risk.sql` đã xác định rõ rằng **khả năng chi trả là một trong những trục rủi ro quan trọng nhất của portfolio**.

Ba findings mạnh nhất:

1. **LTI >= 0.30** chỉ chiếm **12.76% số khoản vay** nhưng tạo ra **54.48% tổng dư nợ vỡ nợ**.
2. **DTI >= 0.45** chiếm **19.48% số khoản vay** nhưng tạo ra **55.50% tổng dư nợ vỡ nợ**.
3. **LTI >= 0.30 và DTI >= 0.45** chỉ chiếm **10.60% danh mục** nhưng có tỷ lệ vỡ nợ **68.55%** và tạo ra **46.73% tổng dư nợ vỡ nợ**.

Trong khi đó:

- Credit Utilization gần như không phân tách rủi ro.
- Other Debt tuyệt đối có thể gây hiểu sai nếu không đặt trong tương quan với Income.
- Existing `is_high_dti` flag không có đủ observations để dùng cho segmentation.

Kết quả này củng cố một câu chuyện kinh doanh rất rõ:

> **Rủi ro không đơn giản nằm ở việc khách hàng vay nhiều tiền, mà nằm ở việc khoản vay và tổng nghĩa vụ nợ lớn đến mức nào so với khả năng tài chính của chính khách hàng đó.**

Đây là nền tảng quan trọng để tiếp tục sang `08_credit_stability.sql`, nơi trọng tâm sẽ chuyển từ **khả năng chi trả hiện tại** sang **lịch sử tín dụng và độ ổn định của người vay**.
