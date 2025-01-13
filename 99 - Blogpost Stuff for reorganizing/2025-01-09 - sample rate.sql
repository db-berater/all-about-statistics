--USE master;
--GO

--EXEC sp_create_demo_db;
--GO

SET NOCOUNT ON;
GO

USE demo_db;
GO

DROP TABLE IF EXISTS dbo.customers;
DROP TABLE IF EXISTS dbo.sample_rate_measures;
GO

SELECT	CAST(0.0 AS NUMERIC(10, 2))	AS	size_mb,
		*
INTO	dbo.sample_rate_measures
FROM	ERP_Demo.dbo.get_statistics_columns_info(N'ERP_Demo.dbo.customers', N'U')
WHERE	1 = 0;
GO

SELECT	*
INTO	dbo.customers
FROM	ERP_Demo.dbo.customers
WHERE	1 = 0;
GO

DECLARE	@num_rows		INT = 10000;
DECLARE	@num_interval	INT = 5000;
DECLARE	@t TABLE (nums INT);

WHILE @num_rows <= 1000000
BEGIN
	/* We truncate the table */
	RAISERROR ('inserting %d rows into dbo.customers', 0, 1, @num_rows) WITH NOWAIT;
	TRUNCATE TABLE dbo.customers;

	/* Now we insert @num_rows into the table */
	INSERT INTO dbo.customers WITH (TABLOCK)
	SELECT	TOP (@num_rows) *
	FROM	ERP_Demo.dbo.customers
	ORDER BY
			c_custkey;

	/* Drop all stats */
	EXEC dbo.sp_drop_statistics;

	/* and run a query on c_nationkey */
	INSERT INTO @t(nums)
	SELECT	COUNT(*)
	FROM	dbo.customers
	WHERE	c_nationkey  = 46;

	/* now we save the stats information in the staging table */
	INSERT INTO dbo.sample_rate_measures
	SELECT	(SELECT	CAST(COUNT_BIG(*) AS NUMERIC(10, 2)) / 128.0 FROM	sys.dm_db_database_page_allocations(DB_ID(), OBJECT_ID(N'dbo.customers'), NULL, NULL, N'LIMITED')),
			*
	FROM	dbo.get_statistics_columns_info(N'dbo.customers', N'U');

	/* next turn */
	SET	@num_rows += @num_interval;
END
GO