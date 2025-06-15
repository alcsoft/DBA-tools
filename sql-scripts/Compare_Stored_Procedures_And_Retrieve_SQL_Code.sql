-- ========================================================
-- Compare and List the SQL Code of Different Stored Procedures
-- This script compares the stored procedures between two databases 
-- on the same instance and fetches their SQL code if their definitions differ.
-- It helps DBAs identify discrepancies in the stored procedure definitions 
-- between two environments (e.g., development and production).
-- 
-- Explanation:
-- 1. The script compares stored procedures between two databases by checking their definitions 
--    using the INFORMATION_SCHEMA.ROUTINES view.
-- 2. A FULL JOIN is performed to find differences in routines between the two databases.
-- 3. It excludes specific routines based on certain patterns (e.g., routine names, schemas).
-- 4. It retrieves the SQL code of the differing routines using sp_helptext.
-- 5. It concatenates the SQL code into a single string and prints it for review.
--
-- Author: Ennis (alcsoft)
-- ========================================================

DECLARE @DB1 VARCHAR(50) = 'DB1_Name'; -- Replace with your first database name
DECLARE @DB2 VARCHAR(50) = 'DB2_Name'; -- Replace with your second database name
DECLARE @SQL VARCHAR(MAX);

-- Prepare the SQL query to compare stored procedures between the two databases
SET @SQL =
'SELECT db1.Routine_Name
FROM ' + @DB1 + '.INFORMATION_SCHEMA.ROUTINES db1
FULL JOIN ' + @DB2 + '.INFORMATION_SCHEMA.ROUTINES db2 
    ON db1.routine_name = db2.routine_name
    AND db1.ROUTINE_SCHEMA = db2.ROUTINE_SCHEMA
WHERE db1.ROUTINE_DEFINITION <> db2.ROUTINE_DEFINITION
    AND db1.Routine_Name NOT LIKE ''%Something%'' -- Exclude routines with specific patterns
    AND db1.ROUTINE_SCHEMA <> ''Something'''; -- Exclude specific schemas if needed

-- Drop previous temp tables
DROP TABLE IF EXISTS #code;
CREATE TABLE #code (ln VARCHAR(1000));

DROP TABLE IF EXISTS #sprocstable;
CREATE TABLE #sprocstable (sproc VARCHAR(1000));

-- Insert the names of stored procedures that have different definitions into the temp table
INSERT INTO #sprocstable
EXEC(@SQL);

DECLARE @sprocname VARCHAR(1000);

-- Cursor to loop through the stored procedure names
DECLARE myCur CURSOR FAST_FORWARD
FOR
SELECT sproc FROM #sprocstable;

OPEN myCur;
FETCH NEXT FROM myCur INTO @sprocname;

-- Loop through each stored procedure and get its code using sp_helptext
WHILE @@FETCH_STATUS = 0
BEGIN
    -- Insert the SQL code of the stored procedure into the #code table
    INSERT INTO #code
    EXEC sp_helptext @sprocname;

    FETCH NEXT FROM myCur INTO @sprocname;
END

CLOSE myCur;
DEALLOCATE myCur;

-- Select all the SQL code from the #code table
SELECT * FROM #code;

DECLARE @ln VARCHAR(1000);
SET @SQL = '';

-- Cursor to concatenate the SQL code of the stored procedures into a single string
DECLARE myCur CURSOR FAST_FORWARD
FOR
SELECT ln FROM #code;

OPEN myCur;
FETCH NEXT FROM myCur INTO @ln;

-- Loop through each line of the SQL code and concatenate it
WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = @SQL + @ln; -- Concatenate each line of code
    FETCH NEXT FROM myCur INTO @ln;
END

CLOSE myCur;
DEALLOCATE myCur;

-- Print the concatenated SQL code
PRINT @SQL;
