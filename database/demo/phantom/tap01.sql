USE banking_transaction;
GO
-- Session này sẽ đợi 8 giây để mô phỏng tiến trình xử lý chậm
EXEC dbo.sp_Demo_Phantom_Bad @Delay = '00:00:08';
GO
