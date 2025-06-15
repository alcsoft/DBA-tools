-- ========================================================
-- Search for Jobs Containing a Specific String in SSIS Steps
-- This query searches for a given string inside the SSIS Job steps (step_name and command).
-- The query joins the sysjobsteps table with the sysjobs table in MSDB database 
-- to retrieve job names, step names, and the associated commands containing the string.
-- Author: Ennis (alcsoft)
-- ========================================================

-- Query to search for specific text in SSIS jobs and their steps
SELECT 
    Jobs.name AS jobname,          -- Job name from sysjobs table
    Steps.step_id,                 -- Step ID from sysjobsteps table
    Steps.step_name,               -- Step name from sysjobsteps table
    Steps.command                  -- Command associated with the job step
FROM 
    msdb.dbo.sysjobsteps Steps
JOIN 
    msdb.dbo.sysjobs Jobs 
    ON Steps.job_id = Jobs.job_id   -- Join to match job_id from both tables
WHERE 
    Steps.step_name LIKE '%Any String you want to look for inside the jobs%'  -- Search in step names
    OR Steps.command LIKE '%Any String you want to look for inside the jobs%'  -- Search in commands
