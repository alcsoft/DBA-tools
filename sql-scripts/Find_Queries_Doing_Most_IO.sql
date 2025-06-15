-- ========================================================
-- SQL Script to Find Queries Doing Most I/O
-- This script helps DBAs identify the queries that are doing 
-- the most I/O (logical reads and writes) in SQL Server.
-- It calculates the average I/O, total I/O, and execution count 
-- for each query, helping to identify high I/O queries.
-- Author: DBA Tools
-- ========================================================

-- ========================================================
-- Key Features:
-- 1. **Identify High I/O Queries**:
--    - Retrieves the queries that are doing the most I/O (logical reads + writes).
--    - Provides average I/O, total I/O, and execution count for each query.
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
--    - Helps monitor the performance of queries that are consuming significant I/O resources.
-- ========================================================

SELECT TOP 100
    (total_logical_reads + total_logical_writes) / qs.execution_count AS average_IO,  -- Average I/O per execution
    (total_logical_reads + total_logical_writes) AS total_IO,  -- Total I/O (reads + writes)
    qs.execution_count AS execution_count,  -- Number of executions
    SUBSTRING (
        qt.text, qs.statement_start_offset / 2,  -- Query text extraction
        (CASE WHEN qs.statement_end_offset = -1 
            THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2 
            ELSE qs.statement_end_offset END - qs.statement_start_offset) / 2
    ) AS indivudual_query,  -- Individual query text
    o.name AS object_name,  -- Object name (e.g., stored procedure or function)
    DB_NAME(qt.dbid) AS database_name  -- Database name for the query
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt  -- Get SQL text from cached plans
LEFT OUTER JOIN sys.objects o ON qt.objectid = o.object_id  -- Join to get object name
WHERE qt.dbid = DB_ID()  -- Filter for the current database
ORDER BY average_IO DESC;  -- Order queries by average I/O in descending order
