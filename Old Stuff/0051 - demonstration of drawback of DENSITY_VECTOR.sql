/*============================================================================
	File:		0051 - demonstration of drawback of DENSITY_VECTOR.sql

	Summary:	This script demonstrates the usage of the density vector
				and the histogram of a statistics object with the depending
				drawback when it is used with skewed data

				THIS SCRIPT IS PART OF THE TRACK: "SQL Server Statistics"

	Date:		January 2016

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

-- let's create the demo environment
EXEC	dbo.PrepareWorkbench
	@create_table = 1,
	@fill_table = 1,
	@language_id = 1031;
	GO

-- Create a nonclustered index on severity
CREATE NONCLUSTERED INDEX nix_messages_severity ON dbo.messages (severity);
GO

-- Now we create a procedure for the demonstration. It only selects a few
-- data based on the given severity!
IF OBJECT_ID('dbo.GetMessageData', N'P') IS NOT NULL
	DROP PROC dbo.GetMessageData;
	GO

CREATE PROCEDURE dbo.GetMessageData
	@Severity TINYINT
AS
BEGIN
	SET NOCOUNT ON;

	SELECT	message_id,
			language_id,
			severity,
			is_event_logged,
			text
	FROM	dbo.messages
	WHERE	severity = @severity
	ORDER BY
			text;

	SET NOCOUNT OFF;
END
GO

-- now we check the estimates when the proc will be executed.
-- for reason of PARAMETER SNIFFING the proc cache will be flushed 
-- before executing!
DBCC FREEPROCCACHE;
GO

EXEC dbo.GetMessageData @Severity = 12;
GO

DBCC FREEPROCCACHE;
GO

EXEC dbo.GetMessageData @Severity = 16;
GO

-- now the proc will be modified!
IF OBJECT_ID('dbo.GetMessageData', N'P') IS NOT NULL
	DROP PROC dbo.GetMessageData;
	GO

CREATE PROCEDURE dbo.GetMessageData
	@Severity TINYINT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @myVar TINYINT = @Severity;

	SELECT	message_id,
			language_id,
			severity,
			is_event_logged,
			text
	FROM	dbo.messages
	WHERE	severity = @myVar
	ORDER BY
			text;

	SET NOCOUNT OFF;
END
GO

-- and the same proc will be executed again!
DBCC FREEPROCCACHE;
GO

EXEC dbo.GetMessageData @Severity = 12;
GO

DBCC FREEPROCCACHE;
GO

EXEC dbo.GetMessageData @Severity = 16;
GO

-- Show the statistics object of the index
DBCC SHOW_STATISTICS (N'dbo.messages', N'nix_messages_severity');
GO

SELECT 13274 * 0.0625

-- Clean the kitchen
IF OBJECT_ID('dbo.GetMessageData', N'P') IS NOT NULL
	DROP PROC dbo.GetMessageData;
	GO

EXEC dbo.PrepareWorkbench
	@create_table = 0;
