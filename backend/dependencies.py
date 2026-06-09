from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from auth import decode_token

security = HTTPBearer()

# Dependency 1: lấy thông tin user từ token
# Dùng trong mọi route cần biết user là ai
def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security)
) -> dict:
    token = credentials.credentials
    payload = decode_token(token)

    if payload is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token không hợp lệ hoặc đã hết hạn"
        )
    return payload
    # payload = {"user_id": "KH001", "role": "customer", "ma_tk": "TK001"}


# Dependency 2: kiểm tra role
# Dùng khi route chỉ cho phép role cụ thể
def require_role(*allowed_roles: str):
    def checker(user: dict = Depends(get_current_user)) -> dict:
        if user["role"] not in allowed_roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Yêu cầu quyền: {', '.join(allowed_roles)}"
            )
        return user
    return checker