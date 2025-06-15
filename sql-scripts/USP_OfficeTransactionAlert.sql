-- ========================================================
-- Stored Procedure to Collect Office Sessions
-- This procedure checks long-running transactions that have been running
-- for more than the specified threshold (default 10 minutes), sends an alert
-- by email with the details of the transactions.
-- Author: Ennis (alcsoft)
-- ========================================================

USE DBARepository;
GO

DROP PROCEDURE IF EXISTS USP_OfficeTransactionAlert;
GO

CREATE PROCEDURE USP_OfficeTransactionAlert AS
BEGIN
    /*
    Developed by: Anas Hamza
    On: 5/15/2018
    Purpose: Collects session data related to office applications
    Captures the sessions into the table TraceOfficeQueries.
    */

    -- Set threshold for long-running transactions
    DECLARE @AlertingThresholdMinutes INT = 10;
    DECLARE @OperatorName SYSNAME = 'anas.hamza@alcsoft.com';

    SET NOCOUNT ON;

    -- Declare variables for email content
    DECLARE @subject VARCHAR(MAX);
    DECLARE @tableHTML NVARCHAR(MAX);
    DECLARE @header VARCHAR(MAX);

    -- Set the subject and header for the email
    SET @subject = '[Warning] Long Running Transaction On ' + @@SERVERNAME;
    SET @header = 'Check SSMS > Server > Reports > Top Transactions By Age.';

    -- Temporary table for collecting session data
    CREATE TABLE #Transactions (
        [l1] INT NULL,
        [l2] BIGINT NULL,
        [ExecutionTime] INT NULL,
        [transaction_id] BIGINT NULL,
        [name] SYSNAME NULL,
        [database_tran_state] INT NULL,
        [text] NVARCHAR(MAX) NULL,
        [session_id] INT NULL,
        [trans_name] NVARCHAR(32) NOT NULL,
        [trans_type] INT NOT NULL,
        [tran_start_time] DATETIME NOT NULL,
        [first_update_time] DATETIME NULL,
        [state] VARCHAR(14) NULL,
        [transaction_isolation_level] VARCHAR(16) NULL,
        [tran_locks_count] INT NULL,
        [db_span_count] INT NULL,
        [is_local] BIT NULL,
        [login_name] NVARCHAR(128) NULL
    );

    -- Collect transaction data from sysprocesses and sys.dm_exec_requests
    INSERT INTO #Transactions (
        [spid], [blocked], [loginame], [cmd], [status], [text], 
        [Databasename], [hostname], [program_name], [sql_handle], 
        [ecid], [waittime], [lastwaittype], [wait_resource], 
        [context_info], [login_time], [start_time], 
        [estimated_completion_time], [date_first], [cpu], 
        [physical_io], [reads], [writes], [row_count]
    )
    SELECT 
        s.spid, s.blocked, s.loginame, s.cmd, r.status, text, 
        DB_NAME(s.dbid) AS Databasename, s.hostname, s.program_name,
        s.sql_handle, s.ecid, s.waittime, s.lastwaittype, r.wait_resource,
        CONVERT(VARCHAR(64), s.context_info) AS context_info, s.login_time,
        r.start_time, r.estimated_completion_time, r.date_first, 
        s.cpu, s.physical_io, r.reads, r.writes, r.row_count
    FROM master..sysprocesses AS s WITH (NOLOCK)
    LEFT OUTER JOIN sys.dm_exec_requests r ON r.session_id = s.spid
    LEFT JOIN sys.dm_exec_connections b ON s.spid = b.session_id
    CROSS APPLY sys.dm_exec_sql_text(most_recent_sql_handle)
    WHERE s.program_name LIKE '%Office%'
        AND s.dbid <> 0
        AND s.cmd NOT LIKE '%BACKUP%'
        AND s.cmd NOT LIKE '%RESTORE%'
        AND s.cmd NOT LIKE 'FG MONITOR%'
        AND s.spid > 50
        AND s.spid <> @@SPID;

    -- Filter long-running transactions
    DECLARE @minlogintime DATETIME;
    SELECT @minlogintime = MIN(login_time) FROM #Transactions;

    -- Construct the email content in HTML format
    SET @tableHTML =
        N'<H1 style="color: red">' + @header + '</H1>' +
        N'<table border="1">' +
        N'<tr>' +
        N'<th>l1</th><th>l2</th><th>ExecutionTime</th><th>transaction_id</th>' +
        N'<th>DatbaseName</th><th>database_tran_state</th><th>text</th>' +
        N'<th>session_id</th><th>trans_name</th><th>trans_type</th>' +
        N'<th>tran_start_time</th><th>first_update_time</th><th>state</th>' +
        N'<th>transaction_isolation_level</th><th>tran_locks_count</th>' +
        N'<th>db_span_count</th><th>is_local</th><th>login_name</th>' +
        N'</tr>' +
        CAST ( ( SELECT
            td = [l1], td = [l2], td = [ExecutionTime], td = [transaction_id], 
            td = [name], td = [database_tran_state], td = [text], td = [session_id], 
            td = [trans_name], td = [trans_type], td = [tran_start_time], 
            td = [first_update_time], td = [state], td = [transaction_isolation_level], 
            td = [tran_locks_count], td = [db_span_count], td = [is_local], 
            td = [login_name]
        FROM #Transactions
        WHERE ExecutionTime > @AlertingThresholdMinutes * 60
        FOR XML PATH('tr'), TYPE
        ) AS NVARCHAR(MAX) ) +
        N'</table>';

    -- Send email if there are long-running transactions
    IF (SELECT COUNT(1) FROM #Transactions WHERE ExecutionTime > @AlertingThresholdMinutes * 60) > 0
    BEGIN
        EXEC msdb.dbo.sp_send_dbmail
            @recipients = @OperatorName,
            @reply_to = @OperatorName,
            @body = @tableHTML,
            @subject = @subject,
            @body_format = 'HTML';
    END

    -- Cleanup
    DROP TABLE #Transactions;
END
GO
