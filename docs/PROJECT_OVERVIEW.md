Tên dự án:
Banking Transaction Management System

Mục tiêu:
Xây dựng hệ thống quản lý giao dịch ngân hàng phục vụ đồ án môn Hệ quản trị cơ sở dữ liệu.

Công nghệ:
- Python Flask
- SQL Server
- pyodbc
- Bootstrap 5
- Jinja Template

Nguyên tắc:
- UI chỉ gọi route.
- Route chỉ gọi service.
- Service gọi stored procedure/view/function.
- Không xử lý nghiệp vụ chuyển tiền trực tiếp trong Python.
- Logic giao dịch chính phải nằm trong SQL Server.