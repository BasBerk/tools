/*
##Script:           SQL_set_to_simple.sql
##
##Description:      Generates a script as outcome for setting all databases to simple recovery mode except sys databases
##Created by:       Bas B
##Creation Date:    8-2-2015  
##Instructions:     Run this script, copy the outcome and run that again.
*/
SELECT 
      'ALTER DATABASE [' + d.name + N']' + CHAR(13) + CHAR(10) 
    + 'SET RECOVERY SIMPLE WITH NO_WAIT' 
    + CHAR(13) + CHAR(10) + CHAR(13) + CHAR(10) 
FROM 
         sys.master_files mf 
    JOIN sys.databases d 
        ON mf.database_id = d.database_id 
WHERE d.database_id > 4
	AND  
		mf.name like '%_log%';