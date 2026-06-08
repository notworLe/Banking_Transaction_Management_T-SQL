from copy import deepcopy

from app.mock_data import customer as customer_mock


def _format_balance(total):
    return f"{total:,}".replace(",", ".") + " ₫"


def get_dashboard(username):
    """Dashboard khách hàng — sau này gọi vw_CustomerDashboard."""
    profile = customer_mock.get_profile_by_username(username)
    accounts = customer_mock.get_accounts_by_username(username)
    transactions = customer_mock.get_transactions_by_username(username)
    total_balance = sum(acc["balance"] for acc in accounts)

    return {
        "title": "Bảng điều khiển Khách hàng",
        "customer_name": profile["full_name"],
        "stats": [
            {"label": "Tổng số tài khoản", "value": len(accounts), "icon": "credit-card"},
            {"label": "Tổng số dư", "value": _format_balance(total_balance), "icon": "piggy-bank"},
            {"label": "Số giao dịch gần đây", "value": len(transactions), "icon": "receipt"},
        ],
        "accounts": [
            {
                "account_number": acc["account_number"],
                "account_type": acc["account_type_label"],
                "balance": acc["balance_display"],
                "status": "Hoạt động" if acc["status"] == "active" else "Đã khóa",
            }
            for acc in accounts
        ],
        "recent_transactions": [
            {
                "time": tx["created_at"],
                "type": tx["transaction_type_label"],
                "description": tx["description"],
                "amount": tx["amount_display"],
            }
            for tx in transactions[:5]
        ],
    }


def get_accounts(username):
    """Tài khoản của khách hàng hiện tại — sau này gọi vw_CustomerAccounts."""
    return deepcopy(customer_mock.get_accounts_by_username(username))


def get_transactions(username):
    """Lịch sử giao dịch khách hàng — sau này gọi vw_CustomerTransactions."""
    return deepcopy(customer_mock.get_transactions_by_username(username))


def get_owned_account_numbers(username):
    accounts = customer_mock.get_accounts_by_username(username)
    return [acc["account_number"] for acc in accounts]
