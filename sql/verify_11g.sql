-- Capability check for the Database Security coursework (Oracle XE 11.2)
-- Confirms every feature the five assignments depend on.
set pagesize 200 linesize 140 feedback off
col parameter for a34
col value for a34
col name for a26

prompt ===== VERSION =====
select banner from v$version where rownum = 1;

prompt
prompt ===== OPTIONS (Project 2 depends on these) =====
select parameter, value
  from v$option
 where parameter in ('Fine-grained auditing',
                     'Flashback Database',
                     'Oracle Label Security',
                     'Oracle Database Vault');

prompt
prompt ===== AUDIT / AUTH PARAMETERS =====
select name, value
  from v$parameter
 where name in ('audit_trail',
                'audit_sys_operations',
                'audit_file_dest',
                'os_authent_prefix',
                'resource_limit',
                'db_recovery_file_dest');

prompt
prompt ===== ARCHIVELOG STATE (Project 3) =====
select log_mode from v$database;

exit
