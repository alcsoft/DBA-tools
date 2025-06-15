-- ========================================================
-- SQL Script to Search SQL Agent Job Steps for a Specific String
-- This script helps DBAs search for a string within the SQL Agent job steps.
-- It filters job steps based on the provided search string and whether the job is enabled or not.
-- Author: Ennis (alcsoft)
-- ========================================================

-- ========================================================
-- Key Features:
-- 1. **Search SQL Agent Job Steps**:
--    - Searches for a specific string (e.g., 'loadtable') within the job steps' command text.
--    - Allows filtering by job status (enabled/disabled).
--
-- 2. **Dynamic Search String**:
--    - The `@SearchString` variable allows dynamic searching of job steps.
--    - Replace `'loadtable'` with any string you want to search for.
--
-- 3. **Enabled Job Filter**:
--    - The `@IsEnabled` variable helps filter jobs based on their enabled status.
--    - Set to `0` for disabled jobs, `1` for enabled jobs, or `2` to include both.
-- ========================================================

-- Declare search string and job enabled status
DECLARE
    @SearchString varchar(255),
    @IsEnabled bit;

-- Set the search string and job enabled status
SET @SearchString = 'loadtable';  -- Enter Search String Here. Leave Blank for All
SET @IsEnabled = 2;  -- 0 = Disabled, 1 = Enabled, 2 = All

-- Query to search for job steps containing the search string
SELECT
    j.Name AS JobName,                 -- Job name
    j.Description AS JobDescription,   -- Job description
    js.step_id AS StepID,              -- Job step ID
    js.step_name AS StepName,          -- Job step name
    js.database_name AS DatabaseName,  -- Database name for the step
    js.command AS StepCommand          -- SQL command executed in the job step
FROM
    msdb..sysjobs j
INNER JOIN
    msdb..sysjobsteps js ON j.job_id = js.job_id
WHERE
    (j.enabled = @IsEnabled OR @IsEnabled = 2) AND  -- Filter by job enabled status
    js.command LIKE '%' + @SearchString + '%'      -- Search job steps for the string
ORDER BY
    j.Name,                                        -- Order by job name
    js.step_id;                                    -- Order by step ID
