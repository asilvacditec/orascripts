
### CONFIGURAÇÃO DO PARAMETER FILE (DEPOIS DE CONFIGURADO CRIAR UM SPFILE)

audit_file_dest='/u01/app/oracle/admin/DEST2/adump'
audit_trail='db'
compatible='11.2.0.0.0'
db_block_size=8192
db_domain=''
db_name='DEST2'
db_create_online_log_dest_1 = +DATA
db_create_file_dest = +DATA
db_recovery_file_dest = +DATA
db_recovery_file_dest_size = 1G
diagnostic_dest='/u01/app/oracle'
dispatchers='(PROTOCOL=TCP) (SERVICE=ORCLXDB)'
DEST2.instance_number=1
memory_target=516582400
open_cursors=300
processes=150
remote_login_passwordfile='exclusive'
DEST2.thread=1
control_files=(controlfile01.ctl,controlfile02.ctl,controlfile03.ctl)
undo_tablespace='UNDOTBS01'



### CRIAÇÃO DO BANCO DE DADOS

CREATE DATABASE DEST2
   USER SYS IDENTIFIED BY oracle
   USER SYSTEM IDENTIFIED BY oracle
   LOGFILE GROUP 1 ('+DATA/DEST2/onlinelog/redo01.log') SIZE 10M,
           GROUP 2 ('+DATA/DEST2/onlinelog/redo02.log') SIZE 10M,
           GROUP 3 ('+DATA/DEST2/onlinelog/redo03.log') SIZE 10M
   MAXLOGFILES 10
   MAXLOGMEMBERS 5
   MAXLOGHISTORY 1
   MAXDATAFILES 1000
   CHARACTER SET US7ASCII
   NATIONAL CHARACTER SET AL16UTF16
   EXTENT MANAGEMENT LOCAL
   DATAFILE '+DATA/DEST2/datafile/system01.dbf' SIZE 400M REUSE
   SYSAUX DATAFILE '+DATA/DEST2/datafile/sysaux01.dbf' SIZE 400M REUSE
   DEFAULT TABLESPACE users
      DATAFILE '+DATA/DEST2/datafile/users01.dbf'
      SIZE 500M REUSE AUTOEXTEND ON MAXSIZE UNLIMITED
   DEFAULT TEMPORARY TABLESPACE tempts1
      TEMPFILE '+DATA/DEST2/datafile/temp01.dbf'
      SIZE 100M REUSE
   UNDO TABLESPACE UNDOTBS01
      DATAFILE '+DATA/DEST2/datafile/undotbs01.dbf'
      SIZE 200M REUSE AUTOEXTEND ON MAXSIZE UNLIMITED;


### CONFIGURAÇÃO DO LISTENER (ARQUIVO LISTENER.ORA)

LISTENER_DEST2=
  (DESCRIPTION=
    (ADDRESS_LIST=
      (ADDRESS=(PROTOCOL=tcp)(HOST=rac1)(PORT=1523))
      (ADDRESS=(PROTOCOL=ipc)(KEY=extproc))
    )
  )

SID_LIST_LISTENER_DEST2=
  (SID_LIST=
    (SID_DESC=
      (GLOBAL_DBNAME=DEST2)
      (SID_NAME=DEST2)      
      (ORACLE_HOME=/u01/app/oracle/product/11.2.0/dbhome_1)
    )
  )



### CONFIGURAÇÃO DO SERVIÇO DE NOMES (TNSNAMES.ORA)


DEST2 =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = rac1)(PORT = 1523))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = DEST2)
    )
  )


### CONFIGURAÇÃO PARA SOMENTE ENVIAR OS ARCHIVELOGS PARA O NOVO DESTINO (SEM APLICAR)

























