-- SQL Script to Monitor Long Running Jobs
-- This stored procedure helps you find long running jobs on your SQL Server 
-- and sends an email notification if the job is running longer than the specified threshold.

-- ============================================= 
-- Author:  DBA Tools 
-- Create date: 08/02/2011 
-- Description: This job monitors long running jobs (longer than @lRunValue mins) and sends an email to the specified email addresses.
-- The script should be run periodically (e.g., every hour).
-- Important Note: If the job you want to monitor contains only one step, add a dummy step as a first step like "SELECT GetDATE()" 
-- to the job(s) which you want to monitor. 
-- =============================================

DECLARE @lRunValue INTEGER;
DECLARE @szEmailAddresses VARCHAR(100);
SET @lRunValue = 2;  -- Time threshold for long running jobs in minutes
SET @szEmailAddresses = 'ahamza@ruan.com';  -- Email address to notify

DECLARE @vcSubject VARCHAR(100);
SET @vcSubject = 'Long Running Job! ON ' + @@SERVERNAME;

DECLARE @step_id INT, @run_status INT, @next_runstep INT, @jobname VARCHAR(128), @jobid UNIQUEIDENTIFIER;
DECLARE @step_action INT , @next_step_id INT;
DECLARE @run_date VARCHAR(100), @run_time VARCHAR(100);
DECLARE @QUERY VARCHAR(1000);
DECLARE @StartDate DATETIME;
DECLARE @Hours INT, @Mins INT, @Sec INT;

-- Get the job id
DECLARE jobIDs CURSOR FOR
SELECT job_id
FROM sysjobs
WHERE ENABLED = 1;

OPEN jobIDs;
FETCH jobIDs INTO @jobid;

WHILE @@FETCH_STATUS <> -1
BEGIN
    SELECT @jobname = name 
    FROM sysjobs 
    WHERE job_id = @jobid;

    -- Find the last running step
    SELECT @step_id = MAX(step_id)
    FROM dbo.sysjobhistory sjh 
    WHERE job_id = @jobid 
    AND sjh.instance_id > (
        SELECT MAX(instance_id) 
        FROM sysjobhistory sjh1 
        WHERE sjh1.step_name = '(Job outcome)' 
        AND sjh1.job_id = @jobid
    );

    IF @step_id IS NOT NULL
    BEGIN
        -- Find the job start time
        SELECT @run_date = run_date, @run_time = run_time
        FROM dbo.sysjobhistory sjh
        WHERE job_id = @jobid
        AND sjh.instance_id > (
            SELECT MAX(instance_id) 
            FROM sysjobhistory sjh1 
            WHERE sjh1.step_name = '(Job outcome)' 
            AND sjh1.job_id = @jobid
        );

        IF LEN(RTRIM(LTRIM(@run_time))) < 6
            SET @run_time = '0' + @run_time;

        SELECT @Hours = SUBSTRING(@run_time, 1, 2);
        SELECT @Mins = SUBSTRING(@run_time, 3, 2);
        SELECT @Sec = SUBSTRING(@run_time, 5, 2);
        SELECT @StartDate = DATEADD(ss, @Sec, DATEADD(mi, @Mins, DATEADD(hh, @Hours, CONVERT(DATETIME, @run_date))));

        -- Calculate job run duration
        SELECT *
        FROM dbo.sysjobhistory sjh
        WHERE job_id = @jobid
        AND sjh.instance_id > (
            SELECT MAX(instance_id) 
            FROM sysjobhistory sjh1 
            WHERE sjh1.step_name = '(Job outcome)' 
            AND sjh1.job_id = @jobid
        );

        -- Get the step status
        SELECT @run_status = run_status, @run_date = run_date, @run_time = run_time
        FROM sysjobhistory sjh
        WHERE job_id = @jobid 
        AND step_id = @step_id
        AND instance_id > (
            SELECT MAX(instance_id)
            FROM sysjobhistory sjh1
            WHERE sjh1.step_name = '(Job outcome)' 
            AND sjh1.job_id = @jobid
        );

        -- Determine the next step to execute
        SELECT @step_action = CASE 
            WHEN @run_status = 1 THEN on_success_action
            ELSE on_fail_action
        END,
        @next_step_id = CASE
            WHEN @run_status = 1 THEN on_success_step_id
            ELSE on_fail_step_id
        END
        FROM msdb.dbo.sysjobsteps
        WHERE job_id = @jobid 
        AND step_id = @step_id;

        -- Set the next step
        SELECT @next_runstep = CASE
            WHEN @step_action IN (1, 2) THEN @step_id -- Current step
            WHEN @step_action = 3 THEN @step_id + 1 -- Next step
            WHEN @step_action = 4 THEN @next_step_id -- Go to the next step
            ELSE -1 -- Unknown step
        END;

        -- Check if the job has been running longer than the threshold
        IF DATEDIFF(MI, @StartDate, GETDATE()) > @lRunValue
        BEGIN
            SELECT @QUERY = 'This job starts on ' + CONVERT(CHAR(30), GETDATE(), 9) 
                            + ' and hasn''t finished yet! (Running for ' 
                            + CONVERT(CHAR(5), DATEDIFF(MI, @StartDate, GETDATE())) 
                            + ' MIN(s))! Job name: ' + @jobname 
                            + ', Step number ' + CAST(@next_runstep AS VARCHAR);

            -- Send email notification
            EXEC msdb.dbo.sp_send_dbmail
                @profile_name = 'DBMail Profile',
                @recipients = @szEmailAddresses,
                @body = @QUERY,
                @subject = @vcSubject;
        END
    END
    FETCH jobIDs INTO @jobid;
END

DEALLOCATE jobIDs;
