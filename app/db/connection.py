"""SQL Server connection via pyodbc — dùng khi tích hợp DB (chưa gọi từ services UI-first)."""

import pyodbc
from flask import current_app


def get_db_connection():
    """Open a pyodbc connection using Flask app config from environment."""
    cfg = current_app.config
    trust = cfg.get("DB_TRUST_SERVER_CERTIFICATE", "yes")
    conn_str = (
        f"DRIVER={{{cfg['DB_DRIVER']}}};"
        f"SERVER={cfg['DB_SERVER']};"
        f"DATABASE={cfg['DB_NAME']};"
        f"UID={cfg['DB_USER']};"
        f"PWD={cfg['DB_PASSWORD']};"
        f"TrustServerCertificate={trust};"
    )
    return pyodbc.connect(conn_str)
