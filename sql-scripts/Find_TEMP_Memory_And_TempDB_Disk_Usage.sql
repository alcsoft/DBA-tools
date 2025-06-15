-- ========================================================
-- SQL Script to Find TEMP Memory Contention and TempDB Disk Usage
-- This script helps DBAs identify memory contention issues 
-- related to TEMPDB as well as temp object disk usage.
-- It includes two sections:
-- 1. Finds sessions experiencing memory contention in TEMPDB.
-- 2. Identifies temp objects using disk in TEMPDB and their page allocation details.
-- Author: DBA Tools
-- ========================================================

-- ========================================================
-- Key Features:
-- 1. **Find TEMP Memory Contention**:
--    - Identifies sessions that are waiting for TEMP memory (PFS, GAM, SGAM page latches).
--    - Helps identify TEMPDB memory contention issues related to these types of pages.
--
-- 2. **Find Temp Object Using Disk**:
--    - Retrieves information on temp objects (tables, indexes) in TEMPDB that are using disk.
--    - Analyzes used pages, the number of pages in cache, and the allocation unit type for temp objects.
--
-- 3. **TEMPDB Performance Monitoring**:
--    - Monitors TEMPDB usage and contention, aiding in performance optimization.
-- ========================================================

-----############################## Find TEMP MEMORY Contention #######################
SELECT session_id,
       wait_type,
       wait_duration_ms,
       blocking_session_id,
       resource_description,
       ResourceType = CASE
                        WHEN CAST(RIGHT(resource_description, LEN(resource_description) - CHARINDEX(':', resource_description, 3)) AS INT) - 1 % 8088 = 0 THEN 'Is PFS Page'
                        WHEN CAST(RIGHT(resource_description, LEN(resource_description) - CHARINDEX(':', resource_description, 3)) AS INT) - 2 % 511232 = 0 THEN 'Is GAM Page'
                        WHEN CAST(RIGHT(resource_description, LEN(resource_description) - CHARINDEX(':', resource_description, 3)) AS INT) - 3 % 511232 = 0 THEN 'Is SGAM Page'
                        ELSE 'Is Not PFS, GAM, or SGAM page'
                    END
FROM sys.dm_os_waiting_tasks
WHERE wait_type LIKE 'PAGE%LATCH_%'
  AND resource_description LIKE '2:%'
GO

-----############################## Find which Temp object is using Disk #######################
USE tempDB;
WITH Objs (
    ObjectName,
    ObjectID,
    IndexID,
    AU_ID,
    used_pages,
    AU_Type
)
AS (
    SELECT OBJECT_NAME(object_id) AS ObjectName,
           object_id,
           index_id,
           allocation_unit_id,
           used_pages,
           AU.type_desc
    FROM sys.allocation_units AS AU
    INNER JOIN sys.partitions AS P ON AU.container_id = P.hobt_id
    AND AU.type IN (1, 3) -- IN_ROW_DATA and ROW_OVERFLOW_DATA
    UNION ALL
    SELECT OBJECT_NAME(object_id) AS ObjectName,
           object_id,
           index_id,
           allocation_unit_id,
           used_pages,
           AU.type_desc
    FROM sys.allocation_units AS AU
    INNER JOIN sys.partitions AS P ON AU.container_id = P.partition_id
    AND AU.type = 2 -- LOB_DATA
)
SELECT ObjectName,
       AU_Type,
       IndexID,
       MAX(used_pages) PagesOnDisk,
       COUNT(*) PagesInCache,
       MAX(used_pages) - COUNT(*) PageAllocationDiff
FROM sys.dm_os_buffer_descriptors AS BD
LEFT JOIN Objs O ON BD.allocation_unit_id = O.AU_ID
WHERE database_id = DB_ID()
  AND ObjectPropertyEx(ObjectID, 'IsUserTable') = 1
GROUP BY ObjectName, AU_Type, IndexID, used_pages
ORDER BY O.ObjectName, O.AU_Type;
