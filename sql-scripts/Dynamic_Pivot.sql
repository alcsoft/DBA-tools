-- ========================================================
-- Dynamic Pivot for SQL Server
-- This script dynamically generates a pivot table, where
-- the dates in the column are dynamically generated based
-- on the distinct values of the [Date] column in the table.
-- The data is aggregated (SUM) by 'Size' for each date.
-- Author: Ennis (alcsoft)
-- ========================================================

DECLARE @DynamicPivotQuery AS NVARCHAR(MAX);  -- Variable to hold the dynamic SQL query
DECLARE @PivotColumnNames AS NVARCHAR(MAX);   -- Variable to hold the dynamically generated column names

-- Step 1: Get distinct dates for the PIVOT columns.
-- This will generate a comma-separated list of unique dates
-- which will be used to create the dynamic column names for the pivot table.
SELECT @PivotColumnNames = COALESCE(@PivotColumnNames + ', ', '') + QUOTENAME(CONVERT(NVARCHAR, [Date], 23))
FROM (SELECT DISTINCT [Date] FROM YourTableName) AS Dates;

-- Step 2: Construct the Dynamic Pivot Query.
-- We use the dynamic column names generated above and construct the full PIVOT query.
SET @DynamicPivotQuery = 
    N'SELECT Server_name, Database_Name, Client, ' + @PivotColumnNames + '
      FROM (
            SELECT Server_name, Database_Name, Client, Size, [Date]
            FROM YourTableName
           ) AS SourceTable
      PIVOT (
            SUM(Size)  -- Aggregate the 'Size' values for each date
            FOR [Date] IN (' + @PivotColumnNames + ')  -- Pivot for each distinct date
           ) AS PivotTable;';

-- Step 3: Execute the dynamic query.
-- The dynamically generated query is executed using sp_executesql.
EXEC sp_executesql @DynamicPivotQuery;
