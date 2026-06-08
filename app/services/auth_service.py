ROLE_DISPLAY_NAMES = {
    "admin": "Quản trị viên",
    "banker": "Nhân viên ngân hàng",
    "customer": "Khách hàng",
}

VALID_ROLES = frozenset(ROLE_DISPLAY_NAMES.keys())


def mock_login(username, password, role):
    """
    Đăng nhập mock — không kiểm tra mật khẩu thật.
    Sau này thay bằng stored procedure xác thực.
  """
    if not username or not password:
        return None

    if role not in VALID_ROLES:
        return None

    return {
        "username": username,
        "role": role,
        "display_name": ROLE_DISPLAY_NAMES[role],
    }


def get_dashboard_url_for_role(role):
    routes = {
        "admin": "admin.dashboard",
        "banker": "banker.dashboard",
        "customer": "customer.dashboard",
    }
    return routes.get(role)
