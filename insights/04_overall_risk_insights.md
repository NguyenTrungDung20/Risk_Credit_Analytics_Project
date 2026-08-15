# 04 - Nhận định tổng quan về danh mục và kết quả khoản vay

**Dự án:** Risk_Credit_Analytics_Project  
**Nguồn truy vấn:** `sql/04_overall_risk.sql`  
**Nguồn kết quả:** `results_3.md`  
**Bảng phân tích:** `credit_risk_clean`  
**Phạm vi:** Thiết lập bức tranh tổng quan trước khi phân tích sâu từng nhóm người vay và khoản vay.

> **Quy ước quan trọng:** Ý nghĩa nghiệp vụ chính thức của `loan_status = 0` và `loan_status = 1` chưa được xác nhận độc lập từ tài liệu nguồn. Vì vậy, báo cáo chỉ sử dụng các tên trung lập `status_0`, `status_1` và `status_1_rate`. Không diễn giải `status_1` là khoản vay xấu, vỡ nợ hay rủi ro cao.

> **Lưu ý về tiền tệ:** Bộ dữ liệu không có cột cho biết đơn vị tiền tệ hoặc tỷ giá quy đổi. Các giá trị tiền trong báo cáo được trình bày theo **đơn vị tiền tệ của dữ liệu**, không tự động coi là USD, GBP hay CAD.

---

## 1. Tóm tắt kết quả chính

Danh mục gồm **32.581 khoản vay** của **32.581 khách hàng**, với tổng giá trị khoản vay khoảng **312,43 triệu đơn vị tiền tệ**.

`status_1` chiếm:

- **7.108 khoản vay**, tương đương **21,82%** số khoản vay.
- Khoảng **77,13 triệu**, tương đương **24,69%** tổng giá trị khoản vay.

Tỷ trọng giá trị khoản vay của `status_1` cao hơn tỷ trọng số khoản vay **2,87 điểm phần trăm**. Điều này cho thấy các khoản vay thuộc `status_1` nhìn chung có giá trị lớn hơn.

So với `status_0`, nhóm `status_1` có các khác biệt nổi bật ở mức tổng hợp:

- Thu nhập trung vị thấp hơn khoảng **30,8%**.
- Giá trị khoản vay trung vị cao hơn **20,0%**.
- LTI trung vị cao hơn khoảng **79,4%**.
- DTI trung vị cao hơn khoảng **31,6%**.
- Lãi suất trung vị cao hơn **2,90 điểm phần trăm**.
- Thâm niên làm việc trung bình thấp hơn khoảng **0,84 năm**.

Hai biến cho thấy khả năng phân tách kết quả khoản vay rõ nhất trong bước tổng quan là:

- `loan_grade`.
- `cb_person_default_on_file`.

Ngược lại, tuổi, thời hạn vay, mức sử dụng tín dụng, độ dài lịch sử tín dụng, số tài khoản đang mở và số lần quá hạn trước đây chưa cho thấy khác biệt lớn giữa hai nhóm kết quả khi chỉ nhìn ở mức trung bình hoặc trung vị toàn danh mục.

---

## 2. Quy mô danh mục

| Chỉ tiêu | Kết quả |
|---|---:|
| Tổng số khoản vay | 32.581 |
| Số khách hàng khác nhau | 32.581 |
| Tổng giá trị khoản vay | 312.431.300 |
| Giá trị khoản vay trung bình | 9.589,37 |
| Giá trị khoản vay trung vị | 8.000,00 |
| Lãi suất trung bình | 11,01% |
| Số khoản vay có dữ liệu lãi suất | 29.465 |
| Tỷ lệ bao phủ dữ liệu lãi suất | 90,44% |

### Cách hiểu

Giá trị khoản vay trung bình là **9.589,37**, cao hơn trung vị **8.000,00**. Điều này cho thấy phân phối giá trị khoản vay bị kéo lên bởi một số khoản vay lớn. Vì vậy, trung vị phù hợp hơn trung bình khi mô tả một khoản vay điển hình.

Lãi suất trung bình **11,01%** chỉ được tính trên **29.465 khoản vay có lãi suất**, tương đương **90,44% danh mục**. Mọi nhận định về lãi suất cần đi kèm tỷ lệ bao phủ này.

---

## 3. Phân phối kết quả khoản vay

| Kết quả | Số khoản vay | Tỷ trọng khoản vay | Giá trị khoản vay | Tỷ trọng giá trị |
|---|---:|---:|---:|---:|
| `status_0` | 25.473 | 78,18% | 235.305.925 | 75,31% |
| `status_1` | 7.108 | 21,82% | 77.125.375 | 24,69% |

`status_1_rate` toàn danh mục là **21,82%**.

Giá trị khoản vay trung bình và trung vị của hai nhóm cũng xác nhận sự khác biệt về quy mô:

| Chỉ tiêu | `status_0` | `status_1` | Chênh lệch quan sát được |
|---|---:|---:|---:|
| Giá trị khoản vay trung bình | 9.237,46 | 10.850,50 | `status_1` cao hơn khoảng 17,5% |
| Giá trị khoản vay trung vị | 8.000,00 | 9.600,00 | `status_1` cao hơn 20,0% |

### Ý nghĩa

Không nên chỉ theo dõi số lượng theo từng kết quả. Cần xem đồng thời:

- `status_1_rate`.
- Số khoản vay thuộc `status_1`.
- Tổng giá trị khoản vay thuộc `status_1`.
- Tỷ trọng giá trị khoản vay thuộc `status_1`.

Nếu tài liệu nguồn sau này xác nhận `status_1` là một kết quả bất lợi, phần giá trị khoản vay gắn với `status_1` sẽ là chỉ tiêu quan trọng để đánh giá mức độ ảnh hưởng đến danh mục.

---

## 4. So sánh tài chính giữa hai nhóm kết quả

Do thu nhập và dư nợ có giá trị ngoại lệ lớn, phần này ưu tiên các phân vị P25, trung vị và P75 thay vì chỉ nhìn trung bình.

| Chỉ tiêu | `status_0`: P25 / Trung vị / P75 | `status_1`: P25 / Trung vị / P75 | Nhận xét ngắn |
|---|---:|---:|---|
| Thu nhập | 42.000 / 60.000 / 84.000 | 30.000 / 41.498 / 59.497 | Phân phối của `status_1` thấp hơn rõ rệt |
| Giá trị khoản vay | 5.000 / 8.000 / 12.000 | 5.000 / 9.600 / 15.000 | `status_1` cao hơn từ vùng trung vị trở lên |
| Lãi suất | 7,68% / 10,59% / 12,69% | 10,74% / 13,49% / 15,58% | `status_1` có lãi suất cao hơn |
| LTI | 8,33% / 13,33% / 20,00% | 13,89% / 23,92% / 34,34% | Khác biệt lớn về gánh nặng khoản vay so với thu nhập |
| DTI | 24,04% / 31,76% / 39,54% | 31,32% / 41,79% / 53,00% | `status_1` có tổng gánh nặng nợ tương đối cao hơn |
| Mức sử dụng tín dụng | 27,54% / 49,94% / 72,23% | 27,53% / 50,42% / 73,39% | Hai nhóm gần như tương đương |
| Khoản nợ khác | 5.907,32 / 9.727,99 / 15.471,50 | 3.862,62 / 6.692,35 / 11.080,16 | Giá trị tuyệt đối của `status_1` thấp hơn |
| Thời hạn vay | 24 / 36 / 60 tháng | 24 / 36 / 60 tháng | Không khác biệt ở ba phân vị chính |

### 4.1 Thu nhập và khả năng chi trả

Thu nhập trung vị của `status_1` là **41.498**, thấp hơn mức **60.000** của `status_0`. Khác biệt cũng xuất hiện ở P25 và P75, vì vậy đây không chỉ là ảnh hưởng của một vài giá trị ngoại lệ.

Trong khi thu nhập thấp hơn, giá trị khoản vay trung vị của `status_1` lại cao hơn. Kết hợp hai yếu tố này giúp giải thích vì sao LTI của `status_1` cao hơn rõ rệt:

```text
Thu nhập thấp hơn
        +
Giá trị khoản vay cao hơn
        ↓
LTI quan sát được cao hơn
```

Đây là mối liên hệ mô tả, chưa phải bằng chứng rằng thu nhập hoặc LTI gây ra `status_1`.

### 4.2 Gánh nặng nợ

DTI trung vị của `status_1` là **41,79%**, so với **31,76%** của `status_0`. P75 của `status_1` đạt **53,00%**, trong khi `status_0` là **39,54%**.

Khoản nợ khác của `status_1` thấp hơn về giá trị tuyệt đối, nhưng DTI lại cao hơn. Điều này không mâu thuẫn vì DTI đo tổng nợ so với thu nhập. Một người có khoản nợ tuyệt đối thấp vẫn có thể chịu gánh nặng nợ cao nếu thu nhập cũng thấp.

Vì vậy, không nên sử dụng `other_debt` riêng lẻ để đánh giá khả năng chi trả. Cần đặt nó trong mối quan hệ với thu nhập và tổng khoản vay.

### 4.3 Lãi suất

Lãi suất trung vị của `status_1` là **13,49%**, cao hơn **2,90 điểm phần trăm** so với `status_0` ở mức **10,59%**.

Đây là một mối liên hệ đáng chú ý, nhưng không thể kết luận lãi suất cao gây ra `status_1`. Lãi suất có thể phản ánh cách định giá theo mức độ rủi ro đã được nhận diện trước đó, mức gánh nặng trả nợ, hoặc cả hai.

Tỷ lệ bao phủ lãi suất khá tương đồng giữa hai nhóm:

- `status_0`: **90,30%**.
- `status_1`: **90,94%**.

Do đó, chênh lệch lãi suất không có dấu hiệu đơn giản là do một nhóm thiếu dữ liệu nhiều hơn hẳn nhóm còn lại. Tuy nhiên, kết quả vẫn chỉ đại diện cho các khoản vay có dữ liệu lãi suất.

### 4.4 Các chỉ tiêu ít khác biệt ở mức tổng hợp

Mức sử dụng tín dụng và thời hạn vay gần như giống nhau giữa hai nhóm:

- Mức sử dụng tín dụng trung vị: **49,94%** so với **50,42%**.
- Thời hạn vay trung vị: đều là **36 tháng**.

Điều này chỉ cho thấy khác biệt yếu ở mức tổng hợp. Các khoảng giá trị cụ thể vẫn có thể có xu hướng riêng và cần được kiểm tra theo nhóm giá trị trong các bước EDA sau.

---

## 5. So sánh đặc điểm người vay

| Chỉ tiêu | `status_0` | `status_1` | Nhận xét |
|---|---:|---:|---|
| Tuổi trung bình | 27,79 | 27,47 | Gần như tương đương |
| Thâm niên làm việc trung bình | 4,96 năm | 4,12 năm | `status_1` thấp hơn khoảng 0,84 năm |
| Độ dài lịch sử tín dụng trung bình | 5,84 năm | 5,69 năm | Khác biệt nhỏ |
| Số tài khoản đang mở trung bình | 8,05 | 8,02 | Gần như không khác biệt |
| Số lần quá hạn trước đây trung bình | 0,5050 | 0,5058 | Gần như giống nhau |

### Ý nghĩa

Thâm niên làm việc là chỉ tiêu duy nhất trong nhóm này cho thấy khác biệt tương đối rõ ở mức trung bình. `status_1` thấp hơn khoảng **16,9%**, nhưng vẫn cần kiểm tra theo nhóm giá trị và theo loại hình việc làm trước khi đánh giá mức độ quan trọng.

Tuổi, lịch sử tín dụng, số tài khoản đang mở và số lần quá hạn trước đây chưa cho thấy khả năng phân tách rõ ở mức trung bình. Tuy nhiên, trung bình có thể che khuất các xu hướng phi tuyến, chẳng hạn nhóm không có lần quá hạn so với nhóm có từ hai lần trở lên. Vì vậy, chưa nên loại bỏ các biến này khỏi những bước EDA sau.

---

## 6. Mức độ đầy đủ của dữ liệu phân tích

| Chỉ tiêu | Quan sát hợp lệ | Thiếu/không sử dụng được | Tỷ lệ bao phủ |
|---|---:|---:|---:|
| Tuổi | 32.576 | 5 | 99,98% |
| Thâm niên làm việc | 31.684 | 897 | 97,25% |
| Lãi suất | 29.465 | 3.116 | 90,44% |

Các cờ dữ liệu có liên quan trực tiếp đến báo cáo này:

| Cờ | Số khoản vay bị ảnh hưởng | Tỷ lệ danh mục |
|---|---:|---:|
| Thiếu lãi suất | 3.116 | 9,56% |
| Thiếu thâm niên làm việc | 895 | 2,75% |
| Tuổi không hợp lệ | 5 | 0,02% |
| DTI lớn hơn 1 | 4 | 0,01% |
| Thâm niên làm việc không hợp lệ | 2 | 0,01% |

### Cách hiểu

- Tuổi gần như đầy đủ và không tạo ra hạn chế đáng kể cho phân tích tổng quan.
- Có **897** giá trị thâm niên không sử dụng được, gồm **895** giá trị thiếu và **2** giá trị không hợp lệ.
- Lãi suất là chỉ tiêu cần lưu ý nhất vì thiếu ở **9,56% danh mục**.
- Bốn trường hợp DTI lớn hơn 1 đã được giữ lại có chủ đích. Đây là các quan sát tài chính cần xem xét, không phải lỗi dữ liệu đã được chứng minh.

Nhìn chung, dữ liệu đủ tốt để tiếp tục EDA. Riêng các kết luận liên quan đến lãi suất phải luôn ghi rõ tỷ lệ bao phủ **90,44%**.

---

## 7. Tín hiệu ban đầu theo hạng khoản vay

| Hạng | Số khoản vay | Tỷ trọng danh mục | Số `status_0` | Số `status_1` | `status_1_rate` | Tổng giá trị khoản vay | Giá trị thuộc `status_1` |
|---|---:|---:|---:|---:|---:|---:|---:|
| A | 10.777 | 33,08% | 9.704 | 1.073 | 9,96% | 92,03 triệu | 10,20 triệu |
| B | 10.451 | 32,08% | 8.750 | 1.701 | 16,28% | 104,46 triệu | 19,12 triệu |
| C | 6.458 | 19,82% | 5.119 | 1.339 | 20,73% | 59,50 triệu | 13,58 triệu |
| D | 3.626 | 11,13% | 1.485 | 2.141 | 59,05% | 39,34 triệu | 22,80 triệu |
| E | 964 | 2,96% | 343 | 621 | 64,42% | 12,45 triệu | 7,83 triệu |
| F | 241 | 0,74% | 71 | 170 | 70,54% | 3,55 triệu | 2,50 triệu |
| G | 64 | 0,20% | 1 | 63 | 98,44% | 1,10 triệu | 1,10 triệu |

### Xu hướng quan sát được

`status_1_rate` tăng gần như liên tục từ hạng A đến hạng G:

```text
A      B      C      D      E      F      G
9,96%  16,28% 20,73% 59,05% 64,42% 70,54% 98,44%
```

Bước nhảy lớn nhất nằm giữa hạng C và hạng D, từ **20,73%** lên **59,05%**, chênh lệch **38,32 điểm phần trăm**.

### Luôn xem tỷ lệ cùng quy mô

Hạng G có `status_1_rate` cao nhất nhưng chỉ có **64 khoản vay**, tương đương **0,20% danh mục**. Vì vậy, không thể coi hạng G là nhóm có ảnh hưởng lớn nhất chỉ dựa vào tỷ lệ.

Hạng D đáng chú ý hơn về tác động tuyệt đối vì đồng thời có:

- **3.626 khoản vay**.
- `status_1_rate` **59,05%**.
- **2.141 khoản vay thuộc `status_1`**.
- Khoảng **22,80 triệu** giá trị khoản vay thuộc `status_1`.

Riêng hạng D đóng góp khoảng **30,1% tổng số khoản vay `status_1`** và **29,6% tổng giá trị khoản vay `status_1`** của toàn danh mục.

Khi gộp Grades D đến G, nhóm này chiếm khoảng:

- **15,0%** tổng số khoản vay.
- **18,1%** tổng giá trị khoản vay.
- **42,1%** tổng số khoản vay `status_1`.
- **44,4%** tổng giá trị khoản vay `status_1`.

Đây là một vùng tập trung `status_1` đáng ưu tiên nghiên cứu, nhưng chưa phải phân khúc rủi ro cuối cùng và không đủ để xây dựng quy tắc phê duyệt.

---

## 8. Tín hiệu ban đầu theo lịch sử vỡ nợ trên hồ sơ

| Cờ lịch sử | Số khoản vay | Tỷ trọng danh mục | Số `status_0` | Số `status_1` | `status_1_rate` | Tổng giá trị khoản vay | Giá trị thuộc `status_1` |
|---|---:|---:|---:|---:|---:|---:|---:|
| N | 26.836 | 82,37% | 21.900 | 4.936 | 18,39% | 254,27 triệu | 53,45 triệu |
| Y | 5.745 | 17,63% | 3.573 | 2.172 | 37,81% | 58,16 triệu | 23,68 triệu |

### Cách hiểu

Nhóm `cb_person_default_on_file = Y` có `status_1_rate` **37,81%**, cao khoảng **2,06 lần** nhóm N ở mức **18,39%**. Đây là một mối liên hệ mô tả rõ ràng và cần được kiểm tra sâu hơn trong phần phân tích lịch sử tín dụng.

Tuy nhiên, nhóm N vẫn đóng góp:

- **4.936 trên 7.108 khoản vay `status_1`**, tương đương khoảng **69,4%**.
- Khoảng **53,45 trên 77,13 triệu giá trị khoản vay `status_1`**, tương đương khoảng **69,3%**.

Nguyên nhân là nhóm N chiếm tới **82,37% danh mục**. Ví dụ này cho thấy phải phân biệt rõ:

```text
Tỷ lệ status_1 của một nhóm
                và
Đóng góp tuyệt đối của nhóm đó vào toàn danh mục
```

Một nhóm có tỷ lệ cao chưa chắc tạo ra số lượng hoặc giá trị `status_1` lớn nhất.

---

## 9. Mức độ ưu tiên cho các bước EDA tiếp theo

Bảng dưới đây chỉ phản ánh **mức khác biệt quan sát được trong EDA tổng quan**, không phải mức độ quan trọng của biến trong mô hình và không phải kết quả mô hình dự báo.

| Biến hoặc nhóm biến | Mức khác biệt quan sát được | Hướng kiểm tra tiếp theo |
|---|---|---|
| `loan_grade` | Rất rõ | Kiểm tra sâu theo hạng, giá trị khoản vay và các biến tài chính |
| LTI và DTI | Rất rõ | Phân tích theo nhóm giá trị và theo giao điểm khả năng chi trả |
| Thu nhập | Rõ | Phân tích theo nhóm thu nhập và quy mô khoản vay |
| Lãi suất | Rõ | Phân tích theo nhóm giá trị, luôn kèm tỷ lệ bao phủ |
| Giá trị khoản vay | Rõ | Phân tích theo nhóm giá trị và tổng giá trị khoản vay |
| Lịch sử vỡ nợ trên hồ sơ | Rõ | Kết hợp với lịch sử tín dụng và số lần quá hạn |
| Thâm niên làm việc | Có tín hiệu | Kiểm tra theo nhóm giá trị và loại hình việc làm |
| Khoản nợ khác | Cần đặt trong bối cảnh | Phân tích cùng thu nhập và DTI |
| Mức sử dụng tín dụng | Khác biệt yếu ở mức tổng hợp | Kiểm tra theo nhóm giá trị để tìm xu hướng phi tuyến |
| Tuổi và thời hạn vay | Khác biệt yếu ở mức tổng hợp | Kiểm tra theo nhóm giá trị |
| Lịch sử tín dụng và tài khoản mở | Khác biệt yếu ở mức tổng hợp | Kiểm tra phân phối và mối tương tác |
| Số lần quá hạn trước đây | Gần như không khác ở trung bình | Kiểm tra nhóm 0, 1 và từ 2 lần trở lên |

---

## 10. Câu chuyện tổng thể của danh mục

Bức tranh mô tả hiện tại có thể tóm tắt như sau:

```text
status_1 chiếm 21,82% số khoản vay
nhưng chiếm 24,69% tổng giá trị khoản vay.

Nhóm status_1 có xu hướng:
thu nhập thấp hơn
+ khoản vay lớn hơn
+ LTI cao hơn
+ DTI cao hơn
+ lãi suất cao hơn.

Hạng khoản vay và lịch sử vỡ nợ trên hồ sơ
cho thấy sự khác biệt kết quả rõ ràng.
```

Các xu hướng trên nhất quán với một câu chuyện về khả năng chi trả và phân loại khoản vay. Tuy nhiên, chúng chỉ thể hiện **mối liên hệ thống kê trong dữ liệu**, chưa chứng minh quan hệ nguyên nhân và chưa xác nhận ý nghĩa nghiệp vụ của `status_1`.

---

## 11. Nội dung cần làm rõ trước khi đưa vào Power BI hoặc chính sách

1. Xác nhận chính thức ý nghĩa của `loan_status = 0` và `loan_status = 1`.
2. Xác nhận đơn vị tiền tệ và liệu các giá trị giữa USA, UK và Canada đã được quy đổi về cùng một đơn vị hay chưa.
3. Không thay `status_1_rate` bằng `default_rate` trước khi hoàn thành xác nhận trên.
4. Không sử dụng các xu hướng hiện tại như quy tắc phê duyệt hoặc từ chối khoản vay.
5. Không coi mức khác biệt trong EDA là mức độ quan trọng của biến trong mô hình hoặc khả năng dự báo.
6. Luôn xem `status_1_rate` cùng cỡ mẫu, tổng giá trị khoản vay và `status_1_exposure`.
7. Khi phân tích lãi suất, luôn ghi rõ tỷ lệ bao phủ hiện tại là **90,44%**.
8. Không xây dựng điểm rủi ro chỉ từ các kết quả tổng quan này.

---

## 12. Kết luận

`04_overall_risk.sql` đã hoàn thành vai trò thiết lập đường cơ sở cho toàn danh mục.

Kết quả quan trọng nhất là `status_1` có tỷ trọng giá trị khoản vay cao hơn tỷ trọng số khoản vay và đi cùng một hồ sơ tài chính khác biệt rõ: thu nhập thấp hơn, giá trị khoản vay cao hơn, LTI và DTI cao hơn, cùng lãi suất cao hơn. `loan_grade` tạo ra sự phân tách kết quả rất rõ, đặc biệt từ hạng D, trong khi lịch sử vỡ nợ trên hồ sơ cũng liên quan đến `status_1_rate` cao hơn khoảng hai lần.

Ở chiều ngược lại, một số biến chưa tạo ra khác biệt đáng kể ở mức tổng hợp. Chúng vẫn cần được kiểm tra theo nhóm giá trị trong các bước EDA sau, thay vì bị loại bỏ chỉ dựa trên trung bình.

Bước kế tiếp nên bắt đầu từ hồ sơ người vay, ưu tiên thu nhập và thâm niên làm việc, đồng thời vẫn giữ đầy đủ số khoản vay, `status_1_rate`, tổng giá trị khoản vay và giá trị thuộc `status_1` trong mọi so sánh phân khúc.
