import os

from dotenv import load_dotenv

load_dotenv()


class Config:
    SECRET_KEY = os.getenv("SECRET_KEY", "dev-secret-key-change-in-production")
    FLASK_ENV = os.getenv("FLASK_ENV", "development")
    FLASK_DEBUG = os.getenv("FLASK_DEBUG", "1") == "1"

    # SQL Server — chưa kết nối trong giai đoạn UI-first
    DB_SERVER = os.getenv("DB_SERVER", "localhost")
    DB_NAME = os.getenv("DB_NAME", "BankingDB")
    DB_USER = os.getenv("DB_USER", "")
    DB_PASSWORD = os.getenv("DB_PASSWORD", "")
    DB_DRIVER = os.getenv("DB_DRIVER", "ODBC Driver 18 for SQL Server")
    DB_TRUST_SERVER_CERTIFICATE = os.getenv("DB_TRUST_SERVER_CERTIFICATE", "yes")
