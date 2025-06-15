-- ========================================================
-- Trigger to Monitor Login Violations on SQL Server
-- This trigger is designed to monitor a specific SQL login
-- and sends an email alert if it's used to log in via SQL Server Management Studio (SSMS)
-- from an unauthorized machine.
-- Author: Ennis (alcsoft)
-- ========================================================

USE [master];
GO

-- Drop existing trigger if it exists
DROP TRIGGER [MonitorLoginViolation] ON ALL SERVER;
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

-- Create the trigger to monitor login violations
CREATE TRIGGER [MonitorLoginViolation] 
    ON ALL SERVER
    WITH EXECUTE AS 'sa'
    FOR LOGON
AS
BEGIN
    DECLARE @body VARCHAR(150);
    DECLARE @systemSQLUser VARCHAR(50);
    DECLARE @AllowedServers TABLE (Hostname VARCHAR(50));

    -- Specify the SQL login you want to monitor
    SET @systemSQLUser = '<WhichLoginWantToMonitor>'; -- Replace with the actual SQL login name you want to monitor

    -- List of servers that are allowed to connect using the specified SQL login
    -- You can add more servers as needed to exclude them from the monitoring
    INSERT INTO @AllowedServers (Hostname)
    VALUES ('MyOfficeComputer'); -- Replace with your own machine name (this machine is allowed to connect)

    -- Check if the login is the one you are monitoring and it's coming from an unauthorized machine
    IF ORIGINAL_LOGIN() = @systemSQLUser
        AND APP_NAME() LIKE '%Microsoft%' -- This checks for Microsoft applications, e.g., SSMS
        AND HOST_NAME() NOT IN (SELECT Hostname FROM @AllowedServers)
    BEGIN
        -- Compose the body of the email alert
        SET @Body = 'On ' + @@SERVERNAME + ', someone used ' 
                    + ORIGINAL_LOGIN() + ' from ' 
                    + HOST_NAME() + ' by launching ' 
                    + APP_NAME();

        -- Send an email alert (you need to have Database Mail configured)
        EXECUTE AS LOGIN = 'sa';
        EXEC msdb.dbo.sp_send_dbmail 
            @recipients = 'anas.hamza@company.com',  -- Replace with your email address
            @subject = 'System Login Violation',
            @body = @Body,
            @body_format = 'html',
            @query_no_truncate = 1;
    END;
END;
GO

-- Set ANSI_NULLS and QUOTED_IDENTIFIER back to OFF
SET ANSI_NULLS OFF;
GO
SET QUOTED_IDENTIFIER OFF;
GO

-- Enable the trigger after creation
ENABLE TRIGGER [MonitorLoginViolation] ON ALL SERVER;
GO
