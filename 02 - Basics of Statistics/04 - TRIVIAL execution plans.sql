/*
	============================================================================
	File:		04 - TRIVIAL execution plans.sql

	Summary:	this - complex - demo shows the situation of statistics update
				with the following condition(s):

				- AdHoc queries
				- TRIVIAL optimization level

				NOTE: This is only relevant for auto_update_stats!

				THIS SCRIPT IS PART OF THE TRACK:
					Session - All about Statistics

	Date:		October 2024
	Revion:		January 2025

	SQL Server Version: >= 2016
	============================================================================
*/
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
ALTER DATABASE [ERP_Demo] SET QUERY_STORE
(
	OPERATION_MODE = READ_WRITE,
	QUERY_CAPTURE_MODE = ALL
);
ALTER DATABASE [ERP_Demo] SET QUERY_STORE CLEAR
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

USE ERP_Demo;
GO

/*
	We make sure we don't have any objects from the previous demo!
*/
EXEC dbo.sp_drop_indexes @table_name = N'ALL', @check_only = 0;
EXEC dbo.sp_drop_statistics @table_name = N'ALL', @check_only = 0;
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
	Now we insert 100,000 rows into the table demo.customers
*/
SELECT	TOP (100000)
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
	Create the statistics objects by using DISTINCT.
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
	SQL Server uses a SAMPLE rate due to the size of the table, but for the demonstration
	we want to generate 100% accurate statistics.
*/
UPDATE STATISTICS demo.customers WITH FULLSCAN, ALL;
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

/* How are the data from c_nationkey distributed? */
SELECT	step_number,
		range_high_key,
		range_rows,
		equal_rows,
		distinct_range_rows,
		average_range_rows
FROM	sys.dm_db_stats_histogram
		(
			OBJECT_ID(N'demo.customers', N'U'),
			4
		);
GO

/*
	Let's run the query the first time to have a valid plan in the cache!
*/
DBCC FREEPROCCACHE;
GO

DBCC TRACEON (3604, 2363);
GO

SELECT	c_custkey,
		c_mktsegment,
		c_nationkey,
		c_name,
		c_address,
		c_phone,
		c_acctbal,
		c_comment
FROM	demo.customers
WHERE	c_nationkey = 0
ORDER BY
		c_custkey;
GO

SELECT	c_custkey,
		c_mktsegment,
		c_nationkey,
		c_name,
		c_address,
		c_phone,
		c_acctbal,
		c_comment
FROM	demo.customers
WHERE	c_nationkey = 1
ORDER BY
		c_custkey;
GO

DBCC TRACEOFF (3604, 2363);
GO

/*
	Get an inside into the cached plans!
*/
SELECT	decp.plan_handle,
		decp.usecounts,
		decp.cacheobjtype,
		decp.objtype,
		decp.size_in_bytes,
		dest.[text],
		deqp.query_plan
FROM	sys.dm_exec_cached_plans AS decp
		OUTER APPLY sys.dm_exec_sql_text (decp.plan_handle) AS dest
		OUTER APPLY sys.dm_exec_query_plan (decp.plan_handle) AS deqp
WHERE	dest.[text] NOT LIKE '%dm_exec_cached_plans%'
		AND dest.text NOT LIKE N'%dbo.get_statistics_update_info%'
		AND dest.text NOT LIKE N'%UPDATE%'
		AND dest.[text] LIKE '%SELECT%customers%'
ORDER BY 
		decp.usecounts ASC;
GO

/*
	Let's run 10,000 modifications on c_nationkey and check the modification counters
*/
;WITH l
AS
(
	SELECT	ROW_NUMBER() OVER (ORDER BY c_custkey) AS rn,
			c_custkey
	FROM	demo.customers
)
UPDATE	dc
SET		dc.c_nationkey = CASE WHEN rn % 1000 = 0
							  THEN 0
							  ELSE 99
						 END
FROM	demo.customers AS dc
		INNER JOIN l
		ON (dc.c_custkey = l.c_custkey)
WHERE	l.rn <= 10000;
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
	Now the threshold for statistics update has reached!
	Will SQL Server update the statistics object?
*/
DBCC TRACEON (3604, 2363);
GO

SELECT	c_custkey,
		c_mktsegment,
		c_nationkey,
		c_name,
		c_address,
		c_phone,
		c_acctbal,
		c_comment
FROM	demo.customers
WHERE	c_nationkey = 0
ORDER BY
		c_custkey;
GO

DBCC TRACEOFF (3604, 2363);
GO

SELECT	CP.usecounts,
		CP.cacheobjtype,
		CP.objtype,
		CP.size_in_bytes,
		ST.[text],
		QP.query_plan
FROM	sys.dm_exec_cached_plans AS CP
		OUTER APPLY sys.dm_exec_sql_text (CP.plan_handle) AS ST
		OUTER APPLY sys.dm_exec_query_plan (CP.plan_handle) AS QP
WHERE	ST.[text] NOT LIKE '%dm_exec_cached_plans%'
		AND st.text NOT LIKE N'%dbo.get_statistics_update_info%'
		AND st.text NOT LIKE N'%UPDATE%'
		AND ST.[text] LIKE '%SELECT%customers%'
ORDER BY 
		CP.usecounts ASC;
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

/* How are the data from c_nationkey distributed? */
SELECT	step_number,
		range_high_key,
		range_rows,
		equal_rows,
		distinct_range_rows,
		average_range_rows
FROM	sys.dm_db_stats_histogram
		(
			OBJECT_ID(N'demo.customers', N'U'),
			4
		);
GO

/*
	But when the query text changes (AdHoc) a new execution plan will be generated
	The update of the statistics are triggered!
*/
DBCC TRACEON (3604, 2363);
GO

SELECT	c_custkey,
		c_mktsegment,
		c_nationkey,
		c_name,
		c_address,
		c_phone,
		c_acctbal,
		c_comment
FROM	demo.customers
WHERE	c_nationkey = 99
ORDER BY
		c_custkey
GO

DBCC TRACEOFF (3604, 2363);
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