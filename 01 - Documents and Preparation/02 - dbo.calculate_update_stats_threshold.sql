/*
	============================================================================
	File:		02 - dbo.calculate_update_stats_threshold.sql

	Summary:	This script generates a list for a given number of rows and its
				depending threshold for the old CE and the new CE!
				
				THIS SCRIPT IS PART OF THE TRACK:
					Session - All about Statistics

	Date:		October 2024
	Revion:		January 2025

	SQL Server Version: >= 2016
	============================================================================
*/
USE ERP_Demo;
GO

CREATE OR ALTER FUNCTION dbo.calculate_update_stats_threshold
(
	@start_value	BIGINT	=	0,
	@interval_value	BIGINT	=	5000,
	@max_value		BIGINT	=	1000000
)
RETURNS TABLE
AS
RETURN
(
	WITH l
	AS
	(
		SELECT	@start_value	AS	rows

		UNION ALL

		SELECT	rows + @interval_value
		FROM	l
		WHERE	rows < @max_value
	)
	SELECT	rows,
			CASE WHEN rows < 500
				 THEN CAST(0 AS BIGINT)
				 ELSE CAST(500 + (rows * 0.2) AS BIGINT)
			END											AS	old_ce,
			CASE
				WHEN rows < 500 THEN CAST(0 AS BIGINT)
				WHEN rows <= 25000
					 THEN CAST(500 + (rows * 0.2) AS BIGINT)
					 ELSE CAST(SQRT(CAST(1000 AS BIGINT) * rows) AS BIGINT)
			    END									AS	new_ce
	FROM	l
);
GO

SELECT * FROM dbo.calculate_update_stats_threshold(0, 100, 100000)
OPTION (MAXRECURSION 0);
GO
