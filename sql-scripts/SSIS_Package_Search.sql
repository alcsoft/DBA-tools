-- ========================================================
-- Search for a Table Name within SSIS Packages
-- This query searches the SSIS packages stored in MSDB
-- for a specific table name (or other text) within the package data.
-- It casts the `packagedata` from binary to varchar for searching.
-- Author: Ennis (alcsoft)
-- ========================================================

-- Query to search for a table name or other text within SSIS packages
SELECT * 
FROM [msdb].[dbo].[sysdtspackages90]
WHERE CAST(CAST(packagedata AS VARBINARY(MAX)) AS VARCHAR(MAX)) LIKE '%Table Name%';
