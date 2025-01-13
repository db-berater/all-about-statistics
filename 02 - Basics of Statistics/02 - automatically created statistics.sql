/*
	============================================================================
	File:		02 - automatically created statistics.sql

	Summary:	demonstration of automatically created statistics when no indexes
				are present.

				USE CASES:
				- DISTINCT
				- JOIN
				- GROUP BY
				- WHERE
				- ORDER BY

				
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

/*
	Check for existing statistics objects for the table dbo.customers
*/
SELECT	gsci.object_id,
		gsci.stats_id,
		gsci.stats_name,
		gsci.auto_created,
		gsci.stat_columns,
		gsci.stat_rows,
		gsci.stat_sampled_rows,
		gsci.sample_quote
FROM	sys.tables AS t
		CROSS APPLY dbo.get_statistics_columns_info(t.name, t.type) AS gsci;
GO

/*
	Now we force SQL Server to create new statistics automatically.
	The option "AUTO CREATE STATISTICS" must be enabled for the database!
*/
SELECT	name,
		is_auto_create_stats_on
FROM	sys.databases WHERE database_id = DB_ID();
GO


/*
	What happens if we use a DISTINCT operation on the table?
*/
DROP TABLE IF EXISTS #temp_table;
GO

EXEC dbo.sp_drop_statistics;
GO

SELECT	DISTINCT
		*
INTO	#temp_table
FROM	dbo.customers;
GO

SELECT	gsci.object_id,
		gsci.stats_id,
		gsci.stats_name,
		gsci.auto_created,
		gsci.stat_columns,
		gsci.stat_rows,
		gsci.stat_sampled_rows,
		gsci.sample_quote
FROM	sys.tables AS t
		CROSS APPLY dbo.get_statistics_columns_info(t.name, t.type) AS gsci
ORDER BY
		t.name,
		stats_id;
GO


/*
	What happens if we use a JOIN operation on another table?
*/
DROP TABLE IF EXISTS #temp_table;
GO

EXEC sp_drop_statistics;
GO

SELECT	*
INTO	#temp_table
FROM	dbo.customers AS c
		INNER JOIN dbo.nations AS n
		ON (c.c_nationkey = n.n_nationkey)
GO

SELECT	gsci.object_id,
		gsci.stats_id,
		gsci.stats_name,
		gsci.auto_created,
		gsci.stat_columns,
		gsci.stat_rows,
		gsci.stat_sampled_rows,
		gsci.sample_quote
FROM	sys.tables AS t
		CROSS APPLY dbo.get_statistics_columns_info(t.name, t.type) AS gsci
ORDER BY
		t.name,
		stats_id;
GO


/*
	What about aggregations => GROUP BY?
*/
EXEC sp_drop_statistics;
GO

SELECT	c_mktsegment,
		COUNT_BIG(*)
FROM	dbo.customers
GROUP BY
		c_mktsegment;
GO

SELECT	gsci.object_id,
		gsci.stats_id,
		gsci.stats_name,
		gsci.auto_created,
		gsci.stat_columns,
		gsci.stat_rows,
		gsci.stat_sampled_rows,
		gsci.sample_quote
FROM	sys.tables AS t
		CROSS APPLY dbo.get_statistics_columns_info(t.name, t.type) AS gsci
ORDER BY
		t.name,
		stats_id;
GO


/*
	or a WHERE clause to filter the data?
*/
EXEC sp_drop_statistics;
GO

SELECT	*
FROM	dbo.customers
WHERE	c_nationkey = 46;
GO

SELECT	gsci.object_id,
		gsci.stats_id,
		gsci.stats_name,
		gsci.auto_created,
		gsci.stat_columns,
		gsci.stat_rows,
		gsci.stat_sampled_rows,
		gsci.sample_quote
FROM	sys.tables AS t
		CROSS APPLY dbo.get_statistics_columns_info(t.name, t.type) AS gsci
ORDER BY
		t.name,
		stats_id;
GO


EXEC sp_drop_statistics;
GO

/*
	or an ORDER BY to sort the data?
*/
DROP TABLE IF EXISTS #temp_table;
GO

SELECT	*
INTO	#temp_table
FROM	dbo.customers
ORDER BY
		c_custkey;
GO

SELECT	gsci.object_id,
		gsci.stats_id,
		gsci.stats_name,
		gsci.auto_created,
		gsci.stat_columns,
		gsci.stat_rows,
		gsci.stat_sampled_rows,
		gsci.sample_quote
FROM	sys.tables AS t
		CROSS APPLY dbo.get_statistics_columns_info(t.name, t.type) AS gsci
ORDER BY
		t.name,
		stats_id;
GO
