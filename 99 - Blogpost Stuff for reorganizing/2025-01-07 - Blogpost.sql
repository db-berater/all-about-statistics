USE master;
GO

EXEC sp_restore_ERP_demo;
GO

USE ERP_Demo;
GO

EXEC sp_drop_statistics;
GO

/*
	The table dbo.customers contains 1.6 mio rows.
	We create the PRIMARY KEY on the c_custkey attribute
	and a nonclustered index on the c_nationkey attribute
*/
EXEC sp_drop_indexes @table_name = N'ALL';
GO

ALTER TABLE dbo.customers ADD CONSTRAINT pk_customers
PRIMARY KEY CLUSTERED (c_custkey)
WITH (SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE);
GO

CREATE NONCLUSTERED INDEX nix_customers_c_nationkey
ON dbo.customers (c_nationkey)
WITH (SORT_IN_TEMPDB = ON, DATA_COMPRESSION = PAGE);
GO

/*
	Let's have a look to the statistics threshold
	Note:	This function is part of the framework of the demo database
			https://www.db-berater.de/downloads/ERP_DEMO_2012.BAK
*/
SELECT	gsui.statistics_name,
		gsui.rows,
		gsui.modification_counter,
		gsui.required_update_rows,
		gsui.update_counter_percentage
FROM	sys.stats AS s
		CROSS APPLY dbo.get_statistics_update_info(s.object_id, s.stats_id, DEFAULT) AS gsui
WHERE	s.object_id = OBJECT_ID(N'dbo.customers', N'U');
GO

/*
	Let's run the query for a first execution plan with loaded statistics
	TF for detailed logical tree and loading the histogram (3604, 2363) -- 
*/
DBCC TRACEON (3604, 9204, 9292, 9481);
GO  

DECLARE @stmt NVARCHAR(1000) = N'SELECT * FROM dbo.customers WHERE c_custkey = @c_custkey;';
DECLARE @parm NVARCHAR(100) = N'@c_custkey BIGINT';
EXEC sp_executesql @stmt, @parm, 50000;
GO 
 
DECLARE @stmt NVARCHAR(1000) = N'SELECT * FROM dbo.customers WHERE c_nationkey = @c_nationkey;';
DECLARE @parm NVARCHAR(100) = N'@c_nationkey INT';
EXEC sp_executesql @stmt, @parm, '46';
GO

DBCC TRACEOFF (3604, 9204, 9292, 9481);
GO 

/*
	Update dbo.customers to reach the threshold for an
	automatic statistics update.
*/
;WITH m
AS
(
	SELECT MAX(c_custkey)	AS	max_c_custkey
	FROM	dbo.customers
)
UPDATE	s
SET		s.c_custkey = s.c_custkey + m.max_c_custkey
		--, s.c_nationkey = 0
FROM	(
			SELECT TOP (20050)
					c_custkey,
					c_nationkey
			FROM	dbo.customers
			ORDER BY
					c_custkey
		) AS s
		CROSS JOIN m;
GO

/*
	Let's have a look to the statistics threshold
	Note:	This function is part of the framework of the demo database
			https://www.db-berater.de/downloads/ERP_DEMO_2012.BAK
*/
SELECT	gsui.statistics_name,
		gsui.rows,
		gsui.modification_counter,
		gsui.required_update_rows,
		gsui.update_counter_percentage
FROM	sys.stats AS s
		CROSS APPLY dbo.get_statistics_update_info(s.object_id, s.stats_id, DEFAULT) AS gsui
WHERE	s.object_id = OBJECT_ID(N'dbo.customers', N'U');
GO

/*
	Running two queries that use different statistics. Microsoft SQL Server would need
	to update both statistics because they have reached the threshold.

	Traceflags for a deeper inside:

	3604: Enables the output of messages to the client instead of to the error log
	9204: Shows the statistics that are "interesting" for the query optimizer that are loaded
	9292: Shows the statistics that the query optimizer considers "interesting" in the compile phase
	9481: Compiles with the "old" CE. Otherwise 9204 and 9292 will not work!
*/
DBCC TRACEON (3604, 9204, 9292, 9481);
GO 
 
DECLARE @stmt NVARCHAR(1000) = N'SELECT * FROM dbo.customers WHERE c_custkey <= @c_custkey;';
DECLARE @parm NVARCHAR(100) = N'@c_custkey BIGINT';
EXEC sp_executesql @stmt, @parm, 50000;
GO
 
DECLARE @stmt NVARCHAR(1000) = N'SELECT * FROM dbo.customers WHERE c_nationkey = @c_nationkey;';
DECLARE @parm NVARCHAR(100) = N'@c_nationkey INT';
EXEC sp_executesql @stmt, @parm, '46';
GO

DBCC TRACEOFF (3604, 9204, 9292, 9481);
GO

/*
	Let's have a look to the statistics threshold
	Note:	This function is part of the framework of the demo database
			https://www.db-berater.de/downloads/ERP_DEMO_2012.BAK
*/
SELECT	gsui.statistics_name,
		gsui.rows,
		gsui.modification_counter,
		gsui.required_update_rows,
		gsui.update_counter_percentage
FROM	sys.stats AS s
		CROSS APPLY dbo.get_statistics_update_info(s.object_id, s.stats_id, DEFAULT) AS gsui
WHERE	s.object_id = OBJECT_ID(N'dbo.customers', N'U');
GO
 