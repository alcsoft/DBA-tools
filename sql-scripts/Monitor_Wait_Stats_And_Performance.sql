-- ========================================================
-- SQL Script to Monitor Wait Statistics and Server Performance
-- This script gathers and analyzes wait statistics to help identify 
-- bottlenecks and assess SQL Server performance. It includes 
-- queries to view wait stats, clear wait stats, and isolate top waits.
-- Author: Ennis (alcsoft)
-- ========================================================

-- Check current wait stats in SQL Server
DBCC SQLPERF('WAITSTATS');
GO

-- Execute a custom procedure to track wait stats
EXEC track_waitstats 100, 1, 'sec'; -- Adjust the parameters as needed
GO

-- Retrieve wait stats using a custom stored procedure
EXECUTE get_waitstats;
GO

-- Query to view all wait stats where waiting tasks count is greater than zero
SELECT *
FROM sys.dm_os_wait_stats
WHERE waiting_tasks_count > 0
ORDER BY wait_time_ms DESC;
GO

-- Clear the wait statistics (reset to zero)
DBCC SQLPERF ('sys.dm_os_wait_stats', CLEAR);
GO

-- Execute custom stored procedure to track wait stats
EXECUTE master.dbo.get_waitstats;

-- View the wait stats from the custom wait stats table
SELECT *
FROM dbo.waitstats;

-- Clear wait stats from the custom table
TRUNCATE TABLE dbo.waitstats;

-- Execute the custom procedure again to track wait stats
EXEC track_waitstats 100, 1, 'sec';
EXECUTE get_waitstats;
GO

-- View the wait stats specifically for CXPACKET wait type (parallelism)
SELECT *
FROM sys.dm_os_wait_stats
WHERE wait_type = 'CXPACKET';
GO

-- Retrieve all current wait stats
SELECT *
FROM sys.dm_os_wait_stats;
GO

-- Query to view latch stats (another type of wait)
SELECT *
FROM sys.dm_os_latch_stats;
GO

-- Isolate top waits for server instance since the last restart or wait stats clear
WITH Waits AS (
    SELECT wait_type, 
           wait_time_ms / 1000. AS wait_time_s, 
           100. * wait_time_ms / SUM(wait_time_ms) OVER() AS pct, 
           ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC) AS rn
    FROM sys.dm_os_wait_stats
    WHERE wait_type NOT IN ('CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'RESOURCE_QUEUE', 'SLEEP_TASK',
                            'SLEEP_SYSTEMTASK', 'SQLTRACE_BUFFER_FLUSH', 'WAITFOR', 'LOGMGR_QUEUE', 
                            'CHECKPOINT_QUEUE', 'REQUEST_FOR_DEADLOCK_SEARCH', 'XE_TIMER_EVENT',
                            'BROKER_TO_FLUSH', 'BROKER_TASK_STOP', 'CLR_MANUAL_EVENT', 'CLR_AUTO_EVENT',
                            'DISPATCHER_QUEUE_SEMAPHORE', 'FT_IFTS_SCHEDULER_IDLE_WAIT',
                            'XE_DISPATCHER_WAIT', 'XE_DISPATCHER_JOIN', 'SQLTRACE_INCREMENTAL_FLUSH_SLEEP')
)
SELECT W1.wait_type,
       CAST(W1.wait_time_s AS DECIMAL(12, 2)) AS wait_time_s,
       CAST(W1.pct AS DECIMAL(12, 2)) AS pct,
       CAST(SUM(W2.pct) AS DECIMAL(12, 2)) AS running_pct
FROM Waits AS W1
INNER JOIN Waits AS W2
    ON W2.rn <= W1.rn
GROUP BY W1.rn, W1.wait_type, W1.wait_time_s, W1.pct
HAVING SUM(W2.pct) - W1.pct < 99  -- Set percentage threshold for displaying top waits
OPTION (RECOMPILE);  -- Recompile the query plan
GO
