-- ========================================================
-- SQL Script to Collect SQL Server Error Log
-- This script uses `sqlcmd.exe` to collect the SQL Server error log.
-- It invokes a script file (`collecterrorlog.sql`) from the command line, 
-- passing the server name as a parameter.
-- Author: DBA Tools
-- ========================================================

-- ========================================================
-- Key Features:
-- 1. **Error Log Collection**:
--    - Uses `sqlcmd.exe` to run a script (`collecterrorlog.sql`) on a specified SQL Server.
--    - Captures the error log by executing the script with server name as a parameter.
--
-- 2. **Command-Line Integration**:
--    - Runs the script using command-line execution (`sqlcmd.exe`).
--    - Allows for flexibility by passing the server name (`%1`) and collecting the error log.
--
-- 3. **Error Log Output**:
--    - Outputs the error log into the console for review and troubleshooting.
-- ========================================================

sqlcmd.exe -S%1 -E -w20000 -W -i collecterrorlog.sql;
