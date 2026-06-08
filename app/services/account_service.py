from copy import deepcopy

from app.mock_data.banker import ACCOUNT_TYPES, ACCOUNTS, CUSTOMERS


def get_account_types():
    return deepcopy(ACCOUNT_TYPES)


def get_accounts():
    """Danh sách tài khoản — sau này gọi vw_BankAccounts."""
    return deepcopy(ACCOUNTS)


def get_customers_for_select():
    return [{"id": c["id"], "label": f"{c['full_name']} ({c['username']})"} for c in CUSTOMERS]


def open_account(customer_id, account_type, initial_balance, created_by_user_id=None):
    """Mở tài khoản — sau này gọi sp_OpenBankAccount."""
    customer = next((c for c in CUSTOMERS if c["id"] == int(customer_id)), None)
    customer_name = customer["full_name"] if customer else "Khách hàng"
    return {
        "success": True,
        "message": f"Đã mở tài khoản cho {customer_name} thành công (mock).",
        "data": {
            "account_number": "ACC-10999",
            "customer_id": customer_id,
            "account_type": account_type,
            "initial_balance": initial_balance,
        },
    }
