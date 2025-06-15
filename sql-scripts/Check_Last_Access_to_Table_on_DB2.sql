-- ========================================================
-- Check the Last Access to a Table in DB2
-- This query retrieves the last access information (user, application, host, and time) 
-- for a specified table within the last 30 days by searching through the 
-- `track_query_info` table. It filters the results based on the table name.
-- Author: Ennis (alcsoft)
-- ========================================================

-- Query to check the last access to a table (replace 'schemaname.tablename' with actual schema and table name)
SELECT 
    USER_ID,                              -- User ID who accessed the table
    APPLICATION,                           -- Application used to access the table
    APPLICATION_HOST,                      -- Host from which the application accessed the table
    time_created                           -- The time when the table was accessed
FROM 
    db2qp.track_query_info
WHERE 
    db2qp.converttostring(STATEMENT) LIKE '%schemaname.tablename%'  -- Search for the specific table access
    AND DATE(time_created) BETWEEN (CURRENT_DATE - 30 DAYS) AND CURRENT_DATE;  -- Filter by the last 30 days

-- Query to check the last access to another table (replace 'schemaname.xyv_5_6' with the actual table name)
SELECT 
    USER_ID,                              -- User ID who accessed the table
    APPLICATION,                           -- Application used to access the table
    APPLICATION_HOST,                      -- Host from which the application accessed the table
    time_created                           -- The time when the table was accessed
FROM 
    db2qp.track_query_info
WHERE 
    db2qp.converttostring(STATEMENT) LIKE '%schemaname.xyv_5_6%'  -- Search for the specific table access
    AND DATE(time_created) BETWEEN (CURRENT_DATE - 30 DAYS) AND CURRENT_DATE;  -- Filter by the last 30 days
