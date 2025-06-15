-- ========================================================
-- Script to Calculate Space Usage for All User Tables
-- This script calculates the space usage for all user tables in the database.
-- It gathers information on the reserved space, data space, index space, and unused space.
-- It then presents the top 10 tables based on reserved space.
-- Author: Ennis (alcsoft)
-- ========================================================

DECLARE @id INT;
DECLARE @type CHAR(2);
DECLARE @pages INT;
DECLARE @dbname SYSNAME;
DECLARE @dbsize DECIMAL(15, 0);
DECLARE @bytesperpage DECIMAL(15, 0);
DECLARE @pagesperMB DECIMAL(15, 0);

-- Create a temporary table to store space usage data for each table
CREATE TABLE #spt_space (
    objid INT NULL,
    rows INT NULL,
    reserved DECIMAL(15) NULL,
    data DECIMAL(15) NULL,
    indexp DECIMAL(15) NULL,
    unused DECIMAL(15) NULL
);

SET NOCOUNT ON;

-- Create a cursor to loop through all user tables in the database
DECLARE c_tables CURSOR FOR
    SELECT id
    FROM sysobjects
    WHERE xtype = 'U';

OPEN c_tables;
FETCH NEXT FROM c_tables INTO @id;

-- Loop through each user table and calculate space usage
WHILE @@FETCH_STATUS = 0
BEGIN
    -- Code from sp_spaceused: Calculate reserved space for the table
    INSERT INTO #spt_space (objid, reserved)
    SELECT @id, SUM(reserved)
    FROM sysindexes
    WHERE indid IN (0, 1, 255) AND id = @id;

    -- Calculate pages used by the table (data pages + index pages)
    SELECT @pages = SUM(dpages)
    FROM sysindexes
    WHERE indid < 2 AND id = @id;

    SELECT @pages = @pages + ISNULL(SUM(used), 0)
    FROM sysindexes
    WHERE indid = 255 AND id = @id;

    -- Update data column with the calculated pages
    UPDATE #spt_space
    SET data = @pages
    WHERE objid = @id;

    -- Calculate index size: sum(used) for index pages
    UPDATE #spt_space
    SET indexp = (SELECT SUM(used)
                  FROM sysindexes
                  WHERE indid IN (0, 1, 255) AND id = @id) - data
    WHERE objid = @id;

    -- Calculate unused space: reserved - used for the table
    UPDATE #spt_space
    SET unused = reserved - (SELECT SUM(used)
                             FROM sysindexes
                             WHERE indid IN (0, 1, 255) AND id = @id)
    WHERE objid = @id;

    -- Get row count for the table
    UPDATE #spt_space
    SET rows = i.rows
    FROM sysindexes i
    WHERE i.indid < 2 AND i.id = @id AND objid = @id;

    FETCH NEXT FROM c_tables INTO @id;
END

-- Query the top 10 tables based on reserved space
SELECT TOP 10 
    DB_Name() AS DbName,
    TableName = (SELECT LEFT(name, 60) FROM sysobjects WHERE id = objid),
    Rows = CONVERT(CHAR(11), rows),
    ReservedKB = LTRIM(STR(reserved * d.low / 1024.0, 15, 0)),
    DataKB = LTRIM(STR(data * d.low / 1024.0, 15, 0)),
    IndexSizeKB = LTRIM(STR(indexp * d.low / 1024.0, 15, 0)),
    UnusedKB = LTRIM(STR(unused * d.low / 1024.0, 15, 0)),
    ReservedGB = LTRIM(STR(reserved * d.low / POWER(1024.0, 3), 15, 2))
FROM #spt_space
JOIN master.dbo.spt_values d ON d.number = 1 AND d.type = 'E'
ORDER BY reserved DESC;

-- Clean up temporary table
DROP TABLE #spt_space;

-- Close and deallocate the cursor
CLOSE c_tables;
DEALLOCATE c_tables;
