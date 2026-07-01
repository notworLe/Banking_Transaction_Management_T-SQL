# CONCURRENCY_CONTROL_DESIGN

## 1. Purpose

Tài liệu này mô tả các cơ chế điều khiển tương tranh (Concurrency Control) được sử dụng trong đồ án **Banking Transaction Management System**.

Mục tiêu của tài liệu:

* Đối chiếu giữa lý thuyết đã học và cách SQL Server 2022 hiện thực.
* Phân tích các phương án có thể sử dụng để xử lý từng Transaction Anomaly.
* Giải thích lý do nhóm lựa chọn phương án cuối cùng.

---

# 2. Concurrency Control Overview

## 2.1 Mục tiêu

Khi nhiều Transaction thực thi đồng thời trên cùng dữ liệu, hệ quản trị cơ sở dữ liệu phải đảm bảo:

* Tính đúng đắn của dữ liệu.
* Tính nhất quán của Transaction.
* Khả năng thực thi đồng thời.
* Hiệu năng của hệ thống.

Nếu không có cơ chế điều khiển tương tranh sẽ xuất hiện các lỗi như:

* Dirty Read
* Non-repeatable Read
* Phantom Read
* Lost Update
* Deadlock

---

# 3. Concurrency Control Techniques

Theo nội dung môn học, có bốn nhóm kỹ thuật điều khiển tương tranh chính.

## 3.1 Lock-Based Protocol

### Ý tưởng

Transaction phải xin quyền truy cập dữ liệu trước khi đọc hoặc ghi.

### Thành phần

* Shared Lock (S)
* Exclusive Lock (X)

### Giao thức

* Two Phase Locking (2PL)
* Strict Two Phase Locking

### Ưu điểm

* Đảm bảo tính đúng đắn cao.
* Được sử dụng rộng rãi trong các DBMS.

### Nhược điểm

* Có thể gây Blocking.
* Có thể phát sinh Deadlock.

### SQL Server 2022

SQL Server sử dụng Lock Manager để quản lý Shared Lock, Exclusive Lock và nhiều loại khóa khác. Đây là cơ chế điều khiển tương tranh mặc định.

---

## 3.2 Timestamp Ordering

### Ý tưởng

Mỗi Transaction được gán một Timestamp.

Mọi thao tác Read/Write đều phải tuân theo thứ tự Timestamp.

### Ưu điểm

* Không xảy ra Deadlock.

### Nhược điểm

* Có thể phải Rollback nhiều Transaction.

### SQL Server 2022

SQL Server không hiện thực Timestamp Ordering như một Isolation Level độc lập.

---

## 3.3 Validation-Based (Optimistic)

### Ý tưởng

Transaction thực hiện mà không khóa dữ liệu.

Trước khi Commit sẽ kiểm tra xem dữ liệu có bị Transaction khác thay đổi hay không.

### Giai đoạn

1. Read Phase
2. Validation Phase
3. Write Phase

### Ưu điểm

* Hiệu năng cao khi ít xung đột.

### Nhược điểm

* Có thể Rollback khi nhiều Transaction cùng cập nhật.

### SQL Server 2022

SQL Server hỗ trợ cơ chế tương tự thông qua Versioning và Snapshot Isolation.

---

## 3.4 Multi-Version Concurrency Control (MVCC)

### Ý tưởng

Mỗi lần cập nhật sẽ tạo ra một phiên bản dữ liệu mới.

Transaction đọc phiên bản phù hợp thay vì chờ khóa.

### Ưu điểm

* Giảm Blocking.
* Tăng khả năng thực thi đồng thời.

### Nhược điểm

* Tăng chi phí lưu trữ phiên bản.

### SQL Server 2022

Được hiện thực thông qua:

* Snapshot Isolation
* Read Committed Snapshot Isolation (RCSI)

---

# 4. Theory Mapping

| Theory             | SQL Server 2022                       |
| ------------------ | ------------------------------------- |
| Shared Lock        | Shared Lock (S)                       |
| Exclusive Lock     | Exclusive Lock (X)                    |
| Two Phase Locking  | Lock Manager                          |
| Strict 2PL         | Isolation Level + Lock giữ đến Commit |
| Timestamp Ordering | Không hỗ trợ trực tiếp                |
| Validation         | Snapshot Version Validation           |
| MVCC               | Snapshot Isolation                    |
| Deadlock Detection | Deadlock Monitor                      |

---

# 5. Transaction Anomalies

## 5.1 Dirty Read

### Định nghĩa

Một Transaction đọc dữ liệu chưa được Commit của Transaction khác.

### Theo lý thuyết

Có thể xử lý bằng:

* Lock-Based Protocol
* Strict 2PL
* Timestamp Ordering
* MVCC

### SQL Server hỗ trợ

* READ COMMITTED
* SNAPSHOT
* SERIALIZABLE

### Phương án nhóm lựa chọn

**READ COMMITTED**

### Lý do

* Isolation Level mặc định của SQL Server.
* Ngăn Dirty Read.
* Đơn giản, dễ minh họa.
* Phù hợp với kiến thức môn học.

---

## 5.2 Non-repeatable Read

### Định nghĩa

Một Transaction đọc cùng một bản ghi nhiều lần nhưng nhận các giá trị khác nhau.

### Theo lý thuyết

* Lock-Based
* Strict 2PL
* Timestamp
* MVCC

### SQL Server hỗ trợ

* REPEATABLE READ
* SERIALIZABLE
* SNAPSHOT

### Phương án nhóm lựa chọn

**REPEATABLE READ**

### Lý do

* Shared Lock được giữ đến Commit.
* Ngăn Transaction khác cập nhật bản ghi đang đọc.
* Không cần sử dụng SERIALIZABLE.

---

## 5.3 Phantom Read

### Định nghĩa

Một Transaction thực hiện cùng một truy vấn nhiều lần và xuất hiện thêm hoặc mất các bản ghi thỏa điều kiện.

### Theo lý thuyết

* Predicate Lock
* Strict 2PL
* MVCC

### SQL Server hỗ trợ

* SERIALIZABLE
* SNAPSHOT

### Phương án nhóm lựa chọn

**SERIALIZABLE**

### Lý do

* SQL Server sử dụng Range Lock để ngăn Insert/Delete trong phạm vi truy vấn.
* Minh họa rõ bản chất của Phantom Read.
* Phù hợp với lý thuyết đã học.

---

## 5.4 Lost Update

### Định nghĩa

Hai Transaction cùng cập nhật một bản ghi, kết quả cập nhật của một Transaction bị ghi đè bởi Transaction khác.

### Theo lý thuyết

* Lock-Based
* Strict 2PL
* Timestamp Ordering
* Validation Protocol

### SQL Server hỗ trợ

* REPEATABLE READ
* SERIALIZABLE
* UPDLOCK
* SNAPSHOT

### Phương án đang xem xét

* UPDLOCK
* SERIALIZABLE

### Ghi chú

Nhóm sẽ lựa chọn sau khi thống nhất phạm vi kỹ thuật được phép sử dụng trong đồ án.

---

## 5.5 Deadlock

### Định nghĩa

Hai hoặc nhiều Transaction chờ nhau giải phóng khóa dẫn đến không Transaction nào tiếp tục được.

### Theo lý thuyết

* Lock Ordering
* Deadlock Detection
* Rollback
* Timeout

### SQL Server hỗ trợ

* Deadlock Monitor
* Deadlock Victim Selection
* Automatic Rollback

### Phương án nhóm lựa chọn

**Consistent Lock Ordering**

### Lý do

* Không phụ thuộc DBMS.
* Là Best Practice phổ biến.
* Dễ triển khai và dễ minh họa.

---

# 6. Design Decisions

| Anomaly             | SQL Server hỗ trợ                       | Phương án lựa chọn | Trạng thái |
| ------------------- | --------------------------------------- | ------------------ | ---------- |
| Dirty Read          | READ COMMITTED, SNAPSHOT, SERIALIZABLE  | READ COMMITTED     | Approved   |
| Non-repeatable Read | REPEATABLE READ, SERIALIZABLE, SNAPSHOT | REPEATABLE READ    | Approved   |
| Phantom Read        | SERIALIZABLE, SNAPSHOT                  | SERIALIZABLE       | Approved   |
| Lost Update         | UPDLOCK, SERIALIZABLE, SNAPSHOT         | Pending Decision   | Reviewing  |
| Deadlock            | Lock Ordering, Deadlock Monitor         | Lock Ordering      | Approved   |

---

# 7. Demo Mapping

| Anomaly             | BAD Stored Procedure      | FIX Stored Procedure      | Technique       |
| ------------------- | ------------------------- | ------------------------- | --------------- |
| Dirty Read          | sp_Demo_DirtyRead_Bad     | sp_Demo_DirtyRead_Fix     | READ COMMITTED  |
| Non-repeatable Read | sp_Demo_NonRepeatable_Bad | sp_Demo_NonRepeatable_Fix | REPEATABLE READ |
| Phantom Read        | sp_Demo_Phantom_Bad       | sp_Demo_Phantom_Fix       | SERIALIZABLE    |
| Lost Update         | sp_Demo_LostUpdate_Bad    | sp_Demo_LostUpdate_Fix    | Pending         |
| Deadlock            | sp_Demo_Deadlock_Bad      | sp_Demo_Deadlock_Fix      | Lock Ordering   |

---