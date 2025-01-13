/*============================================================================
	File:		0050 - how the statistics meta data will be used.sql

	Summary:	This script demonstrates the usage of the density vector
				and the histogram of a statistics object and its dependencies
				on the way a query is written!

				THIS SCRIPT IS PART OF THE TRACK: "SQL Server Statistics"

	Date:		February 2015

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
USE demo_db;
GO

-- let's create the demo environment
EXEC	dbo.PrepareWorkbench
	@create_table = 1,
	@fill_table = 1,
	@language_id = 1031;
	GO

-- we create an index on the severity column for queries
CREATE NONCLUSTERED INDEX nix_messages_severity ON dbo.messages (severity);
GO

-- Let's check the components of a statistics object...
DBCC SHOW_STATISTICS (N'dbo.messages', N'nix_messages_severity')
WITH STAT_HEADER;
DBCC SHOW_STATISTICS (N'dbo.messages', N'nix_messages_severity')
WITH DENSITY_VECTOR;
DBCC SHOW_STATISTICS (N'dbo.messages', N'nix_messages_severity')
WITH HISTOGRAM;
GO

-- what are the estimates for the severity = 10?
SELECT * FROM dbo.messages WHERE severity = 10
OPTION
(
	QUERYTRACEON 3604,
	QUERYTRACEON 2363,
	RECOMPILE
);
GO

-- what are the estimates for the severity = 13?
SELECT * FROM dbo.messages WHERE severity = 13
OPTION
(
	QUERYTRACEON 3604,
	QUERYTRACEON 2363,
	RECOMPILE
);
GO

DBCC FREEPROCCACHE;
GO

-- what will Microsoft SQL Server do, when no predicate is given
-- at compile time?
DECLARE	@severity	TINYINT = 16;
SELECT	*
FROM	dbo.messages
WHERE	severity = @severity
ORDER BY
		text;
GO

SELECT 14098 * 0.0625;


SELECT * FROM dbo.messages WHERE severity = 13
OPTION
(
	QUERYTRACEON 3604,
	QUERYTRACEON 2363
);
GO

DECLARE @Severity SMALLINT = 12;
SELECT * FROM dbo.messages
WHERE	severity = @Severity
ORDER BY
		[text];
GO

DECLARE @Severity SMALLINT = 16;
SELECT * FROM dbo.messages
WHERE	severity = @Severity
ORDER BY
		[text];
GO

DECLARE @Severity SMALLINT = 16;
SELECT * FROM dbo.messages
WHERE	severity = @Severity
ORDER BY
		[text]
OPTION (RECOMPILE);
GO

-- have a look to the density vector to understand this estimate!
DBCC SHOW_STATISTICS (N'dbo.messages', N'nix_messages_severity') WITH STAT_HEADER, DENSITY_VECTOR;
GO

DECLARE	@rows		BIGINT	=	12668.0
DECLARE	@density	FLOAT	=	0.0625

SELECT	@rows * @density;
GO

-- Beispiel mit Stored Proc
CREATE OR ALTER PROC dbo.GetMyMessages
	@Severity TINYINT
AS
BEGIN
	SET NOCOUNT ON;

	SELECT * FROM dbo.messages
	WHERE	severity = @Severity
	ORDER BY
			[text];

	SET NOCOUNT OFF;
END
GO

DBCC FREEPROCCACHE;
GO

EXEC dbo.GetMyMessages
    @Severity = 12;

EXEC dbo.GetMyMessages
    @Severity = 16;

EXEC dbo.GetMyMessages
    @Severity = 13;
GO

CREATE OR ALTER PROC dbo.GetMyMessages
	@Severity TINYINT
AS
BEGIN
	SET NOCOUNT ON;

	SELECT * FROM dbo.messages
	WHERE	severity = @Severity
	ORDER BY
			[text]
	OPTION (RECOMPILE);

	SET NOCOUNT OFF;
END
GO

EXEC dbo.GetMyMessages
    @Severity = 12;

EXEC dbo.GetMyMessages
    @Severity = 16;

EXEC dbo.GetMyMessages
    @Severity = 13;
GO

-- Clean the kitchen!
EXEC	dbo.PrepareWorkbench
	@create_table = 0;
	GO