-- ========================================================
-- Compare Stored Routines Between Two Databases on the Same Instance
-- This script compares the stored routines (procedures, functions) 
-- between two databases to check if their definitions differ.
-- It helps DBAs identify discrepancies in the stored routines 
-- between different environments.
-- 
-- Explanation:
-- 1. The script uses the INFORMATION_SCHEMA.ROUTINES view to query metadata 
--    about stored routines (procedures, functions) from both databases.
-- 2. A LEFT JOIN is performed on the routine name and schema to compare routines 
--    between the two databases.
-- 3. The WHERE clause ensures that routines with different definitions are returned.
--    It also checks for the existence of routines in one database but not the other.
-- 4. The result includes:
--    - ROUTINE_SCHEMA: The schema of the routine.
--    - ROUTINE_NAME: The name of the routine.
--    - ROUTINE_TYPE: The type of the routine (e.g., PROCEDURE, FUNCTION).
--    - DB1_LAST_ALTERED and DB2_LAST_ALTERED: Last altered timestamps for both databases.
--
-- Author: Ennis (alcsoft)
-- ========================================================

DECLARE @DB1 VARCHAR(50) = 'DB1_Name';  -- Replace with your first database name
DECLARE @DB2 VARCHAR(50) = 'DB2_Name';  -- Replace with your second database name
DECLARE @SQL VARCHAR(7000);

-- Prepare the SQL query to compare stored routines between the two databases
SET @SQL =
'SELECT 
    db1.ROUTINE_SCHEMA,
    db1.ROUTINE_NAME,
    db1.ROUTINE_TYPE,
    db1.DATA_TYPE,
    db1.LAST_ALTERED AS DB1_LAST_ALTERED,
    db2.LAST_ALTERED AS DB2_LAST_ALTERED
FROM ' + @DB1 + '.INFORMATION_SCHEMA.ROUTINES db1
LEFT JOIN ' + @DB2 + '.INFORMATION_SCHEMA.ROUTINES db2 
    ON db1.ROUTINE_NAME = db2.ROUTINE_NAME
    AND db1.ROUTINE_SCHEMA = db2.ROUTINE_SCHEMA
WHERE db1.ROUTINE_DEFINITION <> db2.ROUTINE_DEFINITION
OR (db1.ROUTINE_DEFINITION IS NULL AND db2.ROUTINE_DEFINITION IS NOT NULL)
OR (db2.ROUTINE_DEFINITION IS NULL AND db1.ROUTINE_DEFINITION IS NOT NULL)';

-- Execute the dynamically created SQL query
EXEC(@SQL);
