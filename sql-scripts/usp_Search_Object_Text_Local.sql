-- ========================================================
-- Stored Procedure to Search Text Within Database Objects
-- This procedure searches for a specific string in all 
-- objects in a specified database (including syscomments and sysobjects).
-- Author: Ennis (alcsoft)
-- ========================================================

USE [dbCL_IDS];
GO

SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO

CREATE PROCEDURE [dbo].[usp_Search_Object_Text_Local]
    @Db_Name VARCHAR(100),         -- The name of the database to search in
    @Search_Text VARCHAR(1000)      -- The text to search for within the database objects
AS
BEGIN
    SET NOCOUNT ON;

    -- Prepare the search text for SQL LIKE query
    SET @Search_Text = '''%' + @Search_Text + '%''';

    -- Declare a variable to hold the dynamic SQL
    DECLARE @SQL VARCHAR(8000);

    -- Construct the dynamic SQL to search the text within the syscomments and sysobjects tables
    SET @SQL = '
    DECLARE @numbers TABLE (Num INT NOT NULL PRIMARY KEY CLUSTERED);
    DECLARE @i INT;
    SELECT @i = 1;
    WHILE @i <= 10000
    BEGIN
        INSERT INTO @numbers (Num) VALUES (@i);
        SELECT @i = @i + 1;
    END;

    SELECT DISTINCT 
        @@SERVERNAME AS SERVERNAME,
        ''' + @Db_Name + ''' AS [DATABASE_NAME],
        O.Name, O.Type
    FROM (
        SELECT 
            Id,
            CAST(COALESCE(MIN(CASE WHEN sc.colId = Num - 1 THEN sc.text END), '''') AS VARCHAR(8000)) + 
            CAST(COALESCE(MIN(CASE WHEN sc.colId = Num THEN sc.text END), '''') AS VARCHAR(8000)) AS [text]
        FROM ' + @Db_Name + '.dbo.syscomments SC (NOLOCK)
        INNER JOIN @numbers N ON N.Num = SC.colid OR N.num - 1 = SC.colid
        WHERE N.Num < 30
        GROUP BY id, Num
    ) C
    INNER JOIN ' + @Db_Name + '.dbo.sysobjects O (NOLOCK) ON C.id = O.Id
    WHERE C.TEXT LIKE ' + @Search_Text;

    -- Execute the dynamic SQL
    EXEC (@SQL);
END
