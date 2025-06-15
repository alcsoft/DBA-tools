-- SQL: Get a List of Hotfixes Installed on the Server

-- This script uses xp_cmdshell to execute a Windows command to get the list of installed hotfixes
-- and saves it as an HTML file on the server.

-- Author: DBA Tools
-- Date: [Insert Date]
-- Description: This script executes a command to get all hotfixes installed on the SQL Server
-- and saves the result to a file (C:\hotfixes.htm).

-- Enable xp_cmdshell if it's not enabled already
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;

-- Execute the WMIC command to get hotfix list and save to a file
EXEC xp_cmdshell 'wmic qfe list full /format:htable > C:\hotfixes.htm';

-- Disable xp_cmdshell after usage for security reasons
EXEC sp_configure 'xp_cmdshell', 0;
RECONFIGURE;

-- The output will be saved in the file C:\hotfixes.htm, which can be opened in a web browser
