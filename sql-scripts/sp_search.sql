-- ========================================================
-- Stored Procedure to Search All Objects in the Database
-- This procedure searches all objects in the database
-- for a specific string in their definitions.
-- Author: Ennis (alcsoft)
-- ========================================================

SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

ALTER PROCEDURE [dbo].[sp_search]
    @text VARCHAR(255)  -- The text to search for in all database objects
AS
BEGIN
    -- Search for the string in all objects' definitions
    SELECT name
    FROM sysobjects
    WHERE id IN (
        SELECT id
        FROM syscomments
        WHERE text LIKE '%' + @text + '%'
    )
    ORDER BY name;
END
