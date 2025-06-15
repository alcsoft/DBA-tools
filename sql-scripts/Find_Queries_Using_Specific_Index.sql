-- ========================================================
-- SQL Script to Find Queries Using a Specific Index
-- This script helps DBAs identify queries that are using a 
-- specific index. It queries the cached plans and execution 
-- plans to find any query using the specified index.
-- Author: DBA Tools
-- ========================================================

-- ========================================================
-- Key Features:
-- 1. **Find Queries Using Specific Index**:
--    - Searches for cached plans where a specific index is used.
--    - Uses the execution plan and XML parsing to identify index usage in query plans.
--
-- 2. **Dynamic Index Selection**:
--    - Allows specifying an index name by setting the `@IndexName` variable.
--    - Searches through the cached query plans and identifies the index usage.
--
-- 3. **Detailed Information**:
--    - Provides detailed information about the query, including the database name, object name, plan handle, 
--      query text, and the XML representation of the query plan.
-- ========================================================

DECLARE @IndexName sysname;
SET @IndexName = 'IX_Tbl_Routes_Split_Ref_ID';  -- Enter the index name to search for

WITH XMLNAMESPACES (
    'http://schemas.microsoft.com/sqlserver/2004/07/showplan' AS p
)
SELECT TOP 5
    DB_NAME(qp.dbid) + '.' + OBJECT_SCHEMA_NAME(qp.objectid, qp.dbid) + '.' + OBJECT_NAME(qp.objectid, qp.dbid) AS database_object,  -- Database and object name
    iobj.value('@Index', 'sysname') AS IndexName,  -- Index name from the query plan
    cp.plan_handle,  -- Plan handle for the cached query plan
    iobj.query('.') AS IndexUsage,  -- XML representation of index usage
    qp.query_plan,  -- Complete query plan
    cp.plan_handle,  -- Duplicate plan handle for reference
    qt.text  -- SQL query text
FROM sys.dm_exec_cached_plans cp
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) qp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) qt
CROSS APPLY qp.query_plan.nodes('//p:RelOp') IndexScan(scan)
CROSS APPLY scan.nodes('//p:Object') AS IndexObject(iobj)
WHERE iobj.value('@Index', 'nvarchar(max)') = QUOTENAME(@IndexName, '[');  -- Filter by specified index name
