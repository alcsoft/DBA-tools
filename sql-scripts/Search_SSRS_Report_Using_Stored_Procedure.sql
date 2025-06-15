-- ========================================================
-- Search SSRS Reports for a Specific String
-- This query connects to the SSRS report database and searches 
-- the Report Server Catalog for reports that contain a specific 
-- stored procedure name or string in their RDL (Report Definition Language).
-- The content of the reports is stored in the `content` column as a binary type,
-- which is cast to `VARCHAR(MAX)` and then to `XML` for searching.
-- Author: Ennis (alcsoft)
-- ========================================================

-- Query to search for a specific string in the SSRS Report Definition Language (RDL)
SELECT 
    name,                              -- Report name from the Catalog table
    path,                              -- Path to the report in the Report Server
    CAST(CAST(CAST(content AS VARBINARY(MAX)) AS VARCHAR(MAX)) AS XML) AS RDL -- Convert the content from binary to XML format for easier searching
FROM 
    Catalog WITH (NOLOCK)              -- Query the Catalog table in SSRS report database
WHERE 
    CAST(CAST(content AS VARBINARY(MAX)) AS VARCHAR(MAX)) LIKE '%usp_h_spp_015_m%' -- Search for the specific string in the RDL content
