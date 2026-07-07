from fastapi import APIRouter, HTTPException, Request, Depends
from fastapi.security import HTTPAuthorizationCredentials
from .schemas import LoginForm, RegisterForm, TokenResponse
from jwt_utils import verify_password, create_token, hash_password
from database import get_conn
from dependencies import get_current_user, security
import pyodbc

router = APIRouter(prefix="/api/auth", tags=["auth"])


def _log_login(cursor, user_id, username, status, ip):
    cursor.execute(
        "INSERT INTO LoginLogs (UserId, UserName, LoginStatus, IPAddress) VALUES (?,?,?,?)",
        user_id, username, status, ip
    )


@router.post("/login", response_model=TokenResponse)
def login(form: LoginForm, request: Request):
    conn = get_conn()
    cur = conn.cursor()
    try:
        cur.execute("""
            SELECT u.UserId, u.PasswordHash, u.Status, r.RoleName, u.Username
            FROM Users u JOIN Roles r ON u.RoleId = r.RoleId
            WHERE u.Username = ?
        """, form.username)
        row = cur.fetchone()
        ip = request.client.host if request.client else None

        if not row:
            raise HTTPException(status_code=401, detail="Sai tên đăng nhập hoặc mật khẩu")

        user_id, pwd_hash, status, role_name, username = row

        if not verify_password(form.password, pwd_hash):
            _log_login(cur, str(user_id), username, "failed", ip)
            conn.commit()
            raise HTTPException(status_code=401, detail="Sai tên đăng nhập hoặc mật khẩu")

        if status == "locked":
            raise HTTPException(status_code=403, detail="Tài khoản đã bị khóa")

        # Get primary bank account for Customer
        ma_tk = ""
        if role_name == "Customer":
            cur.execute("""
                SELECT TOP 1 ba.BankAccountId
                FROM Customers c JOIN BankAccounts ba ON c.CustomerId = ba.CustomerId
                WHERE c.UserId = ? AND ba.Status = 'active'
            """, str(user_id))
            acc = cur.fetchone()
            if acc:
                ma_tk = str(acc[0])

        cur.execute("UPDATE Users SET LastLoginAt = SYSDATETIME() WHERE UserId = ?", str(user_id))
        _log_login(cur, str(user_id), username, "success", ip)
        conn.commit()

        token = create_token(str(user_id), role_name, ma_tk)
        return TokenResponse(access_token=token, role=role_name, username=username)
    finally:
        cur.close()
        conn.close()


@router.post("/register", status_code=201)
def register(form: RegisterForm):
    conn = get_conn()
    cur = conn.cursor()
    try:
        hashed = hash_password(form.password)

        # Gọi stored procedure sp_RegisterCustomer
        # SP tự xử lý: kiểm tra trùng lặp, tạo User + Customer + BankAccount
        # trong 1 atomic transaction
        cur.execute("""
            DECLARE @UserId       UNIQUEIDENTIFIER,
                    @CustomerId   UNIQUEIDENTIFIER,
                    @AccountNumber NVARCHAR(20);

            EXEC dbo.sp_RegisterCustomer
                @Username     = ?,
                @PasswordHash = ?,
                @FullName     = ?,
                @Email        = ?,
                @PhoneNumber  = ?,
                @Address      = ?,
                @BirthDay     = ?,
                @UserId       = @UserId       OUTPUT,
                @CustomerId   = @CustomerId   OUTPUT,
                @AccountNumber = @AccountNumber OUTPUT;

            SELECT @UserId AS UserId, @CustomerId AS CustomerId, @AccountNumber AS AccountNumber;
        """,
            form.username, hashed, form.full_name,
            form.email, form.phone,
            form.address or None,
            form.birthday or None
        )

        row = cur.fetchone()
        conn.commit()

        return {
            "message": "Đăng ký thành công",
            "user_id": str(row[0]),
            "customer_id": str(row[1]),
            "account_number": str(row[2])
        }

    except pyodbc.ProgrammingError as e:
        conn.rollback()
        msg = str(e)
        if "50010" in msg:
            raise HTTPException(status_code=400, detail="Username đã tồn tại")
        if "50011" in msg:
            raise HTTPException(status_code=400, detail="Email đã được sử dụng")
        if "50012" in msg:
            raise HTTPException(status_code=400, detail="Số điện thoại đã được sử dụng")
        raise HTTPException(status_code=500, detail=f"Lỗi hệ thống: {msg}")
    except pyodbc.IntegrityError:
        conn.rollback()
        raise HTTPException(status_code=400, detail="Dữ liệu bị trùng lặp")
    finally:
        cur.close()
        conn.close()


@router.post("/register_bad", status_code=201)
def register_bad(form: RegisterForm):
    """Đăng ký KHÔNG dùng TRANSACTION — dùng cho demo Atomicity.
    Cố tình INSERT BankAccount với AccountType không hợp lệ để gây lỗi.
    User + Customer vẫn được commit → orphan data."""
    conn = get_conn()
    cur = conn.cursor()
    try:
        # Lấy role Customer
        cur.execute("SELECT RoleId FROM Roles WHERE RoleName = 'Customer'")
        role_row = cur.fetchone()
        if not role_row:
            raise HTTPException(status_code=500, detail="Role Customer không tồn tại")
        role_id = str(role_row[0])

        hashed = hash_password(form.password)

        # Bước 1: INSERT User — KHÔNG CÓ TRANSACTION
        cur.execute(
            "INSERT INTO Users (RoleId, Username, PasswordHash)"
            " OUTPUT INSERTED.UserId"
            " VALUES (?, ?, ?)",
            role_id, form.username, hashed
        )
        user_id = str(cur.fetchone()[0])
        conn.commit()  # Commit ngay — không an toàn!

        # Bước 2: INSERT Customer — KHÔNG CÓ TRANSACTION
        cur.execute(
            "INSERT INTO Customers (UserId, FullName, Email, PhoneNumber, Address, BirthDay)"
            " OUTPUT INSERTED.CustomerId"
            " VALUES (?, ?, ?, ?, ?, ?)",
            user_id, form.full_name, form.email, form.phone,
            form.address or None, form.birthday or None
        )
        customer_id = str(cur.fetchone()[0])
        conn.commit()  # Commit ngay — User + Customer đã lưu!

        # Bước 3: INSERT BankAccount — CỐ TÌNH LỖI (AccountType='INVALID')
        bank_account_error = None
        try:
            cur.execute(
                "INSERT INTO BankAccounts (CustomerId, AccountNumber, AccountType, Balance)"
                " VALUES (?, ?, ?, ?)",
                customer_id, '9704_BAD_' + form.username[:6], 'INVALID_TYPE', 0.00
            )
            conn.commit()
        except Exception as e:
            bank_account_error = str(e)
            # KHÔNG rollback User + Customer — đây chính là vấn đề!

        return {
            "message": "Đăng ký hoàn tất (BAD — không có transaction)",
            "user_id": user_id,
            "customer_id": customer_id,
            "bank_account_created": bank_account_error is None,
            "bank_account_error": bank_account_error
        }

    except pyodbc.IntegrityError:
        conn.rollback()
        raise HTTPException(status_code=400, detail="Dữ liệu bị trùng lặp")
    finally:
        cur.close()
        conn.close()



@router.post("/logout")
def logout(credentials: HTTPAuthorizationCredentials = Depends(security)):
    user = get_current_user(credentials)
    conn = get_conn()
    cur = conn.cursor()
    try:
        cur.execute("""
            UPDATE LoginLogs SET LogoutTime = SYSDATETIME()
            WHERE LoginLogId = (
                SELECT TOP 1 LoginLogId FROM LoginLogs
                WHERE UserId = ? AND LogoutTime IS NULL
                ORDER BY LoginTime DESC
            )
        """, user["user_id"])
        conn.commit()
        return {"message": "Đăng xuất thành công"}
    finally:
        cur.close()
        conn.close()


@router.get("/me")
def get_me(credentials: HTTPAuthorizationCredentials = Depends(security)):
    return get_current_user(credentials)