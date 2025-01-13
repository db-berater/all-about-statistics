/*============================================================================
	File:		0040 - DBCC SHOW_STATISTICS in detail.sql

	Summary:	This script demonstrates the objects / information of the
				output componentes of DBCC SHOW_STATISTICS

				THIS SCRIPT IS PART OF THE TRACK: "SQL Server Statistics"

	Date:		January 2017

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

-- Create a clustered index on message_id and language_id
CREATE UNIQUE CLUSTERED INDEX cuix_messages_message_id ON dbo.messages
(
	message_id,
	language_id
);
GO

CREATE NONCLUSTERED INDEX nix_messages_severity ON dbo.messages (severity);
GO

-- get the output of DBCC SHOW_STATISTICS for each component
DBCC SHOW_STATISTICS(N'dbo.messages', N'cuix_messages_message_id')
WITH STAT_HEADER;
GO
DBCC SHOW_STATISTICS(N'dbo.messages', N'nix_messages_severity')
WITH STAT_HEADER;
GO

DBCC SHOW_STATISTICS (N'dbo.messages', N'cuix_messages_message_id')
WITH DENSITY_VECTOR;
DBCC SHOW_STATISTICS (N'dbo.messages', N'nix_messages_severity')
WITH DENSITY_VECTOR;
GO

DBCC SHOW_STATISTICS (N'dbo.messages', N'cuix_messages_message_id')
WITH HISTOGRAM;
DBCC SHOW_STATISTICS (N'dbo.messages', N'nix_messages_severity')
WITH HISTOGRAM;
GO

-- clean the kitchen!
EXEC	dbo.PrepareWorkbench
	@create_table = 0;
	GO
