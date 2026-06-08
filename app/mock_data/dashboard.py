ADMIN_DASHBOARD = {
    "title": "Bảng điều khiển Quản trị viên",
    "stats": [
        {"label": "Tổng người dùng", "value": 128, "icon": "people"},
        {"label": "Tài khoản đang hoạt động", "value": 342, "icon": "wallet2"},
        {"label": "Giao dịch hôm nay", "value": 57, "icon": "arrow-left-right"},
        {"label": "Cảnh báo bảo mật", "value": 3, "icon": "shield-exclamation"},
    ],
    "recent_logs": [
        {
            "time": "2026-06-08 09:15",
            "user": "admin01",
            "action": "Khóa tài khoản user",
            "detail": "user_id=45",
        },
        {
            "time": "2026-06-08 08:42",
            "user": "admin01",
            "action": "Xem audit logs",
            "detail": "filter=7days",
        },
        {
            "time": "2026-06-07 17:30",
            "user": "admin02",
            "action": "Mở tài khoản user",
            "detail": "user_id=12",
        },
    ],
}

BANKER_DASHBOARD = {
    "title": "Bảng điều khiển Nhân viên ngân hàng",
    "stats": [
        {"label": "Khách hàng phụ trách", "value": 24, "icon": "person-lines-fill"},
        {"label": "Tài khoản đang quản lý", "value": 38, "icon": "bank"},
        {"label": "Giao dịch hôm nay", "value": 12, "icon": "cash-stack"},
        {"label": "Chờ xử lý", "value": 2, "icon": "hourglass-split"},
    ],
    "recent_transactions": [
        {
            "time": "2026-06-08 10:20",
            "type": "Nạp tiền",
            "account": "ACC-10021",
            "amount": "5.000.000 ₫",
        },
        {
            "time": "2026-06-08 09:55",
            "type": "Chuyển khoản",
            "account": "ACC-10008 → ACC-10015",
            "amount": "2.500.000 ₫",
        },
        {
            "time": "2026-06-07 16:10",
            "type": "Rút tiền",
            "account": "ACC-10003",
            "amount": "1.000.000 ₫",
        },
    ],
}

CUSTOMER_DASHBOARD = {
    "title": "Bảng điều khiển Khách hàng",
    "customer_name": "Nguyễn Văn An",
    "stats": [
        {"label": "Tổng số dư", "value": "45.750.000 ₫", "icon": "piggy-bank"},
        {"label": "Số tài khoản", "value": 2, "icon": "credit-card"},
        {"label": "Giao dịch tháng này", "value": 8, "icon": "receipt"},
        {"label": "Thông báo mới", "value": 1, "icon": "bell"},
    ],
    "accounts": [
        {
            "account_number": "ACC-10021",
            "account_type": "Thanh toán",
            "balance": "32.500.000 ₫",
            "status": "Hoạt động",
        },
        {
            "account_number": "ACC-10022",
            "account_type": "Tiết kiệm",
            "balance": "13.250.000 ₫",
            "status": "Hoạt động",
        },
    ],
    "recent_transactions": [
        {
            "time": "2026-06-07 14:30",
            "type": "Chuyển khoản",
            "description": "Chuyển tiền cho bạn bè",
            "amount": "-500.000 ₫",
        },
        {
            "time": "2026-06-05 09:00",
            "type": "Nạp tiền",
            "description": "Nạp tiền mặt tại quầy",
            "amount": "+2.000.000 ₫",
        },
        {
            "time": "2026-06-01 18:45",
            "type": "Rút tiền",
            "description": "Rút tiền ATM",
            "amount": "-1.000.000 ₫",
        },
    ],
}

MOCK_USERS = {
    "admin": {"username": "admin", "password": "admin123", "role": "admin", "display_name": "Quản trị viên"},
    "banker": {"username": "banker", "password": "banker123", "role": "banker", "display_name": "Nhân viên NH"},
    "customer": {"username": "customer", "password": "customer123", "role": "customer", "display_name": "Khách hàng"},
}
