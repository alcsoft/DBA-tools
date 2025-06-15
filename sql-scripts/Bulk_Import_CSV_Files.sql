-- ========================================================
-- Script to Import Multiple CSV Files Into SQL Server
-- This script automates the process of importing multiple CSV files into SQL Server.
-- The script creates tables dynamically, loads data from CSV files using BULK INSERT,
-- and tracks the import process for validation and error handling.
-- Author: Ennis (alcsoft)
-- ========================================================

USE [master];
GO

-- Create a new database for the imported data
CREATE DATABASE [SalesForceCRM]
CONTAINMENT = NONE
ON PRIMARY
(
    NAME = N'SalesforceCRM', FILENAME = N'S:\DATA\SalesForceCRM.mdf', SIZE = 266176KB, MAXSIZE = UNLIMITED, FILEGROWTH = 262144KB
)
LOG ON
(
    NAME = N'SalesforceCRM_log', FILENAME = N'T:\Log\SalesForceCRM_log.ldf', SIZE = 266176KB, MAXSIZE = 2048GB, FILEGROWTH = 262144KB
);
GO

USE [SalesForceCRM];
GO

-- Create tracking tables to store metadata about the files and columns
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'ALLTableColumns')
    DROP TABLE ALLTableColumns;
CREATE TABLE ALLTableColumns (
    [COLNames] VARCHAR(MAX)
);

IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'ALLFileNames')
    DROP TABLE ALLFileNames;
CREATE TABLE ALLFileNames (
    [TableName] VARCHAR(255),
    [FileName] VARCHAR(255),
    [Path] VARCHAR(255),
    [COLNames] VARCHAR(MAX),
    [processed] CHAR(1),
    [Error] VARCHAR(MAX) NULL,
    [RowsIns] INT NULL
);
GO

-- Set file path and command for directory listing
DECLARE @FileName VARCHAR(255), @path VARCHAR(255), @sql NVARCHAR(MAX), @cmd VARCHAR(1000), @TableName VARCHAR(255);
SET @path = 'C:\BKB\SF\';
SET @cmd = 'dir ' + @path + '*.csv /b';

-- Insert file information into the ALLFileNames table
INSERT INTO ALLFileNames ([FileName])
EXEC master..xp_cmdshell @cmd;

DELETE FROM ALLFileNames WHERE [FileName] IS NULL;
UPDATE ALLFileNames SET [Path] = @path WHERE [Path] IS NULL;
GO

-- Read metadata of the files and columns
DECLARE c1 CURSOR FOR
    SELECT [Path], [FileName] FROM ALLFileNames WHERE [FileName] LIKE '%.csv%';

OPEN c1;
FETCH NEXT FROM c1 INTO @path, @FileName;

WHILE @@FETCH_STATUS <> -1
BEGIN
    SET @TableName = SUBSTRING(RTRIM(@FileName), 1, LEN(RTRIM(@FileName)) - 4);

    -- Truncate the ALLTableColumns table and load column names
    TRUNCATE TABLE ALLTableColumns;
    SET @sql = 'BULK INSERT ALLTableColumns FROM ''' + @path + @FileName + ''' WITH (ROWTERMINATOR = ''0x0a'', FIRSTROW = 1, LastRow = 1, KeepNulls)';
    EXEC (@sql);

    UPDATE ALLFileNames
    SET [processed] = 'N', [TableName] = @TableName, [COLNames] = (SELECT [COLNames] FROM ALLTableColumns)
    WHERE [FileName] = @FileName;

    FETCH NEXT FROM c1 INTO @path, @FileName;
END

CLOSE c1;
DEALLOCATE c1;
GO

-- Create tables based on the CSV files and column metadata
DECLARE c2 CURSOR FOR
    SELECT TableName FROM ALLFileNames;

OPEN c2;
FETCH NEXT FROM c2 INTO @TableName;

WHILE @@FETCH_STATUS <> -1
BEGIN
    SELECT @sql = 'IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = ''' + @TableName + ''') ' +
                  'CREATE TABLE [' + @TableName + '] (' + REPLACE(COLNames, ',', ' VARCHAR(MAX) NULL,') + ' VARCHAR(MAX) NULL);'
    FROM ALLFileNames WHERE TableName = @TableName;

    EXEC (@sql);

    UPDATE ALLFileNames SET [processed] = 'C' WHERE [TableName] = @TableName;

    FETCH NEXT FROM c2 INTO @TableName;
END

CLOSE c2;
DEALLOCATE c2;
GO

-- Load data from CSV files into the created tables using BULK INSERT
DECLARE c3 CURSOR FOR
    SELECT [TableName], [FileName], [Path] FROM ALLFileNames;

OPEN c3;
FETCH NEXT FROM c3 INTO @TableName, @FileName, @path;

WHILE @@FETCH_STATUS <> -1
BEGIN
    BEGIN TRY
        SET @sql = 'BULK INSERT [' + @TableName + '] FROM ''' + @path + @FileName + ''' WITH (' +
                   'FIELDTERMINATOR = '','',' ROWTERMINATOR = ''0x0a'', FIRSTROW = 2, KeepNulls, CODEPAGE = 28591)'';
        EXEC (@sql);

        UPDATE ALLFileNames SET [processed] = 'Y', [RowsIns] = @@ROWCOUNT WHERE [TableName] = @TableName;
    END TRY
    BEGIN CATCH
        UPDATE ALLFileNames SET [processed] = 'F', [RowsIns] = 0, [Error] = ERROR_MESSAGE() WHERE [TableName] = @TableName;
    END CATCH

    FETCH NEXT FROM c3 INTO @TableName, @FileName, @path;
END

CLOSE c3;
DEALLOCATE c3;
GO

-- Validate the data to ensure the correct number of rows were inserted
DECLARE @RowsIns INT;

DECLARE c4 CURSOR FOR
    SELECT [TableName], [RowsIns] FROM ALLFileNames;

OPEN c4;
FETCH NEXT FROM c4 INTO @TableName, @RowsIns;

WHILE @@FETCH_STATUS <> -1
BEGIN
    DECLARE @ACTRowsIns INT;
    SET @sql = 'SELECT @cnt = COUNT(1) FROM [' + @TableName + ']';
    EXEC sp_executesql @sql, N'@cnt INT OUTPUT', @cnt = @ACTRowsIns OUTPUT;

    IF @ACTRowsIns = @RowsIns
        UPDATE ALLFileNames SET [processed] = 'K' WHERE [TableName] = @TableName;
    ELSE
        UPDATE ALLFileNames SET [processed] = 'I' WHERE [TableName] = @TableName;

    FETCH NEXT FROM c4 INTO @TableName, @RowsIns;
END

CLOSE c4;
DEALLOCATE c4;
GO

-- Remove leading and trailing quotes from each column
DECLARE @FirstCol VARCHAR(MAX), @LastCol VARCHAR(MAX);

DECLARE c5 CURSOR FOR
    SELECT TableName, LEFT(COLNames, CHARINDEX('","', COLNames)) AS FirstCol, RIGHT(COLNames, CHARINDEX('","', REVERSE(COLNames))) AS LastCol
    FROM [dbo].[ALLFileNames];

OPEN c5;
FETCH NEXT FROM c5 INTO @TableName, @FirstCol, @LastCol;

WHILE @@FETCH_STATUS <> -1
BEGIN
    SET @sql = '';
    SELECT @sql += 'UPDATE [' + @TableName + '] SET ' + @FirstCol + ' = SUBSTRING(' + @FirstCol + ', 2, LEN(' + @FirstCol + ')) WHERE LEFT(' + @FirstCol + ', 1) = ''"'';';
    SELECT @sql += 'UPDATE [' + @TableName + '] SET ' + @LastCol + ' = SUBSTRING(' + @LastCol + ', 1, LEN(' + @LastCol + ')-1) WHERE RIGHT(' + @LastCol + ', 1) = ''"'';';
    EXEC (@sql);

    FETCH NEXT FROM c5 INTO @TableName, @FirstCol, @LastCol;
END

CLOSE c5;
DEALLOCATE c5;
GO
