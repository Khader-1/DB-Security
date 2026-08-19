-- =====================================================================
-- SHORT EXAM  (8 pts)  +  VERY SHORT EXAM  (2 pts)
-- Oracle Database 11g Express Edition. Run as SYSDBA.
-- =====================================================================
set echo on
set linesize 140
set pagesize 60

-- =====================================================================
-- SHORT EXAM
--   1. an Oracle user reachable through OPERATING SYSTEM authentication
--   2. a role named Ucas_rl
--   3. grant CREATE SESSION, CONNECT, CREATE ANY TABLE, RESOURCE to it
--   4. grant the role to the user
--   5. log in with OS authentication, no Oracle password
-- =====================================================================

-- The OS account 'ucas' is created first (see 10a_create_os_user.sh).
-- OS_AUTHENT_PREFIX decides the Oracle user name.
show parameter os_authent_prefix

create role Ucas_rl;

grant create session    to Ucas_rl;
grant connect           to Ucas_rl;
grant create any table  to Ucas_rl;
grant resource          to Ucas_rl;

create user ops$ucas identified externally
  default tablespace users
  quota 5m on users;

grant Ucas_rl to ops$ucas;

-- proof of what was granted
select granted_role, admin_option, default_role
  from dba_role_privs where grantee = 'OPS$UCAS';

select privilege from dba_sys_privs where grantee = 'UCAS_RL' order by privilege;

select granted_role from dba_role_privs where grantee = 'UCAS_RL' order by granted_role;

select username, authentication_type, account_status
  from dba_users where username = 'OPS$UCAS';

-- =====================================================================
-- VERY SHORT EXAM
--   create a user named 2026 and give it the ability to connect.
--   The name begins with a digit, so it is not a valid ordinary
--   identifier and MUST be quoted - otherwise ORA-00911 / ORA-01935.
--   Ucas_rl from the previous exam already carries CREATE SESSION,
--   so granting that role is enough, as the question allows.
-- =====================================================================
create user "2026" identified by "Ucas#2026"
  default tablespace users
  quota 5m on users;

grant Ucas_rl to "2026";

select username, authentication_type, account_status
  from dba_users where username = '2026';

select granted_role from dba_role_privs where grantee = '2026';

exit
