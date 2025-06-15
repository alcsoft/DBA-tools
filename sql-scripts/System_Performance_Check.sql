-- ========================================================
-- System Performance Check for Memory Usage and Buffer Pool
-- This script checks various performance counters related to memory usage,
-- page life expectancy, and top consumers from SQL Server's buffer pool.
-- It also provides information on the memory pressure (internal and external).
-- Author: Ennis (alcsoft)
-- ========================================================

-- Internal and External Pressure on Memory Clerks
SELECT 
    TYPE, 
    SUM(single_pages_kb) AS InternalPressure, 
    SUM(multi_pages_kb) AS ExternalPressure
FROM sys.dm_os_memory_clerks
GROUP BY TYPE
ORDER BY SUM(single_pages_kb) DESC, SUM(multi_pages_kb) DESC;

-- Server Memory Performance Counters (in GB)
SELECT 
    counter_name, 
    cntr_value, 
    CAST((cntr_value / 1024.0) / 1024.0 AS NUMERIC(8,2)) AS Gb
FROM sys.dm_os_performance_counters
WHERE counter_name LIKE '%server_memory%';

-- Page Life Expectancy (Buffer Manager)
SELECT 
    object_name, 
    counter_name, 
    cntr_value AS 'Page Life Expectancy'
FROM sys.dm_os_performance_counters
WHERE object_name LIKE '%Buffer Manager%'
AND counter_name = 'Page life expectancy';

-- Top 10 Consumers of Memory from Buffer Pool (In MB)
SELECT TOP (10) 
    type, 
    SUM(single_pages_kb) / 1024.0 AS [SPA Mem, MB], 
    SUM(multi_pages_kb) / 1024.0 AS [MPA Mem, MB]
FROM sys.dm_os_memory_clerks
GROUP BY type
HAVING SUM(single_pages_kb) + SUM(multi_pages_kb) > 20000
ORDER BY SUM(single_pages_kb) DESC;

-- Internal and External Pressure (KB)
SELECT 
    TYPE, 
    SUM(single_pages_kb) / 1024.0 AS [InternalPressure, KB], 
    SUM(multi_pages_kb) / 1024.0 AS [ExternalPressure, KB]
FROM sys.dm_os_memory_clerks
GROUP BY TYPE
ORDER BY SUM(single_pages_kb) DESC, SUM(multi_pages_kb) DESC;

-- Total Buffer Usage by Database (MB)
SELECT 
    DB_NAME(database_id) AS [Database Name], 
    COUNT(*) * 8 / 1024.0 AS [Cached Size (MB)]
FROM sys.dm_os_buffer_descriptors
WHERE database_id > 4  -- Exclude system databases
GROUP BY DB_NAME(database_id)
ORDER BY [Cached Size (MB)] DESC;

-- Total Cached Size (MB) for Non-System Databases
SELECT 
    COUNT(*) * 8 / 1024.0 AS [Cached Size (MB)]
FROM sys.dm_os_buffer_descriptors
WHERE database_id > 4; -- Exclude system databases

-- Check Page Life Expectancy Again (BUFFER MANAGER)
SELECT *
FROM sys.dm_os_performance_counters
WHERE counter_name = 'Page life expectancy'
AND [object_name] LIKE '%BUFFER MANAGER%';
