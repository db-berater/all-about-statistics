/*============================================================================
	File:		0090 - Ascending key problem - 2390.sql

	Summary:	This script creates a demo database which will be used for
				the future demonstration scripts

				THIS SCRIPT IS PART OF THE TRACK: "SQL Server Statistics"

	Date:		September 2017

	SQL Server Version: 2008 / 2012 / 2014 / 2016 / 2017 / 2017
------------------------------------------------------------------------------
	Written by Uwe Ricken, db Berater GmbH

	This script is intended only as a supplement to demos and lectures
	given by Uwe Ricken.  
  
	THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
	ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
	TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
	PARTICULAR PURPOSE.
============================================================================*/
USE [StatisticsDB];
GO

ALTER AUTHORIZATION ON DATABASE::STATISTICSDB TO sa;
ALTER DATABASE STATISTICSDB SET COMPATIBILITY_LEVEL = 110;
ALTER DATABASE STATISTICSDB SET RECOVERY SIMPLE;
ALTER DATABASE STATISTICSDB SET AUTO_UPDATE_STATISTICS OFF;
GO

-- check the compatibility level of the database!
SELECT	name, compatibility_level, is_auto_update_stats_on
FROM	sys.databases
WHERE	database_id = DB_ID();
GO

-- what indexes do we have in dbo.orders
SELECT	object_id,
		name,
		index_id,
		type,
		type_desc,
		is_unique
FROM	sys.indexes
WHERE	OBJECT_ID = OBJECT_ID('dbo.Orders', 'U');
GO

-- Auszuführende Query
SET STATISTICS IO, TIME ON;
GO

SELECT	ID,
        CUSTID,
        ORDERDATE,
        AMOUNT,
        NOTE
FROM	dbo.Orders
WHERE	custid = 160
		AND OrderDate >= '20140101'
		AND OrderDate < '20150101'
ORDER BY
		Id
--OPTION	(
--			USE HINT('FORCE_LEGACY_CARDINALITY_ESTIMATION'),
--			QUERYTRACEON 9130
--		);
GO

SET STATISTICS IO ON;
GO

DBCC SHOW_STATISTICS('dbo.Orders', 'nix_Orders_OrderDate');
DBCC SHOW_STATISTICS('dbo.Orders', 'nix_Orders_CUSTID');
GO

-- CUSTID = 160	=> 1.000 Bestellungen
-- DATE	  = 2014 => 1 Bestellung

-- ES KANN NUR 1 BESTELLUNG GEBEN!


-- what statistics do we have in the table?
SELECT	S.name,
		P.object_id,
        P.stats_id,
        P.last_updated,
        P.rows,
        P.rows_sampled,
        P.steps,
        P.unfiltered_rows,
        P.modification_counter,
        P.persisted_sample_percent
FROM	sys.stats AS S
		CROSS APPLY sys.dm_db_stats_properties
		(
			S.object_id,
			S.stats_id
		) AS P
WHERE	S.object_id = OBJECT_ID(N'dbo.Orders', N'U');
GO

SET STATISTICS IO, TIME ON;
GO

SELECT	ID,
        CUSTID,
        ORDERDATE,
        AMOUNT,
        NOTE
FROM	dbo.Orders
WHERE	custid = 160
		AND OrderDate >= '20140101'
		AND OrderDate < '20150101'
ORDER BY
		Id
OPTION	(
			USE HINT('FORCE_LEGACY_CARDINALITY_ESTIMATION'),
			QUERYTRACEON 9130
		);
GO

SELECT	ID,
        CUSTID,
        ORDERDATE,
        AMOUNT,
        NOTE
FROM	dbo.Orders
WHERE	custid = 160;
GO

SELECT	ID ,
        CUSTID ,
        ORDERDATE ,
        AMOUNT ,
        NOTE
FROM	dbo.Orders
WHERE	OrderDate >= '20140101'
		AND OrderDate < '20150101'
OPTION	(QUERYTRACEON 2390);;
GO

-- same query with new cardinal estimator!
SELECT	ID ,
        CUSTID ,
        ORDERDATE ,
        AMOUNT ,
        NOTE
FROM	dbo.Orders
WHERE	custid = 160 AND
		OrderDate >= '20140101'
		AND OrderDate < '20150101'
OPTION	(
			QUERYTRACEON 2390,
			QUERYTRACEON 9130
		);
GO


-- Manual optimization :-)
SELECT	10000000 * 0.0001711157	AS Density_OrderDate,
		10000000 * 0.0001		AS Density_CustID

DECLARE	@CustId	INT = 160;
DECLARE	@StartDate DATE = '20140101';
DECLARE	@FinishDate DATE = '20150101';

SELECT	*
FROM	dbo.Orders
WHERE	custid = @CustId
		AND OrderDate >= @StartDate
		AND OrderDate < @FinishDate
ORDER BY
		Id
OPTION	(QUERYTRACEON 9130);
GO

UPDATE STATISTICS dbo.Orders WITH FULLSCAN;
GO

-- what statistics do we have in the table?
SELECT	S.name,
		P.object_id,
        P.stats_id,
        P.last_updated,
        P.rows,
        P.rows_sampled,
        P.steps,
        P.unfiltered_rows,
        P.modification_counter,
        P.persisted_sample_percent
FROM	sys.stats AS S
		CROSS APPLY sys.dm_db_stats_properties
		(
			S.object_id,
			S.stats_id
		) AS P
WHERE	S.object_id = OBJECT_ID(N'dbo.Orders', N'U');
GO
