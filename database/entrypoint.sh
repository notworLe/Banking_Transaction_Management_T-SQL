#!/bin/bash
# Start SQL Server in background
/opt/mssql/bin/sqlservr &
PID=$!

# Chờ SQL Server ready
echo "Waiting for SQL Server..."
for i in {1..30}; do
    /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -Q "SELECT 1" -C &>/dev/null && break
    sleep 2
done

# Chạy init script
echo "Running init.sql..."
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$SA_PASSWORD" -i /init.sql -C
echo "DB init done!"

# Giữ SQL Server chạy
wait $PID