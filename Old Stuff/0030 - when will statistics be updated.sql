/*============================================================================
	File:		0030 - when will statistics be updated.sql

	Summary:	This script demonstrates the behavior of a query when it detects
				outdated statistics.

				THIS SCRIPT IS PART OF THE TRACK: "SQL Server Statistics"

	Date:		November 2016

	SQL Server Version: 2008 / 2012 / 2014 / 2016 / 2017
------------------------------------------------------------------------------
	Written by Uwe Ricken, db Berater GmbH

	This script is intended only as a supplement to demos and lectures
	given by Uwe Ricken.  
  
	THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
	ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
	TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
	PARTICULAR PURPOSE.
============================================================================*/
SET NOCOUNT ON;
SET LANGUAGE us_english;
GO

USE demo_db;
GO


-- let's create a table and fill it with demo data
EXEC dbo.PrepareWorkbench
	@create_table = 1,
	@fill_table = 1,
	@language_id = 1031;
	GO

SELECT * FROM dbo.messages;
GO

-- Now we create an index on the severity column and check the statistics
CREATE NONCLUSTERED INDEX nix_messages_severity ON dbo.messages (severity);
GO

-- what statistics do we have and what is the modification counter?
SELECT	S.name,
		SP.object_id,
        SP.stats_id,
        SP.last_updated,
        SP.rows,
        SP.rows_sampled,
        SP.steps,
        SP.unfiltered_rows,
        SP.modification_counter,
        SP.persisted_sample_percent
FROM	sys.stats AS S
		CROSS APPLY sys.dm_db_stats_properties
		(
			S.object_id,
			S.stats_id
		) AS SP
WHERE	s.object_id = OBJECT_ID(N'dbo.messages', N'U');
GO

SET STATISTICS IO ON;
GO

-- let's run a query against the table to check the statistics
SELECT * FROM dbo.messages WHERE severity = 13;
GO
SELECT * FROM dbo.messages WHERE severity = 16
OPTION (QUERYTRACEON 9130);
GO

-- Let's do a math:
-- we have 15.731 records in the table (depends on the version of SQL Server!)
-- 20% + 500 changes = 3.200 + 500 =>	3,700 changes!

-- Let's enter 2.000 more records into dbo.messages
INSERT INTO dbo.messages WITH (TABLOCK)
(message_id, language_id, severity, is_event_logged, [text])
SELECT	TOP (2200)
		message_id, language_id, severity, is_event_logged, [text]
FROM	sys.messages
WHERE	language_id = 1033;
GO

-- what statistics do we have and what is the modification counter?
SELECT	S.name,
		SP.object_id,
        SP.stats_id,
        SP.last_updated,
        SP.rows,
        SP.rows_sampled,
        SP.steps,
        SP.unfiltered_rows,
        SP.modification_counter,
        SP.persisted_sample_percent
FROM	sys.stats AS S
		CROSS APPLY sys.dm_db_stats_properties
		(
			S.object_id,
			S.stats_id
		) AS SP
WHERE	s.object_id = OBJECT_ID(N'dbo.messages', N'U');
GO

DBCC SHOW_STATISTICS (N'dbo.messages', N'nix_messages_severity');

-- let's run a query against the table to check the statistics
SELECT	message_id,
		language_id,
		severity,
		is_event_logged,
		text
FROM	dbo.messages
WHERE	severity = 13
OPTION (USE HINT ('FORCE_LEGACY_CARDINALITY_ESTIMATION'));
GO

SELECT	message_id,
		language_id,
		severity,
		is_event_logged,
		text
FROM	dbo.messages
WHERE	severity = 13
OPTION (USE HINT ('FORCE_DEFAULT_CARDINALITY_ESTIMATION'));
GO

SELECT	message_id,
		language_id,
		severity,
		is_event_logged,
		text
FROM	dbo.messages
WHERE	severity = 16
OPTION (USE HINT ('FORCE_LEGACY_CARDINALITY_ESTIMATION'));
GO

SELECT	message_id,
		language_id,
		severity,
		is_event_logged,
		text
FROM	dbo.messages
WHERE	severity = 16
OPTION (USE HINT ('FORCE_DEFAULT_CARDINALITY_ESTIMATION'));
GO

-- let's add another 2.000 records into the table to hit the threshold!
INSERT INTO dbo.messages WITH (TABLOCK)
(message_id, language_id, severity, is_event_logged, [text])
SELECT	TOP (2200)
		message_id, language_id, severity, is_event_logged, [text]
FROM	sys.messages
WHERE	language_id = 1028;
GO

-- what statistics do we have and what is the modification counter?
SELECT	S.name,
		SP.object_id,
        SP.stats_id,
        SP.last_updated,
        SP.rows,
        SP.rows_sampled,
        SP.steps,
        SP.unfiltered_rows,
        SP.modification_counter,
        SP.persisted_sample_percent
FROM	sys.stats AS S
		CROSS APPLY sys.dm_db_stats_properties
		(
			S.object_id,
			S.stats_id
		) AS SP
WHERE	s.object_id = OBJECT_ID(N'dbo.messages', N'U');
GO

DBCC SHOW_STATISTICS(N'dbo.messages', N'nix_messages_severity')
WITH STAT_HEADER;
DBCC SHOW_STATISTICS(N'dbo.messages', N'nix_messages_severity')
WITH HISTOGRAM
GO

-- let's run a query against the table to check the statistics
EXEC sp_executesql N'SELECT * FROM dbo.messages WHERE severity = @Id;',
N'@Id TINYINT', 13;
GO

ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
EXEC sp_executesql N'SELECT * FROM dbo.messages WHERE severity = @Id;',
N'@Id TINYINT', 16;
GO

UPDATE STATISTICS dbo.messages WITH FULLSCAN;
GO

-- what statistics do we have and what is the modification counter?
SELECT	S.name,
		SP.object_id,
        SP.stats_id,
        SP.last_updated,
        SP.rows,
        SP.rows_sampled,
        SP.steps,
        SP.unfiltered_rows,
        SP.modification_counter,
        SP.persisted_sample_percent
FROM	sys.stats AS S
		CROSS APPLY sys.dm_db_stats_properties
		(
			S.object_id,
			S.stats_id
		) AS SP
WHERE	s.object_id = OBJECT_ID(N'dbo.messages', N'U');
GO

SELECT * FROM dbo.messages WHERE severity = 13;
DBCC SHOW_STATISTICS (N'dbo.messages', N'nix_messages_severity')

-- clean the kitchen!
EXEC dbo.PrepareWorkbench
	@create_table = 0;
	GO