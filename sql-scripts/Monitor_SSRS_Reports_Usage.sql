-- ========================================================
-- SQL Script to Query Report Server for Usage of Specific Tables, Views, or Data Sources
-- This script helps DBAs find reports that are using a specific table, view, stored procedure,
-- function, or data source. It also allows you to list the datasets, data sources, 
-- and the most frequently used reports in SQL Server Reporting Services (SSRS).
-- Author: Ennis (alcsoft)
-- ========================================================

-- ========================================================
-- Key Features:
-- 1. **Find Reports Using a Specific Table/Function**:
--    - Searches for reports that contain a specified string (like a table or function) in their query.
--    - Uses XML parsing to extract the relevant data from the `content` field in the `ReportServer.dbo.Catalog` table.
--
-- 2. **List Data Sources and Datasets**:
--    - Retrieves the names of data sources and datasets used by each report.
--    - Provides insight into which data sources are associated with each report and the datasets in use.
--
-- 3. **Track Report Usage**:
--    - Identifies the most frequently used reports based on their execution count.
--    - Joins the `ExecutionLog` and `Catalog` tables to calculate execution frequency.
--
-- 4. **Reports Executed in the Last 30 Days**:
--    - Returns a list of reports executed in the past 30 days, filtering for successful executions (`StatusCode = 1`).
--    - Provides the number of times each report was run during that period.
-- ========================================================

-- ========================================================
-- Find Reports Using a Specific Table, View, Sproc, Function, or Data Source
-- This query searches for reports in the ReportServer database that use a specific string 
-- (e.g., table name, function name, or data source) in their query.
-- ========================================================

DECLARE @StringToSearch VARCHAR(100)
SELECT @StringToSearch = '%Customer%'  -- Replace with the string you want to search for

;WITH XMLNAMESPACES (
    DEFAULT 'http://schemas.microsoft.com/sqlserver/reporting/2005/01/reportdefinition',
    'http://schemas.microsoft.com/SQLServer/reporting/reportdesigner' AS rd
)
SELECT
    name AS ReportName,                      -- Report name
    x.value('CommandType[1]', 'VARCHAR(50)') AS CommandType,  -- Command type (e.g., SQL, stored procedure)
    x.value('CommandText[1]', 'VARCHAR(MAX)') AS CommandText,  -- SQL or command text
    x.value('DataSourceName[1]', 'VARCHAR(50)') AS DataSource -- Data source name used in the report
FROM (
    SELECT name,
        CAST(CAST(content AS VARBINARY(MAX)) AS XML) AS reportXML
    FROM ReportServer.dbo.Catalog
    WHERE content IS NOT NULL
      AND type = 2  -- Only reports
) a
CROSS APPLY reportXML.nodes('/Report/DataSets/DataSet/Query') dataquery(x)
WHERE x.value('CommandText[1]', 'VARCHAR(MAX)') LIKE @StringToSearch;  -- Search command text for the string

-- ========================================================
-- List the Data Sources and Datasets Used by the Reports
-- This query retrieves the data source and dataset names used by reports.
-- ========================================================

;WITH XMLNAMESPACES (
    DEFAULT 'http://schemas.microsoft.com/sqlserver/reporting/2005/01/reportdefinition',
    'http://schemas.microsoft.com/SQLServer/reporting/reportdesigner' AS rd
)
SELECT
    name AS ReportName,                          -- Report name
    q.value('@Name[1]', 'VARCHAR(100)') AS DataSetName,  -- Dataset name
    x.value('DataSourceName[1]', 'VARCHAR(50)') AS DataSourceName -- Data source name used
FROM (
    SELECT name,
        CAST(CAST(content AS VARBINARY(MAX)) AS XML) AS reportXML
    FROM ReportServer.dbo.Catalog
    WHERE Type = 2  -- Only reports
) a
CROSS APPLY reportXML.nodes('/Report/DataSets/DataSet') d(q)
CROSS APPLY q.nodes('Query') r(x);

-- ========================================================
-- Get the Most Frequently Used Reports Based on Execution Count
-- This query counts how many times each report has been executed and orders the reports by execution frequency.
-- ========================================================

SELECT 
    c.Path,                                 -- Report path
    c.Name,                                 -- Report name
    COUNT(1) AS cnt                         -- Count of executions
FROM ReportServer.dbo.ExecutionLog e 
JOIN ReportServer.dbo.Catalog c ON e.ReportID = c.ItemID
GROUP BY c.Path, c.Name
ORDER BY cnt DESC;  -- Order reports by execution frequency

-- ========================================================
-- Get Reports that Have Run in the Last 30 Days
-- This query retrieves the reports that were executed in the past 30 days.
-- It joins the ExecutionLogs with the Reports table and filters by successful executions (status code = 1).
-- ========================================================

DECLARE @pMinDate DATETIME, @pMaxDate DATETIME;
SET @pMinDate = DATEADD(MONTH, -1, GETDATE());  -- Set start date to 1 month ago
SET @pMaxDate = DATEADD(DAY, -1, GETDATE());   -- Set end date to 1 day ago

SELECT
    Reports.Name,                                 -- Report name
    CONVERT(DATE, ExecutionLogs.TimeStart) AS RunningDate,  -- Date the report was run
    COUNT(*) AS #TimesRun                          -- Number of times the report ran
FROM ExecutionLogs
INNER JOIN Reports ON ExecutionLogs.ReportKey = Reports.ReportKey
WHERE 
    (ExecutionLogs.TimeStart BETWEEN @pMinDate AND @pMaxDate)  -- Filter by last 30 days
    AND (ExecutionLogs.StatusCode = 1)  -- Successful executions only
GROUP BY Reports.Name, CONVERT(DATE, ExecutionLogs.TimeStart)
ORDER BY CONVERT(DATE, ExecutionLogs.TimeStart) DESC;  -- Order by date executed
