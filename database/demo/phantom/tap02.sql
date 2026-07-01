USE banking_transaction;
GO
-- Session này sẽ chỉ đợi 2 giây để xen vào giữa lúc Tab 1 đang xử lý
EXEC dbo.sp_Demo_Phantom_Bad @Delay = '00:00:02';
GO
