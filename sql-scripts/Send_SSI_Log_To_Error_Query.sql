-- ========================================================
-- Retrieve SSIS Logs for OnError Events
-- This query retrieves error logs from the SSIS execution logs 
-- where the event is 'OnError'. It filters the logs based on 
-- the specified start time and can be customized further 
-- by source or message.
-- Author: Ennis (alcsoft)
-- ========================================================

-- Query to retrieve error logs from SSIS
SELECT 
    [source],                              -- Source of the error event
    [sourceid],                             -- Source ID of the error event
    [executionid],                          -- Execution ID associated with the error
    [starttime],                            -- Start time of the error event
    [endtime],                              -- End time of the error event
    [datacode],                             -- Data code associated with the error
    [databytes],                            -- Data bytes associated with the error
    [message]                               -- Error message
FROM 
    [MSA_AE].[dbo].[sysdtslog90] 
WHERE 
    event = 'OnError'                      -- Filter by 'OnError' event type
    AND [starttime] > '2010-07-01 14:39:05.000' -- Filter by start time
-- Optional Filters:
--    AND source = 'T_REAL_ESTATE'           -- Uncomment and specify the source if needed
--    AND message LIKE '%sequence%'          -- Uncomment and specify the message filter if needed
ORDER BY 
    [starttime] DESC;                       -- Order by start time in descending order
