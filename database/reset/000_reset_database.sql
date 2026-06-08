/*
================================================================================
RESET SCRIPT — CHỈ CHẠY THỦ CÔNG KHI MUỐN XÓA SẠCH DATABASE
================================================================================
Script này DROP và tạo lại database BankingTransactionDB.
Mọi dữ liệu (schema + seed) sẽ bị mất.

Thứ tự khuyến nghị sau reset:
  1. database/schema/001_create_tables.sql
  2. database/seed/001_seed_sample_data.sql

Không chạy script này trong seed hoặc trong quy trình deploy tự động.
================================================================================
*/

USE master;
GO

IF DB_ID(N'BankingTransactionDB') IS NOT NULL
BEGIN
    ALTER DATABASE BankingTransactionDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BankingTransactionDB;
END
GO

CREATE DATABASE BankingTransactionDB;
GO
