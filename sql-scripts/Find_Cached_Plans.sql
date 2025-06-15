-- ========================================================
-- SQL Script to Find Cached Plans for a Specific Object
-- This script helps DBAs find cached query plans for a specific 
-- database and object, and provides performance metrics such 
-- as CPU time, I/O, and elapsed time. It retrieves execution 
-- details from `sys.dm_exec_query_stats` and the corresponding 
-- query plan from `sys.dm_exec_query_plan`.
-- Author: DBA Tools
-- ========================================================

-- ========================================================
-- Key Features:
-- 1. **Find Cached Plans**:
--    - Searches for cached query plans for a specific database and object (stored procedure, function, etc.).
--    - Provides detailed performance metrics like CPU time, I/O, and elapsed time for the cached plans.
--
-- 2. **Flexible Search by Database and Object**:
--    - Allows searching by specifying the database and object name (stored procedure, function, etc.).
--    - If no specific database or object is provided, it can search across all available plans.
--
-- 3. **Performance Metrics**:
--    - Calculates average CPU time, I/O, and elapsed time for each cached plan.
--    - Returns the number of times the plan was used (`usecounts`) to help identify frequently executed queries.
--
-- 4. **Query Plan Retrieval**:
--    - Retrieves the actual query plan for each cached plan, helping to analyze the execution plan for potential optimization.
-- ========================================================

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
GO

DECLARE @DatabaseName sysname,
        @ObjectName sysname;

-- Set database and object names to search
SELECT @DatabaseName = 'msdb',    -- Enter database name here
       @ObjectName = 'sp_jobhistory_row_limiter';  -- Enter object name here (e.g., stored procedure)

WITH PlanSearch AS (
    SELECT qp.dbid,
           qp.objectid,
           DB_NAME(qp.dbid) AS DatabaseName,
           OBJECT_NAME(qp.objectid, qp.dbid) AS ObjectName,
           cp.usecounts,
           cp.plan_handle
    FROM sys.dm_exec_cached_plans cp
    CROSS APPLY sys.dm_exec_text_query_plan(cp.plan_handle, DEFAULT, DEFAULT) qp
    WHERE cp.cacheobjtype = 'Compiled Plan'
      AND (DB_NAME(qp.dbid) = @DatabaseName OR NULLIF(@DatabaseName,'') IS NULL)
      AND (OBJECT_NAME(qp.objectid, qp.dbid) = @ObjectName OR NULLIF(@ObjectName, '') IS NULL)
),
PlansAndStats AS (
    SELECT ps.DatabaseName,
           ps.ObjectName,
           ps.usecounts,  -- Use in place of qs.execution_count for whole plan count
           CAST(SUM(qs.total_worker_time)/(ps.usecounts*1.) AS DECIMAL(12,2)) AS avg_cpu_time,
           CAST(SUM(qs.total_logical_reads + qs.total_logical_writes)/(ps.usecounts*1.) AS DECIMAL(12,2)) AS avg_io,
           SUM(qs.total_elapsed_time)/(ps.usecounts)/1000 AS avg_elapsed_time_ms,
           ps.plan_handle
    FROM PlanSearch ps
    LEFT OUTER JOIN sys.dm_exec_query_stats qs ON ps.plan_handle = qs.plan_handle
    GROUP BY ps.DatabaseName,
             ps.ObjectName,
             ps.usecounts,
             ps.plan_handle
)
SELECT ps.DatabaseName,
       ps.ObjectName,
       ps.usecounts,
       ps.avg_cpu_time,
       ps.avg_io,
       ps.avg_elapsed_time_ms,
       qp.query_plan,
       ps.plan_handle
FROM PlansAndStats ps
CROSS APPLY sys.dm_exec_query_plan(ps.plan_handle) qp;
