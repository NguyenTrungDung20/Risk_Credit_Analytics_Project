# 05 - Borrower Profile: Business Insights

**Project:** Risk_Credit_Analytics_Project  
**Source SQL:** `sql/05_borrower_profile.sql`  
**Source table:** `credit_risk_clean`  
**Mục tiêu:** Xác định những đặc điểm của người vay có liên quan đến tỷ lệ vỡ nợ cao hoặc thấp.

---

## 1. Tóm tắt điều hành

Kết quả của `05_borrower_profile.sql` cho thấy **không phải mọi đặc điểm người vay đều có giá trị phân tách rủi ro như nhau**.

Ba tín hiệu nổi bật nhất là:

1. **Thu nhập**: tỷ lệ vỡ nợ giảm rất rõ khi thu nhập tăng.
2. **Thâm niên làm việc**: người có thời gian làm việc dài hơn có tỷ lệ vỡ nợ thấp hơn.
3. **Tình trạng sở hữu nhà**: nhóm thuê nhà có tỷ lệ vỡ nợ cao hơn nhiều so với nhóm có thế chấp hoặc sở hữu nhà.

Ngược lại, các yếu tố sau gần như không tạo ra khác biệt đáng kể:

- Giới tính.
- Tình trạng hôn nhân.
- Trình độ học vấn.
- Loại hình việc làm.
- Tuổi, nếu chỉ xét theo các nhóm tuổi hiện tại.

Ngoài ra, nhóm bị thiếu dữ liệu về thâm niên làm việc có tỷ lệ vỡ nợ cao hơn đáng kể so với nhóm có dữ liệu đầy đủ. Đây là một tín hiệu cần điều tra thêm về quy trình thu thập dữ liệu, nhưng chưa nên xem thiếu dữ liệu là nguyên nhân gây vỡ nợ.

---

# 2. Phân bố độ tuổi

## 2.1 Kết quả tổng thể

| Chỉ số | Giá trị |
|---|---:|
| Số quan sát hợp lệ | 32,576 |
| Tuổi nhỏ nhất | 20 |
| P25 | 23 |
| Trung vị | 26 |
| Trung bình | 27.72 |
| P75 | 30 |
| Tuổi lớn nhất | 94 |

### Ý nghĩa

Phần lớn người vay còn khá trẻ.

- 25% người vay có tuổi từ 23 trở xuống.
- Một nửa người vay có tuổi từ 26 trở xuống.
- 75% người vay có tuổi từ 30 trở xuống.

Tuổi trung bình là **27.72**, cao hơn trung vị **26**, cho thấy có một nhóm người vay lớn tuổi kéo mức trung bình lên.

Giá trị lớn nhất là **94 tuổi**, nhưng vì đây chỉ là một giá trị cực đại nên không nên dùng để đại diện cho nhóm người vay nói chung.

---

# 3. Tỷ lệ vỡ nợ theo nhóm tuổi

| Nhóm tuổi | Tỷ trọng danh mục | Tỷ lệ vỡ nợ |
|---|---:|---:|
| <25 | 37.80% | 23.22% |
| 25-34 | 49.66% | 20.97% |
| 35-44 | 10.21% | 20.57% |
| 45-54 | 1.84% | 21.96% |
| 55+ | 0.47% | 25.32% |
| Không xác định | 0.02% | 0.00% |

## Ý nghĩa

Tỷ lệ vỡ nợ giữa các nhóm tuổi chính không chênh lệch quá lớn.

Ba nhóm chiếm phần lớn danh mục:

- `<25`: 23.22%
- `25-34`: 20.97%
- `35-44`: 20.57%

Mức chênh giữa nhóm `<25` và `35-44` chỉ khoảng **2.65 điểm phần trăm**.

Nhóm `55+` có tỷ lệ vỡ nợ cao nhất là **25.32%**, nhưng chỉ có **154 khoản vay**, tương đương **0.47% danh mục**. Vì vậy không nên xem đây là bằng chứng mạnh rằng người lớn tuổi rủi ro hơn.

## Business Insight

> Tuổi hiện chưa cho thấy khả năng phân tách rủi ro mạnh trong danh mục.

Nhóm dưới 35 tuổi chiếm khoảng **87.46% tổng số khoản vay** và cũng chiếm gần tương ứng phần lớn số khoản vỡ nợ. Điều này cho thấy số lượng vỡ nợ lớn ở nhóm trẻ phần lớn đến từ việc họ chiếm tỷ trọng rất lớn trong danh mục, chứ không phải vì tỷ lệ vỡ nợ cao vượt trội.

### Kết luận

**Age = tín hiệu yếu ở mức EDA hiện tại.**

Nên giữ tuổi để phân tích và lọc trên Power BI, nhưng không nên xem tuổi là biến trọng tâm của chính sách rủi ro chỉ dựa trên kết quả này.

---

# 4. Phân bố thu nhập

## 4.1 Kết quả tổng thể

| Chỉ số | Giá trị |
|---|---:|
| Thu nhập nhỏ nhất | $4,000 |
| P25 | $38,500 |
| Trung vị | $55,000 |
| Trung bình | $66,074.85 |
| P75 | $79,200 |
| Thu nhập lớn nhất | $6,000,000 |

## Ý nghĩa

Thu nhập có phân phối lệch phải rất rõ.

Trung vị chỉ là **$55,000** trong khi trung bình là **$66,074.85**, và giá trị cực đại lên tới **$6,000,000**.

Điều này cho thấy một số người có thu nhập rất cao kéo giá trị trung bình lên.

## Business Insight

> Khi phân tích thu nhập, trung vị và các nhóm thu nhập có ý nghĩa hơn việc chỉ nhìn vào thu nhập trung bình.

Việc chia thành các dải thu nhập trong query là hợp lý và giúp nhìn rõ mối quan hệ giữa thu nhập và rủi ro.

---

# 5. Tỷ lệ vỡ nợ theo nhóm thu nhập

| Nhóm thu nhập | Tỷ trọng danh mục | Tỷ lệ vỡ nợ |
|---|---:|---:|
| <30K | 11.26% | **47.07%** |
| 30K-50K | 29.57% | **28.15%** |
| 50K-75K | 30.14% | **17.59%** |
| 75K-100K | 15.00% | **10.91%** |
| 100K+ | 14.03% | **8.93%** |

## Ý nghĩa

Đây là một trong những pattern rõ nhất của toàn bộ Borrower Profile.

Tỷ lệ vỡ nợ giảm liên tục khi thu nhập tăng:

```text
<30K        47.07%
30K-50K     28.15%
50K-75K     17.59%
75K-100K    10.91%
100K+        8.93%
```

Nhóm dưới $30K có tỷ lệ vỡ nợ cao hơn khoảng **5.3 lần** nhóm $100K+.

## Business Insight

> Thu nhập là một trong những tín hiệu rủi ro mạnh nhất trong hồ sơ người vay.

Người vay có thu nhập thấp có tỷ lệ vỡ nợ cao hơn rõ rệt.

Hai nhóm thu nhập dưới $50K chỉ chiếm khoảng **40.83% danh mục**, nhưng tạo ra khoảng **62.45% tổng số khoản vỡ nợ**.

Điều này cho thấy rủi ro tập trung đáng kể ở nhóm thu nhập thấp.

Tuy nhiên, không nên hiểu:

```text
Thu nhập thấp → chắc chắn vỡ nợ
```

Thu nhập cần được đặt cùng với:

- Số tiền vay.
- LTI.
- DTI.
- Lãi suất.
- Thâm niên làm việc.

### Kết luận

**Income = tín hiệu rất mạnh.**

Đây nên là một trong những biến chính trên Power BI và trong các bước phân tích khả năng chi trả tiếp theo.

---

# 6. Trình độ học vấn

| Trình độ | Tỷ lệ vỡ nợ |
|---|---:|
| Master | 22.17% |
| High School | 22.06% |
| Bachelor | 21.41% |
| PhD | 21.16% |

## Ý nghĩa

Tỷ lệ vỡ nợ giữa các trình độ học vấn chỉ dao động từ **21.16% đến 22.17%**.

Khoảng cách giữa nhóm cao nhất và thấp nhất chỉ khoảng **1.01 điểm phần trăm**.

## Business Insight

> Trình độ học vấn gần như không tạo ra sự khác biệt đáng kể về tỷ lệ vỡ nợ trong dữ liệu hiện tại.

### Kết luận

**Education Level = tín hiệu yếu.**

Không nên sử dụng trình độ học vấn như một biến chính để giải thích rủi ro từ kết quả EDA hiện tại.

---

# 7. Giới tính

| Giới tính | Tỷ lệ vỡ nợ |
|---|---:|
| Female | 21.87% |
| Male | 21.76% |

## Ý nghĩa

Chênh lệch chỉ là **0.11 điểm phần trăm**.

Hai nhóm cũng có quy mô gần như cân bằng:

- Female: 49.75%
- Male: 50.25%

## Business Insight

> Không có khác biệt đáng kể về tỷ lệ vỡ nợ giữa nam và nữ.

Đây là một finding hữu ích từ góc độ công bằng: dữ liệu hiện tại không cho thấy giới tính là một yếu tố phân tách rủi ro đáng kể.

### Kết luận

**Gender = gần như không có tín hiệu rủi ro.**

Không nên sử dụng giới tính làm cơ sở cho quyết định tín dụng.

---

# 8. Tình trạng hôn nhân

| Tình trạng | Tỷ lệ vỡ nợ |
|---|---:|
| Married | 21.96% |
| Divorced | 21.81% |
| Single | 21.76% |
| Widowed | 21.37% |

## Ý nghĩa

Tỷ lệ vỡ nợ của tất cả các nhóm đều nằm rất gần nhau.

Khoảng cách giữa nhóm cao nhất và thấp nhất chỉ khoảng **0.59 điểm phần trăm**.

## Business Insight

> Tình trạng hôn nhân không cho thấy khả năng phân tách rủi ro đáng kể.

### Kết luận

**Marital Status = tín hiệu rất yếu.**

Có thể giữ trên dashboard để mô tả danh mục, nhưng không nên là trọng tâm của risk analysis.

---

# 9. Tổng hợp các biến nhân khẩu học

Ba biến:

- Gender.
- Marital Status.
- Education Level.

đều có tỷ lệ vỡ nợ rất gần mức trung bình toàn danh mục khoảng **21.82%**.

## Business Insight

> Các đặc điểm nhân khẩu học đang cho thấy sức phân tách rủi ro yếu hơn rất nhiều so với các yếu tố tài chính như Income.

Điều này có ý nghĩa quan trọng đối với mục tiêu cho vay công bằng của Nova Bank.

Nếu các biến nhân khẩu học không giúp phân tách rủi ro đáng kể, ngân hàng không có lý do mạnh từ dữ liệu hiện tại để dựa nhiều vào chúng trong đánh giá rủi ro.

---

# 10. Loại hình việc làm

| Loại hình việc làm | Tỷ trọng danh mục | Tỷ lệ vỡ nợ |
|---|---:|---:|
| Unemployed | 5.13% | 22.67% |
| Self-employed | 15.12% | 22.49% |
| Part-time | 19.98% | 21.83% |
| Full-time | 59.77% | 21.57% |

## Ý nghĩa

Mặc dù nhóm thất nghiệp có tỷ lệ cao nhất, khoảng cách giữa nhóm cao nhất và thấp nhất chỉ **1.10 điểm phần trăm**.

Full-time tạo ra nhiều khoản vỡ nợ nhất về số lượng tuyệt đối vì nhóm này chiếm gần **60% danh mục**, không phải vì tỷ lệ vỡ nợ cao hơn.

## Business Insight

> Loại hình việc làm hiện không phải là một tín hiệu mạnh về rủi ro.

Điều này cũng cho thấy không nên nhầm:

```text
Số khoản vỡ nợ nhiều
```

với:

```text
Tỷ lệ vỡ nợ cao
```

### Kết luận

**Employment Type = tín hiệu yếu ở mức tổng hợp.**

---

# 11. Thâm niên làm việc

| Thâm niên | Tỷ trọng danh mục | Tỷ lệ vỡ nợ |
|---|---:|---:|
| <1 năm | 12.60% | **27.94%** |
| 1-3 năm | 31.37% | **24.35%** |
| 4-6 năm | 26.05% | **19.54%** |
| 7-10 năm | 18.25% | **17.76%** |
| 10+ năm | 8.98% | **16.23%** |
| Không có dữ liệu | 2.75% | **31.55%** |

## Ý nghĩa

Nếu tách riêng nhóm thiếu dữ liệu, tỷ lệ vỡ nợ giảm khá đều khi thâm niên làm việc tăng:

```text
<1 năm      27.94%
1-3 năm     24.35%
4-6 năm     19.54%
7-10 năm    17.76%
10+ năm     16.23%
```

Từ nhóm `<1 năm` đến `10+ năm`, tỷ lệ vỡ nợ giảm khoảng **11.71 điểm phần trăm**.

## Business Insight

> Thâm niên làm việc có mối liên hệ khá rõ với khả năng trả nợ.

Người có thời gian làm việc dài hơn có tỷ lệ vỡ nợ thấp hơn.

Hai nhóm dưới 4 năm chiếm khoảng **43.97% danh mục**, nhưng tạo ra hơn **51% tổng số khoản vỡ nợ**.

### Kết luận

**Employment Length = tín hiệu mạnh.**

Đây nên là một dimension quan trọng trong Borrower Risk dashboard.

---

# 12. Nhóm thiếu dữ liệu thâm niên làm việc

| Trạng thái dữ liệu | Loan Count | Tỷ lệ vỡ nợ |
|---|---:|---:|
| Có dữ liệu | 31,684 | 21.54% |
| Thiếu dữ liệu | 897 | 31.55% |

## Ý nghĩa

Nhóm thiếu Employment Length có tỷ lệ vỡ nợ **31.55%**, so với **21.54%** ở nhóm có dữ liệu.

Chênh lệch khoảng **10.01 điểm phần trăm**.

## Business Insight

> Việc thiếu dữ liệu thâm niên làm việc có liên hệ với tỷ lệ vỡ nợ cao hơn trong dataset hiện tại.

Tuy nhiên, không được kết luận rằng thiếu dữ liệu gây ra vỡ nợ.

Có thể tồn tại yếu tố khác phía sau, ví dụ:

- Hồ sơ khó xác minh việc làm.
- Quy trình thu thập hồ sơ không đầy đủ.
- Một nhóm nghề nghiệp đặc thù.
- Đặc điểm khách hàng khác chưa được quan sát.

### Hướng xử lý

Nên giữ nhóm `Unknown` riêng trong phân tích thay vì tự động điền một giá trị trung bình.

Đây có thể là một **tín hiệu về dữ liệu hoặc quy trình** đáng theo dõi.

---

# 13. Tình trạng sở hữu nhà

| Tình trạng nhà ở | Tỷ trọng danh mục | Tỷ lệ vỡ nợ |
|---|---:|---:|
| RENT | 50.48% | **31.57%** |
| OTHER | 0.33% | **30.84%** |
| MORTGAGE | 41.26% | **12.57%** |
| OWN | 7.93% | **7.47%** |

## Ý nghĩa

Đây là một trong những pattern mạnh nhất của Borrower Profile.

Nhóm thuê nhà có tỷ lệ vỡ nợ **31.57%**, trong khi:

- Mortgage: **12.57%**
- Own: **7.47%**

Nhóm RENT có tỷ lệ vỡ nợ:

- Cao khoảng **2.5 lần** nhóm MORTGAGE.
- Cao hơn **4 lần** nhóm OWN.

## Business Insight

> Home Ownership là một strong borrower risk signal trong dữ liệu hiện tại.

Nhóm RENT đặc biệt đáng chú ý vì:

- Chiếm **50.48% tổng số khoản vay**.
- Có tỷ lệ vỡ nợ cao **31.57%**.
- Tạo ra **5,192 khoản vỡ nợ**.

Nhóm RENT chiếm khoảng **73% tổng số khoản vỡ nợ**, dù chỉ chiếm khoảng một nửa danh mục.

Default exposure của RENT khoảng **$55.87 triệu**, tương đương hơn **72% tổng default exposure**.

Đây là một **rủi ro tập trung rất đáng chú ý**.

### Lưu ý

Không nên diễn giải:

```text
Thuê nhà → gây ra vỡ nợ
```

Tình trạng thuê nhà có thể phản ánh những yếu tố khác như:

- Thu nhập.
- Khả năng tích lũy tài sản.
- Độ ổn định tài chính.
- Tuổi.
- Thâm niên làm việc.

Các mối quan hệ này chỉ nên được kiểm tra trong bước phân tích đa biến sau này.

---

# 14. Nhóm OTHER cần thận trọng

`OTHER` có:

- 107 khoản vay.
- Tỷ lệ vỡ nợ 30.84%.

Mặc dù vượt ngưỡng kỹ thuật 100 observations, nhóm này chỉ chiếm **0.33% danh mục**.

## Business Insight

> Không nên xếp OTHER ngang mức độ quan trọng với RENT chỉ vì tỷ lệ vỡ nợ tương đương.

Một lần nữa:

```text
Tỷ lệ cao
≠
Tác động kinh doanh lớn
```

Cần xem đồng thời:

- Tỷ lệ vỡ nợ.
- Quy mô nhóm.
- Loan exposure.
- Default exposure.

---

# 15. Xếp hạng các tín hiệu Borrower Profile

| Biến | Mức độ tín hiệu |
|---|---|
| Income | 🔴 Rất mạnh |
| Home Ownership | 🔴 Rất mạnh |
| Employment Length | 🔴 Mạnh |
| Employment Length Missing | 🟠 Tín hiệu quy trình/dữ liệu đáng chú ý |
| Age | 🟡 Yếu |
| Employment Type | ⚪ Yếu |
| Education Level | ⚪ Rất yếu |
| Marital Status | ⚪ Rất yếu |
| Gender | ⚪ Gần như không có |

> Đây chỉ là xếp hạng ưu tiên EDA dựa trên mức độ khác biệt quan sát được. Đây không phải feature importance của mô hình dự báo.

---

# 16. Business Story của Borrower Profile

Kết quả có thể được tóm tắt như sau:

> Rủi ro vỡ nợ trong danh mục không khác biệt đáng kể theo giới tính, tình trạng hôn nhân, trình độ học vấn hay loại hình việc làm. Ngược lại, rủi ro phân tách rõ ràng theo khả năng tài chính và mức độ ổn định của người vay. Tỷ lệ vỡ nợ giảm mạnh khi thu nhập tăng và khi thâm niên làm việc dài hơn. Tình trạng sở hữu nhà cũng tạo ra sự khác biệt rất lớn, trong đó nhóm thuê nhà vừa có tỷ lệ vỡ nợ cao vừa chiếm quy mô rất lớn của danh mục.

Một borrower-risk pattern đang hình thành:

```text
Lower Income
      +
Shorter Employment Tenure
      +
Renting Home
      ↓
Higher observed default association
```

Tuy nhiên, đây vẫn chỉ là association và chưa nên xem là final risk segmentation.

---

# 17. Những insight quan trọng nhất

## Insight 1 — Thu nhập là một tín hiệu rất mạnh

Tỷ lệ vỡ nợ giảm từ **47.07% ở nhóm dưới $30K** xuống **8.93% ở nhóm $100K+**.

Đây là một xu hướng rõ và đều.

## Insight 2 — Thâm niên làm việc càng dài, tỷ lệ vỡ nợ càng thấp

Tỷ lệ vỡ nợ giảm từ **27.94% ở nhóm dưới 1 năm** xuống **16.23% ở nhóm 10+ năm**.

Employment stability có khả năng là một risk signal đáng tin cậy hơn Employment Type.

## Insight 3 — RENT là một risk concentration lớn

Nhóm RENT:

- Chiếm 50.48% danh mục.
- Có tỷ lệ vỡ nợ 31.57%.
- Tạo ra khoảng 73% tổng số khoản vỡ nợ.
- Chiếm hơn 72% tổng default exposure.

Đây là borrower segment có tác động kinh doanh rất lớn.

## Insight 4 — Nhân khẩu học gần như không phân tách rủi ro

Gender, Marital Status và Education đều có tỷ lệ vỡ nợ rất gần nhau.

Điều này hỗ trợ định hướng cho vay công bằng hơn vì không có bằng chứng mạnh từ EDA hiện tại cho thấy các biến này cần đóng vai trò chính trong đánh giá rủi ro.

## Insight 5 — Employment Type không mạnh bằng Employment Length

Full-time, Part-time, Self-employed và Unemployed có tỷ lệ vỡ nợ khá gần nhau.

Trong khi đó Employment Length cho thấy một xu hướng giảm rủi ro rõ ràng theo thời gian.

> **Độ ổn định công việc có vẻ quan trọng hơn nhãn loại hình công việc.**

## Insight 6 — Missing Employment Length không nên bỏ qua

Nhóm thiếu dữ liệu có tỷ lệ vỡ nợ **31.55%**, cao hơn đáng kể mức **21.54%** của nhóm có dữ liệu.

Đây có thể là tín hiệu về chất lượng hồ sơ hoặc quy trình thu thập dữ liệu.

---

# 18. Hàm ý cho Power BI

## Nên ưu tiên trên dashboard

- Income Band.
- Employment Length Band.
- Home Ownership.
- Default Rate.
- Loan Count.
- Loan Exposure.
- Default Exposure.

## Có thể giữ để mô tả hoặc làm slicer

- Age Band.
- Employment Type.
- Education.
- Marital Status.
- Gender.

## Không nên tạo quá nhiều visual riêng

Gender, Marital Status và Education có signal rất yếu. Nếu dashboard có giới hạn không gian, các biến này nên được đưa vào slicer hoặc bảng phụ thay vì chiếm visual chính.

---

# 19. Hướng EDA tiếp theo

## 06 - Loan Analysis

Ưu tiên:

- Loan Purpose.
- Loan Grade.
- Loan Amount Bands.
- Interest Rate Bands.
- Loan Term.

Đặc biệt cần kiểm tra liệu Loan Amount và Interest Rate có tiếp tục phân tách mạnh giữa nhóm vỡ nợ và không vỡ nợ hay không.

## 07 - Financial Risk

Đây sẽ là bước rất quan trọng vì kết quả từ `04` và `05` đã chỉ ra:

```text
Income
+
Loan Amount
+
LTI
+
DTI
```

có khả năng tạo ra một câu chuyện về khả năng chi trả rất rõ.

## 08 - Credit And Stability

Tiếp tục kiểm tra:

- Previous Default.
- Credit History.
- Past Delinquencies.
- Open Accounts.
- Employment stability.

## 09 - Segmentation

Chỉ sau khi hoàn thành `06-08` mới nên kiểm tra các tổ hợp như:

```text
Income Band × Home Ownership
Income Band × Employment Length
Home Ownership × DTI
Employment Length × LTI
```

Không nên xây final risk score ở bước 05.

---

# 20. Lưu ý khi diễn giải

1. Tỷ lệ vỡ nợ cao không đồng nghĩa với số lượng vỡ nợ lớn nhất.
2. Luôn xem đồng thời sample size và exposure.
3. Mối liên hệ không đồng nghĩa với quan hệ nguyên nhân.
4. Các biến nhân khẩu học cần được diễn giải thận trọng vì liên quan đến tính công bằng.
5. Nhóm nhỏ như `OTHER` và `55+` cần được đọc cẩn thận dù vượt ngưỡng kỹ thuật 100 observations.
6. Missing Employment Length là một data/process signal, chưa phải nguyên nhân rủi ro.
7. Không xây chính sách cho vay chỉ dựa trên một đặc điểm người vay đơn lẻ.

---

# 21. Kết luận cuối cùng

`05_borrower_profile.sql` đã xác định rõ rằng các yếu tố người vay không có mức độ liên quan với rủi ro như nhau.

Ba findings quan trọng nhất là:

1. **Thu nhập càng thấp, tỷ lệ vỡ nợ càng cao.**
2. **Thâm niên làm việc càng ngắn, tỷ lệ vỡ nợ càng cao.**
3. **Nhóm thuê nhà có tỷ lệ vỡ nợ và mức tập trung vỡ nợ cao hơn đáng kể.**

Trong khi đó:

- Gender.
- Marital Status.
- Education.
- Employment Type.

không cho thấy sự khác biệt đủ lớn để trở thành các tín hiệu rủi ro ưu tiên.

Kết quả này cho thấy borrower risk trong dataset hiện tại có vẻ liên quan nhiều hơn đến:

```text
Khả năng tài chính
+
Độ ổn định kinh tế
+
Tình trạng nhà ở
```

hơn là các đặc điểm nhân khẩu học cơ bản.

Đây là nền tảng tốt để chuyển sang `06_loan_analysis.sql`, nơi cần kiểm tra các đặc điểm của chính khoản vay trước khi kết hợp borrower risk với affordability và credit history ở những bước sau.
