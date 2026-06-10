from pydantic import BaseModel
from typing import Optional


class LoginForm(BaseModel):
    username: str
    password: str


class RegisterForm(BaseModel):
    username: str
    password: str
    full_name: str
    email: str
    phone: str
    address: Optional[str] = None
    birthday: Optional[str] = None


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    role: str
    username: str
