# TRANSACTION ANOMALIES GUIDE

## 1. Giới thiệu

Trong hệ quản trị cơ sở dữ liệu, nhiều Transaction có thể được thực hiện đồng thời nhằm tăng hiệu năng và khả năng phục vụ nhiều người dùng cùng lúc.

Tuy nhiên, nếu các Transaction truy cập và cập nhật cùng một dữ liệu mà không được đồng bộ đúng cách, hệ thống có thể xuất hiện các hiện tượng bất thường (Transaction Anomalies).

Trong dự án **Banking Transaction Management**, nhóm xây dựng các kịch bản mô phỏng năm lỗi đồng thời phổ biến nhằm minh họa cơ chế hoạt động của Transaction và các phương pháp khắc phục trong SQL Server.

---

# 2. Transaction và ACID

## Transaction là gì?

Transaction là một đơn vị xử lý logic gồm một hoặc nhiều thao tác trên cơ sở dữ liệu.

Một Transaction chỉ kết thúc khi:

- COMMIT
- hoặc ROLLBACK

---

## Tính chất ACID

| Thuộc tính | Ý nghĩa |
|------------|----------|
| Atomicity | Hoặc thực hiện toàn bộ, hoặc không thực hiện gì |
| Consistency | Đưa dữ liệu từ trạng thái hợp lệ này sang trạng thái hợp lệ khác |
| Isolation | Các Transaction không ảnh hưởng lẫn nhau khi đang thực hiện |
| Durability | Dữ liệu đã Commit sẽ không bị mất |

Trong tài liệu này, nhóm tập trung vào **Isolation**, vì đây là nguyên nhân dẫn đến các lỗi truy cập đồng thời.

---

# 3. Isolation Level

Isolation Level quy định mức độ cô lập giữa các Transaction đang chạy đồng thời.

SQL Server hỗ trợ nhiều mức cô lập khác nhau.

| Isolation Level | Dirty Read | Non-repeatable Read | Phantom | Lost Update | Deadlock |
|-----------------|-----------|---------------------|----------|-------------|----------|
| READ UNCOMMITTED | ✗ | ✗ | ✗ | ✗ | Có thể |
| READ COMMITTED | ✓ | ✗ | ✗ | ✗ | Có thể |
| REPEATABLE READ | ✓ | ✓ | ✗ | ✗ | Có thể |
| SERIALIZABLE | ✓ | ✓ | ✓ | ✓* | Có thể |

> *Lost Update còn phụ thuộc vào cách thiết kế câu lệnh cập nhật dữ liệu.

---

# 4. Dirty Read

## Định nghĩa

Dirty Read xảy ra khi một Transaction đọc dữ liệu chưa được COMMIT của Transaction khác.

Nếu Transaction ghi sau đó ROLLBACK thì dữ liệu đã đọc thực chất chưa từng tồn tại.

---

## Điều kiện xảy ra

- Transaction A cập nhật dữ liệu.
- Chưa COMMIT.
- Transaction B đọc dữ liệu đó.
- Transaction A ROLLBACK.

---

## Hậu quả

- Đọc dữ liệu không hợp lệ.
- Quyết định nghiệp vụ sai.
- Báo cáo sai.

---

## Kịch bản demo

**Nghiệp vụ**

Phê duyệt khoản vay dựa trên số dư tài khoản.

Transaction A đang cập nhật số dư nhưng chưa COMMIT.

Transaction B đọc ngay số dư đó để quyết định phê duyệt khoản vay.

Sau đó Transaction A bị lỗi và ROLLBACK.

Kết quả:

Banker đã ra quyết định dựa trên dữ liệu chưa từng tồn tại.

---

## Phương pháp khắc phục

- READ COMMITTED (mặc định SQL Server)
- Snapshot Isolation (nếu cần đọc không khóa)

---

# 5. Non-repeatable Read

## Định nghĩa

Non-repeatable Read xảy ra khi cùng một Transaction đọc cùng một bản ghi hai lần nhưng nhận hai kết quả khác nhau.

Nguyên nhân là giữa hai lần đọc có Transaction khác cập nhật và COMMIT dữ liệu.

---

## Điều kiện xảy ra

- Transaction A đọc dữ liệu.
- Transaction B cập nhật dữ liệu và COMMIT.
- Transaction A đọc lại.

---

## Hậu quả

- Báo cáo không nhất quán.
- So sánh dữ liệu sai.

---

## Kịch bản demo

**Nghiệp vụ**

Nhân viên kiểm tra thông tin tài khoản khách hàng.

Trong lúc đang xem, giao dịch khác thay đổi trạng thái tài khoản.

Lần đọc thứ hai cho kết quả khác lần đầu.

---

## Phương pháp khắc phục

- REPEATABLE READ
- SERIALIZABLE

---

# 6. Phantom Read

## Định nghĩa

Phantom Read xảy ra khi cùng một Transaction thực hiện nhiều lần một câu truy vấn theo điều kiện (Range Query) nhưng số lượng bản ghi hoặc kết quả tổng hợp thay đổi vì Transaction khác chèn hoặc xóa bản ghi phù hợp điều kiện.

Điểm khác biệt so với Non-repeatable Read là dữ liệu thay đổi không phải do sửa một dòng đã tồn tại mà do xuất hiện hoặc biến mất các dòng mới.

---

## Điều kiện xảy ra

- Transaction A truy vấn theo điều kiện.
- Transaction B INSERT hoặc DELETE dữ liệu phù hợp điều kiện.
- Transaction A truy vấn lại.

---

## Hậu quả

- Tổng tiền sai.
- Đếm số lượng sai.
- Kiểm tra hạn mức sai.

---

## Kịch bản demo

**Nghiệp vụ**

Kiểm tra hạn mức chuyển tiền tối đa 100 triệu đồng/ngày.

Hai giao dịch cùng kiểm tra tổng tiền đã chuyển trong ngày.

Cả hai đều thấy điều kiện còn hợp lệ và cùng thực hiện chuyển tiền.

Kết quả tổng tiền vượt quá hạn mức quy định.

---

## Phương pháp khắc phục

- SERIALIZABLE
- HOLDLOCK
- UPDLOCK

---

# 7. Lost Update

## Định nghĩa

Lost Update xảy ra khi hai Transaction cùng cập nhật một bản ghi và kết quả cập nhật của Transaction trước bị Transaction sau ghi đè.

Một trong hai thay đổi bị mất hoàn toàn.

---

## Điều kiện xảy ra

- Hai Transaction cùng đọc một giá trị.
- Cùng tính toán giá trị mới.
- Cùng UPDATE.

---

## Hậu quả

- Mất dữ liệu.
- Sai số dư.
- Sai kết quả tính toán.

---

## Kịch bản demo

**Nghiệp vụ**

Hai giao dịch cùng cộng điểm thưởng cho một khách hàng.

Cả hai đều đọc điểm hiện tại là 100.

Một giao dịch cộng thêm 10 điểm.

Giao dịch còn lại cộng thêm 20 điểm.

Kết quả cuối cùng chỉ còn 120 hoặc 110 thay vì 130.

---

## Phương pháp khắc phục

- UPDLOCK
- SERIALIZABLE
- Optimistic Concurrency (Version)

---

# 8. Deadlock

## Định nghĩa

Deadlock xảy ra khi hai hoặc nhiều Transaction giữ khóa của nhau và cùng chờ tài nguyên mà Transaction còn lại đang nắm giữ.

Không Transaction nào có thể tiếp tục.

SQL Server sẽ tự động chọn một Transaction làm Deadlock Victim và ROLLBACK Transaction đó.

---

## Điều kiện xảy ra

- Transaction A giữ khóa tài nguyên X.
- Transaction B giữ khóa tài nguyên Y.
- A chờ Y.
- B chờ X.

---

## Hậu quả

- Transaction bị hủy.
- Người dùng nhận lỗi 1205.
- Phải thực hiện lại giao dịch.

---

## Kịch bản demo

**Nghiệp vụ**

Hai nhân viên ngân hàng đồng thời thực hiện chuyển quyền quản lý hai tài khoản theo thứ tự khóa khác nhau.

Mỗi Transaction giữ một khóa và chờ khóa còn lại.

SQL Server phát hiện Deadlock và hủy một Transaction.

---

## Phương pháp khắc phục

- Thống nhất thứ tự khóa tài nguyên.
- Giữ Transaction ngắn.
- Retry khi gặp lỗi 1205.

---

# 9. Tổng hợp các lỗi

| Lỗi | Đặc điểm | Giải pháp chính |
|------|----------|-----------------|
| Dirty Read | Đọc dữ liệu chưa Commit | READ COMMITTED |
| Non-repeatable Read | Một dòng thay đổi giữa hai lần đọc | REPEATABLE READ |
| Phantom Read | Xuất hiện hoặc mất các dòng dữ liệu | SERIALIZABLE |
| Lost Update | Hai Transaction ghi đè lẫn nhau | UPDLOCK / Version |
| Deadlock | Hai Transaction chờ khóa của nhau | Thống nhất thứ tự khóa, Retry |

---

# 10. Kết luận

Các lỗi truy cập đồng thời là hệ quả tất yếu khi nhiều Transaction cùng thao tác trên dữ liệu.

Việc lựa chọn mức cô lập (Isolation Level) và cơ chế khóa (Locking) phù hợp giúp cân bằng giữa tính nhất quán dữ liệu và hiệu năng của hệ thống.

Trong dự án này, nhóm xây dựng năm kịch bản mô phỏng tương ứng với năm lỗi phổ biến nhằm giúp người học quan sát trực tiếp nguyên nhân, hậu quả và phương pháp khắc phục của từng hiện tượng trong SQL Server.