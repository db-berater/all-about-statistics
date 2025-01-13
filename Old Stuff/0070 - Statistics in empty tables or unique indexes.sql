/*============================================================================
	File:		0060 - Statistics in empty tables.sql

	Summary:	This script creates a temporary table and a table variable
				with the same amount and quality of data and compares the
				execution plans

				THIS SCRIPT IS PART OF THE TRACK: "SQL Server Statistics"

	Attention:	This script is designed for Microsoft SQL Server >= 2014.
				To make the usage of statistics visible in SQL Server <= 2012
				use the following traceflags:

				DBCC TRACEON (3604, 9204, 9292, 8666);

	Date:		November 2016

	SQL Server Version: 2014 / 2016 / 2017
------------------------------------------------------------------------------
	Written by Uwe Ricken, db Berater GmbH

	This script is intended only as a supplement to demos and lectures
	given by Uwe Ricken.  
  
	THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
	ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
	TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
	PARTICULAR PURPOSE.
============================================================================*/
USE demo_db;
GO

-- Prepare an empty table
EXEC dbo.PrepareWorkbench
	@create_table = 1,
    @fill_table = 0;
	GO

-- create a unique clustered index on message_id!
CREATE UNIQUE CLUSTERED INDEX cuix_messages_message_Id ON dbo.messages (message_id);
GO

-- create a nonclustered index on severity
CREATE NONCLUSTERED INDEX nix_messages_severity ON dbo.messages (severity);
GO

-- what statistics do we have in the table?
SELECT	S.name,
		P.*
FROM	sys.stats AS S
		CROSS APPLY sys.dm_db_stats_properties
		(
			S.object_id,
			S.stats_id
		) AS P
WHERE	S.object_id = OBJECT_ID(N'dbo.messages', N'U');
GO

-- now we run a prepared statement againt the EMPTY table!
DECLARE	@stmt NVARCHAR(512) = N'SELECT * FROM dbo.messages WHERE message_id = @message_id;';
DECLARE @vars NVARCHAR(32)  = N'@message_id INT';
EXEC sp_executesql @stmt, @vars, 101;
GO

DECLARE	@stmt NVARCHAR(512) = N'SELECT * FROM dbo.messages WHERE severity = @severity;';
DECLARE @vars NVARCHAR(32)  = N'@severity TINYINT';
EXEC sp_executesql @stmt, @vars, 16;
GO

SELECT	S.name,
		P.*
FROM	sys.stats AS S
		CROSS APPLY sys.dm_db_stats_properties
		(
			S.object_id,
			S.stats_id
		) AS P
WHERE	S.object_id = OBJECT_ID(N'dbo.messages', N'U');
GO

-- After the query has been executed we load data into the table...
INSERT INTO dbo.messages WITH (TABLOCK)
(message_id, language_id, severity, is_event_logged, [text])
SELECT	M.message_id, M.language_id, M.severity, M.is_event_logged, M.[text]
FROM	sys.messages AS M
WHERE	M.language_id = 1033;
GO

SELECT	S.name,
		P.*
FROM	sys.stats AS S
		CROSS APPLY sys.dm_db_stats_properties
		(
			S.object_id,
			S.stats_id
		) AS P
WHERE	S.object_id = OBJECT_ID(N'dbo.messages', N'U');
GO

-- now we run a prepared statement againt the FULL table!
DECLARE	@stmt NVARCHAR(512) = N'SELECT * FROM dbo.messages WHERE message_id = @message_id;';
DECLARE @vars NVARCHAR(32)  = N'@message_id INT';
EXEC sp_executesql @stmt, @vars, 101;
GO

DECLARE	@stmt NVARCHAR(512) = N'SELECT * FROM dbo.messages WHERE severity = @severity;';
DECLARE @vars NVARCHAR(32)  = N'@severity TINYINT';
EXEC sp_executesql @stmt, @vars, 16;
GO

SELECT	S.name,
		P.*
FROM	sys.stats AS S
		CROSS APPLY sys.dm_db_stats_properties
		(
			S.object_id,
			S.stats_id
		) AS P
WHERE	S.object_id = OBJECT_ID(N'dbo.messages', N'U');
GO

-- now we repeat the whole scenario with a look behind the scenes...
DBCC FREEPROCCACHE;
GO

EXEC dbo.PrepareWorkbench
	@create_table = 1,
    @fill_table = 0;
	GO

-- create a unique clustered index on message_id!
CREATE UNIQUE CLUSTERED INDEX cuix_messages_message_Id ON dbo.messages (message_id);
GO

-- create a nonclustered index on severity
CREATE NONCLUSTERED INDEX nix_messages_severity ON dbo.messages (severity);
GO

-- what statistics do we have in the table?
SELECT	S.name,
		P.*
FROM	sys.stats AS S
		CROSS APPLY sys.dm_db_stats_properties
		(
			S.object_id,
			S.stats_id
		) AS P
WHERE	S.object_id = OBJECT_ID(N'dbo.messages', N'U');
GO

-- now we run a prepared statement againt the FULL table!
DECLARE	@stmt NVARCHAR(512) = N'SELECT * FROM dbo.messages WHERE message_id = @message_id
OPTION
(
	QUERYTRACEON 3604,
	QUERYTRACEON 2363
);';
DECLARE @vars NVARCHAR(32)  = N'@message_id INT';
EXEC sp_executesql @stmt, @vars, 101;
GO

DECLARE	@stmt NVARCHAR(512) = N'SELECT * FROM dbo.messages WHERE severity = @severity
OPTION
(
	QUERYTRACEON 3604,
	QUERYTRACEON 2363
);';
DECLARE @vars NVARCHAR(32)  = N'@severity TINYINT';
EXEC sp_executesql @stmt, @vars, 16;
GO

-- what plans do we have in the procedure cache?
SELECT	DECP.usecounts,
		DEQP.query_plan,
		DEST.[text]
FROM	sys.dm_exec_cached_plans AS DECP
		CROSS APPLY sys.dm_exec_query_plan(DECP.plan_handle) AS DEQP
		CROSS APPLY sys.dm_exec_sql_text(DECP.plan_handle) AS DEST
WHERE	DEST.text LIKE '%SELECT * FROM dbo.messages%'
		AND DECP.objtype = N'Prepared'
		AND DEST.text NOT LIKE '%dm_exec_cached_plans%';
GO

-- now we fill data into the table and run the queries again!
INSERT INTO dbo.messages WITH (TABLOCK)
(message_id, language_id, severity, is_event_logged, [text])
SELECT	M.message_id, M.language_id, M.severity, M.is_event_logged, M.[text]
FROM	sys.messages AS M
WHERE	M.language_id = 1033;
GO

-- do we have any changes recorded in the statistics?
SELECT	S.name,
		P.*
FROM	sys.stats AS S
		CROSS APPLY sys.dm_db_stats_properties
		(
			S.object_id,
			S.stats_id
		) AS P
WHERE	S.object_id = OBJECT_ID(N'dbo.messages', N'U');
GO

-- let's run the same queries again against the table
DECLARE	@stmt NVARCHAR(512) = N'SELECT * FROM dbo.messages WHERE message_id = @message_id
OPTION
(
	QUERYTRACEON 3604,
	QUERYTRACEON 2363
);';
DECLARE @vars NVARCHAR(32)  = N'@message_id INT';
EXEC sp_executesql @stmt, @vars, 101;
GO

DECLARE	@stmt NVARCHAR(512) = N'SELECT * FROM dbo.messages WHERE severity = @severity
OPTION
(
	QUERYTRACEON 3604,
	QUERYTRACEON 2363
);';
DECLARE @vars NVARCHAR(32)  = N'@severity TINYINT';
EXEC sp_executesql @stmt, @vars, 16;
GO

-- what about the statistics objects in the database?
SELECT	S.name,
		P.*
FROM	sys.stats AS S
		CROSS APPLY sys.dm_db_stats_properties
		(
			S.object_id,
			S.stats_id
		) AS P
WHERE	S.object_id = OBJECT_ID(N'dbo.messages', N'U');
GO

-- clean the kitchen!
EXEC dbo.PrepareWorkbench
	@create_table = 0;
	GO