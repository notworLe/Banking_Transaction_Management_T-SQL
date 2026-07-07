#!/bin/bash
# Start SQL Server in background
/opt/mssql/bin/sqlservr &
PID=$!

# Chá» SQL Server ready
echo "Waiting for SQL Server..."
for i in {1..30}; do
    /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -Q "SELECT 1" -C &>/dev/null && break
    sleep 2
done

# Cháº¡y init script
echo "Running init.sql..."
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -i /init.sql -C
echo "DB init done!"

# Cháº¡y cÃ¡c file demo theo thá»© tá»±
echo "Running 00_add_table_log.sql..."
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -i /demo/00_add_table_log.sql -C
echo "Running 01_reset.sql (phantom)..."
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -i /demo/phantom/01_reset.sql -C
echo "Running 02_bad.sql (phantom)..."
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -i /demo/phantom/02_bad.sql -C
echo "Running 03_fix.sql (phantom)..."
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -i /demo/phantom/03_fix.sql -C
echo "Running 01_reset.sql (deadlock)..."
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -i /demo/deadlock/01_reset.sql -C
echo "Running 02_bad.sql (deadlock)..."
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -i /demo/deadlock/02_bad.sql -C
echo "Running 03_fix.sql (deadlock)..."
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -i /demo/deadlock/03_fix.sql -C

echo "Running statuslock 01_reset.sql..."
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -i /demo/statuslock/01_reset.sql -C
echo "Running statuslock 02_bad.sql..."
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -i /demo/statuslock/02_bad.sql -C
echo "Running statuslock 03_fix.sql..."
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -i /demo/statuslock/03_fix.sql -C
echo "All demo scripts done!"

# Giá»¯ SQL Server cháº¡y
wait $PID