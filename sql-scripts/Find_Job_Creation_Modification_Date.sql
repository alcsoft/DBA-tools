-- ========================================================
-- Find the Creation and Modification Dates of a Job
-- This query retrieves the creation date and the last modification date
-- of a specified SQL Server Agent job by searching in the msdb..SYSJOBS table.
-- Author: Ennis (alcsoft)
-- ========================================================

-- Query to find the creation and modification dates of a specific job
SELECT 
    date_created,   -- The creation date of the job
    date_modified  -- The last modification date of the job
FROM 
    msdb..SYSJOBS
WHERE 
    name = 'jobCL_HES_Loss_Mitigation_Workout';  -- Specify the job name
