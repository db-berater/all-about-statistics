/*
	============================================================================
	File:		07 - parameterized - FULL - 500 rows.sql

	Summary:	this - complex - demo shows the situation of statistics update
				with the following condition(s):

				- <= 500 rows
				- parameterized query
				- FULL plan optimization

				NOTE: This is only relevant for auto_update_stats!

				THIS SCRIPT IS PART OF THE TRACK:
					Session - All about Statistics

	Date:		October 2024
	Revion:		January 2025

	SQL Server Version: >= 2016
	============================================================================
*/
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

USE ERP_Demo;
GO

/*
	We make sure we don't have any objects from the previous demo!
*/
EXEC sp_drop_indexes @table_name = N'ALL', @check_only = 0;
EXEC sp_drop_statistics @table_name = N'ALL', @check_only = 0;
GO

/*
	Let's create a new table in a schema called [demo]
*/
IF SCHEMA_ID(N'demo') IS NULL
	EXEC sp_executesql N'CREATE SCHEMA [demo] AUTHORIZATION dbo;';
	GO

DROP TABLE IF EXISTS demo.customers;
GO

/*
	Now we insert 500 rows into the table demo.customers
*/
SELECT	TOP (500)
		c_custkey,
		c_mktsegment,
		c_nationkey,
		c_name,
		c_address,
		c_phone,
		c_acctbal,
		c_comment
INTO	demo.customers
FROM	dbo.customers
ORDER BY
		c_custkey;
GO

/*
	Create the statistics objects by using DISTINT.
	Than we get for each column a statistics object!
*/
SELECT	DISTINCT
		c_custkey,
		c_mktsegment,
		c_nationkey,
		c_name,
		c_address,
		c_phone,
		c_acctbal,
		c_comment
FROM	demo.customers;
GO

/*
	How many row updates must we have to trigger an auto_update_stats

    The used function is part of the framework of the demo database ERP_Demo.
    Download: https://www.db-berater.de/downloads/ERP_DEMO_2012.BAK
*/
SELECT	gsui.stats_id,
		gsui.statistics_name,
		gsui.rows,
		gsui.modification_counter,
		gsui.required_update_rows,
		gsui.update_counter_percentage
FROM	sys.tables AS t
		INNER JOIN sys.stats AS s
		ON (t.object_id = s.object_id)
		CROSS APPLY dbo.get_statistics_update_info(t.object_id, s.stats_id, 1) AS gsui
WHERE	t.object_id = OBJECT_ID(N'demo.customers', N'U');
GO

/*
	Let's run 400 modifications on c_nationkey and check the modification counters
*/
;WITH l
AS
(
	SELECT	ROW_NUMBER() OVER (ORDER BY c_custkey) AS rn,
			c_custkey
	FROM	demo.customers
)
UPDATE	dc
SET		dc.c_nationkey = 0
FROM	demo.customers AS dc
		INNER JOIN l
		ON (dc.c_custkey = l.c_custkey)
WHERE	l.rn <= 400;
GO

/*
	How many rows changes have been occured so far?

    The used function is part of the framework of the demo database ERP_Demo.
    Download: https://www.db-berater.de/downloads/ERP_DEMO_2012.BAK
*/
SELECT	gsui.stats_id,
		gsui.statistics_name,
		gsui.rows,
		gsui.modification_counter,
		gsui.required_update_rows,
		gsui.update_counter_percentage
FROM	sys.tables AS t
		INNER JOIN sys.stats AS s
		ON (t.object_id = s.object_id)
		CROSS APPLY dbo.get_statistics_update_info(t.object_id, s.stats_id, 1) AS gsui
WHERE	t.object_id = OBJECT_ID(N'demo.customers', N'U');
GO

/*
	This query will not trigger an update of the statistisc because
	the threshold is not reached!
*/
DECLARE	@stmt	NVARCHAR(1024) = N'
SELECT	c_custkey,
		c_mktsegment,
		c_nationkey,
		c_name,
		c_address,
		c_phone,
		c_acctbal,
		c_comment
FROM	demo.customers
WHERE	c_nationkey = @c_nationkey
		AND 1 = (SELECT 1)
ORDER BY
		c_custkey
OPTION	(
			QUERYTRACEON 3604,
			QUERYTRACEON 2363
		);';

EXEC sp_executesql @stmt, N'@c_nationkey INT', 0;
GO


/*
	Did the query trigger the update of the statistics?

    The used function is part of the framework of the demo database ERP_Demo.
    Download: https://www.db-berater.de/downloads/ERP_DEMO_2012.BAK
*/
SELECT	gsui.stats_id,
		gsui.statistics_name,
		gsui.rows,
		gsui.modification_counter,
		gsui.required_update_rows,
		gsui.update_counter_percentage
FROM	sys.tables AS t
		INNER JOIN sys.stats AS s
		ON (t.object_id = s.object_id)
		CROSS APPLY dbo.get_statistics_update_info(t.object_id, s.stats_id, 1) AS gsui
WHERE	t.object_id = OBJECT_ID(N'demo.customers', N'U');
GO

/*
	Let's run another 100 modifications on c_nationkey to reach the threshold
*/
;WITH l
AS
(
	SELECT	ROW_NUMBER() OVER (ORDER BY c_custkey) AS rn,
			c_custkey
	FROM	demo.customers
)
UPDATE	dc
SET		dc.c_nationkey = 99
FROM	demo.customers AS dc
		INNER JOIN l
		ON (dc.c_custkey = l.c_custkey)
WHERE	l.rn between 401 AND 500
GO

/*
	How many rows changes have been occured so far?

    The used function is part of the framework of the demo database ERP_Demo.
    Download: https://www.db-berater.de/downloads/ERP_DEMO_2012.BAK
*/
SELECT	gsui.stats_id,
		gsui.statistics_name,
		gsui.rows,
		gsui.modification_counter,
		gsui.required_update_rows,
		gsui.update_counter_percentage
FROM	sys.tables AS t
		INNER JOIN sys.stats AS s
		ON (t.object_id = s.object_id)
		CROSS APPLY dbo.get_statistics_update_info(t.object_id, s.stats_id, 1) AS gsui
WHERE	t.object_id = OBJECT_ID(N'demo.customers', N'U');
GO

/*
	Now the update of the statistics will be triggered because...
	- we reached the threshold
	- the optimization level is FULL 
*/
DECLARE	@stmt	NVARCHAR(1024) = N'
SELECT	c_custkey,
		c_mktsegment,
		c_nationkey,
		c_name,
		c_address,
		c_phone,
		c_acctbal,
		c_comment
FROM	demo.customers
WHERE	c_nationkey = @c_nationkey
		AND 1 = (SELECT 1)
ORDER BY
		c_custkey
OPTION	(
			QUERYTRACEON 3604,
			QUERYTRACEON 2363
		);';

EXEC sp_executesql @stmt, N'@c_nationkey INT', 99;
GO


SELECT	gsui.stats_id,
		gsui.statistics_name,
		gsui.rows,
		gsui.modification_counter,
		gsui.required_update_rows,
		gsui.update_counter_percentage
FROM	sys.tables AS t
		INNER JOIN sys.stats AS s
		ON (t.object_id = s.object_id)
		CROSS APPLY dbo.get_statistics_update_info(t.object_id, s.stats_id, 1) AS gsui
WHERE	t.object_id = OBJECT_ID(N'demo.customers', N'U');
GO