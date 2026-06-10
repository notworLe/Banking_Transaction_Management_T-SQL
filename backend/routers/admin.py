from fastapi import APIRouter, Depends, HTTPException
from database import get_conn
from dependencies import require_role
from jwt_utils import hash_password
from pydantic import BaseModel
from typing import Optional

router = APIRouter(prefix="/api/admin", tags=["admin"])


class CreateBankerForm(BaseModel):
    username: str
    password: str
    full_name: str
    email: str
    phone: str
    employee_code: str


class UpdateStatusForm(BaseModel):
    status: str  # active | locked


@router.get("/users")
def get_users(user=Depends(require_role("Admin"))):
    conn = get_conn()
    cur = conn.cursor()
    try:
        cur.execute("""
            SELECT u.UserId, u.Username, r.RoleName, u.Status, u.LastLoginAt, u.CreatedAt
            FROM Users u JOIN Roles r ON u.RoleId = r.RoleId
            ORDER BY u.CreatedAt DESC
        """)
        return [{"user_id": str(r[0]), "username": r[1], "role": r[2],
                 "status": r[3], "last_login": str(r[4]) if r[4] else None,
                 "created_at": str(r[5])} for r in cur.fetchall()]
    finally:
        cur.close(); conn.close()


@router.get("/bankers")
def get_bankers(user=Depends(require_role("Admin"))):
    conn = get_conn()
    cur = conn.cursor()
    try:
        cur.execute("""
            SELECT b.BankerId, b.EmployeeCode, b.FullName, b.Email, b.PhoneNumber,
                   u.Username, u.Status, u.CreatedAt
            FROM Bankers b JOIN Users u ON b.UserId = u.UserId
            ORDER BY u.CreatedAt DESC
        """)
        return [{"banker_id": str(r[0]), "employee_code": r[1], "full_name": r[2],
                 "email": r[3], "phone": r[4], "username": r[5],
                 "status": r[6], "created_at": str(r[7])} for r in cur.fetchall()]
    finally:
        cur.close(); conn.close()


@router.post("/bankers", status_code=201)
def create_banker(form: CreateBankerForm, user=Depends(require_role("Admin"))):
    conn = get_conn()
    cur = conn.cursor()
    try:
        cur.execute("SELECT RoleId FROM Roles WHERE RoleName = 'Banker'")
        role_row = cur.fetchone()
        if not role_row:
            raise HTTPException(status_code=500, detail="Role Banker không tồn tại")
        role_id = str(role_row[0])

        cur.execute("SELECT 1 FROM Users WHERE Username = ?", form.username)
        if cur.fetchone():
            raise HTTPException(status_code=400, detail="Username đã tồn tại")

        hashed = hash_password(form.password)
        cur.execute(
            "INSERT INTO Users (RoleId, Username, PasswordHash)"
            " OUTPUT INSERTED.UserId VALUES (?, ?, ?)",
            role_id, form.username, hashed
        )
        user_id = str(cur.fetchone()[0])

        cur.execute(
            "INSERT INTO Bankers (UserId, EmployeeCode, FullName, Email, PhoneNumber)"
            " VALUES (?, ?, ?, ?, ?)",
            user_id, form.employee_code, form.full_name, form.email, form.phone
        )

        cur.execute("""
            INSERT INTO AuditLogs (UserId, ActionType, TargetTable, Description)
            VALUES (?, 'CREATE_BANKER', 'Bankers', ?)
        """, user["user_id"], f"Admin tạo banker {form.employee_code} - {form.full_name}")

        conn.commit()
        return {"message": "Tạo Banker thành công", "user_id": user_id}
    finally:
        cur.close(); conn.close()


@router.patch("/users/{user_id}/status")
def update_user_status(user_id: str, form: UpdateStatusForm, user=Depends(require_role("Admin"))):
    conn = get_conn()
    cur = conn.cursor()
    try:
        cur.execute("UPDATE Users SET Status = ? WHERE UserId = ?", form.status, user_id)
        action = "LOCK_USER" if form.status == "locked" else "UNLOCK_USER"
        cur.execute("""
            INSERT INTO AuditLogs (UserId, ActionType, TargetTable, TargetId, Description)
            VALUES (?, ?, 'Users', ?, ?)
        """, user["user_id"], action, user_id, f"Admin {action} userId={user_id}")
        conn.commit()
        return {"message": f"Cập nhật thành {form.status}"}
    finally:
        cur.close(); conn.close()


@router.get("/audit-logs")
def get_audit_logs(user=Depends(require_role("Admin"))):
    conn = get_conn()
    cur = conn.cursor()
    try:
        cur.execute("""
            SELECT a.AuditLogId, u.Username, a.ActionType, a.TargetTable,
                   a.TargetId, a.Description, a.CreatedAt
            FROM AuditLogs a JOIN Users u ON a.UserId = u.UserId
            ORDER BY a.CreatedAt DESC
        """)
        return [{"id": str(r[0]), "username": r[1], "action": r[2],
                 "target_table": r[3], "target_id": str(r[4]) if r[4] else None,
                 "description": r[5], "created_at": str(r[6])} for r in cur.fetchall()]
    finally:
        cur.close(); conn.close()


@router.get("/login-logs")
def get_login_logs(user=Depends(require_role("Admin"))):
    conn = get_conn()
    cur = conn.cursor()
    try:
        cur.execute("""
            SELECT LoginLogId, UserName, LoginTime, LogoutTime, LoginStatus, IPAddress
            FROM LoginLogs ORDER BY LoginTime DESC
        """)
        return [{"id": str(r[0]), "username": r[1], "login_time": str(r[2]),
                 "logout_time": str(r[3]) if r[3] else None,
                 "status": r[4], "ip": r[5]} for r in cur.fetchall()]
    finally:
        cur.close(); conn.close()


@router.get("/stats")
def get_stats(user=Depends(require_role("Admin"))):
    conn = get_conn()
    cur = conn.cursor()
    try:
        cur.execute("SELECT COUNT(*) FROM Users")
        total_users = cur.fetchone()[0]
        cur.execute("SELECT COUNT(*) FROM Bankers")
        total_bankers = cur.fetchone()[0]
        cur.execute("SELECT COUNT(*) FROM Customers")
        total_customers = cur.fetchone()[0]
        cur.execute("SELECT COUNT(*) FROM Transactions WHERE Status='success'")
        total_txn = cur.fetchone()[0]
        cur.execute("SELECT ISNULL(SUM(Amount),0) FROM Transactions WHERE Type='deposit' AND Status='success'")
        total_deposit = float(cur.fetchone()[0])
        return {
            "total_users": total_users, "total_bankers": total_bankers,
            "total_customers": total_customers, "total_transactions": total_txn,
            "total_deposit": total_deposit
        }
    finally:
        cur.close(); conn.close()
