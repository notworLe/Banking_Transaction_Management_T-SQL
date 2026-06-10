from passlib.context import CryptContext
from jose import jwt, JWTError
from datetime import datetime, timedelta

SECRET_KEY = "banking-secret-key-2024-!@#$%"
ALGORITHM = "HS256"
TOKEN_EXPIRE_HOUR = 8

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


def hash_password(password: str) -> str:
    return pwd_context.hash(password)


def verify_password(plain: str, hashed: str) -> bool:
    return pwd_context.verify(plain, hashed)


def create_token(user_id: str, role: str, ma_tk: str) -> str:
    payload = {
        "user_id": user_id,
        "role": role,
        "ma_tk": ma_tk,
        "exp": datetime.utcnow() + timedelta(hours=TOKEN_EXPIRE_HOUR)
    }
    return jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)


def decode_token(token: str) -> dict:
    try:
        return jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    except JWTError:
        return None
