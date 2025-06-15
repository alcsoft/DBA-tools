-- ========================================================
-- SQL Script to Search for Indexes That Don't Allow Page Locks
-- This script searches across all user databases in SQL Server 
-- and finds all indexes that do not allow page locks.
-- The script excludes system databases and certain indexes 
-- like 'queue_clustered_index' and 'queue_secondary_index'.
-- Author: DBA Tools
-- ========================================================

-- ========================================================
-- Key Features:
-- 1. **Search Across All Databases**:
--    - Searches through all databases except system databases (`master`, `tempdb`, `model`, `msdb`).
--    - Uses a cursor to iterate through each database.
--
-- 2. **Dynamic SQL Execution**:
--    - Constructs dynamic SQL for each database to find indexes that do not allow page locks.
--    - Executes the dynamic SQL to retrieve the list of indexes for each database.
--
-- 3. **Excludes Specific Indexes**:
--    - Excludes indexes named `'queue_clustered_index'` and `'queue_secondary_index'` from the results.
-- ========================================================

DECLARE @DBName NVARCHAR(50);
DECLARE @DynamicSQL NVARCHAR(300);
DECLARE @DBCursor CURSOR;

-- Declare a cursor to loop through each user database
SET @DBCursor = CURSOR FOR
    SELECT NAME
    FROM SYS.DATABASES
    WHERE NAME NOT IN ('master','tempdb','model','msdb');  -- Exclude system databases

OPEN @DBCursor;
FETCH NEXT FROM @DBCursor INTO @DBName;

-- Loop through each database
WHILE @@FETCH_STATUS = 0
BEGIN
    -- Create dynamic SQL to search for indexes that don't allow page locks
    SET @DynamicSQL = 'SELECT * FROM [' + @DBName + '].sys.indexes 
                       WHERE allow_page_locks = 0 
                       AND name <> ''queue_clustered_index'' 
                       AND name <> ''queue_secondary_index''';

    -- Print the dynamic SQL for logging purposes
    PRINT @DynamicSQL;

    -- Execute the dynamic SQL
    EXEC SP_EXECUTESQL @DynamicSQL;

    FETCH NEXT FROM @DBCursor INTO @DBName;
END;

-- Clean up cursor
CLOSE @DBCursor;
DEALLOCATE @DBCursor;
