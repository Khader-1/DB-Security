-- =====================================================================
-- PROJECT 1 - requirement 6: prove that permitted operations succeed
-- and unauthorized ones fail.
-- Run as SYSDBA (it switches identity with CONNECT as it goes).
-- =====================================================================
set echo on
set linesize 140
set pagesize 50

-- =====================================================================
-- TEST 1 - the PASSWORD user. Oracle checks the password itself.
-- =====================================================================
connect khader_pwd/"Khader#120191118"@localhost:1521/XE

show user

-- 1a. ALLOWED - khader_read_rl grants SELECT on the non-sensitive table
select emp_id, full_name, dept from khader.employees order by emp_id;

-- 1b. ALLOWED - khader_write_rl grants INSERT on the same table
insert into khader.employees values (1004, 'Test User', 'IT', 'test@ucas.edu.ps');
commit;

-- 1c. DENIED - this user was never granted khader_sensitive_rl.
--     Expected: ORA-00942 table or view does not exist.
--     Oracle hides the existence of objects you have no privilege on.
select * from khader.salaries;

-- 1d. DENIED - no privilege on the card data either. Expected ORA-00942.
select * from khader.cards;

-- =====================================================================
-- TEST 2 - the PROFILE is really attached and its limits are visible
-- =====================================================================
connect sys/oracle@localhost:1521/XE as sysdba

select username, profile, authentication_type, account_status
  from dba_users
 where username in ('KHADER_PWD','OPS$KHADER');

select resource_name, limit
  from dba_profiles
 where profile = 'KHADER_PROF'
 order by resource_type, resource_name;

-- =====================================================================
-- TEST 3 - which roles each user actually holds
-- =====================================================================
select grantee, granted_role
  from dba_role_privs
 where grantee in ('KHADER_PWD','OPS$KHADER')
 order by grantee, granted_role;

exit
