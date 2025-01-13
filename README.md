<a href="URL_REDIRECT" target="blank"><img align="center" src="https://www.db-berater.de/wp-content/uploads/2015/03/db-berater-gmbh-logo.jpg" height="100" /></a>
# Session - All about Statistics
This repository contains all codes for my Workshop/Session "All about Statistics" which deals with several demos to understand statistics in Microsoft SQL Server.
All scripts are created for the use of Microsoft SQL Server (Version 2016 or higher)
To work with the scripts it is required to have the workshop database [ERP_Demo](https://www.db-berater.de/downloads/ERP_DEMO_2012.BAK) installed on your SQL Server Instance.
The last version of the demo database can be downloaded here:

**https://www.db-berater.de/downloads/ERP_DEMO_2012.BAK**

> Written by
>	[Uwe Ricken](https://www.db-berater.de/uwe-ricken/), 
>	[db Berater GmbH](https://db-berater.de)
> 
> All scripts are intended only as a supplement to demos and lectures
> given by Uwe Ricken.  
>   
> **THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF 
> ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED 
> TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
> PARTICULAR PURPOSE.**

**Note**
The database contains a framework for all workshops / sessions from db Berater GmbH
+ Stored Procedures
+ User Definied Inline Functions

Workshop Scripts for SQL Server Workshop "All about Statistics"

# Folder structure
+ All topics are separated in folders.
+ All scripts have numbers and basically the script with the prefix 01 is for the preparation of the environment
+ The folder **SQL ostress** contains .cmd files as substitute for SQL Query Stress.
   To use ostress you must download and install the **[RML Utilities](https://learn.microsoft.com/en-us/troubleshoot/sql/tools/replay-markup-language-utility)** 
+ The folder **Windows Admin Center** contains json files with the configuration of performance counter. These files can only be used with Windows Admin Center
  - [Windows Admin Center](https://www.microsoft.com/en-us/windows-server/windows-admin-center)
+ The folder **SQL Query Stress** contains prepared configuration settings for each scenario which produce load test with SQLQueryStress from Adam Machanic
  - [SQLQueryStress](https://github.com/ErikEJ/SqlQueryStress)
+ The folder **SQL Extended Events** contains scripts for the implementation of extended events for the different scenarios
  All extended events are written for "LIVE WATCHING" and will not have any target file for saving the results.

# 01 - Documents and Preparation
This folder contains the PowerPoint Presentation used in the Workshop / Session.
The script 00 - dbo.sp_restore_erp_demo.sql installs a stored procedure for the quick restore of the demo database
The scropt 01 - preparation of the demo database.sql restores ERP_Demo on Microsoft SQL Server with the stored procedure sp_restore_erp_demo_

# - 02 Basics of Statistics
This folder contains all preparations / demos for the basic understanding of statistics objects in Microsoft SQL Server
