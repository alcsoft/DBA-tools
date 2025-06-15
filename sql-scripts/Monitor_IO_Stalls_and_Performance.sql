-- ========================================================
-- SQL Script to Monitor I/O Stalls and Track File I/O Performance
-- This script retrieves I/O performance metrics such as read and write
-- stalls, bytes read/written, and pending I/O requests from SQL Server.
-- It also calculates the size of the files and tracks I/O operations.
-- 
-- Explanation:
-- 1. The script retrieves I/O performance data by querying system views 
--    like sys.dm_io_virtual_file_stats and sys.dm_io_pending_io_requests.
-- 2. It calculates the total I/O stall time during reads and writes, 
--    the number of reads and writes performed, and the amount of data read/written.
-- 3. The script orders the results by I/O stall time to highlight the most 
--    impacted files, providing valuable insights for performance optimization.
-- 4. A second query fetches additional details like the physical file name, 
--    bytes read/written, I/O stall times, and file sizes in MB.
-- 5. It joins the sys.databases and sys.master_files views to get file-specific 
--    information like file name, size, and I/O performance.
--
-- Author: Ennis (alcsoft)
-- ========================================================

-- First query to fetch I/O performance data, including read and write stalls
SELECT 
    DB_NAME(d.database_id) AS [Database],  -- Database name
    d.database_id,                         -- Database ID
    file_id,                               -- File ID
    sample_ms,                             -- Sample time in milliseconds
    GETDATE() AS collect_time,             -- Current time of the query execution
    num_of_reads,                          -- Number of reads performed
    num_of_bytes_read,                     -- Number of bytes read
    io_stall_read_ms,                      -- Total I/O stall time during reads (in ms)
    num_of_writes,                         -- Number of writes performed
    num_of_bytes_written,                  -- Number of bytes written
    io_stall_write_ms,                     -- Total I/O stall time during writes (in ms)
    io_stall,                              -- Total I/O stall time
    size_on_disk_bytes,                    -- File size in bytes
    io_type,                               -- Type of I/O (read/write)
    io_pending_ms_ticks                    -- Time in milliseconds spent on pending I/O
FROM 
    sys.dm_io_virtual_file_stats(NULL, NULL) vfs  -- Fetch virtual file stats
JOIN 
    sys.databases d ON vfs.database_id = d.database_id  -- Join with sys.databases to get database names
LEFT JOIN 
    sys.dm_io_pending_io_requests pior ON vfs.file_handle = pior.io_handle  -- Join to get pending I/O requests
ORDER BY 
    io_stall DESC;  -- Order by I/O stall time to highlight the most impacted files

-- Second query to fetch additional file statistics, including size and I/O operations
SELECT 
    DB_NAME(vfs.DbId) AS DatabaseName,   -- Database name
    mf.name,                              -- File name
    mf.physical_name,                     -- Physical file name
    vfs.BytesRead,                        -- Total bytes read
    vfs.BytesWritten,                     -- Total bytes written
    vfs.IoStallMS,                        -- Total I/O stall in milliseconds
    vfs.IoStallReadMS,                    -- Total I/O stall during reads in milliseconds
    vfs.IoStallWriteMS,                   -- Total I/O stall during writes in milliseconds
    vfs.NumberReads,                      -- Number of read operations
    vfs.NumberWrites,                     -- Number of write operations
    (Size * 8) / 1024 AS Size_MB          -- File size in MB (converted from 8KB pages)
FROM 
    ::fn_virtualfilestats(NULL, NULL) vfs  -- Fetch virtual file stats
INNER JOIN 
    sys.master_files mf ON mf.database_id = vfs.DbId  -- Join with sys.master_files to get file details
    AND mf.FILE_ID = vfs.FileId;  -- Match the file ID for the specific file
