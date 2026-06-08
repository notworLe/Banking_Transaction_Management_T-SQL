from app.mock_data.banker import ACCOUNTS, CUSTOMERS

DEFAULT_USERNAME = "customer01"

USERNAME_ALIASES = {
    "customer": DEFAULT_USERNAME,
}

CUSTOMER_TRANSACTIONS = {
    "customer01": [
        {
            "id": "TX-10501",
            "transaction_type": "transfer",
            "transaction_type_label": "Chuyển khoản",
            "from_account": "ACC-10021",
            "to_account": "ACC-10008",
            "amount": 500000,
            "amount_display": "-500.000 ₫",
            "description": "Chuyển tiền cho bạn bè",
            "created_at": "2026-06-07 14:30:00",
        },
        {
            "id": "TX-10502",
            "transaction_type": "deposit",
            "transaction_type_label": "Nạp tiền",
            "from_account": None,
            "to_account": "ACC-10021",
            "amount": 2000000,
            "amount_display": "+2.000.000 ₫",
            "description": "Nạp tiền mặt tại quầy",
            "created_at": "2026-06-05 09:00:00",
        },
        {
            "id": "TX-10503",
            "transaction_type": "withdraw",
            "transaction_type_label": "Rút tiền",
            "from_account": "ACC-10021",
            "to_account": None,
            "amount": 1000000,
            "amount_display": "-1.000.000 ₫",
            "description": "Rút tiền ATM",
            "created_at": "2026-06-01 18:45:00",
        },
    ],
    "customer02": [
        {
            "id": "TX-10601",
            "transaction_type": "deposit",
            "transaction_type_label": "Nạp tiền",
            "from_account": None,
            "to_account": "ACC-10008",
            "amount": 1500000,
            "amount_display": "+1.500.000 ₫",
            "description": "Nạp tiền chuyển khoản",
            "created_at": "2026-06-06 11:20:00",
        },
    ],
    "customer03": [
        {
            "id": "TX-10701",
            "transaction_type": "transfer",
            "transaction_type_label": "Chuyển khoản",
            "from_account": "ACC-10015",
            "to_account": "ACC-10021",
            "amount": 300000,
            "amount_display": "-300.000 ₫",
            "description": "Thanh toán hóa đơn",
            "created_at": "2026-06-04 16:00:00",
        },
    ],
}


def resolve_username(username):
    return USERNAME_ALIASES.get(username, username or DEFAULT_USERNAME)


def get_profile_by_username(username):
    resolved = resolve_username(username)
    for customer in CUSTOMERS:
        if customer["username"] == resolved:
            return customer
    return CUSTOMERS[0]


def get_accounts_by_username(username):
    profile = get_profile_by_username(username)
    return [acc for acc in ACCOUNTS if acc["customer_id"] == profile["id"]]


def get_transactions_by_username(username):
    resolved = resolve_username(username)
    return CUSTOMER_TRANSACTIONS.get(resolved, CUSTOMER_TRANSACTIONS[DEFAULT_USERNAME])
