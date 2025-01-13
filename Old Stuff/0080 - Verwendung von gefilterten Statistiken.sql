/*============================================================================
	File:		0080 - Verwendung von gefilterten Statistiken.sq

	Summary:	This script demonstrates with two tables a use case for the 
				usage of filtered properties in a database.

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
USE master;
GO

EXEC dbo.sp_create_demo_db;
GO

USE demo_db;
GO

IF OBJECT_ID(N'dbo.languages', N'U') IS NOT NULL
	DROP TABLE dbo.languages;
	GO

-- Insert app. 12.000 records with us_english messages
EXEC dbo.PrepareWorkbench
	@create_table = 1,
	@fill_table = 1,
	@language_id = 1033;
	GO

-- Insert 100 records with us_english messages
INSERT INTO dbo.messages WITH (TABLOCK)
SELECT TOP (100)
	   message_id, language_id, severity, is_event_logged, LEFT([text], 1024)
FROM   sys.messages
WHERE  language_id = 1031;
GO

-- Insert app. 250 records with ??? messages
INSERT INTO dbo.messages WITH (TABLOCK)
SELECT TOP (250)
       message_id, language_id, severity, is_event_logged, LEFT([text], 1024)
FROM   sys.messages
WHERE  language_id = 1028;
GO

CREATE NONCLUSTERED INDEX nix_messages_language_id ON dbo.messages (language_id);
GO

SELECT * FROM dbo.messages ORDER BY language_id, message_id;

CREATE TABLE dbo.languages
(
       id     int,
       language     varchar(10)
);
GO

INSERT INTO dbo.languages (id, language)
VALUES
(1033, 'english'),
(1031, 'deutsch'),
(1028, 'japanese');
GO

SET STATISTICS IO ON;
DBCC FREEPROCCACHE;
GO

SELECT * FROM dbo.messages WHERE language_id = 1033;
GO

SELECT * FROM dbo.messages WHERE language_id = 1031;
GO

DBCC SHOW_STATISTICS (N'dbo.messages', N'nix_messages_language_id');
GO
 
-- what happens when we JOIN both tables?
SELECT	m.message_id,
		m.text,
		l.language
FROM	dbo.messages AS M INNER JOIN dbo.languages AS L
		ON (M.language_id = L.id)
WHERE	L.language = 'english'
ORDER BY
		m.message_id;
GO

SELECT	m.message_id,
		m.text,
		l.language
FROM	dbo.messages AS M INNER JOIN dbo.languages AS L
		ON (M.language_id = L.id)
WHERE	L.language = 'deutsch'
ORDER BY
		m.message_id;
GO

-- sort spill because of wrong estimates
SELECT m.message_id,
		m.text,
		l.language
FROM	dbo.messages AS M INNER JOIN dbo.languages AS L
		ON (M.language_id = L.id)
WHERE	L.language = 'english'
ORDER BY
		m.text;
GO

-- create a solution where SQL Server can plan with more detailed values
CREATE STATISTICS st_languages_id_english ON dbo.languages (Id)
WHERE language = 'english';
CREATE STATISTICS st_languages_id_german ON dbo.languages (Id)
WHERE language = 'deutsch';
GO

-- creation of new statistics do not force a recompile of queries
DBCC FREEPROCCACHE;
GO

-- what happens when we JOIN both tables?
SELECT	m.message_id,
		m.text,
		l.language
FROM	dbo.messages AS M INNER JOIN dbo.languages AS L
		ON (M.language_id = L.id)
WHERE	L.language = 'english';
GO

SELECT	m.message_id,
		m.text,
		l.language
FROM	dbo.messages AS M INNER JOIN dbo.languages AS L
		ON (M.language_id = L.id)
WHERE	L.language = 'deutsch';
GO

-- NO MORE sort spills because of wrong estimates
SELECT	m.message_id,
		m.text,
		l.language
FROM	dbo.messages AS M INNER JOIN dbo.languages AS L
		ON (M.language_id = L.id)
WHERE	L.language = 'english'
ORDER BY
		m.text;
GO

SET STATISTICS IO OFF;
GO


-- clean the kitchen
EXEC dbo.PrepareWorkbench
	@create_table = 0;
	GO

IF OBJECT_ID(N'dbo.languages', N'U') IS NOT NULL
	DROP TABLE dbo.languages;
	GO
