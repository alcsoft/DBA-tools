-- ========================================================
-- Capturing Long Running Queries
-- This script captures long running queries from the SQL Server instance
-- and logs the details into the 'longRunningQueries' table. It checks 
-- for queries that have been running longer than a specified threshold 
-- (1 minute in this case) and stores them in a table for monitoring.
-- This script can be set up as a SQL Agent Job that runs every 5 minutes.
-- Author: Ennis (alcsoft)
-- ========================================================

USE <<DBA_DatabaseName>>;
GO

-- Check if the 'longRunningQueries' table exists, create it if it doesn't
IF NOT EXISTS (
    SELECT 1 FROM sys.objects WHERE name = 'longRunningQueries'
)
CREATE TABLE [dbo].[longRunningQueries] (
    [CaptureTime] DATETIME NOT NULL,                     -- The timestamp when the query was captured
    [spid] SMALLINT NOT NULL,                            -- Session ID of the process
    [RunningTimeinMin] INT NULL,                         -- Running time in minutes
    [transaction_id] BIGINT NOT NULL,                    -- Transaction ID
    [transaction_begin_time] DATETIME NOT NULL,          -- Transaction start time
    [loginame] NCHAR(128) NOT NULL,                      -- Login name
    [login_time] DATETIME NOT NULL,                      -- Login time
    [status] NCHAR(30) NOT NULL,                         -- Status of the process
    [blocked] SMALLINT NOT NULL,                         -- Blocked session (if any)
    [open_tran] SMALLINT NOT NULL,                       -- Open transactions count
    [hostname] NCHAR(128) NOT NULL,                      -- Hostname from which the query was executed
    [program_name] NCHAR(128) NOT NULL,                  -- Program name that executed the query
    [TEXT] NVARCHAR(MAX) NULL,                           -- SQL text of the query
    [dbid] SMALLINT NOT NULL,                            -- Database ID
    [DatabaseName] NVARCHAR(128) NULL                    -- Database name
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];

-- Insert long running query details into the table
INSERT INTO [longRunningQueries] (
    [CaptureTime],
    [spid],
    [RunningTimeinMin],
    [transaction_id],
    [transaction_begin_time],
    [loginame],
    [login_time],
    [status],
    [blocked],
    [open_tran],
    [hostname],
    [program_name],
    [TEXT],
    [dbid],
    [DatabaseName]
)
SELECT 
    GETDATE() AS CaptureTime,                             -- Capture the current time
    spid,                                                -- Session ID (spid)
    DATEDIFF(MINUTE, dtat.transaction_begin_time, GETDATE()) AS RunningTimeinMin, -- Time the transaction has been running
    dtat.transaction_id,                                  -- Transaction ID
    dtat.transaction_begin_time,                          -- Transaction begin time
    A.loginame,                                           -- Login name
    A.login_time,                                         -- Login time
    status,                                               -- Status of the process
    A.blocked,                                            -- Blocked session ID (if any)
    A.open_tran,                                          -- Open transactions count
    A.hostname,                                           -- Hostname from which the query was executed
    A.program_name,                                       -- Program name that executed the query
    TEXT,                                                 -- SQL text of the query
    A.dbid,                                               -- Database ID
    DB_NAME(A.dbid) AS DatabaseName                       -- Database name
FROM
    sys.dm_tran_active_transactions dtat
    INNER JOIN sys.dm_tran_session_transactions dtst ON dtat.transaction_id = dtst.transaction_id
    JOIN sys.sysprocesses A ON dtst.session_id = A.spid
    CROSS APPLY sys.dm_exec_sql_text(A.sql_handle)
WHERE 
    DATEDIFF(MINUTE, dtat.transaction_begin_time, GETDATE()) > 1 -- Only queries running longer than 1 minute
    AND status <> 'sleeping' -- Exclude sleeping sessions
