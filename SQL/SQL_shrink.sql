/*
##Script:           SQL_shrink.sql
##
##Description:      Generates a script as outcome for shrinking all databases except sys databases
##Created by:       Bas B
##Creation Date:    19-1-2015  
##Instructions:     Run this script, copy the outcome and run that again.
*/
SELECT 
      'USE [' + d.name + N']' + CHAR(13) + CHAR(10) 
    + 'DBCC SHRINKFILE (N''' + mf.name + N''' , 0, TRUNCATEONLY)' 
    + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) 
FROM 
         sys.master_files mf 
    JOIN sys.databases d 
        ON mf.database_id = d.database_id 
WHERE d.database_id > 4
	AND  
		mf.name like '%_log%';