"""
seed.py – Tạo dữ liệu mẫu với bcrypt password thật.
Chạy 1 lần khi khởi động container (idempotent – kiểm tra tồn tại trước khi insert).
"""
import sys
import time
import pyodbc
import os
from jwt_utils import hash_password

DB_SERVER   = os.getenv("DB_SERVER", "localhost")
DB_NAME     = os.getenv("DB_NAME", "banking_transaction")
DB_USER     = os.getenv("DB_USER", "sa")
DB_PASSWORD = os.getenv("DB_PASSWORD", "BankingDB@2024")
DB_DRIVER   = os.getenv("DB_DRIVER", "ODBC Driver 18 for SQL Server")

if os.getenv("DB_TRUSTED", "").lower() == "yes":
    CONN_STR = (
        f"DRIVER={{{DB_DRIVER}}};"
        f"SERVER={DB_SERVER};DATABASE={DB_NAME};"
        f"Trusted_Connection=yes;TrustServerCertificate=yes;"
    )
else:
    CONN_STR = (
        f"DRIVER={{{DB_DRIVER}}};"
        f"SERVER={DB_SERVER};DATABASE={DB_NAME};"
        f"UID={DB_USER};PWD={DB_PASSWORD};TrustServerCertificate=yes;"
    )


def wait_for_db(retries=15, delay=5):
    for i in range(retries):
        try:
            conn = pyodbc.connect(CONN_STR, timeout=5)
            conn.close()
            print("[seed] Database ready.")
            return True
        except Exception as e:
            print(f"[seed] Waiting for DB... ({i+1}/{retries}): {e}")
            time.sleep(delay)
    print("[seed] Could not connect to DB. Exiting.")
    sys.exit(1)


def insert_user(cur, role_id, username, password, status="active"):
    """Insert user and return new UserId using OUTPUT clause."""
    cur.execute(
        "INSERT INTO Users (RoleId, Username, PasswordHash, Status)"
        " OUTPUT INSERTED.UserId"
        " VALUES (?, ?, ?, ?)",
        role_id, username, hash_password(password), status
    )
    return str(cur.fetchone()[0])


def insert_with_output(cur, sql, *params):
    """Execute INSERT ... OUTPUT INSERTED.<PK> and return the PK."""
    cur.execute(sql, *params)
    return str(cur.fetchone()[0])


def seed():
    conn = pyodbc.connect(CONN_STR)
    cur = conn.cursor()

    # Check already seeded
    cur.execute("SELECT COUNT(*) FROM Users WHERE Username = 'admin'")
    if cur.fetchone()[0] > 0:
        print("[seed] Already seeded. Skipping.")
        cur.close(); conn.close()
        return

    print("[seed] Seeding users with bcrypt passwords...")

    # Get role IDs
    cur.execute("SELECT RoleId, RoleName FROM Roles")
    roles = {r[1]: str(r[0]) for r in cur.fetchall()}

    # ── Users ──────────────────────────────────────────────────
    uid_admin = insert_user(cur, roles["Admin"],    "admin",        "Admin@123")
    uid_b1    = insert_user(cur, roles["Banker"],   "banker_nam",   "Banker@123")
    uid_b2    = insert_user(cur, roles["Banker"],   "banker_lan",   "Banker@123", "locked")
    uid_c1    = insert_user(cur, roles["Customer"], "nguyen_van_a", "Cust@111")
    uid_c2    = insert_user(cur, roles["Customer"], "tran_thi_b",   "Cust@222")
    uid_c3    = insert_user(cur, roles["Customer"], "le_van_c",     "Cust@333", "locked")

    # ── Bankers ────────────────────────────────────────────────
    bid1 = insert_with_output(cur,
        "INSERT INTO Bankers (UserId, EmployeeCode, FullName, Email, PhoneNumber)"
        " OUTPUT INSERTED.BankerId VALUES (?, 'EMP-001', N'Trần Văn Nam', 'nam.tran@vcb.vn', '0901234567')",
        uid_b1)
    bid2 = insert_with_output(cur,
        "INSERT INTO Bankers (UserId, EmployeeCode, FullName, Email, PhoneNumber)"
        " OUTPUT INSERTED.BankerId VALUES (?, 'EMP-002', N'Nguyễn Thị Lan', 'lan.nguyen@vcb.vn', '0912345678')",
        uid_b2)

    # ── Customers ──────────────────────────────────────────────
    cid1 = insert_with_output(cur,
        "INSERT INTO Customers (UserId, FullName, Email, PhoneNumber, Address, BirthDay)"
        " OUTPUT INSERTED.CustomerId"
        " VALUES (?, N'Nguyễn Văn A', 'a.nguyen@gmail.com', '0933111222', N'12 Lê Lợi, Q.1, TP.HCM', '1995-03-15')",
        uid_c1)
    cid2 = insert_with_output(cur,
        "INSERT INTO Customers (UserId, FullName, Email, PhoneNumber, Address, BirthDay)"
        " OUTPUT INSERTED.CustomerId"
        " VALUES (?, N'Trần Thị B', 'b.tran@gmail.com', '0944222333', N'45 Trần Hưng Đạo, Hải Phòng', '1998-07-22')",
        uid_c2)
    cid3 = insert_with_output(cur,
        "INSERT INTO Customers (UserId, FullName, Email, PhoneNumber, Address, BirthDay)"
        " OUTPUT INSERTED.CustomerId"
        " VALUES (?, N'Lê Văn C', 'c.le@gmail.com', '0955333444', N'78 Nguyễn Huệ, Đà Nẵng', '1990-11-05')",
        uid_c3)

    # ── BankAccounts ───────────────────────────────────────────
    acc_sql = (
        "INSERT INTO BankAccounts (CustomerId, AccountNumber, AccountType, Balance, Status)"
        " OUTPUT INSERTED.BankAccountId VALUES (?, ?, ?, ?, ?)"
    )
    acc1a = insert_with_output(cur, acc_sql, cid1, "9704001000001", "payment", 15000000.00, "active")
    acc1b = insert_with_output(cur, acc_sql, cid1, "9704001000002", "saving",  50000000.00, "active")
    acc2a = insert_with_output(cur, acc_sql, cid2, "9704002000001", "payment",  8500000.00, "active")
    acc3a = insert_with_output(cur, acc_sql, cid3, "9704003000001", "debit",    2000000.00, "locked")

    # ── Transactions ───────────────────────────────────────────
    txn = (
        "INSERT INTO Transactions"
        " (FromBankAccountId, ToBankAccountId, CreatedByUserId, Type, Amount, Status, Description)"
        " VALUES (?, ?, ?, ?, ?, ?, ?)"
    )
    cur.execute(txn, None,   acc1a, uid_c1, "deposit",  5000000.00, "success", "Nạp tiền ATM")
    cur.execute(txn, acc1a,  None,  uid_c1, "withdraw", 1000000.00, "success", "Rút tiền quầy")
    cur.execute(txn, acc1a,  acc2a, uid_c1, "transfer", 2000000.00, "success", "Chuyển tiền cho bạn B")
    cur.execute(txn, acc2a,  acc1a, uid_c2, "transfer",  500000.00, "pending", "Chuyển lại tiền")
    cur.execute(txn, acc3a,  None,  uid_c3, "withdraw", 5000000.00, "failed",  "Số dư không đủ")

    # ── AuditLogs ──────────────────────────────────────────────
    audit = "INSERT INTO AuditLogs (UserId, ActionType, TargetTable, Description) VALUES (?, ?, ?, ?)"
    cur.execute(audit, uid_admin, "CREATE_BANKER",   "Bankers",      "Admin tạo banker EMP-001")
    cur.execute(audit, uid_admin, "LOCK_USER",       "Users",        "Admin khoá banker EMP-002")
    cur.execute(audit, uid_b1,   "CREATE_ACCOUNT",  "BankAccounts", "Banker tạo tài khoản cho Nguyễn Văn A")

    conn.commit()
    print("[seed] Done!")
    print("  admin        / Admin@123   (Admin)")
    print("  banker_nam   / Banker@123  (Banker)")
    print("  nguyen_van_a / Cust@111    (Customer)")
    print("  tran_thi_b   / Cust@222    (Customer)")
    cur.close(); conn.close()


if __name__ == "__main__":
    wait_for_db()
    seed()
