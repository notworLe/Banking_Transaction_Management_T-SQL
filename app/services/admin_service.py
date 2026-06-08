from copy import deepcopy

from app.mock_data.admin import AUDIT_LOGS, LOGIN_LOGS, USERS

_status_overrides = {}


def get_users():
    """Danh sách users — sau này gọi vw_Users."""
    result = []
    for user in USERS:
        item = deepcopy(user)
        if user["id"] in _status_overrides:
            item["status"] = _status_overrides[user["id"]]
        result.append(item)
    return result


def get_user_by_id(user_id):
    for user in get_users():
        if user["id"] == user_id:
            return user
    return None


def toggle_user_status(user_id):
    """Khóa/mở khóa user mock — sau này gọi sp_LockUser / sp_UnlockUser."""
    user = get_user_by_id(user_id)
    if not user:
        return False, "Không tìm thấy người dùng."

    if user["status"] == "active":
        _status_overrides[user_id] = "locked"
        return True, f"Đã khóa tài khoản {user['username']} (mock)."

    _status_overrides[user_id] = "active"
    return True, f"Đã mở khóa tài khoản {user['username']} (mock)."


def get_audit_logs():
    """Danh sách audit logs — sau này gọi vw_AuditLogs."""
    return deepcopy(AUDIT_LOGS)


def get_login_logs():
    """Danh sách login logs — sau này gọi vw_LoginLogs."""
    return deepcopy(LOGIN_LOGS)
