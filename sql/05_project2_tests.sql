-- =====================================================================
-- PROJECT 2 - requirement 6: generate activity, then analyse the audit
-- records produced by EACH mechanism, and prove the protection works.
-- Run as SYSDBA.
-- =====================================================================
set echo on
set linesize 160
set pagesize 60
col username    for a12
col action_name for a10
col obj_name    for a12
col sql_text    for a56
col action      for a8
col action_user for a12

-- =====================================================================
-- STEP 1 - generate activity on the LESS sensitive table, as a normal
--          user, so the audit trail has something real to show.
-- =====================================================================
connect khader_pwd/"Khader#120191118"@localhost:1521/XE

select emp_id, full_name from khader.employees where emp_id = 1001;
update khader.employees set dept = 'Security' where emp_id = 1001;
commit;

-- an unauthorized attempt - this is audited too
select * from khader.salaries;

-- =====================================================================
-- STEP 2 - generate activity on the MOST sensitive table
-- =====================================================================
connect sys/oracle@localhost:1521/XE as sysdba

update khader.salaries set base_salary = 9999.99 where emp_id = 1001;
delete from khader.salaries where emp_id = 1003;
commit;

-- =====================================================================
-- STEP 3 - MECHANISM 1: standard auditing (SYS.AUD$ via DBA_AUDIT_TRAIL)
-- Shows WHO ran WHICH STATEMENT and WHEN. SQL_TEXT is populated only
-- because AUDIT_TRAIL = db_extended.
-- =====================================================================
select username, action_name, obj_name, sql_text, timestamp
  from dba_audit_trail
 where obj_name in ('EMPLOYEES','SALARIES')
 order by timestamp;

-- failed logons / unauthorized attempts
select username, action_name, returncode, timestamp
  from dba_audit_trail
 where returncode <> 0
 order by timestamp;

-- =====================================================================
-- STEP 4 - MECHANISM 2: the row-level trigger.
-- Shows the ACTUAL VALUES before and after - which mechanism 1 cannot do.
-- =====================================================================
select audit_id, action, action_user, emp_id, old_salary, new_salary, action_time
  from secaud.salary_audit_log
 order by audit_id;

-- =====================================================================
-- STEP 5 - PROTECTION of the audit records.
-- Even connected as SYSDBA, the append-only trigger refuses the change.
-- Expected: ORA-20999.
-- =====================================================================
delete from secaud.salary_audit_log;

update secaud.salary_audit_log set new_salary = 0;

-- the OS-level trail for SYSDBA actions lives outside the database
show parameter audit_file_dest

exit
