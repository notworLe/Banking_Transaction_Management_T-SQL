from fastapi import APIRouter, Depends, HTTPException
from database import get_conn
from dependencies import require_role
from pydantic import BaseModel
from typing import Optional

router = APIRouter(prefix="/api/banker", tags=["banker"])


class CreateAccountForm(BaseModel):
    customer_id: str
    account_type: str       # payment | saving | debit
    account_number: str
    initial_balance: float = 0.0


class UpdateAccountStatusForm(BaseModel):
    status: str             # active | locked | closed


class TransactionForm(BaseModel):
    account_id: str
    amount: float
    transaction_type: str   # deposit | withdraw
    description: Optional[str] = None


@router.get("/customers")
def get_customers(user=Depends(require_role("Banker", "Admin"))):
    conn = get_conn()
    cur = conn.cursor()
    try:
        cur.execute("""
            SELECT c.CustomerId, c.FullName, c.Email, c.PhoneNumber,
                   c.Address, c.BirthDay, u.Status, u.Username
            FROM Customers c JOIN Users u ON c.UserId = u.UserId
            ORDER BY c.FullName
        """)
        return [{"customer_id": str(r[0]), "full_name": r[1], "email": r[2],
                 "phone": r[3], "address": r[4],
                 "birthday": str(r[5]) if r[5] else None,
                 "status": r[6], "username": r[7]} for r in cur.fetchall()]
    finally:
        cur.close(); conn.close()


@router.get("/customers/{customer_id}")
def get_customer_detail(customer_id: str, user=Depends(require_role("Banker", "Admin"))):
    conn = get_conn()
    cur = conn.cursor()
    try:
        cur.execute("""
            SELECT c.CustomerId, c.FullName, c.Email, c.PhoneNumber, c.Address, c.BirthDay,
                   u.Status, u.Username, u.LastLoginAt
            FROM Customers c JOIN Users u ON c.UserId = u.UserId
            WHERE c.CustomerId = ?
        """, customer_id)
        row = cur.fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Không tìm thấy khách hàng")

        cur.execute("""
            SELECT BankAccountId, AccountNumber, AccountType, Balance, Status, OpenedAt
            FROM BankAccounts WHERE CustomerId = ? ORDER BY OpenedAt DESC
        """, customer_id)
        accounts = [{"account_id": str(a[0]), "account_number": a[1],
                     "account_type": a[2], "balance": float(a[3]),
                     "status": a[4], "opened_at": str(a[5])} for a in cur.fetchall()]

        return {"customer_id": str(row[0]), "full_name": row[1], "email": row[2],
                "phone": row[3], "address": row[4],
                "birthday": str(row[5]) if row[5] else None,
                "status": row[6], "username": row[7],
                "last_login": str(row[8]) if row[8] else None,
                "accounts": accounts}
    finally:
        cur.close(); conn.close()


@router.post("/accounts", status_code=201)
def create_account(form: CreateAccountForm, user=Depends(require_role("Banker", "Admin"))):
    conn = get_conn()
    cur = conn.cursor()
    try:
        cur.execute("SELECT 1 FROM Customers WHERE CustomerId = ?", form.customer_id)
        if not cur.fetchone():
            raise HTTPException(status_code=404, detail="Khách hàng không tồn tại")

        cur.execute("SELECT 1 FROM BankAccounts WHERE AccountNumber = ?", form.account_number)
        if cur.fetchone():
            raise HTTPException(status_code=400, detail="Số tài khoản đã tồn tại")

        cur.execute(
            "INSERT INTO BankAccounts (CustomerId, AccountNumber, AccountType, Balance)"
            " OUTPUT INSERTED.BankAccountId VALUES (?, ?, ?, ?)",
            form.customer_id, form.account_number, form.account_type, form.initial_balance
        )
        account_id = str(cur.fetchone()[0])

        conn.commit()  # commit account truoc

        try:
            cur.execute("SELECT 1 FROM Users WHERE UserId = ?", user["user_id"])
            if cur.fetchone():
                cur.execute("""
                    INSERT INTO AuditLogs (UserId, ActionType, TargetTable, TargetId, Description)
                    VALUES (?, 'CREATE_ACCOUNT', 'BankAccounts', ?, ?)
                """, user["user_id"], account_id,
                    f"Banker tao tai khoan {form.account_type} - {form.account_number}")
                conn.commit()
        except Exception as e:
            print(f"[AuditLog] {e}")

        return {"message": "Tao tai khoan thanh cong", "account_id": account_id}
    finally:
        cur.close(); conn.close()


@router.patch("/accounts/{account_id}/status")
def update_account_status(account_id: str, form: UpdateAccountStatusForm,
                          user=Depends(require_role("Banker", "Admin"))):
    conn = get_conn()
    cur = conn.cursor()
    try:
        cur.execute("UPDATE BankAccounts SET Status = ? WHERE BankAccountId = ?",
                    form.status, account_id)
        action = {"locked": "LOCK_ACCOUNT", "active": "UNLOCK_ACCOUNT",
                  "closed": "CLOSE_ACCOUNT"}.get(form.status, "UPDATE_ACCOUNT")
        conn.commit()  # commit status truoc

        try:
            cur.execute("SELECT 1 FROM Users WHERE UserId = ?", user["user_id"])
            if cur.fetchone():
                cur.execute("""
                    INSERT INTO AuditLogs (UserId, ActionType, TargetTable, TargetId, Description)
                    VALUES (?, ?, 'BankAccounts', ?, ?)
                """, user["user_id"], action, account_id, f"Banker {action} accountId={account_id}")
                conn.commit()
        except Exception as e:
            print(f"[AuditLog] {e}")

        return {"message": f"Cap nhat trang thai thanh {form.status}"}
    finally:
        cur.close(); conn.close()


@router.post("/transactions")
def perform_transaction(form: TransactionForm, user=Depends(require_role("Banker", "Admin"))):
    conn = get_conn()
    cur = conn.cursor()
    try:
        if form.transaction_type == "deposit":
            cur.execute("EXEC sp_Deposit ?, ?, ?, ?",
                        form.account_id, form.amount, user["user_id"], form.description)
        elif form.transaction_type == "withdraw":
            cur.execute("EXEC sp_Withdraw ?, ?, ?, ?",
                        form.account_id, form.amount, user["user_id"], form.description)
        else:
            raise HTTPException(status_code=400, detail="Loại giao dịch không hợp lệ")
        conn.commit()
        return {"message": "Giao dịch thành công"}
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        cur.close(); conn.close()


@router.get("/transactions")
def get_transactions(user=Depends(require_role("Banker", "Admin"))):
    conn = get_conn()
    cur = conn.cursor()
    try:
        cur.execute("""
            SELECT t.TransactionId,
                   fa.AccountNumber, ta.AccountNumber,
                   u.Username, t.Type, t.Amount, t.Status, t.Description, t.CreatedAt
            FROM Transactions t
            LEFT JOIN BankAccounts fa ON t.FromBankAccountId = fa.BankAccountId
            LEFT JOIN BankAccounts ta ON t.ToBankAccountId = ta.BankAccountId
            JOIN Users u ON t.CreatedByUserId = u.UserId
            ORDER BY t.CreatedAt DESC
        """)
        return [{"id": str(r[0]), "from_account": r[1], "to_account": r[2],
                 "created_by": r[3], "type": r[4], "amount": float(r[5]),
                 "status": r[6], "description": r[7], "created_at": str(r[8])}
                for r in cur.fetchall()]
    finally:
        cur.close(); conn.close()


@router.get("/accounts")
def get_all_accounts(user=Depends(require_role("Banker", "Admin"))):
    conn = get_conn()
    cur = conn.cursor()
    try:
        cur.execute("""
            SELECT ba.BankAccountId, ba.AccountNumber, ba.AccountType,
                   ba.Balance, ba.Status, c.FullName, ba.OpenedAt
            FROM BankAccounts ba JOIN Customers c ON ba.CustomerId = c.CustomerId
            ORDER BY ba.OpenedAt DESC
        """)
        return [{"account_id": str(r[0]), "account_number": r[1], "account_type": r[2],
                 "balance": float(r[3]), "status": r[4], "owner": r[5],
                 "opened_at": str(r[6])} for r in cur.fetchall()]
    finally:
        cur.close(); conn.close()
