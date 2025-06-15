-- ========================================================
-- SQL Script to Analyze Query Performance Based on Logical Reads
-- This script retrieves the top 20 most resource-intensive queries 
-- by examining their total logical reads. It includes detailed 
-- metrics such as execution count, elapsed time, and the query plan.
-- 
-- Explanation:
-- 1. The script retrieves I/O performance data by querying system views 
--    like sys.dm_exec_query_stats, sys.dm_exec_sql_text, and sys.dm_exec_query_plan.
-- 2. It calculates the total logical reads, execution count, elapsed time 
--    for each query to identify the most resource-intensive queries.
-- 3. The script retrieves the execution plan for each query, providing insights
--    into how SQL Server executes the query.
-- 4. The results are ordered by the total logical reads to highlight queries 
--    that are most likely consuming resources.
-- 
-- Key Features:
-- 1. **`sys.dm_exec_query_stats`**: Provides performance statistics for cached query plans.
-- 2. **`sys.dm_exec_sql_text`**: Fetches the text of the SQL query being executed.
-- 3. **`sys.dm_exec_query_plan`**: Retrieves the execution plan of a query, which is useful 
--    for identifying potential bottlenecks in query execution.
-- 4. **Logical Reads**: Tracks the number of logical reads performed by the queries, 
--    helping to understand resource utilization.
-- 5. **Elapsed Time**: Measures the time taken by queries to execute, allowing for 
--    performance optimizations.
-- 6. **Query Plan**: Retrieves the actual query plan, which can assist in performance tuning.
-- 
-- Author: Ennis (alcsoft)
-- ========================================================

-- Query to retrieve the top 20 most resource-intensive queries
SELECT TOP 20 
    -- Extract the text of the query being executed
    SUBSTRING(
        qt.text, 
        (qs.statement_start_offset / 2) + 1, 
        ((CASE qs.statement_end_offset 
            WHEN -1 THEN DATALENGTH(qt.text) 
            ELSE qs.statement_end_offset 
         END - qs.statement_start_offset) / 2) + 1
    ) AS query_text,
    
    -- Execution count metrics
    qs.execution_count,
    
    -- Logical read metrics (how many pages are read)
    qs.total_logical_reads, 
    qs.last_logical_reads,
    qs.min_logical_reads, 
    qs.max_logical_reads,
    
    -- Elapsed time metrics (time the query took to execute)
    qs.total_elapsed_time, 
    qs.last_elapsed_time,
    qs.min_elapsed_time, 
    qs.max_elapsed_time,
    
    -- Last execution time of the query
    qs.last_execution_time,
    
    -- The query plan for this query
    qp.query_plan

FROM 
    sys.dm_exec_query_stats qs  -- Query stats DMV
CROSS APPLY 
    sys.dm_exec_sql_text(qs.sql_handle) qt  -- Get the SQL text
CROSS APPLY 
    sys.dm_exec_query_plan(qs.plan_handle) qp  -- Get the execution plan

WHERE 
    qt.encrypted = 0  -- Only consider non-encrypted queries

ORDER BY 
    qs.total_logical_reads DESC;  -- Order by the total logical reads in descending order
