-- Chuyển tiền
CREATE PROCEDURE sp_Transfer
    @FromAccountId  UNIQUEIDENTIFIER,
    @ToAccountId    UNIQUEIDENTIFIER,
    @Amount         DECIMAL(18,2),
    @CreatedByUserId UNIQUEIDENTIFIER,
    @Description    NVARCHAR(500) = N'Chuyển khoản'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @FromBalance DECIMAL(18,2);

    -- Validation
    IF @Amount <= 0
    BEGIN
        RAISERROR(N'Số tiền phải lớn hơn 0', 16, 1);
        RETURN;
    END

    IF @FromAccountId = @ToAccountId
    BEGIN
        RAISERROR(N'Không thể chuyển cho chính mình', 16, 1);
        RETURN;
    END


    -- Main
    BEGIN TRANSACTION;
    BEGIN TRY

        -- When transfering
        SELECT @FromBalance = Balance
        FROM BankAccounts WITH (UPDLOCK, HOLDLOCK)
        WHERE BankAccountId = @FromAccountId;

        SELECT Balance FROM BankAccounts WITH (UPDLOCK, HOLDLOCK)
        WHERE BankAccountId = @Second;

        -- Đọc lại balance của account nguồn sau khi lock
        SELECT @FromBalance = Balance
        FROM BankAccounts
        WHERE BankAccountId = @FromAccountId
          AND Status = 'active';

        -- Kiểm tra account nguồn
        IF @FromBalance IS NULL
        BEGIN
            RAISERROR(N'Tài khoản nguồn không tồn tại hoặc bị khóa', 16, 1);
            ROLLBACK; RETURN;
        END

        -- Kiểm tra account đích
        IF NOT EXISTS (
            SELECT 1 FROM BankAccounts
            WHERE BankAccountId = @ToAccountId AND Status = 'active'
        )
        BEGIN
            RAISERROR(N'Tài khoản đích không tồn tại hoặc bị khóa', 16, 1);
            ROLLBACK; RETURN;
        END

        -- Kiểm tra số dư
        IF @FromBalance < @Amount
        BEGIN
            -- Ghi transaction thất bại
            INSERT INTO Transactions
                (FromBankAccountId, ToBankAccountId, CreatedByUserId,
                 Type, Amount, Status, Description)
            VALUES
                (@FromAccountId, @ToAccountId, @CreatedByUserId,
                 'transfer', @Amount, 'failed', N'Số dư không đủ');

            RAISERROR(N'Số dư không đủ', 16, 1);
            ROLLBACK; RETURN;
        END

        -- Thực hiện chuyển tiền
        UPDATE BankAccounts
        SET Balance = Balance - @Amount
        WHERE BankAccountId = @FromAccountId;

        UPDATE BankAccounts
        SET Balance = Balance + @Amount
        WHERE BankAccountId = @ToAccountId;

        -- Ghi transaction thành công
        INSERT INTO Transactions
            (FromBankAccountId, ToBankAccountId, CreatedByUserId,
             Type, Amount, Status, Description)
        VALUES
            (@FromAccountId, @ToAccountId, @CreatedByUserId,
             'transfer', @Amount, 'success', @Description);

        COMMIT TRANSACTION;
        PRINT N'Chuyển khoản thành công: '
              + FORMAT(@Amount, 'N0') + ' VND';

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        PRINT N'Lỗi: ' + ERROR_MESSAGE();
    END CATCH
END;
GO