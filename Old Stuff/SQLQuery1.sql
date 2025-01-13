
/*******************************************************************************

       query store - cardinality estimator 70 vs 140
       SQL Server version upgrade

*******************************************************************************/

-- Migrate 2008 to 2014 / 2016 / 2017 /2017
USE CustomerOrders;
GO

-- Two unique values for a and b
DECLARE @a int = 1000000;
DECLARE @b int = 1000000;
DECLARE @row_count decimal = 2000000;

-- Conjunction of a and b: a and b
SELECT
       @a / @row_count * @b / @row_count * @row_count AS estimated_number_of_rows_legacy_cardinality_estimator_conjunction
, (      SELECT @a / @row_count ) * SQRT(( SELECT @b / @row_count )) * @row_count AS estimated_number_of_rows_new_cardinality_estimator_conjunction;

-- Disconjunction of a and b: a or b
SELECT (( @a / @row_count + @b / @row_count )
              - ( @a / @row_count * @b / @row_count )
          ) * @row_count AS estimated_number_of_rows_legacy_cardinality_estimator_disconjunction
,         @row_count
          * ( 1 - (( 1 - ( @a / @row_count )) * SQRT(1 - ( @b / @row_count )))) AS estimated_number_of_rows_new_cardinality_estimator_disconjunction;
GO

-- Create a table
DROP TABLE IF EXISTS dbo.test;
GO

CREATE TABLE dbo.test ( col1 int NOT NULL, col2 int NOT NULL );
GO

-- Insert 2.000.000 records
-- col1 : 2 unique vales
-- EQ_ROWS (col1) : 1.000.000 
-- col2 : 2 unique vales
-- EQ_ROWS (col2) : 1.000.000 
WITH cte
AS
       (
              SELECT numbers.col1
              FROM ( VALUES ( 0 )
                        ,     ( 1 )
                        ,     ( 2 )
                        ,     ( 3 )
                        ,     ( 4 )
                        ,     ( 5 )
                        ,     ( 6 )
                        ,     ( 7 )
                        ,     ( 8 )
                        ,     ( 9 )
                     ) AS numbers ( col1 )
       )
INSERT dbo.test
       (
              col1
         , col2
       )
       (
       SELECT (c1.col1 * 100000 + c2.col1 * 10000 + c3.col1 * 1000 + c4.col1 * 100
                     + c5.col1 * 10 + c6.col1 * 1
                 ) % 2
         , (c1.col1 * 100000 + c2.col1 * 10000 + c3.col1 * 1000 + c4.col1 * 100
              + c5.col1 * 10 + c6.col1 * 1
              ) % 2
       FROM
              cte AS c1
       CROSS JOIN cte AS c2
       CROSS JOIN cte AS c3
       CROSS JOIN cte AS c4
       CROSS JOIN cte AS c5
       CROSS JOIN cte AS c6
       UNION ALL
       SELECT (c1.col1 * 100000 + c2.col1 * 10000 + c3.col1 * 1000 + c4.col1 * 100
                     + c5.col1 * 10 + c6.col1 * 1
                 ) % 2
         , (c1.col1 * 100000 + c2.col1 * 10000 + c3.col1 * 1000 + c4.col1 * 100
              + c5.col1 * 10 + c6.col1 * 1
              ) % 2
       FROM
              cte AS c1
       CROSS JOIN cte AS c2
       CROSS JOIN cte AS c3
       CROSS JOIN cte AS c4
       CROSS JOIN cte AS c5
       CROSS JOIN cte AS c6
       );
GO

-- Create stasitics for col1 and col1 each
CREATE STATISTICS sta_col1 ON test ( col1 ) WITH FULLSCAN;
GO
CREATE STATISTICS sta_col2 ON test ( col2 ) WITH FULLSCAN;
GO

-- Set cost threshold for parallelism to 19
EXEC sp_configure 'show advanced options', 1
RECONFIGURE
EXEC sp_configure 'cost threshold for parallelism', 19;
RECONFIGURE;
GO

SET STATISTICS TIME ON;
GO

-- Clear the plan cache for the current database
DECLARE @db_id int = DB_ID();
DBCC FLUSHPROCINDB(@db_id);
GO

-- Set COMPATIBILITY_LEVEL to legacy cardinality estimator 70
ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 110;
GO

-- Force serial plan with old cardinality estimator
-- Cost : 19,4602 > 19
SELECT * FROM dbo.test WHERE col1 = 0 OR col2 = 1 GROUP BY col1, col2
OPTION (MAXDOP 1)
GO

-- Reset query store
ALTER DATABASE CustomerOrders
SET QUERY_STORE CLEAR ALL
GO

-- Get the query store options
-- Ensure query_capture_mode_desc is set to ALL
SELECT
       query_capture_mode_desc, *
FROM
       sys.database_query_store_options;
GO

-- Parallelism
-- Conjunction
-- Cost : 9,17749
-- Estimated number of rows : 1500000
-- Actual number of rows : 2000000
-- Memory Grant : 12488
-- Hash Match, Sort
-- Table 'test'. Scan count 9, logical reads 7663
-- CPU time = 2249 ms,  elapsed time = 327 ms.
SELECT * FROM dbo.test WHERE col1 = 0 OR col2 = 1 GROUP BY col1, col2;
GO

-- Set COMPATIBILITY_LEVEL to new cardinality estimator
ALTER DATABASE CURRENT SET COMPATIBILITY_LEVEL = 140;
GO

-- Force serial plan with new cardinality estimator
-- Cost : 18,1066 < 19
SELECT * FROM dbo.test WHERE col1 = 0 OR col2 = 1 GROUP BY col1, col2
OPTION (MAXDOP 1)
GO

DECLARE @db_id int = DB_ID();
DBCC FLUSHPROCINDB(@db_id);
GO

-- Serial plan
-- Conjunction
-- Cost : 18,1066
-- Estimated number of rows : 1292890
-- Actual number of rows : 2000000
-- Memory grant : 1024 (default)
-- Hash Match
-- Table 'test'. Scan count 1, logical reads 7663
-- Plan is worse than the one before
-- CPU time = 1250 ms,  elapsed time = 1280 ms.
-- CPU time = 2249 ms,  elapsed time = 327 ms.
SELECT * FROM dbo.test WHERE col1 = 0 OR col2 = 1 GROUP BY col1, col2;
GO

-- Compare plans in Regressed Queries

-- Housekeeping
EXEC sp_configure 'cost threshold for parallelism', 5;
RECONFIGURE;
GO
DROP TABLE IF EXISTS dbo.test;
GO
