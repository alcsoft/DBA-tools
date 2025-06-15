-- ========================================================
-- SQL Script to Search for a Specific Text in Stored Procedures
-- This stored procedure searches for a specific text string 
-- in the source code of stored procedures across all databases 
-- or a specified database in the SQL Server instance.
-- Author: Anas Hamza (alcsoft)
-- ========================================================

-- ========================================================
-- Key Features:
-- 1. **Text Search in Stored Procedures**:
--    - Searches for a specific text in the source code of stored procedures.
--    - Uses a `LIKE` query to find the text pattern in the procedure definitions.
--
-- 2. **Database Flexibility**:
--    - Allows searching across all databases in the SQL Server instance or within a specified database.
--    - If `@dbname` is not provided, it searches in all databases.
--
-- 3. **Cursor for Multiple Databases**:
--    - Uses a cursor to iterate over all databases if `@dbname` is NULL.
--    - For each database, the stored procedure is executed to search for the provided text.
--
-- 4. **Dynamic SQL Execution**:
--    - Constructs and executes dynamic SQL to search for the text in the stored procedures.
-- ========================================================

CREATE PROCEDURE [dbo].[find_text_in_sp]
  @text VARCHAR(250),
  @dbname VARCHAR(64) = NULL
AS BEGIN
    SET NOCOUNT ON;

    -- If no database is specified, search across all databases
    IF @dbname IS NULL
    BEGIN
        -- Declare a cursor to iterate through all databases
        DECLARE #db CURSOR FOR 
            SELECT Name 
            FROM master..sysdatabases;

        DECLARE @c_dbname VARCHAR(64);

        OPEN #db;
        FETCH #db INTO @c_dbname;

        -- Loop through each database
        WHILE @@FETCH_STATUS <> -1
        BEGIN
            -- Ensure the database name is surrounded by brackets
            IF (LEFT(@c_dbname, 1) <> '[')
                SET @c_dbname = '[' + @c_dbname + ']';

            PRINT @c_dbname;  -- Print the database being searched

            -- Recursively call the procedure for each database
            EXECUTE find_text_in_sp @text, @c_dbname;

            FETCH #db INTO @c_dbname;
        END;

        CLOSE #db;
        DEALLOCATE #db;
    END -- If @dbname is NULL
    ELSE
    BEGIN
        -- If @dbname is provided, search within the specified database
        DECLARE @sql VARCHAR(250);

        -- Ensure the database name is surrounded by brackets
        IF (LEFT(@dbname, 1) <> '[')
            SET @dbname = '[' + @dbname + ']';

        -- Create the dynamic SQL to search the stored procedures
        SELECT @sql = 'SELECT ''' + @dbname + ''' AS db, o.name, type_desc, m.definition 
                       FROM ' + @dbname + '.sys.sql_modules m 
                       INNER JOIN ' + @dbname + '.sys.objects o ON m.object_id = o.object_id
                       WHERE m.definition LIKE ''%' + @text + '%''';

        -- Execute the dynamic SQL
        EXECUTE (@sql);
    END; -- If @dbname is not NULL
END;
GO
