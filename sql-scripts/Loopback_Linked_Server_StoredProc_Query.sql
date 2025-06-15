-- ========================================================
-- SQL Script to Query Stored Procedure Using Loopback Linked Server
-- This script uses a loopback linked server to execute a stored procedure
-- on the same SQL Server instance and captures metadata from the result set.
-- Author: Ennis (alcsoft)
-- ========================================================

-- Enable the linked server (loopback)
EXEC master.dbo.sp_addlinkedserver 
    @server = N'LOOPBACK', 
    @srvproduct = N' ', 
    @provider = N'SQLNCLI', 
    @datasrc = N'InstanceName';  -- Replace 'InstanceName' with your server name

-- Add the linked server login
EXEC master.dbo.sp_addlinkedsrvlogin
    @rmtsrvname = N'LOOPBACK',
    @useself = N'True', 
    @locallogin = NULL, 
    @rmtuser = NULL, 
    @rmtpassword = NULL;

-- Sample query to execute the stored procedure and capture column metadata
SELECT *
INTO #t
FROM openquery(LOOPBACK, 'EXEC DBname.Schema.SprocName @Parmlist = NULL');  -- Replace with your stored procedure and parameters

-- Get column metadata from the temporary table
SELECT *
FROM tempdb.sys.all_columns c
WHERE c.[object_id] = OBJECT_ID('tempdb..#t');

-- Drop the temporary table after processing
DROP TABLE #t;
