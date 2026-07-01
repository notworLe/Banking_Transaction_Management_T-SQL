### Chuyển tiền:
1. Bắt đầu transaction.
2. Kiểm tra số tiền chuyển phải > 0.
3. Kiểm tra tài khoản nguồn tồn tại.
4. Kiểm tra tài khoản nhận tồn tại.
5. Kiểm tra tài khoản nguồn và tài khoản nhận khác nhau.
6. Kiểm tra tài khoản nguồn đang active.
7. Kiểm tra tài khoản nhận đang active.
8. Nếu người chuyển là customer, kiểm tra tài khoản nguồn thuộc về customer đó.
9. Kiểm tra số dư tài khoản nguồn đủ để chuyển.
10. Trừ tiền tài khoản nguồn.
11. Cộng tiền tài khoản nhận.
12. Ghi bản ghi vào bảng Transactions.
13. Ghi log vào AuditLogs.
14. Commit nếu tất cả thành công.
15. Rollback nếu có lỗi.

### Mở tài khoản:
1. Bắt đầu transaction.
2. Kiểm tra customer tồn tại.
3. Kiểm tra user thực hiện có quyền mở tài khoản.
4. Kiểm tra loại tài khoản hợp lệ.
5. Kiểm tra số dư ban đầu >= 0.
6. Sinh AccountNumber duy nhất.
7. Insert tài khoản mới vào BankAccounts.
8. Ghi log vào AuditLogs.
9. Commit nếu thành công.
10. Rollback nếu có lỗi.