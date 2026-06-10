# 📚 T-SQL Demo: Các khái niệm DBMS

## Cách chạy

1. Mở **SSMS** → kết nối `localhost,1433` (sa / BankingDB@2024)  
2. Chạy `excer.sql` trước (tạo DB + data mẫu)  
3. Chạy từng **SECTION** trong `demo_concepts.sql`

---

## Các khái niệm được demo

| Section | Khái niệm | Chức năng minh họa |
|---------|-----------|-------------------|
| 1 | **ACID Transaction** | Chuyển tiền: Atomicity + Consistency |
| 2 | **SAVEPOINT** | Rollback một phần trong transaction |
| 3 | **Isolation Levels** | READ UNCOMMITTED → SERIALIZABLE |
| 4 | **Deadlock** | Phòng tránh bằng lock theo thứ tự |
| 5 | **Locking Hints** | UPDLOCK, ROWLOCK, NOLOCK |
| 6 | **Index** | Tăng tốc query giao dịch |
| 7 | **View** | Đơn giản hóa JOIN phức tạp |
| 8 | **Trigger** | Tự động audit khi balance thay đổi |
| 9 | **Concurrency** | SNAPSHOT isolation |
| 10 | **Full Flow** | Toàn bộ luồng nghiệp vụ |

---

## Tóm tắt lý thuyết

### 🔷 ACID
| Tính chất | Ý nghĩa | Ví dụ trong hệ thống |
|-----------|---------|----------------------|
| **Atomicity** | Tất cả hoặc không có gì | Transfer: trừ A + cộng B cùng 1 tran |
| **Consistency** | Dữ liệu luôn hợp lệ | `CHECK (Balance >= 0)` |
| **Isolation** | Các tran độc lập nhau | Isolation Level ngăn dirty read |
| **Durability** | Dữ liệu sau COMMIT không mất | SQL Server write-ahead log |

### 🔷 Isolation Levels (tăng dần độ cô lập)
```
READ UNCOMMITTED → READ COMMITTED → REPEATABLE READ → SERIALIZABLE
    (nhanh nhất)                                        (an toàn nhất)
```

| Level | Dirty Read | Non-repeatable Read | Phantom Read |
|-------|-----------|---------------------|--------------|
| READ UNCOMMITTED | ✅ có | ✅ có | ✅ có |
| READ COMMITTED   | ❌ | ✅ có | ✅ có |
| REPEATABLE READ  | ❌ | ❌ | ✅ có |
| SERIALIZABLE     | ❌ | ❌ | ❌ |

### 🔷 Deadlock
```
Session A: Lock TK_A → chờ TK_B
Session B: Lock TK_B → chờ TK_A  ← Deadlock!
```
**Phòng tránh:** luôn lock theo thứ tự `AccountNumber ASC` → `sp_SafeTransfer` đã làm điều này.

### 🔷 Stored Procedures có sẵn
```sql
EXEC sp_Deposit   @AccountId, @Amount, @UserId, @Desc
EXEC sp_Withdraw  @AccountId, @Amount, @UserId, @Desc  
EXEC sp_Transfer  @FromId, @ToId, @Amount, @UserId, @Desc
EXEC sp_SafeTransfer  @FromAccNum, @ToAccNum, @Amount, @UserId, @Desc
```

### 🔷 Views có sẵn
```sql
SELECT * FROM vw_CustomerBalance;      -- Số dư tất cả khách hàng
SELECT * FROM vw_TransactionHistory;   -- Lịch sử giao dịch đầy đủ
```

---

## Demo tài khoản mẫu

| Username | Password | Role | Tài khoản |
|----------|----------|------|-----------|
| admin | Admin@123 | Admin | — |
| banker_nam | Banker@123 | Banker | — |
| nguyen_van_a | Cust@111 | Customer | 9704001000001 (15tr), 9704001000002 (50tr) |
| tran_thi_b | Cust@222 | Customer | 9704002000001 (8.5tr) |
| le_van_c | Cust@333 | Customer | 9704003000001 (locked) |
