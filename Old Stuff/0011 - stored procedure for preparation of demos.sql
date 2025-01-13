/*============================================================================
	File:		0011 - stored procedure for preparation of demos.sql

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
USE demo_db;
GO

IF OBJECT_ID(N'dbo.PrepareWorkbench', N'P') IS NOT NULL
	DROP PROC dbo.PrepareWorkBench
	GO

CREATE PROC dbo.PrepareWorkbench
	@create_table	BIT = 1,
	@fill_table		BIT = 1,
	@language_id	INT	= 0
AS
	SET NOCOUNT ON;


	IF OBJECT_ID(N'dbo.messages', N'U') IS NOT NULL
	BEGIN
		RAISERROR (N'dropping existing table...', 0, 1) WITH NOWAIT;
		DROP TABLE dbo.messages;
	END

	IF @create_table = 0
		RETURN;

	IF @create_table = 1
	BEGIN
		RAISERROR (N'creating demo table [dbo].[messages]...', 0, 1) WITH NOWAIT;

		CREATE TABLE dbo.messages
		(
			message_id		INT,
			language_id		INT,
			severity		TINYINT,
			is_event_logged	BIT,
			[text]			CHAR(2048)
		);
	END

	IF @fill_table = 1
	BEGIN
		RAISERROR (N'filling demo table with data...', 0, 1) WITH NOWAIT;

		INSERT INTO dbo.messages WITH (TABLOCK)
		(message_id, language_id, severity, is_event_logged, [text])
		SELECT	message_id,
				language_id,
				severity,
				is_event_logged,
				[text]
		FROM	sys.messages
		WHERE	language_id = @language_id
				OR (@language_id = 0);
	END

	SET NOCOUNT OFF;
GO
