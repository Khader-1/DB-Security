-- =====================================================================
-- PROJECT 2 - Database Auditing & Monitoring
-- Oracle Database 11g Express Edition
-- Run as SYSDBA.
--
-- Follows the style of the course code files (Oracle_Audit_Commands.txt
-- and "Old New Value Auditing.txt"), with schema KHADER in place of the
-- instructor's ASHAAT.
--
-- Requirements covered:
--   1. Standard auditing stored in the DB, keeping the SQL statement
--   2. Monitoring of the LESS sensitive data (standard auditing)
--   3. TWO different mechanisms for the MOST sensitive data
--   4. An auditing trigger, implemented practically
--   5. Protection of the audit records against the DBA
--   6. Analysis of the resulting audit records
--
-- NOTE on Fine-Grained Auditing: the course also covers DBMS_FGA
-- (FGA.txt). FGA is an Enterprise Edition feature and is NOT available
-- in Express Edition - DBMS_FGA.add_policy fails with
--   ORA-00439: feature not enabled: Fine-grained Auditing
-- The brief allows for this ("if it is supported in your environment"),
-- so the two mechanisms below are standard auditing and a trigger,
-- exactly as shown in "Old New Value Auditing.txt".
-- =====================================================================
set echo on
set linesize 140

-- =====================================================================
-- 1. STANDARD AUDITING INTO THE DATABASE, KEEPING THE SQL TEXT
-- ---------------------------------------------------------------------
-- Already applied in 00_instance_config.sql and activated by a restart:
--     alter system set audit_trail = 'db_extended' scope = spfile;
-- 'db'          -> write audit records into SYS.AUD$
-- '..._extended'-> additionally store SQLTEXT and SQLBIND
-- On 11g the literal value is db_extended; the 'DB,EXTENDED' form used
-- in the course notes raises ORA-00096 on this release.
-- =====================================================================
show parameter audit_trail

-- =====================================================================
-- 2. LESS SENSITIVE DATA - standard auditing on KHADER.EMPLOYEES
-- =====================================================================
audit select, insert, update, delete on khader.employees by access;

-- session / privilege level auditing, as in Oracle_Audit_Commands.txt.
-- NOTE: that file lists "AUDIT GRANT, REVOKE BY ACCESS", which is not
-- valid syntax on 11g (ORA-00956: missing or invalid auditing option).
-- The correct statement for auditing privilege and role grants is:
audit session whenever not successful;
audit system grant by access;

-- =====================================================================
-- 3+4. MOST SENSITIVE DATA - TWO DIFFERENT MECHANISMS
-- =====================================================================

-- ---------- MECHANISM 1: standard object auditing, BY ACCESS ----------
-- One audit record per statement, with the SQL text, in SYS.AUD$.
-- Strength : no code to maintain, catches every access including SELECT.
-- Weakness : records the STATEMENT, not the row values that changed.
audit select, insert, update, delete on khader.salaries by access;

-- ---------- MECHANISM 2: row-level trigger capturing OLD/NEW ----------
-- Strength : records the actual values before and after the change,
--            which standard auditing cannot do.
-- Weakness : DML only - a SELECT cannot be captured by a trigger.
-- The two mechanisms are therefore complementary, not redundant.

create user secaud identified by "Secaud#2026"
  default tablespace users
  quota unlimited on users;

grant create session to secaud;

-- NOTE: 11g has no IDENTITY columns (that is 12c and later), so the
-- surrogate key comes from a sequence.
create table secaud.salary_audit_log (
  audit_id     number,
  action       varchar2(10),
  action_user  varchar2(30),
  action_time  timestamp,
  emp_id       number(6),
  old_salary   number(10,2),
  new_salary   number(10,2)
);

create sequence secaud.seq_salary_audit start with 1 increment by 1 nocache;

-- the grant must come BEFORE the trigger, otherwise the trigger fails to
-- compile with ORA-00942: table or view does not exist
grant insert on secaud.salary_audit_log to khader;
grant select on secaud.seq_salary_audit to khader;

create or replace trigger khader.trg_salaries_audit
after insert or update or delete on khader.salaries
for each row
declare
  v_action varchar2(10);
begin
  -- INSERTING / UPDATING / DELETING are PL/SQL predicates. They cannot be
  -- used inside a SQL statement (a CASE in the VALUES list fails with
  -- ORA-00920: invalid relational operator), so the action is resolved
  -- in PL/SQL first and only the resulting variable goes into the INSERT.
  if inserting then
    v_action := 'INSERT';
  elsif updating then
    v_action := 'UPDATE';
  else
    v_action := 'DELETE';
  end if;

  insert into secaud.salary_audit_log
        (audit_id, action, action_user, action_time, emp_id, old_salary, new_salary)
  values (secaud.seq_salary_audit.nextval,
          v_action,
          user, systimestamp,
          nvl(:new.emp_id, :old.emp_id),
          :old.base_salary,
          :new.base_salary);
end;
/

-- =====================================================================
-- 5. PROTECTING THE AUDIT RECORDS FROM THE DBA
-- ---------------------------------------------------------------------
-- Layer 1 - audit the audit trail itself. Any attempt to read or delete
--           SYS.AUD$ leaves its own audit record.
-- =====================================================================
audit all on sys.aud$ by access;
audit delete any table by access;

-- Layer 2 - audit privileged (SYSDBA) activity to OPERATING SYSTEM files.
--           Set in 00_instance_config.sql:
--               alter system set audit_sys_operations = TRUE scope=spfile;
--           These files live in AUDIT_FILE_DEST, outside the database, so
--           a DBA cannot remove them with SQL - only with OS access, which
--           should belong to a different person.
show parameter audit_file_dest
show parameter audit_sys_operations

-- Layer 3 - make the custom audit table append-only, by refusing any
--           UPDATE or DELETE on it regardless of who issues it.
create or replace trigger secaud.trg_protect_salary_log
before update or delete on secaud.salary_audit_log
begin
  raise_application_error(-20999,
    'Audit records are append-only and cannot be modified or deleted.');
end;
/

-- Honest limitation, to state in the report and the discussion:
-- a DBA keeps ALTER ANY TRIGGER / DROP ANY TABLE and can therefore
-- disable these layers. Complete separation of duties needs Oracle
-- Database Vault or Audit Vault, neither of which exists in XE
-- (v$option reports "Oracle Database Vault = FALSE"). The OS trail from
-- Layer 2 is the strongest control actually available here.

exit
