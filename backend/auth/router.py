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
        cur.execute("SELECT RoleId FROM Roles WHERE RoleName = 'Customer'")
        role_row = cur.fetchone()
        if not role_row:
            raise HTTPException(status_code=500, detail="Role Customer không tồn tại")
        role_id = str(role_row[0])

        cur.execute("SELECT 1 FROM Users WHERE Username = ?", form.username)
        if cur.fetchone():
            raise HTTPException(status_code=400, detail="Username đã tồn tại")

        cur.execute("SELECT 1 FROM Customers WHERE Email = ?", form.email)
        if cur.fetchone():
            raise HTTPException(status_code=400, detail="Email đã được sử dụng")

        hashed = hash_password(form.password)

        cur.execute(
            "INSERT INTO Users (RoleId, Username, PasswordHash)"
            " OUTPUT INSERTED.UserId"
            " VALUES (?, ?, ?)",
            role_id, form.username, hashed
        )
        user_id = str(cur.fetchone()[0])

        cur.execute(
            "INSERT INTO Customers (UserId, FullName, Email, PhoneNumber, Address, BirthDay)"
            " VALUES (?, ?, ?, ?, ?, ?)",
            user_id, form.full_name, form.email, form.phone, form.address, form.birthday
        )

        conn.commit()
        return {"message": "Đăng ký thành công", "user_id": user_id}
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