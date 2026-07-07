USE banking_transaction;
GO
EXEC dbo.sp_Demo_Deadlock_Reset;
GO

/*
  HƯỚNG DẪN KIỂM TRA TRANSACTIONS:
  1. Chạy file này trước để Reset môi trường (xoá logs, khôi phục số dư).
  2. Mở SSMS Window 1: Chạy nội dung trong tap01.sql
  3. Mở SSMS Window 2: Chạy nội dung trong tap02.sql (ngay sau khi Window 1 chạy)
  4. Đợi khoảng 8-10 giây để SQL Server phát hiện Deadlock và chọn Victim.
  5. Chạy câu query dưới đây để xem toàn bộ lịch sử (timeline) log và xem rollback/error:
*/

USE banking_transaction;

SELECT *
FROM dbo.Demo_Logs
WHERE Scenario = 'DEADLOCK'
ORDER BY ActionTime ASC, LogId ASC;
