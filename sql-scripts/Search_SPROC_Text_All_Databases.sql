-- ========================================================
-- Search for a Specific String in All Stored Procedures
-- This script searches for a specific string in the text of 
-- all stored procedures across all databases in the SQL Server instance.
-- It uses a cursor to loop through all databases and searches 
-- in the sys.procedures and syscomments tables for the specified text.
-- Author: Ennis (alcsoft)
-- ========================================================

DECLARE @text VARCHAR(255);         -- Variable to hold the text to search for
DECLARE @sql VARCHAR(1024);         -- Variable to hold the dynamic SQL query
DECLARE @DB VARCHAR(64);            -- Variable to hold the current database name

-- Set the string you want to search for inside stored procedures
SET @text = '%DONNA01.MIN_DUE_DT_HEQ%';

-- Declare cursor to loop through all databases
DECLARE DBs CURSOR FOR
    SELECT Name
    FROM sys.databases
    WHERE state_desc = 'ONLINE' -- Ensure only online databases are checked
    ORDER BY database_id;

-- Open the cursor
OPEN DBs;

-- Fetch the first database name
FETCH NEXT FROM DBs INTO @DB;

-- Loop through all databases
WHILE(@@FETCH_STATUS = 0)
BEGIN
    -- Build the dynamic SQL query for each database
    SET @sql = 'SELECT ''' + @DB + ''', P.name
                FROM ' + @DB + '.sys.procedures P
                INNER JOIN ' + @DB + '..syscomments C ON P.object_id = C.id
                WHERE C.text LIKE ''%' + @text + '%'';';
    
    -- Execute the dynamic SQL query
    EXEC(@sql);

    -- Fetch the next database name
    FETCH NEXT FROM DBs INTO @DB;
END

-- Close and deallocate the cursor
CLOSE DBs;
DEALLOCAT
