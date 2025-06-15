-- ========================================================
-- SQL Script to Find Queries Taking Longest Elapsed Time
-- This script helps DBAs identify the queries that are taking 
-- the longest time to execute in SQL Server. It calculates 
-- the average elapsed time, total time, and execution count 
-- for each query and orders them by the average elapsed time.
-- Author: DBA Tools
-- ========================================================

-- ========================================================
-- Key Features:
-- 1. **Identify Long Running Queries**:
--    - Retrieves the queries with the longest elapsed times.
--    - Provides the average elapsed time, total elapsed time, and execution count for each query.
--
-- 2. **Detailed Query Information**:
--    - Includes the SQL text, object name, and database name for each query.
--    - Extracts individual query statements when there are multiple statements in the same batch.
--
-- 3. **Database-Specific Querying**:
--    - Filters queries based on the current database using `qt.dbid = DB_ID()`.
--    - Ensures results are scoped to the active database.
--
-- 4. **Performance Monitoring**:
--    - Helps monitor the performance of frequently executed and long-running queries.
-- ========================================================

SELECT TOP 100
    qs.total_elapsed_time / qs.execution_count / 1000000.0 AS average_seconds,  -- Average time in seconds
    qs.total_elapsed_time / 1000000.0 AS total_seconds,  -- Total time in seconds
    qs.execution_count,  -- Number of executions
    SUBSTRING (
        qt.text, qs.statement_start_offset / 2,  -- Query text extraction
        (CASE WHEN qs.statement_end_offset = -1 
            THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
            ELSE qs.statement_end_offset END - qs.statement_start_offset) / 2
    ) AS individual_query,  -- Individual query text
    o.name AS object_name,  -- Object name (e.g., stored procedure or function)
    DB_NAME(qt.dbid) AS database_name  -- Database name for the query
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt  -- Get SQL text from cached plans
LEFT OUTER JOIN sys.objects o ON qt.objectid = o.object_id  -- Join to get object name
WHERE qt.dbid = DB_ID()  -- Filter for the current database
ORDER BY average_seconds DESC;  -- Order queries by average elapsed time in descending order
