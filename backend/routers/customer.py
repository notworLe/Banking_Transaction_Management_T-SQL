from fastapi import APIRouter, Depends, HTTPException
from database import get_conn
from dependencies import require_role
from pydantic import BaseModel
from typing import Optional

router = APIRouter(prefix="/api/customer", tags=["customer"])


class TransferForm(BaseModel):
    from_account_id: str
    to_account_number: str
    amount: float
    description: Optional[str] = None


class WithdrawForm(BaseModel):
    account_id: str
    amount: float
    description: Optional[str] = None


class DepositForm(BaseModel):
    account_id: str
    amount: float
    description: Optional[str] = None


@router.get("/profile")
def get_profile(user=Depends(require_role("Customer"))):
    conn = get_conn()
    cur = conn.cursor()
    try:
        cur.execute("""
            SELECT c.CustomerId, c.FullName, c.Email, c.PhoneNumber,
                   c.Address, c.BirthDay, u.Username, u.Status, u.LastLoginAt
            FROM Customers c JOIN Users u ON c.UserId = u.UserId
            WHERE u.UserId = ?
        """, user["user_id"])
        row = cur.fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Không tìm thấy thông tin")
        return {"customer_id": str(row[0]), "full_name": row[1], "email": row[2],
                "phone": row[3], "address": row[4],
                "birthday": str(row[5]) if row[5] else None,
                "username": row[6], "status": row[7],
                "last_login": str(row[8]) if row[8] else None}
    finally:
        cur.close(); conn.close()


@router.get("/accounts")
def get_accounts(user=Depends(require_role("Customer"))):
    conn = get_conn()
    cur = conn.cursor()
    try:
        cur.execute("""
            SELECT ba.BankAccountId, ba.AccountNumber, ba.AccountType,
                   ba.Balance, ba.Status, ba.OpenedAt
            FROM BankAccounts ba
            JOIN Customers c ON ba.CustomerId = c.CustomerId
            WHERE c.UserId = ?
            ORDER BY ba.OpenedAt DESC
        """, user["user_id"])
        return [{"account_id": str(r[0]), "account_number": r[1],
                 "account_type": r[2], "balance": float(r[3]),
                 "status": r[4], "opened_at": str(r[5])} for r in cur.fetchall()]
    finally:
        cur.close(); conn.close()


@router.get("/transactions")
def get_transactions(user=Depends(require_role("Customer"))):
    conn = get_conn()
    cur = conn.cursor()
    try:
        cur.execute("""
            SELECT t.TransactionId,
                   fa.AccountNumber, ta.AccountNumber,
                   t.Type, t.Amount, t.Status, t.Description, t.CreatedAt
            FROM Transactions t
            LEFT JOIN BankAccounts fa ON t.FromBankAccountId = fa.BankAccountId
            LEFT JOIN BankAccounts ta ON t.ToBankAccountId = ta.BankAccountId
            JOIN Customers c ON (
                (fa.CustomerId = c.CustomerId) OR (ta.CustomerId = c.CustomerId)
            )
            WHERE c.UserId = ?
            ORDER BY t.CreatedAt DESC
        """, user["user_id"])
        return [{"id": str(r[0]), "from_account": r[1], "to_account": r[2],
                 "type": r[3], "amount": float(r[4]), "status": r[5],
                 "description": r[6], "created_at": str(r[7])} for r in cur.fetchall()]
    finally:
        cur.close(); conn.close()


@router.post("/transactions/transfer")
def transfer(form: TransferForm, user=Depends(require_role("Customer"))):
    conn = get_conn()
    cur = conn.cursor()
    try:
        # Verify from_account belongs to this customer
        cur.execute("""
            SELECT 1 FROM BankAccounts ba
            JOIN Customers c ON ba.CustomerId = c.CustomerId
            WHERE ba.BankAccountId = ? AND c.UserId = ? AND ba.Status = 'active'
        """, form.from_account_id, user["user_id"])
        if not cur.fetchone():
            raise HTTPException(status_code=403, detail="Tài khoản không hợp lệ")

        # Get destination account
        cur.execute("SELECT BankAccountId FROM BankAccounts WHERE AccountNumber = ? AND Status = 'active'",
                    form.to_account_number)
        to_row = cur.fetchone()
        if not to_row:
            raise HTTPException(status_code=404, detail="Tài khoản đích không tồn tại hoặc bị khóa")

        cur.execute("EXEC sp_Transfer ?, ?, ?, ?, ?",
                    form.from_account_id, str(to_row[0]),
                    form.amount, user["user_id"], form.description)
        conn.commit()
        return {"message": "Chuyển tiền thành công"}
    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        cur.close(); conn.close()


@router.post("/transactions/withdraw")
def withdraw(form: WithdrawForm, user=Depends(require_role("Customer"))):
    conn = get_conn()
    cur = conn.cursor()
    try:
        cur.execute("""
            SELECT 1 FROM BankAccounts ba
            JOIN Customers c ON ba.CustomerId = c.CustomerId
            WHERE ba.BankAccountId = ? AND c.UserId = ? AND ba.Status = 'active'
        """, form.account_id, user["user_id"])
        if not cur.fetchone():
            raise HTTPException(status_code=403, detail="Tài khoản không hợp lệ")

        cur.execute("EXEC sp_Withdraw ?, ?, ?, ?",
                    form.account_id, form.amount, user["user_id"], form.description)
        conn.commit()
        return {"message": "Rút tiền thành công"}
    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        cur.close(); conn.close()


@router.post("/transactions/deposit")
def deposit(form: DepositForm, user=Depends(require_role("Customer"))):
    conn = get_conn()
    cur = conn.cursor()
    try:
        cur.execute("""
            SELECT 1 FROM BankAccounts ba
            JOIN Customers c ON ba.CustomerId = c.CustomerId
            WHERE ba.BankAccountId = ? AND c.UserId = ? AND ba.Status = 'active'
        """, form.account_id, user["user_id"])
        if not cur.fetchone():
            raise HTTPException(status_code=403, detail="Tài khoản không hợp lệ")

        cur.execute("EXEC sp_Deposit ?, ?, ?, ?",
                    form.account_id, form.amount, user["user_id"], form.description)
        conn.commit()
        return {"message": "Nạp tiền thành công"}
    except HTTPException:
        raise
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=400, detail=str(e))
    finally:
        cur.close(); conn.close()
