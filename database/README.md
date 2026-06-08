# Database scripts

Database name thống nhất: **BankingTransactionDB**

## Cấu trúc

```
database/
  reset/   000_reset_database.sql        — DROP + CREATE DB (chỉ chạy thủ công)
  schema/  001_create_tables.sql         — Tạo bảng, constraint, index
  seed/    001_seed_sample_data.sql      — Demo data cơ bản (UI dev)
           002_seed_performance_data.sql  — Dữ liệu lớn (set-based, có marker)
           003_seed_query_test_cases.sql — Case đặc biệt cho test query/SP
```

## Thứ tự chạy

| Bước | Script | Khi nào |
|------|--------|---------|
| 1 (tùy chọn) | `reset/000_reset_database.sql` | Muốn xóa sạch và tạo lại database |
| 2 | `schema/001_create_tables.sql` | Sau reset, hoặc lần đầu setup |
| 3 | `seed/001_seed_sample_data.sql` | Demo cơ bản — **bắt buộc** trước 002/003 |
| 4 (tùy chọn) | `seed/002_seed_performance_data.sql` | Benchmark / test truy vấn lớn |
| 5 (tùy chọn) | `seed/003_seed_query_test_cases.sql` | Test case đặc biệt cho SP |

- `002` và `003` có **marker idempotent** — chạy lại sẽ bỏ qua nếu đã seed.
- `001` chạy một lần trên DB trống (không có marker).
- Không seed trước schema. `reset` không nằm trong seed tự động.

## Docker (sqlcmd)

Thay `YOUR_SA_PASSWORD` bằng `MSSQL_SA_PASSWORD` trong `.env`.

```bash
# 1. Reset (tùy chọn)
docker compose exec sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "YOUR_SA_PASSWORD" -C \
  -i /database/reset/000_reset_database.sql

# 2. Schema
docker compose exec sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "YOUR_SA_PASSWORD" -C \
  -i /database/schema/001_create_tables.sql

# 3. Demo seed
docker compose exec sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "YOUR_SA_PASSWORD" -C \
  -i /database/seed/001_seed_sample_data.sql

# 4. Performance seed (tùy chọn — có thể mất vài phút)
docker compose exec sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "YOUR_SA_PASSWORD" -C \
  -i /database/seed/002_seed_performance_data.sql

# 5. Query test cases (tùy chọn)
docker compose exec sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "YOUR_SA_PASSWORD" -C \
  -i /database/seed/003_seed_query_test_cases.sql
```

Đặt `DB_NAME=BankingTransactionDB` trong `.env` khi tích hợp ứng dụng.

## Query kiểm tra sau seed

```sql
USE BankingTransactionDB;

-- Tổng số bản ghi theo bảng
SELECT 'Users' AS Tbl, COUNT(*) AS Cnt FROM Users
UNION ALL SELECT 'Customers', COUNT(*) FROM Customers
UNION ALL SELECT 'BankAccounts', COUNT(*) FROM BankAccounts
UNION ALL SELECT 'Transactions', COUNT(*) FROM Transactions
UNION ALL SELECT 'LoginLogs', COUNT(*) FROM LoginLogs
UNION ALL SELECT 'AuditLogs', COUNT(*) FROM AuditLogs;

-- Performance marker
SELECT COUNT(*) AS PerfCustomers FROM Users WHERE Username LIKE N'perf_customer_%';

-- Query test marker
SELECT COUNT(*) AS QcAccounts FROM BankAccounts WHERE AccountNumber LIKE N'QC%';

-- Phân bố giao dịch theo status
SELECT Status, Type, COUNT(*) AS Cnt
FROM Transactions
GROUP BY Status, Type
ORDER BY Status, Type;

-- Tài khoản heavy (case 2)
SELECT COUNT(*) AS HeavyTxCount
FROM Transactions
WHERE Description LIKE N'[QC] %heavy%';
```
