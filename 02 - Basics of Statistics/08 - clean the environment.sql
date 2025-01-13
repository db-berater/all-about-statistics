/*
	============================================================================
	File:		08 - clean the environment.sql

	Summary:	Cleanup of environment for the topic
				"02 Basics of Statistics"

				THIS SCRIPT IS PART OF THE TRACK:
					Session - All about Statistics

	Date:		October 2024
	Revion:		January 2025

	SQL Server Version: >= 2016
	============================================================================
*/
ALTER DATABASE SCOPED CONFIGURATION CLEAR PROCEDURE_CACHE;
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO

USE ERP_Demo;
GO

/*
	We make sure we don't have any objects from the previous demo!
*/
EXEC sp_drop_indexes @table_name = N'ALL', @check_only = 0;
EXEC sp_drop_statistics @table_name = N'ALL', @check_only = 0;
GO

/* Drop additional objects */
DROP TABLE IF EXISTS demo.customers;
DROP SCHEMA IF EXISTS demo;
GO