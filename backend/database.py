import pyodbc
import os

def get_conn():
    driver = os.getenv('DB_DRIVER', 'ODBC Driver 18 for SQL Server')
    db_name = os.getenv('DB_NAME', 'banking_transaction')  # default to banking_transaction to match compose
    
    if os.getenv('DB_TRUSTED', '').lower() == 'yes':
        conn_str = (
            f"DRIVER={{{driver}}};"
            f"SERVER={os.getenv('DB_SERVER', 'localhost')};"
            f"DATABASE={db_name};"
            f"Trusted_Connection=yes;"
            f"TrustServerCertificate=yes;"
        )
    else:
        conn_str = (
            f"DRIVER={{{driver}}};"
            f"SERVER={os.getenv('DB_SERVER', 'localhost')};"
            f"DATABASE={db_name};"
            f"UID={os.getenv('DB_USER', 'sa')};"
            f"PWD={os.getenv('DB_PASSWORD', 'BankingDB@2024')};"
            f"TrustServerCertificate=yes;"
        )
    return pyodbc.connect(conn_str)

