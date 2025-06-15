-- ========================================================
-- Search for a Column in the Database
-- This query searches for a column name across all tables
-- in the database and returns the column name, table name,
-- creation and modification dates of the tables.
-- Author: Ennis (alcsoft)
-- ========================================================

-- Query to search for a specific column in the database
SELECT 
    a.name AS column_name,              -- Column name from sys.columns table
    b.name AS table_name,               -- Table name from sys.objects table
    b.create_date,                      -- Table creation date
    b.modify_date                       -- Table last modification date
FROM 
    sys.columns a
JOIN 
    sys.objects b 
    ON a.object_ID = b.object_ID        -- Join sys.columns and sys.objects on object_ID
WHERE 
    a.name LIKE '%acct_id%';            -- Search for columns containing 'acct_id'
