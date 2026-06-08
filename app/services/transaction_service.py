from copy import deepcopy

from app.mock_data.banker import TRANSACTIONS


def get_transactions():
    """Lịch sử giao dịch — sau này gọi vw_TransactionHistory."""
    return deepcopy(TRANSACTIONS)


def deposit(account_number, amount, description, created_by_user_id=None):
    """Nạp tiền — sau này gọi sp_Deposit."""
    return {
        "success": True,
        "message": f"Nạp tiền vào tài khoản {account_number} thành công (mock).",
        "data": {
            "transaction_id": "TX-10999",
            "account_number": account_number,
            "amount": amount,
            "description": description,
        },
    }


def withdraw(account_number, amount, description, created_by_user_id=None):
    """Rút tiền — sau này gọi sp_Withdraw."""
    return {
        "success": True,
        "message": f"Rút tiền từ tài khoản {account_number} thành công (mock).",
        "data": {
            "transaction_id": "TX-10998",
            "account_number": account_number,
            "amount": amount,
            "description": description,
        },
    }


def transfer(from_account_number, to_account_number, amount, description, created_by_user_id=None):
    """Chuyển khoản — sau này gọi sp_Transfer."""
    return {
        "success": True,
        "message": f"Chuyển khoản từ {from_account_number} sang {to_account_number} thành công (mock).",
        "data": {
            "transaction_id": "TX-10997",
            "from_account_number": from_account_number,
            "to_account_number": to_account_number,
            "amount": amount,
            "description": description,
        },
    }
