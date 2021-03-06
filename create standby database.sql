
###
###CREATE PHYSICAL STANDBY DATABASE 
###

## LISTENER

SID_LIST_LISTENER =
 (SID_LIST =
  (SID_DESC =
   (GLOBAL_DBNAME = PROD)
   (ORACLE_HOME = /u01/app/oracle/product/11.2.0/dbhome_1)
   (SID_NAME = ORCL1)
  )
 )





SID_LIST_LISTENER =
 (SID_LIST =
  (SID_DESC =
   (GLOBAL_DBNAME = STBY)
   (ORACLE_HOME = /u01/app/oracle/product/11.2.0/dbhome_1)
   (SID_NAME = ORCL1)
  )
 )


### TNSNAMES

PROD =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = rac112-scan)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = PROD)
    )
  )

STBY =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = rac121-scan)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = STBY)
    )
  )



### TNSNAMES para RMAN

PROD_RAC1-VIP =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = rac1-vip)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = PROD)
      (INSTANCE_NAME=ORCL1)
    )
  )

PROD_RAC2-VIP =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = rac2-vip)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = PROD)
      (INSTANCE_NAME=ORCL2)
    )
  )

STBY-RAC3-VIP =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = rac3-vip)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = STBY)
      (INSTANCE_NAME=ORCL1)
    )
  )

STBY-RAC4-VIP =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = rac4-vip)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = STBY)
      (INSTANCE_NAME=ORCL2)
    )
  )



### ADIÇÃO DOS REDOS DE ALTA DISPONIBILIDADE 

alter database add standby logfile thread 1 group 5 '+DATA' size 50M;
alter database add standby logfile thread 1 group 6 '+DATA' size 50M;
alter database add standby logfile thread 1 group 7 '+DATA' size 50M;
alter database add standby logfile thread 2 group 8 '+DATA' size 50M;
alter database add standby logfile thread 2 group 9 '+DATA' size 50M;
alter database add standby logfile thread 2 group 10 '+DATA' size 50M;



### CONFIGURAÇÃO DO SERVIDOR PRIMÁRIO 
### (JÁ PREPARANDO PARA O CASDO DE VIDRAR STANDBY DEVIDO A UM POSSÍVEL SWITCHOVER OU FAILOVER)

alter system set db_unique_name='PROD' scope=spfile sid='*';
alter system set log_archive_config = 'DG_CONFIG=(PROD,STBY)' scope=both sid='*';
alter system set standby_file_management=AUTO scope=both sid='*';
alter system set db_file_name_convert='PROD','STBY','STBY','PROD','ORCL','STBY','STBY','ORCL' scope=spfile sid='*';
alter system set log_file_name_convert='PROD','STBY','STBY','PROD','ORCL','STBY','STBY','ORCL' scope=spfile sid='*';
alter system set log_archive_dest_2='SERVICE=STBY VALID_FOR=(ONLINE_LOGFILES,PRIMARY_ROLE) DB_UNIQUE_NAME=STBY' scope=spfile sid='*';
alter system set log_archive_dest_state_2=defer scope=spfile sid='*';
alter system set fal_server='STBY' scope=spfile sid='*';


### CONFIGURAÇÕES ORIGINAIS DO DB NO CLUSTER

[oracle@rac1 ~]$ srvctl config db -d ORCL
Database unique name: ORCL
Database name: ORCL
Oracle home: /u01/app/oracle/product/11.2.0/dbhome_1
Oracle user: oracle
Spfile: +DATA/ORCL/spfileORCL.ora
Domain: 
Start options: open
Stop options: immediate
Database role: PRIMARY
Management policy: AUTOMATIC
Server pools: ORCL
Database instances: ORCL1,ORCL2
Disk Groups: DATA
Services: 
Database is administrator managed



### REMOVER E RECRIAR O RECURSO DB NO CLUSTER (ALTERANDO O TARGET DE MONITORAMENTO PARA MONITORAR UM PRIMARIO)

srvctl stop db -d ORCL
srvctl remove inst -d ORCL -i ORCL1
srvctl remove inst -d ORCL -i ORCL2
srvctl remove db -d ORCL
srvctl add db -d PROD -n ORCL -a "DATA" -r PRIMARY -o /u01/app/oracle/product/11.2.0/dbhome_1 -p +DATA/ORCL/spfileORCL.ora
srvctl add inst -d PROD -i ORCL1 -n rac1
srvctl add inst -d PROD -i ORCL2 -n rac2
srvctl start db -d PROD


### DUPLICAR A BASE PARA STANDBY 

connect target sys/oracle@prod_rac1-vip
connect auxiliary sys/oracle@stby-rac3-vip
duplicate target database for standby from active database
dorecover
spfile
 parameter_value_convert "PROD","STBY","ORCL","STBY"
 set db_unique_name="STBY"
 set log_archive_dest_2="service=PROD VALID_FOR=(online_logfile,primary_role) DB_UNIQUE_NAME=PROD"
 set fal_server="STBY"
 set fal_client="PROD"
 set remote_listener="rac121-scan.cditec.br:1521"
NOFILENAMECHECK;



### ADICIONAR O NOVO BANCO DE DADOS STANDBY PARA SER MONITORADO PELO CLUSTERWARE

srvctl add db -d STBY -n ORCL -a "DATA" -r physical_standby -s mount -o /u01/app/oracle/product/11.2.0/dbhome_1 -p +DATA/stby/parameterfile/spfile.286.838809193
srvctl add inst -d STBY -i ORCL1 -n rac3
srvctl add inst -d STBY -i ORCL2 -n rac4
srvctl start db -d STBY


### ATIVAR A APLICAÇÃO DOS ARCHIVELOGS NO STANDBY

alter database recover managed standby database disconnect parallel 8;




### MONITORING

-- PRIMARY

prompt check the max log sequence on Primary DB

SELECT Max(sequence#) 
FROM   v$log_history; 

prompt identify the last sequence generated on Primary DB

SELECT thread#, 
       Max(sequence#) "Last Primary Seq Generated" 
FROM   v$archived_log 
WHERE  first_time BETWEEN ( SYSDATE - 1 ) AND ( SYSDATE + 1 ) 
GROUP  BY thread# 
ORDER  BY 1; 


-- STANDBY

prompt Now run the following queries below on Standby database: 


prompt double-check that you are on Standby database - the query below should return "mounted"

SELECT status FROM   v$instance; 

prompt check the max log sequence

SELECT Max(sequence#) 
FROM   v$log_history;

prompt check the last log received from Primary DB

SELECT thread#, 
       Max(sequence#) "Last Standby Seq Received" 
FROM   v$archived_log 
GROUP  BY thread# 
ORDER  BY 1; 

prompt check the last log applied

SELECT thread#, 
       Max(sequence#) "Last Standby Seq Applied" 
FROM   v$archived_log 
WHERE  applied = 'YES' 
GROUP  BY thread# 
ORDER  BY 1; 





select thread#,max(sequence#) from v$archived_log group by thread#
/
select thread#,max(sequence#) from v$archived_log where applied = 'YES' group by thread#
/


-- PROCEDURE PARA VERIFICAR GAP ENTRE PROD E STBY
create or replace procedure gap (p_thread in number) as

 v_archived number;
 v_applied number;
 i number;
 v_result number;

 cursor c1 is select max(sequence#) sequence from v$archived_log where thread# = p_thread;
 cursor c2 is select max(sequence#) sequence from v$archived_log where thread# = p_thread and applied = 'YES';

begin

 for i in c1 loop
  v_archived := i.sequence;
 end loop;

 for i in c2 loop
  v_applied := i.sequence;
 end loop;

 v_result := v_archived - v_applied;

 if v_result = 0 then
   dbms_output.put_line('Sincronizado');
 else 
   dbms_output.put_line('Gap atual ' || to_char(v_archived - v_applied));
 end if;

end;
/







