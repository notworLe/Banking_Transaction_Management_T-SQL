## sp_Login

Used by:
- UC-ADMIN-01
- UC-BANKER-01
- UC-CUSTOMER-01

Input:
- @Username
- @Password

Output:
- Success
- Message
- UserId
- Role

Main tables:
- Users
- LoginLogs

---

## vw_Users

Used by:
- UC-ADMIN-02

Columns:
- UserId
- Username
- Role
- Status
- LastLoginAt
- CreatedAt

Main tables:
- Users

---

## sp_LockUser

Used by:
- UC-ADMIN-03

Input:
- @UserId
- @UpdatedByUserId

Output:
- Success
- Message

Main tables:
- Users
- AuditLogs

---

## sp_UnlockUser

Used by:
- UC-ADMIN-03

Input:
- @UserId
- @UpdatedByUserId

Output:
- Success
- Message

Main tables:
- Users
- AuditLogs

---

## vw_AuditLogs

Used by:
- UC-ADMIN-04

Columns:
- User
- ActionType
- TargetTable
- TargetId
- Description
- CreatedAt

Main tables:
- AuditLogs
- Users

---

## vw_LoginLogs

Used by:
- UC-ADMIN-05

Columns:
- Username
- LoginTime
- LogoutTime
- LoginStatus
- IPAddress

Main tables:
- LoginLogs
- Users

---

## vw_Customers

Used by:
- UC-BANKER-02

Columns:
- CustomerId
- FullName
- Email
- PhoneNumber
- Address
- BirthDay
- Username
- CreatedAt

Main tables:
- Customers
- Users

---

## sp_CreateCustomer

Used by:
- UC-BANKER-03

Input:
- @FullName
- @Email
- @PhoneNumber
- @Address
- @BirthDay
- @Username
- @Password
- @CreatedByUserId

Output:
- Success
- Message
- CustomerId

Main tables:
- Customers
- Users
- AuditLogs

---

## vw_BankAccounts

Used by:
- UC-BANKER-04
- UC-BANKER-05
- UC-BANKER-06

Columns:
- AccountNumber
- CustomerId
- CustomerName
- AccountType
- Balance
- Status
- OpenedAt

Main tables:
- BankAccounts
- Customers

---

## sp_OpenBankAccount

Used by:
- UC-BANKER-04

Input:
- @CustomerId
- @AccountType
- @InitialBalance
- @CreatedByUserId

Output:
- Success
- Message
- AccountNumber

Main tables:
- BankAccounts
- AuditLogs

---

## sp_LockBankAccount

Used by:
- UC-BANKER-05

Input:
- @AccountNumber
- @UpdatedByUserId

Output:
- Success
- Message

Main tables:
- BankAccounts
- AuditLogs

---

## sp_CloseBankAccount

Used by:
- UC-BANKER-06

Input:
- @AccountNumber
- @UpdatedByUserId

Output:
- Success
- Message

Main tables:
- BankAccounts
- AuditLogs

---

## vw_TransactionHistory

Used by:
- UC-BANKER-07
- UC-BANKER-08
- UC-BANKER-09
- UC-BANKER-10

Columns:
- TransactionId
- TransactionType
- FromAccountNumber
- ToAccountNumber
- Amount
- Description
- CreatedAt
- CreatedBy

Main tables:
- Transactions
- BankAccounts
- Users

---

## sp_Deposit

Used by:
- UC-BANKER-07

Input:
- @ToAccountNumber
- @Amount
- @CreatedByUserId
- @Description

Output:
- Success
- Message
- TransactionId

Main tables:
- BankAccounts
- Transactions
- AuditLogs

---

## sp_Withdraw

Used by:
- UC-BANKER-08

Input:
- @AccountNumber
- @Amount
- @CreatedByUserId
- @Description

Output:
- Success
- Message
- TransactionId

Main tables:
- BankAccounts
- Transactions
- AuditLogs

---

## vw_CustomerDashboard

Used by:
- UC-CUSTOMER-02

Columns:
- CustomerId
- CustomerName
- TotalAccounts
- TotalBalance
- RecentTransactionCount

Main tables:
- Customers
- BankAccounts
- Transactions

---

## vw_CustomerAccounts

Used by:
- UC-CUSTOMER-03

Columns:
- AccountNumber
- AccountType
- Balance
- Status
- OpenedAt

Main tables:
- BankAccounts
- Customers

Filter:
- @CustomerId hoặc @Username

---

## vw_CustomerTransactions

Used by:
- UC-CUSTOMER-04
- UC-CUSTOMER-05

Columns:
- TransactionId
- TransactionType
- FromAccountNumber
- ToAccountNumber
- Amount
- Description
- CreatedAt

Main tables:
- Transactions
- BankAccounts
- Customers

Filter:
- @CustomerId hoặc @Username

---

## sp_Transfer

Used by:
- UC-BANKER-09
- UC-CUSTOMER-05

Input:
- @FromAccountNumber
- @ToAccountNumber
- @Amount
- @CreatedByUserId
- @Description

Output:
- Success
- Message
- TransactionId

Main tables:
- BankAccounts
- Transactions
- AuditLogs
