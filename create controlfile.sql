

CREATE CONTROLFILE REUSE DATABASE "DEST2" RESETLOGS NOARCHIVELOG 
    MAXLOGFILES 16 
    MAXLOGMEMBERS 3 
    MAXDATAFILES 100 
    MAXINSTANCES 8 
    MAXLOGHISTORY 292 
LOGFILE 
  GROUP 1 '/home/oracle/oradata/DEST2/onlinelogs/redo01.log'  SIZE 10M, 
  GROUP 2 '/home/oracle/oradata/DEST2/onlinelogs/redo02.log'  SIZE 10M, 
  GROUP 3 '/home/oracle/oradata/DEST2/onlinelogs/redo03.log'  SIZE 10M 
DATAFILE 
  '/home/oracle/oradata/DEST2/datafiles/system01.dbf', 
  '/home/oracle/oradata/DEST2/datafiles/undotbs01.dbf', 
  '/home/oracle/oradata/DEST2/datafiles/sysaux01.dbf', 
  '/home/oracle/oradata/DEST2/datafiles/users01.dbf'
CHARACTER SET WE8MSWIN1252; 


