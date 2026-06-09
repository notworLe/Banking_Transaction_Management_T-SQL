import pyodbc
import os

def get_conn():
    conn_str = (
        f"DRIVER={{ODBC Driver 18 for SQL Server}};"
        f"SERVER={os.getenv('DB_SERVER', 'localhost')};"
        f"DATABASE={os.getenv('DB_NAME', 'PractiseBanking')};"
        f"UID={os.getenv('DB_USER', 'sa')};"
        f"PWD={os.getenv('DB_PASSWORD', 'BankingDB@2024')};"
        f"TrustServerCertificate=yes;"
    )
    return pyodbc.connect(conn_str)

