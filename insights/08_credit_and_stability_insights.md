# 08 - Credit and Stability: Business Insights

**Project:** Risk_Credit_Analytics_Project  
**Source SQL:** `sql/08_credit_and_stability.sql`  
**Source table:** `credit_risk_clean`  
**Mục tiêu:** Phân tích lịch sử tín dụng và mức độ ổn định của người vay để xác định những yếu tố nào thực sự có liên hệ với nguy cơ vỡ nợ.

---

# 1. Tóm tắt điều hành

Kết quả của `08_credit_and_stability.sql` cho thấy **không phải mọi biến lịch sử tín dụng đều có sức phân tách rủi ro mạnh như kỳ vọng**.

Các finding quan trọng nhất:

1. **Previous Default** là tín hiệu lịch sử rất mạnh. Người từng có default trước đây có tỷ lệ vỡ nợ hiện tại **37.81%**, cao hơn khoảng **2.06 lần** nhóm chưa từng default (**18.39%**).
2. **Credit History Length** chỉ cho thấy tín hiệu yếu. Nhóm có lịch sử tín dụng dưới 3 năm có tỷ lệ vỡ nợ cao hơn một chút, nhưng chênh lệch giữa các nhóm không lớn.
3. **Open Accounts** gần như không phân tách rủi ro. Tỷ lệ vỡ nợ của các nhóm đều quanh 21%–22%.
4. **Past Delinquencies** cũng gần như không tạo khác biệt. Người có 0, 1 hoặc 2+ lần quá hạn đều có tỷ lệ vỡ nợ gần mức trung bình danh mục.
5. **Previous Default + Employment Length ngắn** tạo ra một nhóm rủi ro đáng chú ý: tỷ lệ vỡ nợ **42.89%**.
6. **Previous Default + RENT** là giao điểm mạnh nhất trong file 08: chỉ chiếm **10.06% danh mục** nhưng có tỷ lệ vỡ nợ **46.86%** và tạo ra **20.40% tổng dư nợ vỡ nợ**.
7. **RENT** tiếp tục là một biến rất mạnh ngay cả khi tách theo lịch sử default. Điều này cho thấy tình trạng nhà ở mang thêm thông tin rủi ro ngoài previous default.
8. **Past Delinquency không bổ sung nhiều thông tin** cho Previous Default. Trong nhóm đã từng default, tỷ lệ vỡ nợ chỉ tăng nhẹ từ **37.14%** lên **38.86%** khi có thêm lịch sử quá hạn.

Tóm lại, trong nhóm biến Credit & Stability, ba tín hiệu đáng ưu tiên nhất hiện nay là:

```text
Previous Default
+
Employment Stability
+
Home Ownership
```

Trong khi:

```text
Credit History Length
Open Accounts
Past Delinquencies
```

có sức phân tách yếu hơn đáng kể.

---

# 2. Previous Default History

## 2.1 Kết quả

| Previous Default | Tỷ trọng danh mục | Tỷ lệ vỡ nợ | Tỷ trọng tổng dư nợ vỡ nợ |
|---|---:|---:|---:|
| N | 82.37% | 18.39% | 69.30% |
| Y | 17.63% | **37.81%** | **30.70%** |

## 2.2 Ý nghĩa

Nhóm từng có default trong quá khứ chỉ chiếm:

**17.63% số khoản vay**

nhưng có tỷ lệ vỡ nợ hiện tại:

**37.81%**

so với:

**18.39%**

ở nhóm chưa từng default.

Tức là tỷ lệ vỡ nợ của nhóm Y cao hơn khoảng:

**2.06 lần**

nhóm N.

## Business Insight

> Lịch sử default trước đây là một trong những tín hiệu tín dụng mạnh nhất của dataset.

Nhóm `Y`:

- Chỉ chiếm 17.63% danh mục.
- Nhưng tạo ra 2,172 khoản vỡ nợ.
- Chiếm 30.70% tổng dư nợ vỡ nợ.

Điều này cho thấy rủi ro hiện tại có mức độ tập trung rõ trong nhóm đã từng gặp vấn đề trả nợ trước đây.

### Tuy nhiên

Không nên sử dụng Previous Default như một quy tắc loại bỏ đơn lẻ.

Nhóm `N` vẫn tạo ra:

**4,936 / 7,108 khoản vỡ nợ**

tức gần **69.4% tổng số khoản vỡ nợ**.

Nguyên nhân là nhóm N chiếm hơn 82% toàn danh mục.

Do đó cần phân biệt:

```text
Tỷ lệ rủi ro của nhóm
vs
Đóng góp tuyệt đối vào danh mục
```

---

# 3. Credit History Length

## 3.1 Phân bố

| Chỉ số | Giá trị |
|---|---:|
| Min | 2 năm |
| P25 | 3 năm |
| Median | 4 năm |
| Average | 5.80 năm |
| P75 | 8 năm |
| Max | 30 năm |

## Ý nghĩa

Phần lớn khách hàng có lịch sử tín dụng tương đối ngắn.

Một nửa người vay có lịch sử tín dụng không quá khoảng **4 năm**.

---

# 4. Tỷ lệ vỡ nợ theo Credit History Length

| Lịch sử tín dụng | Tỷ trọng danh mục | Tỷ lệ vỡ nợ |
|---|---:|---:|
| <3 năm | 18.31% | **23.57%** |
| 3-5 năm | 42.20% | 22.07% |
| 6-10 năm | 28.87% | 20.64% |
| 10+ năm | 10.63% | 21.00% |

## Ý nghĩa

Có một xu hướng nhẹ:

```text
Lịch sử tín dụng ngắn
→ tỷ lệ vỡ nợ cao hơn một chút
```

Nhưng mức khác biệt khá nhỏ.

Nhóm `<3 năm`:

**23.57%**

so với nhóm `6-10 năm`:

**20.64%**

chỉ chênh khoảng:

**2.93 điểm phần trăm**.

Ngoài ra, nhóm `10+ năm` lại tăng nhẹ lên 21.00%, cho thấy quan hệ không hoàn toàn giảm đều.

## Business Insight

> Credit History Length chỉ là một tín hiệu yếu đến trung bình.

Lịch sử tín dụng ngắn có thể làm ngân hàng có ít thông tin để đánh giá khách hàng hơn, nhưng trong dataset này nó không phân tách mạnh bằng:

- Previous Default.
- Income.
- LTI.
- DTI.
- Home Ownership.
- Loan Grade.

### Kết luận

Không nên dùng Credit History Length như một risk driver chính nếu đứng riêng.

---

# 5. Open Accounts

## 5.1 Phân bố

| Chỉ số | Giá trị |
|---|---:|
| Min | 0 |
| P25 | 4 |
| Median | 8 |
| Average | 8.04 |
| P75 | 12 |
| Max | 15 |

---

# 6. Tỷ lệ vỡ nợ theo số tài khoản đang mở

| Open Accounts | Tỷ lệ vỡ nợ |
|---|---:|
| <5 | 21.89% |
| 5-9 | 22.26% |
| 10-14 | 21.27% |
| 15+ | 22.06% |

## Ý nghĩa

Tất cả các nhóm đều gần mức trung bình toàn danh mục:

**21.82%**

Khoảng cách giữa nhóm cao nhất và thấp nhất chỉ khoảng:

**0.99 điểm phần trăm**.

## Business Insight

> Số tài khoản đang mở gần như không có khả năng phân tách rủi ro trong dữ liệu hiện tại.

Khách hàng có nhiều tài khoản hơn không cho thấy tỷ lệ vỡ nợ tăng rõ.

### Kết luận

**Open Accounts = tín hiệu rất yếu.**

Nếu dashboard có giới hạn không gian, đây không nên là visual chính.

---

# 7. Past Delinquencies

## 7.1 Phân bố

Tổng số khoản vay:

**32,581**

Trong đó:

- 0 lần quá hạn: **19,702**
- 1 lần quá hạn: **9,829**
- 2+ lần quá hạn: **3,050**

Khoảng:

**60.47%**

khách hàng không có past delinquency.

---

# 8. Tỷ lệ vỡ nợ theo Past Delinquencies

| Past Delinquencies | Tỷ lệ vỡ nợ |
|---|---:|
| 0 | 21.77% |
| 1 | 22.02% |
| 2+ | 21.48% |

## Ý nghĩa

Kết quả gần như bằng nhau.

Thậm chí nhóm `2+` không có tỷ lệ vỡ nợ cao hơn nhóm 0.

Điều này xác nhận finding ở `04_overall_risk.sql`, nơi average Past Delinquencies giữa Default và Non-default gần như giống nhau.

## Business Insight

> Past Delinquencies không phải một tín hiệu mạnh trong dataset này.

Đây là finding đáng chú ý vì về mặt trực giác ta có thể kỳ vọng nhiều lần quá hạn trong quá khứ sẽ đi cùng rủi ro hiện tại cao hơn.

Nhưng dữ liệu không cho thấy điều đó.

### Kết luận

Không nên suy diễn:

```text
Nhiều lần quá hạn
=
Chắc chắn rủi ro cao hơn
```

dựa trên dataset hiện tại.

---

# 9. Previous Default × Employment Stability

## 9.1 Kết quả

| Previous Default | Employment Length | Tỷ lệ vỡ nợ |
|---|---|---:|
| N | <4 năm | 21.26% |
| N | 4+ năm | **15.53%** |
| N | Unknown | 28.85% |
| Y | <4 năm | **42.89%** |
| Y | 4+ năm | 32.54% |
| Y | Unknown | 49.57% |

## Ý nghĩa

Employment Stability tiếp tục tạo ra khác biệt ngay cả sau khi kiểm soát theo Previous Default.

Trong nhóm `N`:

```text
<4 năm = 21.26%
4+ năm = 15.53%
```

Chênh:

**5.73 điểm phần trăm**

Trong nhóm `Y`:

```text
<4 năm = 42.89%
4+ năm = 32.54%
```

Chênh:

**10.35 điểm phần trăm**

## Business Insight

> Lịch sử default và thâm niên làm việc mang thông tin bổ sung cho nhau.

Người vừa:

```text
Từng Default
+
Employment <4 năm
```

có tỷ lệ vỡ nợ:

**42.89%**

cao hơn nhiều mức portfolio 21.82%.

Nhóm này:

- Chỉ chiếm **8.38% danh mục**.
- Nhưng tạo ra **15.15% tổng dư nợ vỡ nợ**.

Đây là một candidate segment đáng quan tâm trong file 09.

---

# 10. Nhóm thiếu Employment Length

Trong cả nhóm N và Y, nhóm thiếu dữ liệu employment length đều có tỷ lệ vỡ nợ cao:

```text
N + Unknown = 28.85%
Y + Unknown = 49.57%
```

## Business Insight

Điều này củng cố finding ở file 05:

> Missing Employment Length có thể là một data/process signal.

Tuy nhiên nhóm `Y + Unknown` chỉ có 117 khoản vay, vì vậy cần đọc thận trọng.

Không được kết luận việc thiếu dữ liệu gây ra vỡ nợ.

---

# 11. Previous Default × Home Ownership

Đây là một trong những phần quan trọng nhất của file 08.

## 11.1 Kết quả chính

| Previous Default | Home Ownership | Tỷ lệ vỡ nợ |
|---|---|---:|
| N | OWN | **6.78%** |
| N | MORTGAGE | **9.76%** |
| N | RENT | **27.76%** |
| Y | OWN | 10.81% |
| Y | MORTGAGE | **28.69%** |
| Y | RENT | **46.86%** |

## Ý nghĩa

Tình trạng nhà ở vẫn phân tách rất mạnh ngay cả khi xét riêng lịch sử default.

### Trong nhóm chưa từng default

```text
OWN      6.78%
MORTGAGE 9.76%
RENT    27.76%
```

Một người không có lịch sử default nhưng đang RENT vẫn có tỷ lệ vỡ nợ khá cao.

### Trong nhóm từng default

```text
OWN      10.81%
MORTGAGE 28.69%
RENT     46.86%
```

Previous Default tiếp tục làm tăng rủi ro trong hầu hết các nhóm nhà ở.

## Business Insight

> Home Ownership không chỉ đơn giản phản ánh Previous Default.

Nó mang thêm khả năng phân tách riêng.

Điều đặc biệt đáng chú ý:

```text
Previous Default = N + RENT
Default Rate = 27.76%
```

cao hơn đáng kể:

```text
Previous Default = Y + OWN
Default Rate = 10.81%
```

Điều này cho thấy không thể dùng một biến đơn lẻ để đánh giá rủi ro.

---

# 12. Previous Default = Y + RENT

Đây là giao điểm mạnh nhất của file 08 có quy mô đáng kể.

Kết quả:

```text
Loan Count                = 3,278
Portfolio Share           = 10.06%
Default Count             = 1,536
Default Rate              = 46.86%
Loan Exposure             = $29.75M
Default Exposure          = $15.73M
Share of Default Exposure = 20.40%
```

## Business Insight

> Chỉ khoảng 10% danh mục nhưng tạo ra hơn 20% tổng dư nợ vỡ nợ.

Đây là một mức tập trung rất đáng chú ý.

Nhóm này vừa có:

- Previous Default.
- RENT.
- Tỷ lệ vỡ nợ cao.
- Quy mô đủ lớn.
- Default Exposure lớn.

Đây là một candidate segment rất mạnh để mang sang file 09.

---

# 13. RENT vẫn là một vấn đề lớn ngay cả khi chưa từng default

Nhóm:

```text
Previous Default = N
Home Ownership = RENT
```

có:

- **13,168 khoản vay**
- Chiếm **40.42% toàn danh mục**
- Tỷ lệ vỡ nợ **27.76%**
- Tạo ra **52.04% tổng dư nợ vỡ nợ**

## Business Insight

Đây là một finding cực kỳ quan trọng:

> Rất nhiều rủi ro không nằm trong nhóm Previous Default = Y.

Ngay cả khách hàng chưa từng default nhưng đang RENT vẫn đóng góp hơn một nửa tổng dư nợ vỡ nợ.

Điều này giải thích tại sao chỉ dùng Previous Default làm rule sẽ bỏ sót một lượng lớn rủi ro.

---

# 14. Previous Default × Past Delinquency

## 14.1 Kết quả

| Previous Default | Delinquency History | Tỷ lệ vỡ nợ |
|---|---|---:|
| N | Không có | 18.43% |
| N | Có | 18.34% |
| Y | Không có | 37.14% |
| Y | Có | 38.86% |

## Ý nghĩa

Past Delinquency gần như không bổ sung sức phân tách trong nhóm Previous Default = N:

```text
18.43%
vs
18.34%
```

Trong nhóm Previous Default = Y:

```text
37.14%
vs
38.86%
```

chỉ chênh:

**1.72 điểm phần trăm**.

## Business Insight

> Previous Default mạnh hơn Past Delinquency rất nhiều.

Nếu khách hàng đã có previous-default flag, việc bổ sung thông tin có/không có past delinquency chỉ cải thiện rất ít khả năng phân tách.

### Kết luận

Past Delinquency có thể là một biến phụ trợ, nhưng chưa đáng ưu tiên cho final segmentation dựa trên EDA hiện tại.

---

# 15. Credit & Stability Checkpoint

| Điều kiện | Tỷ trọng danh mục | Tỷ lệ vỡ nợ | Tỷ trọng tổng dư nợ vỡ nợ |
|---|---:|---:|---:|
| Portfolio | 100% | 21.82% | 100% |
| Previous Default = Y | 17.63% | **37.81%** | 30.70% |
| Credit History <3 năm | 18.31% | 23.57% | 18.94% |
| Past Delinquency >=1 | 39.53% | 21.89% | 39.25% |
| Employment <4 năm | 43.97% | 25.38% | 47.92% |
| RENT | 50.48% | **31.57%** | **72.44%** |
| Previous Default = Y + Employment <4 | 8.38% | **42.89%** | 15.15% |
| Previous Default = Y + RENT | 10.06% | **46.86%** | **20.40%** |
| Previous Default = Y + Past Delinquency | 6.83% | 38.86% | 12.34% |

---

# 16. Insight từ bảng checkpoint

## 16.1 Previous Default = Y

Rõ ràng là tín hiệu mạnh:

```text
17.63% danh mục
→ 37.81% Default Rate
→ 30.70% Default Exposure
```

---

## 16.2 Credit History <3 năm

Tín hiệu khá yếu:

```text
18.31% danh mục
→ 23.57% Default Rate
```

chỉ cao hơn portfolio khoảng 1.75 điểm phần trăm.

---

## 16.3 Past Delinquency >=1

Gần như không có sự khác biệt:

```text
Default Rate = 21.89%
Portfolio    = 21.82%
```

Đây là một trong những bằng chứng rõ nhất cho thấy Past Delinquency không nên là biến ưu tiên.

---

## 16.4 Employment <4 năm

Tín hiệu ở mức vừa:

```text
43.97% danh mục
→ 25.38% Default Rate
→ 47.92% Default Exposure
```

Nhóm này khá lớn nên vẫn đáng quan tâm.

---

## 16.5 RENT

Đây là điều kiện có **tác động danh mục lớn nhất** trong file 08:

```text
50.48% danh mục
→ 31.57% Default Rate
→ 72.44% tổng Default Exposure
```

RENT không có tỷ lệ cao nhất, nhưng vì quy mô rất lớn nên nó tạo tác động kinh doanh lớn nhất.

---

## 16.6 Previous Default = Y + RENT

Đây là điều kiện có mức rủi ro rất cao và vẫn có quy mô đủ lớn:

```text
10.06% danh mục
→ 46.86% Default Rate
→ 20.40% Default Exposure
```

Đây là một candidate segment nổi bật cho bước 09.

---

# 17. Xếp hạng Credit & Stability Signals

| Biến / Điều kiện | Mức độ tín hiệu |
|---|---|
| Previous Default | 🔴 Rất mạnh |
| Home Ownership / RENT | 🔴 Rất mạnh |
| Previous Default × RENT | 🔴 Rất mạnh |
| Previous Default × Employment Stability | 🔴 Mạnh |
| Employment Length | 🟠 Khá mạnh |
| Credit History Length | 🟡 Yếu |
| Past Delinquencies | ⚪ Rất yếu |
| Open Accounts | ⚪ Rất yếu |
| Previous Default × Past Delinquency | 🟡 Chỉ bổ sung ít |

> Đây là xếp hạng ưu tiên EDA, không phải feature importance của mô hình dự báo.

---

# 18. Business Story của Credit & Stability

Kết quả của file 08 có thể được tóm tắt như sau:

> Lịch sử default trước đây là một tín hiệu tín dụng mạnh và làm tỷ lệ vỡ nợ hiện tại tăng khoảng gấp đôi. Tuy nhiên, các biến lịch sử tín dụng khác như số tài khoản mở, số lần quá hạn và độ dài lịch sử tín dụng lại có sức phân tách yếu. Trong khi đó, các yếu tố ổn định kinh tế như thâm niên làm việc và đặc biệt là tình trạng nhà ở mang lại khả năng phân tách đáng kể. Nhóm vừa từng default vừa đang thuê nhà chỉ chiếm khoảng 10% danh mục nhưng có tỷ lệ vỡ nợ gần 47% và tạo ra hơn 20% tổng dư nợ vỡ nợ.

Một pattern nổi bật:

```text
Previous Default
        +
Short Employment Tenure
        +
RENT
        ↓
Higher observed default association
```

Tuy nhiên đây vẫn chưa phải final risk segmentation.

---

# 19. Một finding rất quan trọng về Past Delinquency

Trong nhiều bài toán tín dụng, ta có thể kỳ vọng:

```text
Past Delinquency cao
→ Risk cao
```

Nhưng dataset này không cho thấy điều đó.

Kết quả:

```text
0 lần  = 21.77%
1 lần  = 22.02%
2+ lần = 21.48%
```

và khi kết hợp với Previous Default:

```text
N + Không delinquency = 18.43%
N + Có delinquency    = 18.34%

Y + Không delinquency = 37.14%
Y + Có delinquency    = 38.86%
```

## Business Insight

> Không nên ép dữ liệu phải phù hợp với kỳ vọng lý thuyết.

EDA cần phản ánh đúng những gì dataset cho thấy.

Past Delinquency có thể:

- Được định nghĩa khác kỳ vọng.
- Không đủ mạnh trong dataset này.
- Có mối quan hệ với biến khác.
- Hoặc đã được phản ánh phần nào qua Previous Default.

Đây là một finding hợp lệ, không phải lỗi phân tích.

---

# 20. Hàm ý cho Power BI

## Nên ưu tiên visual chính

### Previous Default

Hiển thị:

- Previous Default Status.
- Default Rate.
- Loan Count.
- Default Exposure.

### Home Ownership

Đây vẫn là một trong những visual quan trọng nhất của Borrower Profile.

### Previous Default × Home Ownership

Có thể dùng Matrix hoặc Heatmap:

```text
Rows    = Previous Default
Columns = Home Ownership
Values  = Default Rate
Tooltip = Loan Count + Default Exposure
```

Đây là visual rất dễ giải thích cho stakeholder.

### Previous Default × Employment Stability

Nên được giữ như một visual hoặc drill-down phụ.

---

## Có thể giảm ưu tiên

- Open Accounts.
- Past Delinquencies.
- Credit History Length.

Các biến này không đủ sức phân tách để chiếm nhiều không gian dashboard.

---

# 21. Hướng sang file 09

Sau `04-08`, dự án đã xác định được khá rõ các tín hiệu mạnh.

## Borrower Profile

```text
Income
Employment Length
Home Ownership
```

## Loan Characteristics

```text
Loan Grade
Interest Rate
Loan Amount
Loan Purpose
```

## Financial Risk

```text
LTI
DTI
LTI × DTI
```

## Credit & Stability

```text
Previous Default
Previous Default × Employment
Previous Default × Home Ownership
```

File `09_geographic_segmentation.sql` nên làm hai nhiệm vụ:

1. Phân tích **geography**:
   - Country
   - State
   - City
   - Có minimum sample control.

2. Xây **multi-factor segmentation** từ các biến đã được EDA chứng minh có sức phân tách mạnh.

Không nên đưa toàn bộ 29 biến vào segmentation.

---

# 22. Candidate dimensions cho bước 09

Dựa trên toàn bộ EDA đến file 08, các biến đáng xem xét nhất cho segmentation là:

```text
Income Band
Home Ownership
Employment Length
Loan Grade
Interest Rate Band
Loan Amount Band
LTI Band
DTI Band
Previous Default
```

Các biến có thể giảm ưu tiên:

```text
Gender
Marital Status
Education
Age
Loan Term
Credit Utilization
Open Accounts
Past Delinquencies
Credit History Length
```

Điều này giúp file 09 tập trung vào những yếu tố thực sự có giá trị thay vì tạo quá nhiều segment khó diễn giải.

---

# 23. Lưu ý khi diễn giải

1. Previous Default mạnh nhưng không đủ để sử dụng đơn lẻ.
2. Home Ownership là association, không phải nguyên nhân.
3. RENT không nên được dùng trực tiếp làm quy tắc từ chối tín dụng.
4. Past Delinquency không nên được gắn nhãn "rủi ro cao" nếu dữ liệu không hỗ trợ.
5. Credit History Length chỉ có signal nhẹ.
6. Interaction analysis vẫn chưa phải final risk segmentation.
7. Cần tiếp tục xem đồng thời:
   - Default Rate
   - Loan Count
   - Loan Exposure
   - Default Exposure
8. Final policy recommendation chỉ nên được đưa ra sau khi hoàn thành file 09 và Power BI analysis.

---

# 24. Kết luận cuối cùng

`08_credit_and_stability.sql` đã chỉ ra một điểm rất quan trọng:

> **Không phải mọi biến lịch sử tín dụng đều có giá trị như nhau.**

Trong dataset hiện tại:

- **Previous Default** là tín hiệu lịch sử mạnh.
- **Home Ownership** tiếp tục là một trong những tín hiệu mạnh nhất của borrower stability.
- **Employment Length** bổ sung thêm khả năng phân tách đáng kể.
- **Previous Default + RENT** tạo ra một nhóm có rủi ro cao và tác động danh mục lớn.
- **Previous Default + Employment <4 năm** cũng là một nhóm đáng chú ý.
- **Past Delinquencies, Open Accounts và Credit History Length** không cho thấy sức phân tách đủ mạnh để trở thành các biến trọng tâm.

Finding quan trọng nhất của file 08 có thể tóm tắt bằng:

```text
Previous Default = Y + RENT
--------------------------------
10.06% Portfolio
46.86% Default Rate
20.40% Total Default Exposure
```

Trong khi một finding quan trọng không kém là:

```text
Previous Default = N + RENT
--------------------------------
40.42% Portfolio
27.76% Default Rate
52.04% Total Default Exposure
```

Điều này cho thấy:

> **Rủi ro không chỉ nằm ở những khách hàng từng default. Một nhóm rất lớn chưa từng default nhưng có đặc điểm kinh tế kém ổn định vẫn đang tạo ra phần lớn dư nợ vỡ nợ.**

Đây là cơ sở rất tốt để bước sang `09_geographic_segmentation.sql`, nơi các tín hiệu mạnh từ toàn bộ EDA sẽ được kết hợp để xác định các nhóm rủi ro có ý nghĩa kinh doanh rõ ràng.
