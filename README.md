# Banking Transaction Management System

Hệ thống quản lý giao dịch ngân hàng — đồ án môn Hệ quản trị cơ sở dữ liệu.

## Công nghệ

- Python Flask + Jinja2
- Bootstrap 5
- SQL Server + pyodbc
- Docker + Docker Compose

### Database

database diagram

## Cấu trúc thư mục

```
app/
  routes/           # Flask blueprints
  services/         # Business layer (mock → stored procedures)
  templates/        # Jinja2 templates & layouts
    base.html       # Layout gốc (navbar, blocks)
    admin_base.html # Layout Admin + sidebar
    banker_base.html
    customer_base.html
    partials/       # Partial templates dùng chung
  static/css/app.css
  mock_data/        # Dữ liệu mẫu cho giai đoạn UI-first
  db/               # Kết nối SQL Server (pyodbc)
database/           # SQL: reset/, schema/, seed/
docs/               # Tài liệu dự án
run.py              # Entry point (gunicorn: run:app)
Dockerfile
docker-compose.yml
```

## Hệ thống layout Jinja


| Template             | Mô tả                                                                   |
| -------------------- | ----------------------------------------------------------------------- |
| `base.html`          | Layout gốc: Bootstrap 5, navbar, blocks `title` / `content` / `scripts` |
| `admin_base.html`    | Kế thừa `base.html`, sidebar Quản trị viên                              |
| `banker_base.html`   | Kế thừa `base.html`, sidebar Nhân viên ngân hàng                        |
| `customer_base.html` | Kế thừa `base.html`, sidebar Khách hàng                                 |


Màn hình mới theo vai trò nên `{% extends "admin_base.html" %}` (hoặc `banker_base` / `customer_base`) và override block `content`.

## Chạy bằng Docker (khuyến nghị cho nhóm)

Yêu cầu: [Docker Desktop](https://www.docker.com/products/docker-desktop/) (hoặc Docker Engine + Docker Compose v2).

### 1. Clone và tạo `.env`

```bash
git clone https://github.com/notworLe/Banking_Transaction_Management_T-SQL.git
cd Banking_Transaction_Management_T-SQL
cp .env.example .env   # Windows: copy .env.example .env
```

Chỉnh `.env`:

- `MSSQL_SA_PASSWORD` — mật khẩu `sa` cho container SQL Server (đủ mạnh theo yêu cầu Microsoft).
- `DB_PASSWORD` — **phải trùng** `MSSQL_SA_PASSWORD` khi chạy Docker.
- Không commit file `.env`.

### 2. Build và chạy

```bash
docker compose up --build
```

- Web app: [http://localhost:5000](http://localhost:5000)
- SQL Server từ máy host: `127.0.0.1,11433` (xem mục kết nối bên dưới)

### SQL Server Docker connection

**VS Code / SQLTools / Azure Data Studio:**


| Thuộc tính               | Giá trị                                                          |
| ------------------------ | ---------------------------------------------------------------- |
| Server                   | `127.0.0.1,11433`                                                |
| User                     | `sa`                                                             |
| Password                 | `Banking@123456` (hoặc giá trị `MSSQL_SA_PASSWORD` trong `.env`) |
| Database                 | `master` hoặc `BankingTransactionDB`                             |
| Encrypt                  | `False`                                                          |
| Trust Server Certificate | `True`                                                           |


**Flask container** (kết nối nội bộ Docker network — đã cấu hình trong `docker-compose.yml`):


| Biến        | Giá trị     |
| ----------- | ----------- |
| `DB_SERVER` | `sqlserver` |
| `DB_PORT`   | `1433`      |


Chạy nền:

```bash
docker compose up --build -d
```

Dừng:

```bash
docker compose down
```

### 3. Chạy script SQL

Thư mục `./database` được mount read-only vào container SQL Server tại `/database`.

Database name: **BankingTransactionDB** — đặt `DB_NAME=BankingTransactionDB` trong `.env`.

Thứ tự chạy (thay `YOUR_SA_PASSWORD` bằng `MSSQL_SA_PASSWORD` trong `.env`):

```bash
# Bước 1 — Reset (tùy chọn, chỉ khi muốn xóa sạch DB)
docker compose exec sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "YOUR_SA_PASSWORD" -C \
  -i /database/reset/000_reset_database.sql

# Bước 2 — Tạo schema
docker compose exec sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "YOUR_SA_PASSWORD" -C \
  -i /database/schema/001_create_tables.sql

# Bước 3 — Seed demo data cơ bản (bắt buộc trước 002/003)
docker compose exec sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "YOUR_SA_PASSWORD" -C \
  -i /database/seed/001_seed_sample_data.sql

# Bước 4 (tùy chọn) — Performance seed (~100k giao dịch, có marker chống chạy trùng)
docker compose exec sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "YOUR_SA_PASSWORD" -C \
  -i /database/seed/002_seed_performance_data.sql

# Bước 5 (tùy chọn) — Query test cases (10 scenario đặc biệt)
docker compose exec sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "YOUR_SA_PASSWORD" -C \
  -i /database/seed/003_seed_query_test_cases.sql
```

Kiểm tra số lượng sau seed:

```bash
docker compose exec sqlserver /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "YOUR_SA_PASSWORD" -C -d BankingTransactionDB \
  -Q "SELECT 'Users' T, COUNT(*) C FROM Users UNION ALL SELECT 'Transactions', COUNT(*) FROM Transactions UNION ALL SELECT 'LoginLogs', COUNT(*) FROM LoginLogs"
```

Chi tiết và query mẫu: [database/README.md](database/README.md).

### 4. Reset database (xóa toàn bộ dữ liệu SQL Server)

```bash
docker compose down -v
docker compose up --build
```

Lệnh `down -v` xóa volume `sqlserver_data` — mọi dữ liệu trong SQL Server container sẽ mất.

### 5. Kiểm tra nhanh

```bash
docker compose ps
docker compose logs web
docker compose logs sqlserver
curl -s -o /dev/null -w "%{http_code}" http://localhost:5000/login
```

Kỳ vọng HTTP `200` tại `/login`.

### Mac Apple Silicon (M1/M2/M3)

- Image `mcr.microsoft.com/mssql/server:2022-latest` **chỉ hỗ trợ linux/amd64** — Docker chạy qua emulation (Rosetta/QEMU), có thể **chậm** hoặc **lỗi khởi động**.
- Nếu gặp sự cố, thêm vào `docker-compose.yml` cho cả `sqlserver` và `web`:

```yaml
platform: linux/amd64
```

- Cài đặt đủ RAM cho Docker Desktop (khuyến nghị ≥ 4 GB cho SQL Server).
- Build image web trên ARM vẫn dùng ODBC Driver 18 cho amd64 khi ép `platform: linux/amd64`.

---

## Cài đặt và chạy (local, không Docker)

### 1. Clone repository

```bash
git clone https://github.com/notworLe/Banking_Transaction_Management_T-SQL.git
cd Banking_Transaction_Management_T-SQL
```

### 2. Tạo virtual environment

```bash
python -m venv venv
```

**Windows (PowerShell):**

```powershell
venv\Scripts\activate
```

**Linux / macOS:**

```bash
source venv/bin/activate
```

### 3. Cài dependencies

```bash
pip install -r requirements.txt
```

### 4. Cấu hình môi trường

**Windows:**

```powershell
copy .env.example .env
```

**Linux / macOS:**

```bash
cp .env.example .env
```

Chỉnh sửa `.env` nếu cần. Giai đoạn UI-first vẫn dùng mock data; module `app/db/connection.py` sẵn sàng khi kết nối SQL Server.

### 5. Chạy ứng dụng

```bash
python run.py
```

Mở trình duyệt: [http://127.0.0.1:5000](http://127.0.0.1:5000)

Ứng dụng tự redirect về `/login`. Sau đăng nhập mock, navbar hiển thị tên hệ thống **Banking Transaction Management** và username tương ứng vai trò.

### Tài khoản demo (mock)


| Vai trò    | Tên đăng nhập | Mật khẩu    | Dashboard             |
| ---------- | ------------- | ----------- | --------------------- |
| Quản trị   | admin         | admin123    | `/admin/dashboard`    |
| Nhân viên  | banker        | banker123   | `/banker/dashboard`   |
| Khách hàng | customer      | customer123 | `/customer/dashboard` |


## Routes hiện có


| Route                 | Mô tả                   |
| --------------------- | ----------------------- |
| `/login`              | Đăng nhập               |
| `/logout`             | Đăng xuất               |
| `/admin/dashboard`    | Dashboard quản trị viên |
| `/banker/dashboard`   | Dashboard nhân viên     |
| `/customer/dashboard` | Dashboard khách hàng    |


## Tài liệu

- [docs/PROJECT_OVERVIEW.md](docs/PROJECT_OVERVIEW.md)
- [docs/USE_CASES.md](docs/USE_CASES.md)
- [docs/UI_SCREEN_MAP.md](docs/UI_SCREEN_MAP.md)
- [docs/DB_OBJECT_MAP.md](docs/DB_OBJECT_MAP.md)