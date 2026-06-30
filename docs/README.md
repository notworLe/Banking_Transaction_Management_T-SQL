# Banking Transaction Management System

Hệ thống mô phỏng các nghiệp vụ cơ bản của ngân hàng kết hợp với việc trình diễn các lỗi giao tác (Transaction Anomalies) trong SQL Server.

---

# 1. Giới thiệu

Đây là đồ án xây dựng hệ thống quản lý giao dịch ngân hàng với mục tiêu:

* Xây dựng các nghiệp vụ ngân hàng cơ bản.
* Thực hành lập trình cơ sở dữ liệu bằng SQL Server.
* Áp dụng Stored Procedure, View, Function, Trigger.
* Tìm hiểu cơ chế Transaction và Lock trong SQL Server.
* Minh họa trực quan các lỗi truy xuất đồng thời và cách khắc phục.

Dự án được phát triển phục vụ mục đích học tập và nghiên cứu.

---

# 2. Công nghệ sử dụng

| Thành phần       | Công nghệ                 |
| ---------------- | ------------------------- |
| Frontend         | React                     |
| Backend          | FastAPI (Python)          |
| Database         | Microsoft SQL Server 2022 |
| Kết nối Database | pyodbc                    |
| Container        | Docker & Docker Compose   |
| Kiểm thử         | Playwright                |

---

# 3. Chức năng chính

## Hệ thống ngân hàng

* Đăng nhập
* Quản lý khách hàng
* Quản lý tài khoản ngân hàng
* Nạp tiền
* Rút tiền
* Chuyển tiền
* Xem lịch sử giao dịch

## Database

Hệ thống sử dụng các đối tượng của SQL Server như:

* View
* Function
* Stored Procedure
* Trigger
* Index

Toàn bộ nghiệp vụ chính đều được xử lý trong Stored Procedure.

## Demo Transaction Anomalies

Hệ thống minh họa 5 lỗi truy xuất đồng thời phổ biến:

* Dirty Read
* Non-repeatable Read
* Phantom Read
* Lost Update
* Deadlock

Mỗi lỗi đều có:

* Kịch bản gây lỗi (BAD)
* Kịch bản đã khắc phục (FIX)
* Nhật ký thực thi (Timeline Log)
* So sánh kết quả trước và sau khi sửa

---

# 4. Cấu trúc dự án

```text
.
├── backend/          # FastAPI
├── frontend/         # React
├── database/
│   ├── schema/       # Tạo bảng
│   ├── seed/         # Dữ liệu mẫu
│   ├── procedures/   # Stored Procedures
│   ├── triggers/
│   ├── views/
│   ├── functions/
│   └── anomalies/    # Demo 5 lỗi Transaction
├── docs/
└── docker/
```

---

# 5. Khởi động dự án

## Bước 1. Clone source

```bash
git clone https://github.com/notworLe/Banking_Transaction_Management_T-SQL.git
cd Banking_Transaction_Management
```

## Bước 2. Khởi động Docker

```bash
docker compose up --build
```

## Bước 3. Khởi tạo Database

Thực thi các script theo thứ tự:

1. Schema
2. Seed
3. Views
4. Functions
5. Stored Procedures
6. Triggers
7. Demo Transaction Anomalies

## Bước 4. Khởi động Backend

```bash
cd backend

uvicorn main:app --reload
```

## Bước 5. Khởi động Frontend

```bash
cd frontend

npm install

npm run dev
```

---

# 6. Tài liệu dự án

| Tài liệu                       | Nội dung                                                                                |
| ------------------------------ | --------------------------------------------------------------------------------------- |
| DATABASE_OBJECT_CATALOG.md     | Danh sách các View, Function, Stored Procedure, Trigger và chức năng của từng đối tượng |
| TRANSACTION_ANOMALIES_GUIDE.md | Giải thích 5 lỗi truy xuất đồng thời, nguyên nhân và phương pháp khắc phục              |
| DEMO_GUIDE.md                  | Hướng dẫn sử dụng hệ thống demo và quy trình trình diễn các lỗi Transaction             |

---
