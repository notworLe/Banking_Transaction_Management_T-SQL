/*
================================================================================
SEED DATA — DEMO DATA CHO ĐỒ ÁN
================================================================================
Dữ liệu mẫu để phát triển UI và kiểm thử. Không dùng cho production.

PasswordHash chỉ là placeholder (ví dụ hash_Admin@123) — không phải bcrypt thật.
Ứng dụng Flask hiện vẫn dùng mock auth; seed phục vụ giai đoạn tích hợp DB sau.

Script này KHÔNG DROP DATABASE. Chạy trên database đã có schema (001_create_tables.sql).
Chạy một lần trên database trống; chạy lại sẽ lỗi do UNIQUE constraint.

Cố định UNIQUEIDENTIFIER để script chạy từ đầu đến cuối không lỗi tham chiếu.
================================================================================
*/

USE BankingTransactionDB;
GO

-- ── Roles ────────────────────────────────────────────────────
DECLARE @RoleAdmin    UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111101';
DECLARE @RoleBanker   UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111102';
DECLARE @RoleCustomer UNIQUEIDENTIFIER = '11111111-1111-1111-1111-111111111103';

INSERT INTO Roles (RoleId, RoleName) VALUES
    (@RoleAdmin,    N'Admin'),
    (@RoleBanker,   N'Banker'),
    (@RoleCustomer, N'Customer');

-- ── Users ─────────────────────────────────────────────────────
-- PasswordHash: placeholder cho đồ án — production phải dùng bcrypt/argon2
DECLARE @UAdmin   UNIQUEIDENTIFIER = '22222222-2222-2222-2222-222222222201';
DECLARE @UBanker1 UNIQUEIDENTIFIER = '22222222-2222-2222-2222-222222222202';
DECLARE @UBanker2 UNIQUEIDENTIFIER = '22222222-2222-2222-2222-222222222203';
DECLARE @UCust1   UNIQUEIDENTIFIER = '22222222-2222-2222-2222-222222222211';
DECLARE @UCust2   UNIQUEIDENTIFIER = '22222222-2222-2222-2222-222222222212';
DECLARE @UCust3   UNIQUEIDENTIFIER = '22222222-2222-2222-2222-222222222213';

INSERT INTO Users (UserId, RoleId, Username, PasswordHash, Status, LastLoginAt, CreatedAt) VALUES
    (@UAdmin,   @RoleAdmin,    N'admin',        N'hash_Admin@123',   N'active', '2025-06-05 08:00:00', '2024-01-01 08:00:00'),
    (@UBanker1, @RoleBanker,   N'banker_nam',   N'hash_Banker@123',  N'active', '2025-06-05 08:15:00', '2024-02-01 08:00:00'),
    (@UBanker2, @RoleBanker,   N'banker_lan',   N'hash_Banker@456',  N'locked', '2025-05-20 09:00:00', '2024-02-15 08:00:00'),
    (@UCust1,   @RoleCustomer, N'nguyen_van_a', N'hash_Cust@111',    N'active', '2025-06-05 10:00:00', '2024-03-01 09:00:00'),
    (@UCust2,   @RoleCustomer, N'tran_thi_b',   N'hash_Cust@222',    N'active', '2025-06-04 14:30:00', '2024-03-10 09:00:00'),
    (@UCust3,   @RoleCustomer, N'le_van_c',     N'hash_Cust@333',    N'locked', '2025-05-01 11:00:00', '2024-04-01 09:00:00');

-- ── Bankers ───────────────────────────────────────────────────
DECLARE @Banker1 UNIQUEIDENTIFIER = '33333333-3333-3333-3333-333333333301';
DECLARE @Banker2 UNIQUEIDENTIFIER = '33333333-3333-3333-3333-333333333302';

INSERT INTO Bankers (BankerId, UserId, EmployeeCode, FullName, Email, PhoneNumber, CreatedAt) VALUES
    (@Banker1, @UBanker1, N'EMP-001', N'Trần Văn Nam',   N'nam.tran@vcb.vn',    N'0901234567', '2024-02-01 08:30:00'),
    (@Banker2, @UBanker2, N'EMP-002', N'Nguyễn Thị Lan', N'lan.nguyen@vcb.vn',  N'0912345678', '2024-02-15 09:00:00');

-- ── Customers ─────────────────────────────────────────────────
DECLARE @Cust1 UNIQUEIDENTIFIER = '44444444-4444-4444-4444-444444444401';
DECLARE @Cust2 UNIQUEIDENTIFIER = '44444444-4444-4444-4444-444444444402';
DECLARE @Cust3 UNIQUEIDENTIFIER = '44444444-4444-4444-4444-444444444403';

INSERT INTO Customers (CustomerId, UserId, FullName, Email, PhoneNumber, Address, BirthDay, CreatedAt) VALUES
    (@Cust1, @UCust1, N'Nguyễn Văn A', N'a.nguyen@gmail.com', N'0933111222',
        N'12 Lê Lợi, Q.1, TP.HCM', '1995-03-15', '2024-03-01 10:00:00'),
    (@Cust2, @UCust2, N'Trần Thị B',   N'b.tran@gmail.com',   N'0944222333',
        N'45 Trần Hưng Đạo, Hải Phòng', '1998-07-22', '2024-03-10 10:00:00'),
    (@Cust3, @UCust3, N'Lê Văn C',     N'c.le@gmail.com',     N'0955333444',
        N'78 Nguyễn Huệ, Đà Nẵng', '1990-11-05', '2024-04-01 10:00:00');

-- ── BankAccounts (4 tài khoản) ────────────────────────────────
DECLARE @Acc1A UNIQUEIDENTIFIER = '55555555-5555-5555-5555-555555555501';
DECLARE @Acc1B UNIQUEIDENTIFIER = '55555555-5555-5555-5555-555555555502';
DECLARE @Acc2A UNIQUEIDENTIFIER = '55555555-5555-5555-5555-555555555503';
DECLARE @Acc3A UNIQUEIDENTIFIER = '55555555-5555-5555-5555-555555555504';

INSERT INTO BankAccounts (BankAccountId, CustomerId, AccountNumber, AccountType, Balance, Status, OpenedAt) VALUES
    (@Acc1A, @Cust1, N'9704001000001', N'payment', 15000000.00, N'active', '2023-01-10 09:00:00'),
    (@Acc1B, @Cust1, N'9704001000002', N'saving',  50000000.00, N'active', '2023-06-01 10:00:00'),
    (@Acc2A, @Cust2, N'9704002000001', N'payment',  8500000.00, N'active', '2024-03-15 08:30:00'),
    (@Acc3A, @Cust3, N'9704003000001', N'debit',    2000000.00, N'locked', '2022-11-20 11:00:00');

-- ── Transactions (deposit / withdraw / transfer × success / pending / failed) ──
INSERT INTO Transactions (FromBankAccountId, ToBankAccountId, CreatedByUserId, Type, Amount, Status, Description, CreatedAt) VALUES
    (NULL,  @Acc1A, @UCust1, N'deposit',   5000000.00, N'success', N'Nạp tiền ATM',              '2025-06-01 09:00:00'),
    (@Acc1A, NULL,  @UCust1, N'withdraw',  1000000.00, N'success', N'Rút tiền quầy',             '2025-06-02 10:30:00'),
    (@Acc1A, @Acc2A, @UCust1, N'transfer', 2000000.00, N'success', N'Chuyển tiền cho bạn B',     '2025-06-03 14:00:00'),
    (@Acc2A, @Acc1A, @UCust2, N'transfer',  500000.00, N'pending', N'Chuyển lại tiền',           '2025-06-04 16:00:00'),
    (@Acc3A, NULL,  @UCust3, N'withdraw',  5000000.00, N'failed',  N'Số dư không đủ',            '2025-06-04 17:00:00'),
    (NULL,  @Acc1B, @UBanker1, N'deposit', 10000000.00, N'success', N'Banker nạp tiền tiết kiệm', '2025-06-05 08:45:00');

-- ── AuditLogs ─────────────────────────────────────────────────
INSERT INTO AuditLogs (UserId, ActionType, TargetTable, TargetId, Description, CreatedAt) VALUES
    (@UAdmin,   N'CREATE_BANKER',  N'Bankers',      @Banker1, N'Admin tạo tài khoản banker EMP-001',           '2024-02-01 08:35:00'),
    (@UAdmin,   N'CREATE_BANKER',  N'Bankers',      @Banker2, N'Admin tạo tài khoản banker EMP-002',           '2024-02-15 09:05:00'),
    (@UAdmin,   N'LOCK_USER',      N'Users',        @UBanker2, N'Admin khoá banker EMP-002',                   '2025-05-20 09:30:00'),
    (@UBanker1, N'CREATE_ACCOUNT', N'BankAccounts', @Acc1A,   N'Banker tạo tài khoản thanh toán cho Nguyễn Văn A', '2023-01-10 09:05:00'),
    (@UBanker1, N'LOCK_ACCOUNT',   N'BankAccounts', @Acc3A,   N'Banker khoá tài khoản của Lê Văn C theo yêu cầu', '2025-05-01 10:00:00'),
    (@UBanker1, N'VIEW_CUSTOMER',  N'Customers',    @Cust2,   N'Banker xem thông tin Trần Thị B',              '2025-06-04 11:00:00');

-- ── LoginLogs (UserId NULL = đăng nhập thất bại, username không tồn tại) ──
INSERT INTO LoginLogs (UserId, UserName, LoginTime, LogoutTime, LoginStatus, IPAddress) VALUES
    (@UAdmin,   N'admin',        '2025-06-05 08:00:00', '2025-06-05 11:00:00', N'success', N'192.168.1.1'),
    (@UBanker1, N'banker_nam',   '2025-06-05 08:15:00', '2025-06-05 17:30:00', N'success', N'192.168.1.10'),
    (@UCust1,   N'nguyen_van_a', '2025-06-05 10:00:00', '2025-06-05 10:45:00', N'success', N'14.232.0.1'),
    (@UCust1,   N'nguyen_van_a', '2025-06-04 09:00:00', NULL,                  N'failed',  N'14.232.0.1'),
    (@UCust2,   N'tran_thi_b',   '2025-06-04 14:30:00', '2025-06-04 15:00:00', N'success', N'27.65.10.5'),
    (@UCust3,   N'le_van_c',     '2025-05-01 11:00:00', '2025-05-01 11:02:00', N'success', N'113.185.4.2'),
    (NULL,      N'unknown_user', '2025-06-05 07:55:00', NULL,                  N'failed',  N'203.0.113.50');

GO
