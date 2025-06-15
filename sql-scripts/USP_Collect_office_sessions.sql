-- ========================================================
-- Stored Procedure to Collect Office Sessions
-- This procedure collects sessions called by office applications
-- into the TraceOfficeQueries table and stores session details 
-- like user, command, status, and resource utilization.
-- The procedure runs periodically (recommended every minute) to 
-- collect data on office application usage.
-- Author: Ennis (alcsoft)
-- ========================================================

USE DBARepository;
GO

DROP PROCEDURE IF EXISTS USP_Collect_office_sessions;
GO

CREATE PROCEDURE USP_Collect_office_sessions AS
BEGIN
    /*
    Developed by: Anas Hamza
    On: 5/15/2018
    Purpose: Collects session data related to office applications
    Captures the sessions into the table TraceOfficeQueries.
    */

    -- Check if TraceOfficeQueries table exists, create if not
    IF NOT EXISTS (
        SELECT name 
        FROM sys.objects 
        WHERE name = 'TraceOfficeQueries'
    )
    BEGIN
        CREATE TABLE [dbo].[TraceOfficeQueries] (
            [spid] [SMALLINT] NOT NULL,
            [blocked] [SMALLINT] NOT NULL,
              NOT NULL,
              NOT NULL,
              NULL,
            [text] [NVARCHAR](MAX) NULL,
              NULL,
              NOT NULL,
              NOT NULL,
              NOT NULL,
            [ecid] [SMALLINT] NOT NULL,
            [waittime] [BIGINT] NOT NULL,
              NOT NULL,
              NULL,
              NULL,
            [login_time] [DATETIME] NOT NULL,
            [start_time] [DATETIME] NULL,
            [estimated_completion_time] [BIGINT] NULL,
            [date_first] [SMALLINT] NULL,
            [cpu] [INT] NOT NULL,
            [physical_io] [BIGINT] NOT NULL,
            [reads] [BIGINT] NULL,
            [writes] [BIGINT] NULL,
            [row_count] [BIGINT] NULL,
            [CollectTime] DATETIME DEFAULT GETDATE()
        ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY];

        CREATE INDEX [IDX_TraceOfficeQueries_login_time] 
        ON TraceOfficeQueries ([login_time])
        INCLUDE ([spid], [loginame], [hostname], [sql_handle]);
    END

    -- Temporary table to store session data before inserting into TraceOfficeQueries
    CREATE TABLE #TraceOfficeQueries (
        ID INT IDENTITY(1,1) PRIMARY KEY,
        [spid] [smallint] NOT NULL,
        [blocked] [smallint] NOT NULL,
          NOT NULL,
          NOT NULL,
          NULL,
        [text] [nvarchar](max) NULL,
          NULL,
          NOT NULL,
          NOT NULL,
          NOT NULL,
        [ecid] [smallint] NOT NULL,
        [waittime] [bigint] NOT NULL,
          NOT NULL,
          NULL,
          NULL,
        [login_time] [datetime] NOT NULL,
        [start_time] [datetime] NULL,
        [estimated_completion_time] [bigint] NULL,
        [date_first] [smallint] NULL,
        [cpu] [int] NOT NULL,
        [physical_io] [bigint] NOT NULL,
        [reads] [bigint] NULL,
        [writes] [bigint] NULL,
        [row_count] [bigint] NULL
    );

    -- Insert data into the temporary table from sysprocesses and dm_exec_requests
    INSERT INTO #TraceOfficeQueries (
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

    -- Track the minimum login time
    DECLARE @minlogintime DATETIME
    SELECT @minlogintime = MIN(login_time) FROM #TraceOfficeQueries;

    -- Insert new sessions into the TraceOfficeQueries table
    ;WITH CTE_NEWSessions AS (
        SELECT [spid], [loginame], [hostname], [sql_handle], [login_time]
        FROM #TraceOfficeQueries
        EXCEPT
        SELECT [spid], [loginame], [hostname], [sql_handle], [login_time]
        FROM #T
    )
    INSERT INTO TraceOfficeQueries (
        [spid], [blocked], [loginame], [cmd], [status], [text], 
        [Databasename], [hostname], [program_name], [sql_handle], 
        [ecid], [waittime], [lastwaittype], [wait_resource], 
        [context_info], [login_time], [start_time], 
        [estimated_completion_time], [date_first], [cpu], 
        [physical_io], [reads], [writes], [row_count]
    )
    SELECT A.[spid], A.[blocked], A.[loginame], A.[cmd], A.[status], 
           A.[text], A.[Databasename], A.[hostname], A.[program_name], 
           A.[sql_handle], A.[ecid], A.[waittime], A.[lastwaittype], 
           A.[wait_resource], A.[context_info], A.[login_time], 
           A.[start_time], A.[estimated_completion_time], A.[date_first], 
           A.[cpu], A.[physical_io], A.[reads], A.[writes], A.[row_count]
    FROM #TraceOfficeQueries A
    JOIN CTE_NEWSessions B ON A.[spid] = B.[spid]
                             AND A.[loginame] = B.[loginame]
                             AND A.[hostname] = B.[hostname]
                             AND A.[sql_handle] = B.[sql_handle]
                             AND A.[login_time] = B.[login_time];

    -- Clean up temporary tables
    DROP TABLE #TraceOfficeQueries;
    DROP TABLE #T;
END
GO
