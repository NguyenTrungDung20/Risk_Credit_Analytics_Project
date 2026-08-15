# 06 - Loan Analysis: Business Insights

**Project:** Risk_Credit_Analytics_Project  
**Source SQL:** `sql/06_loan_analysis.sql`  
**Source table:** `credit_risk_clean`  
**Mục tiêu:** Phân tích các đặc điểm của khoản vay có liên quan đến tỷ lệ vỡ nợ, quy mô dư nợ và mức độ tập trung rủi ro.

---

# 1. Tóm tắt điều hành

Kết quả của `06_loan_analysis.sql` cho thấy các đặc điểm của khoản vay không có mức độ liên quan với rủi ro giống nhau.

Các tín hiệu nổi bật nhất là:

1. **Hạng khoản vay (Loan Grade)** cho thấy khả năng phân tách rủi ro rất mạnh. Tỷ lệ vỡ nợ tăng từ **9.96% ở Grade A** lên **70.54% ở Grade F** và **98.44% ở Grade G**, mặc dù Grade G có quy mô mẫu rất nhỏ.
2. **Lãi suất** cho thấy xu hướng tăng rủi ro rất rõ. Tỷ lệ vỡ nợ tăng từ **9.40% ở nhóm dưới 8%** lên **58.01% ở nhóm từ 15% trở lên**.
3. **Số tiền vay** có mối liên hệ đáng chú ý với rủi ro, đặc biệt từ **15K trở lên**. Hai nhóm này chỉ chiếm khoảng **19.74% số khoản vay** nhưng tạo ra khoảng **52.40% tổng dư nợ vỡ nợ**.
4. **Mục đích vay** có khả năng phân tách rủi ro ở mức khá. Vay để hợp nhất nợ, y tế và cải thiện nhà ở có tỷ lệ vỡ nợ cao hơn; vay cho kinh doanh và giáo dục thấp hơn.
5. **Kỳ hạn vay** gần như không tạo ra khác biệt lớn. Tỷ lệ vỡ nợ chỉ dao động khoảng **19.94%–22.34%**.
6. **Thiếu dữ liệu lãi suất** không cho thấy một nhóm rủi ro bất thường và tỷ lệ thiếu khá đồng đều giữa các Loan Grade. Vì vậy chưa có dấu hiệu rõ rằng missing interest rate đang làm lệch mạnh kết quả phân tích theo hạng vay.

Kết quả này củng cố một câu chuyện rủi ro khá rõ:

```text
Lower Loan Grade
        +
Higher Interest Rate
        +
Larger Loan Amount
        ↓
Higher observed default association
```

Tuy nhiên, đây vẫn là mối liên hệ quan sát được, không phải bằng chứng về quan hệ nguyên nhân.

---

# 2. Mục đích vay

## 2.1 Kết quả

| Mục đích vay | Tỷ trọng danh mục | Tỷ lệ vỡ nợ | Tỷ lệ dư nợ vỡ nợ |
|---|---:|---:|---:|
| DEBTCONSOLIDATION | 16.00% | **28.59%** | **33.12%** |
| MEDICAL | 18.63% | **26.70%** | **32.28%** |
| HOMEIMPROVEMENT | 11.06% | **26.10%** | 24.92% |
| PERSONAL | 16.95% | 19.89% | 21.84% |
| EDUCATION | 19.81% | 17.22% | 19.87% |
| VENTURE | 17.55% | **14.81%** | **17.17%** |

## 2.2 Ý nghĩa

Mục đích vay cho thấy sự khác biệt đáng kể hơn nhiều so với các biến nhân khẩu học ở bước 05.

Ba nhóm có tỷ lệ vỡ nợ cao nhất là:

1. **DEBTCONSOLIDATION: 28.59%**
2. **MEDICAL: 26.70%**
3. **HOMEIMPROVEMENT: 26.10%**

Trong khi:

- EDUCATION: 17.22%
- VENTURE: 14.81%

Nhóm DEBTCONSOLIDATION có tỷ lệ vỡ nợ gần **1.93 lần** nhóm VENTURE.

## Business Insight

> Mục đích vay có liên hệ đáng kể với khả năng vỡ nợ.

Đặc biệt, các khoản vay để **hợp nhất nợ** và **chi phí y tế** vừa có tỷ lệ vỡ nợ cao, vừa có quy mô đủ lớn để tạo tác động đáng kể lên danh mục.

Hai nhóm DEBTCONSOLIDATION và MEDICAL cộng lại:

- Chiếm khoảng **34.63% tổng số khoản vay**.
- Tạo ra khoảng **43.77% tổng số khoản vỡ nợ**.
- Tạo ra khoảng **45.00% tổng dư nợ vỡ nợ**.

Đây là một mức tập trung đáng chú ý.

### Diễn giải

Vay để hợp nhất nợ có thể phản ánh người vay đang có nghĩa vụ nợ sẵn từ trước, còn vay y tế có thể xuất phát từ nhu cầu chi tiêu khó trì hoãn. Tuy nhiên, dữ liệu hiện tại **không chứng minh nguyên nhân**.

Cần kiểm tra các nhóm này cùng:

- Income.
- LTI.
- DTI.
- Other Debt.

ở các bước phân tích sau.

---

# 3. Hạng khoản vay

## 3.1 Kết quả

| Grade | Tỷ trọng danh mục | Tỷ lệ vỡ nợ | Lãi suất TB | Số tiền vay TB |
|---|---:|---:|---:|---:|
| A | 33.08% | **9.96%** | 7.33% | $8,539 |
| B | 32.08% | **16.28%** | 11.00% | $9,995 |
| C | 19.82% | **20.73%** | 13.46% | $9,214 |
| D | 11.13% | **59.05%** | 15.36% | $10,849 |
| E | 2.96% | **64.42%** | 17.01% | $12,916 |
| F | 0.74% | **70.54%** | 18.61% | $14,717 |
| G | 0.20% | **98.44%** | 20.25% | $17,196 |

## 3.2 Ý nghĩa

Loan Grade cho thấy một xu hướng rất rõ:

```text
A → B → C → D → E → F → G
9.96%
16.28%
20.73%
59.05%
64.42%
70.54%
98.44%
```

Điểm thay đổi mạnh nhất xuất hiện từ:

```text
Grade C = 20.73%
Grade D = 59.05%
```

tức tăng hơn **38 điểm phần trăm**.

Đồng thời, lãi suất trung bình cũng tăng gần như liên tục:

```text
A = 7.33%
B = 11.00%
C = 13.46%
D = 15.36%
E = 17.01%
F = 18.61%
G = 20.25%
```

## Business Insight

> Loan Grade hiện là một trong những tín hiệu rủi ro mạnh nhất của toàn bộ dự án.

Hệ thống Grade đang phân tách khá rõ các nhóm có kết quả trả nợ khác nhau.

Đồng thời, Loan Grade càng thấp thì lãi suất nhìn chung càng cao. Điều này cho thấy hạng vay và giá khoản vay có liên hệ rất chặt.

Tuy nhiên không nên kết luận:

```text
Lãi suất cao → gây ra vỡ nợ
```

Có thể quy trình thực tế là:

```text
Khách hàng được đánh giá rủi ro cao
        ↓
Loan Grade thấp hơn
        ↓
Lãi suất được định giá cao hơn
```

Do đó Loan Grade và Interest Rate có thể cùng phản ánh một đánh giá rủi ro nền tảng.

---

# 4. Mức tập trung rủi ro ở Grade D-G

Khi gộp Grade D đến G:

- Số khoản vay: **4,895**
- Chiếm khoảng **15.02% tổng số khoản vay**
- Chiếm khoảng **18.06% tổng dư nợ**
- Tạo ra **2,995 khoản vỡ nợ**
- Chiếm khoảng **42.14% tổng số khoản vỡ nợ**
- Tạo ra khoảng **$34.22 triệu dư nợ vỡ nợ**
- Chiếm khoảng **44.37% tổng dư nợ vỡ nợ**

## Business Insight

> Chỉ khoảng 15% số khoản vay đang tạo ra hơn 42% số trường hợp vỡ nợ.

Đây là một mức tập trung rất mạnh.

Trong đó Grade D đặc biệt quan trọng vì:

- Quy mô lớn hơn E/F/G nhiều.
- Tỷ lệ vỡ nợ đã lên tới 59.05%.
- Dư nợ vỡ nợ khoảng **$22.80 triệu**.

Do đó Grade D có tác động kinh doanh lớn hơn Grade G, dù Grade G có tỷ lệ vỡ nợ gần 100%.

### Lưu ý về Grade G

Grade G chỉ có **64 khoản vay**, vì vậy kết quả 98.44% cần được đọc thận trọng.

Một tỷ lệ cực cao trên nhóm nhỏ không đồng nghĩa với tác động lớn nhất lên toàn danh mục.

---

# 5. Kỳ hạn khoản vay

## 5.1 Kết quả

| Kỳ hạn | Tỷ trọng danh mục | Tỷ lệ vỡ nợ |
|---|---:|---:|
| 12 tháng | 10.25% | 19.94% |
| 24 tháng | 19.56% | 22.09% |
| 36 tháng | 39.73% | 21.76% |
| 60 tháng | 30.46% | 22.34% |

## 5.2 Ý nghĩa

Tỷ lệ vỡ nợ chỉ dao động từ:

**19.94% đến 22.34%**

Khoảng cách giữa nhóm cao nhất và thấp nhất chỉ khoảng **2.40 điểm phần trăm**.

Số tiền vay trung bình và lãi suất trung bình cũng gần như tương đương giữa các kỳ hạn.

## Business Insight

> Kỳ hạn vay hiện không cho thấy khả năng phân tách rủi ro mạnh.

Dù nhóm 60 tháng có tỷ lệ vỡ nợ cao nhất, mức chênh so với các nhóm khác khá nhỏ.

### Kết luận

**Loan Term = tín hiệu yếu.**

Có thể giữ trên Power BI để phân tích hoặc lọc nhưng không nên dành visual chính nếu không gian dashboard hạn chế.

---

# 6. Phân bố số tiền vay

## 6.1 Kết quả tổng thể

| Chỉ số | Giá trị |
|---|---:|
| Min | $500 |
| P25 | $5,000 |
| Median | $8,000 |
| Average | $9,589.37 |
| P75 | $12,200 |
| Max | $35,000 |

## Ý nghĩa

Average cao hơn Median xác nhận Loan Amount có phân phối lệch phải.

Khoảng 75% khoản vay có giá trị không vượt quá khoảng **$12,200**, trong khi một nhóm khoản vay lớn kéo mức trung bình lên.

Việc sử dụng các dải khoản vay thay vì chỉ nhìn average là hợp lý.

---

# 7. Tỷ lệ vỡ nợ theo số tiền vay

| Dải khoản vay | Tỷ trọng số khoản vay | Tỷ lệ vỡ nợ | Tỷ trọng dư nợ |
|---|---:|---:|---:|
| <5K | 22.85% | 20.78% | 7.28% |
| 5K-10K | 35.05% | **17.96%** | 25.07% |
| 10K-15K | 22.36% | 20.93% | 26.76% |
| 15K-20K | 10.05% | **28.15%** | 16.94% |
| 20K+ | 9.69% | **33.68%** | 23.95% |

## 7.1 Ý nghĩa

Mối quan hệ không hoàn toàn tăng đều ở các khoản vay nhỏ và trung bình.

Nhóm có tỷ lệ vỡ nợ thấp nhất là:

**5K-10K: 17.96%**

Sau đó tỷ lệ tăng rõ khi khoản vay vượt 15K:

```text
15K-20K = 28.15%
20K+     = 33.68%
```

Nhóm 20K+ có tỷ lệ vỡ nợ gần **1.88 lần** nhóm 5K-10K.

## Business Insight

> Khoản vay lớn, đặc biệt từ 15K trở lên, có liên hệ rõ hơn với rủi ro vỡ nợ.

Tuy nhiên Loan Amount không nên được xem độc lập vì số tiền vay phải được đặt trong mối quan hệ với thu nhập.

Một khoản vay $20K có thể rất lớn đối với khách hàng thu nhập $30K nhưng không lớn đối với khách hàng thu nhập $150K.

Do đó kết quả này dẫn trực tiếp sang LTI trong `07_financial_risk.sql`.

---

# 8. Mức tập trung rủi ro ở khoản vay từ 15K trở lên

Hai nhóm `15K-20K` và `20K+` cộng lại:

- Có **6,431 khoản vay**
- Chỉ chiếm khoảng **19.74% tổng số khoản vay**
- Nhưng chiếm khoảng **40.89% tổng dư nợ**
- Tạo ra **1,985 khoản vỡ nợ**
- Chiếm khoảng **27.93% tổng số khoản vỡ nợ**
- Tạo ra khoảng **$40.42 triệu dư nợ vỡ nợ**
- Chiếm khoảng **52.40% tổng dư nợ vỡ nợ**

## Business Insight

> Chưa đến 20% số khoản vay nhưng lại tạo ra hơn một nửa tổng dư nợ vỡ nợ.

Đây là một insight rất quan trọng về **mức độ thiệt hại tiềm năng theo quy mô khoản vay**.

Nó cho thấy ngân hàng không nên chỉ theo dõi:

```text
Tỷ lệ vỡ nợ
```

mà phải theo dõi thêm:

```text
Dư nợ vỡ nợ
```

Một nhóm không chiếm quá nhiều số khoản vay vẫn có thể tạo ảnh hưởng tài chính lớn nếu các khoản vay có giá trị cao.

---

# 9. Phân bố lãi suất

## 9.1 Kết quả tổng thể

| Chỉ số | Giá trị |
|---|---:|
| Số khoản có lãi suất | 29,465 |
| Min | 5.42% |
| P25 | 7.90% |
| Median | 10.99% |
| Average | 11.01% |
| P75 | 13.47% |
| Max | 23.22% |

Median và Average gần như bằng nhau, cho thấy vùng trung tâm của phân phối lãi suất tương đối cân bằng hơn so với Income hay Loan Amount.

---

# 10. Tỷ lệ vỡ nợ theo dải lãi suất

| Dải lãi suất | Tỷ trọng danh mục | Tỷ lệ vỡ nợ |
|---|---:|---:|
| <8% | 23.85% | **9.40%** |
| 8%-10% | 11.41% | **13.74%** |
| 10%-12% | 20.96% | **16.71%** |
| 12%-15% | 23.65% | **27.07%** |
| 15%+ | 10.56% | **58.01%** |
| Unknown | 9.56% | 20.67% |

## 10.1 Ý nghĩa

Đây là một trong những pattern rõ nhất của toàn bộ EDA:

```text
<8%       9.40%
8%-10%   13.74%
10%-12%  16.71%
12%-15%  27.07%
15%+     58.01%
```

Tỷ lệ vỡ nợ tăng gần như liên tục khi lãi suất tăng.

Nhóm `15%+` có tỷ lệ vỡ nợ cao hơn khoảng **6.2 lần** nhóm `<8%`.

## Business Insight

> Lãi suất là một tín hiệu phân tách rủi ro rất mạnh trong dữ liệu.

Đặc biệt từ mức **12% trở lên**, tỷ lệ vỡ nợ tăng mạnh.

Tuy nhiên, cần đặc biệt thận trọng về nguyên nhân.

Lãi suất cao có thể:

1. Làm tăng gánh nặng trả nợ.
2. Phản ánh việc ngân hàng đã định giá cao hơn cho khách hàng được đánh giá rủi ro hơn.
3. Đồng thời chịu ảnh hưởng của Loan Grade.

Do đó không nên kết luận lãi suất cao tự nó gây ra vỡ nợ.

---

# 11. Mức tập trung rủi ro ở lãi suất từ 12% trở lên

Hai nhóm `12%-15%` và `15%+` cộng lại:

- Có **11,147 khoản vay**
- Chiếm khoảng **34.21% tổng số khoản vay**
- Tạo ra **4,082 khoản vỡ nợ**
- Chiếm khoảng **57.43% tổng số khoản vỡ nợ**
- Chiếm khoảng **36.80% tổng dư nợ**
- Tạo ra khoảng **$45.28 triệu dư nợ vỡ nợ**
- Chiếm khoảng **58.71% tổng dư nợ vỡ nợ**

## Business Insight

> Khoảng một phần ba danh mục, tập trung ở các khoản vay có lãi suất từ 12% trở lên, tạo ra gần 60% tổng dư nợ vỡ nợ.

Đây là một mức tập trung rất đáng chú ý và nên xuất hiện trên Power BI.

Riêng nhóm `15%+`:

- Chỉ chiếm 10.56% số khoản vay.
- Nhưng tạo ra khoảng **28.08% tổng số khoản vỡ nợ**.
- Và khoảng **30.20% tổng dư nợ vỡ nợ**.

---

# 12. Dữ liệu lãi suất bị thiếu

## 12.1 Kết quả

| Trạng thái | Tỷ trọng danh mục | Tỷ lệ vỡ nợ |
|---|---:|---:|
| Có lãi suất | 90.44% | 21.94% |
| Thiếu lãi suất | 9.56% | 20.67% |

## Ý nghĩa

Tỷ lệ vỡ nợ của hai nhóm chỉ chênh:

**1.27 điểm phần trăm**

Nhóm thiếu lãi suất không có tỷ lệ vỡ nợ bất thường cao hơn.

Số tiền vay trung bình cũng gần như giống nhau:

```text
Có lãi suất     ≈ $9,585
Thiếu lãi suất  ≈ $9,633
```

## Business Insight

> Việc thiếu dữ liệu lãi suất hiện không cho thấy một nhóm khách hàng có hành vi vỡ nợ khác biệt lớn.

Điều này làm giảm lo ngại rằng các phân tích lãi suất đang bỏ sót một nhóm rủi ro đặc biệt lớn.

Tuy nhiên, vì vẫn thiếu **9.56%** dữ liệu nên mọi KPI lãi suất phải ghi rõ phạm vi dữ liệu được sử dụng.

---

# 13. Dữ liệu lãi suất thiếu theo Loan Grade

| Grade | Coverage | Missing |
|---|---:|---:|
| A | 90.69% | 9.31% |
| B | 89.90% | 10.10% |
| C | 90.24% | 9.76% |
| D | 91.40% | 8.60% |
| E | 91.39% | 8.61% |
| F | 88.80% | 11.20% |
| G | 92.19% | 7.81% |

## Ý nghĩa

Tỷ lệ thiếu dữ liệu nhìn chung nằm trong khoảng khoảng **8%–11%** ở hầu hết các Grade.

Không thấy một xu hướng rõ như:

```text
Grade càng thấp → thiếu lãi suất càng nhiều
```

hoặc ngược lại.

Grade F có mức thiếu cao nhất 11.20%, nhưng chỉ có 241 khoản vay.

## Business Insight

> Missing interest rate không có dấu hiệu tập trung mạnh ở một hạng khoản vay cụ thể.

Điều này hỗ trợ việc sử dụng Interest Rate để phân tích rủi ro theo toàn danh mục, với caveat coverage khoảng 90%.

---

# 14. Kiểm tra lại Default vs Non-default

| Kết quả | Số khoản vay | Số tiền vay TB | Lãi suất TB |
|---|---:|---:|---:|
| Không vỡ nợ | 25,473 | $9,237.46 | 10.44% |
| Vỡ nợ | 7,108 | $10,850.50 | 13.06% |

## Ý nghĩa

Kết quả này xác nhận lại finding từ `04_overall_risk.sql`:

- Khoản vỡ nợ có số tiền vay trung bình lớn hơn.
- Khoản vỡ nợ có lãi suất trung bình cao hơn.

Chênh lệch số tiền vay trung bình khoảng **$1,613**.

Chênh lệch lãi suất trung bình khoảng **2.62 điểm phần trăm**.

## Business Insight

> Loan Amount và Interest Rate đều tiếp tục cho thấy sự phân tách giữa nhóm vỡ nợ và không vỡ nợ.

Điều này phù hợp với kết quả banding ở các phần trước và củng cố độ tin cậy của observed pattern.

---

# 15. Xếp hạng mức độ tín hiệu của Loan Analysis

| Biến | Mức độ tín hiệu |
|---|---|
| Loan Grade | 🔴 Rất mạnh |
| Interest Rate | 🔴 Rất mạnh |
| Loan Amount | 🔴 Mạnh, đặc biệt 15K+ |
| Loan Purpose | 🟠 Khá mạnh |
| Loan Term | ⚪ Yếu |
| Missing Interest Rate | ⚪ Không cho thấy risk signal mạnh |

> Đây là xếp hạng ưu tiên EDA, không phải feature importance của mô hình dự báo.

---

# 16. Business Story của Loan Analysis

Kết quả của `06_loan_analysis.sql` có thể được tóm tắt như sau:

> Rủi ro vỡ nợ có sự khác biệt rõ theo hạng khoản vay, lãi suất, quy mô khoản vay và mục đích sử dụng khoản vay. Các Grade thấp hơn có tỷ lệ vỡ nợ và lãi suất cao hơn rất rõ. Những khoản vay từ 15K trở lên chỉ chiếm chưa đến 20% số khoản vay nhưng tạo ra hơn một nửa tổng dư nợ vỡ nợ. Các khoản vay có lãi suất từ 12% trở lên cũng tạo ra gần 60% tổng dư nợ vỡ nợ. Ngược lại, kỳ hạn vay gần như không phân tách rủi ro. Mục đích vay cho thấy rủi ro tập trung hơn ở hợp nhất nợ và y tế, trong khi vay kinh doanh và giáo dục có tỷ lệ vỡ nợ thấp hơn.

Một pattern tổng quát đang hình thành:

```text
Lower Loan Grade
        +
Higher Interest Rate
        +
Larger Loan Amount
        +
Certain Loan Purposes
        ↓
Higher observed default association
```

---

# 17. Insight quan trọng nhất

## Insight 1 — Loan Grade là tín hiệu phân tách rất mạnh

Tỷ lệ vỡ nợ tăng từ:

**9.96% ở Grade A**

lên:

**59.05% ở Grade D**

và tiếp tục tăng ở E/F/G.

Điểm C → D là một breakpoint rất đáng chú ý.

---

## Insight 2 — Lãi suất có xu hướng tăng cùng tỷ lệ vỡ nợ

Tỷ lệ vỡ nợ tăng từ:

**9.40% ở dưới 8%**

lên:

**58.01% ở 15%+**

Đây là một trong những quan hệ rõ nhất của dataset.

---

## Insight 3 — Khoản vay lớn tạo ra mức thiệt hại tiềm năng rất lớn

Các khoản từ 15K trở lên:

- Chỉ chiếm khoảng 19.74% số khoản vay.
- Nhưng chiếm khoảng 52.40% tổng dư nợ vỡ nợ.

Do đó Loan Amount cần được quản lý theo cả **tỷ lệ vỡ nợ** và **giá trị vốn có nguy cơ mất**.

---

## Insight 4 — Mục đích vay có ý nghĩa

DEBTCONSOLIDATION và MEDICAL có mức rủi ro cao hơn đáng kể.

Hai nhóm này tạo ra khoảng:

- 43.77% số khoản vỡ nợ.
- 45.00% tổng dư nợ vỡ nợ.

---

## Insight 5 — Kỳ hạn vay không phải tín hiệu mạnh

12, 24, 36 và 60 tháng đều có tỷ lệ vỡ nợ quanh mức 20%–22%.

Không có bằng chứng mạnh từ EDA hiện tại rằng kỳ hạn tự nó phân tách rủi ro tốt.

---

## Insight 6 — Missing Interest Rate chưa tạo ra lo ngại lớn về thiên lệch

Nhóm thiếu lãi suất có tỷ lệ vỡ nợ gần nhóm có dữ liệu và missing rate cũng tương đối đồng đều giữa Loan Grade.

Vì vậy có thể tiếp tục sử dụng lãi suất trong phân tích, nhưng cần ghi rõ coverage 90.44%.

---

# 18. Hàm ý cho Power BI

## Các biến nên được ưu tiên

### Loan Grade

Nên có visual thể hiện:

```text
Loan Grade
→ Default Rate
→ Loan Count
→ Default Exposure
```

Grade D cần được nhấn mạnh vì vừa có tỷ lệ rủi ro cao vừa có quy mô đáng kể.

### Interest Rate Band

Đây nên là một visual chính.

Có thể sử dụng:

- Column chart: Interest Rate Band vs Default Rate.
- Tooltip: Loan Count và Default Exposure.

### Loan Amount Band

Nên hiển thị đồng thời:

- Default Rate.
- Loan Exposure.
- Default Exposure.

Đặc biệt làm rõ nhóm `15K+`.

### Loan Purpose

Nên xếp theo Default Rate hoặc Default Exposure.

DEBTCONSOLIDATION và MEDICAL là các nhóm đáng chú ý nhất.

---

## Biến có thể giữ làm slicer hoặc visual phụ

- Loan Term.
- Pricing Data Status.

Hai biến này hiện không có sức phân tách rủi ro đủ mạnh để chiếm không gian lớn trên dashboard chính.

---

# 19. Những chỉ số nên giữ cho Power BI

Các analytical views sau này nên có tối thiểu:

```text
Loan Count
Default Count
Default Rate
Loan Exposure
Default Exposure
Default Exposure Rate
Portfolio Share
Exposure Share
```

Đối với Interest Rate nên có thêm:

```text
Interest Rate Coverage
```

Không nên chỉ nhìn Default Rate vì một nhóm có tỷ lệ cao nhưng quy mô nhỏ có thể ít quan trọng hơn một nhóm có tỷ lệ thấp hơn nhưng dư nợ rất lớn.

---

# 20. Hướng chuyển sang 07 - Financial Risk

Kết quả từ `04`, `05` và `06` hiện đã tạo ra các tín hiệu mạnh:

```text
Lower Income
+
Higher Loan Amount
+
Higher Interest Rate
+
Lower Loan Grade
+
Higher Default Rate
```

Bước tiếp theo cần trả lời:

> **Rủi ro có thực sự liên quan đến việc khoản vay quá lớn so với khả năng tài chính của người vay hay không?**

Do đó `07_financial_risk.sql` nên ưu tiên:

1. Loan-to-Income Ratio bands.
2. Debt-to-Income Ratio bands.
3. Credit Utilization bands.
4. Other Debt.
5. LTI × DTI intersection.
6. Exposure concentration theo affordability.
7. Kiểm tra các ngưỡng rủi ro cao đã được tạo ở cleaning layer.
8. Chỉ sau khi phân tích từng biến mới kiểm tra các tổ hợp affordability.

---

# 21. Lưu ý khi diễn giải

1. **Loan Grade và Interest Rate có liên hệ chặt**, nên không được xem chúng là hai nguyên nhân độc lập nếu chưa có kiểm định sâu hơn.
2. Interest Rate cao không nhất thiết gây ra vỡ nợ; nó có thể phản ánh risk-based pricing.
3. Loan Amount cần được đặt trong mối quan hệ với Income.
4. Tỷ lệ vỡ nợ phải luôn được đọc cùng Sample Size và Exposure.
5. Grade G có tỷ lệ rất cao nhưng chỉ có 64 khoản vay.
6. Mục đích vay chỉ cho thấy association, không phải nguyên nhân.
7. Kỳ hạn có tín hiệu yếu nhưng chưa cần loại khỏi dữ liệu.
8. Missing Interest Rate vẫn cần được ghi chú do coverage chỉ 90.44%.

---

# 22. Kết luận cuối cùng

`06_loan_analysis.sql` đã xác định được ba yếu tố khoản vay có sức phân tách rủi ro rõ nhất:

1. **Loan Grade**
2. **Interest Rate**
3. **Loan Amount**

Trong đó:

- Grade D-G chỉ chiếm khoảng **15.02% số khoản vay** nhưng tạo ra khoảng **44.37% tổng dư nợ vỡ nợ**.
- Các khoản vay từ **15K trở lên** chỉ chiếm khoảng **19.74% số khoản vay** nhưng tạo ra khoảng **52.40% tổng dư nợ vỡ nợ**.
- Các khoản vay có lãi suất từ **12% trở lên** chiếm khoảng **34.21% số khoản vay** nhưng tạo ra khoảng **58.71% tổng dư nợ vỡ nợ**.
- DEBTCONSOLIDATION và MEDICAL là hai mục đích vay có mức tập trung rủi ro đáng chú ý.
- Loan Term không cho thấy sự khác biệt đủ lớn để được xem là risk signal chính.
- Dữ liệu lãi suất bị thiếu không có dấu hiệu tập trung bất thường theo Loan Grade.

Kết quả này tạo nền tảng rất rõ để chuyển sang `07_financial_risk.sql`, nơi trọng tâm sẽ không còn là **khoản vay lớn bao nhiêu**, mà là:

> **Khoản vay lớn đến mức nào so với khả năng tài chính của người vay?**
