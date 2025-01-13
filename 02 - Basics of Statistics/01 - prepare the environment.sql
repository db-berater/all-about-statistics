/*
	============================================================================
	File:		01 - Preparation of environment.sql

	Summary:	This script removes all existing statistics objects from all
				user tables to make sure the demos will always find a clean
				environment.
				
				THIS SCRIPT IS PART OF THE TRACK:
					Session - All about Statistics

	Date:		October 2024
	Revion:		January 2025

	SQL Server Version: >= 2016
	============================================================================
*/
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

USE ERP_Demo;
GO

/* Variable for the dynamic sql string to remove the statistics */
DECLARE	@stmt	NVARCHAR(4000);

DECLARE c CURSOR LOCAL FORWARD_ONLY READ_ONLY
FOR
	SELECT	'DROP STATISTICS ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name) + '.' + QUOTENAME(st.name)
	FROM	sys.tables AS t
			INNER JOIN sys.schemas AS s
			ON (t.schema_id = s.schema_id)
			INNER JOIN sys.stats AS st
			ON (t.object_id = st.object_id)
	WHERE	t.is_ms_shipped = 0
			AND t.name NOT IN (N'blob_data', N'excluded_wait_types');

OPEN c;

FETCH NEXT FROM c INTO @stmt;
WHILE @@FETCH_STATUS = 0
BEGIN
	RAISERROR ('executing %s', 0, 1, @stmt) WITH NOWAIT;
	EXEC sp_executesql @stmt;

	FETCH NEXT FROM c INTO @stmt;
END

CLOSE c;
DEALLOCATE c;
GO

