/*
	============================================================================
	File:		03 - index created statistics.sql

	Summary:	demonstration of statistics when an index gets created.

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

EXEC dbo.sp_drop_indexes @table_name = N'ALL', @check_only = 0;
EXEC dbo.sp_drop_statistics;
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
	Now we create all required indexes on the dbo.customers table to see,
	what statistics have been created!
*/
EXEC sp_create_indexes_customers;
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
		CROSS APPLY dbo.get_statistics_columns_info(t.name, t.type) AS gsci;
GO

/*
	As long as we run queries against indexed attributes no
	automatically generated statistics will be created
*/
SELECT	*
FROM	dbo.customers
WHERE	c_custkey = 10;
GO

SELECT	*
FROM	dbo.customers
WHERE	c_custkey = 10
		AND c_nationkey = 5;
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
		CROSS APPLY dbo.get_statistics_columns_info(t.name, t.type) AS gsci;
GO

/*
	But when we query a column with no index and no statistics
	the statistics object is created automatically
*/
SELECT	*
FROM	dbo.customers
WHERE	c_name = 'Uwe Ricken';
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
		CROSS APPLY dbo.get_statistics_columns_info(t.name, t.type) AS gsci;
GO

/*
	NOTE: If you create a new index on an attribute with an existing
		  statistics object, the automatically created object will
		  NOT be deleted!
*/
CREATE NONCLUSTERED INDEX nix_customers_c_name
ON dbo.customers (c_name)
WITH (SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE);
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
		CROSS APPLY dbo.get_statistics_columns_info(t.name, t.type) AS gsci;
GO

/*
	Clean the environment
*/
EXEC sp_drop_indexes @table_name = N'ALL', @check_only = 0;
EXEC sp_drop_statistics @table_name = N'ALL', @check_only = 0;
GO

