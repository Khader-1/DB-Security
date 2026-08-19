-- =====================================================================
-- PROJECT 1 - Authentication & Authorization
-- Run as SYSDBA.
--
-- Requirements covered:
--   1. A user authenticated EXTERNALLY (by the operating system)
--   2. A user authenticated by PASSWORD
--   3. Roles, each granted appropriate privileges
--   4. A PROFILE, with an explanation of how it works and how to enable it
--   5. Users bound to the roles
--   6. Proof that permitted operations succeed and unauthorized ones fail
-- =====================================================================
set echo on
set linesize 140

-- =====================================================================
-- 4. PROFILE
-- ---------------------------------------------------------------------
-- A profile is a named set of limits attached to a user. It has two
-- kinds of limits:
--   * PASSWORD limits - always enforced.
--   * KERNEL/resource limits (SESSIONS_PER_USER, IDLE_TIME, ...) - only
--     enforced when the instance parameter RESOURCE_LIMIT = TRUE, which
--     is why 00_instance_config.sql sets it. That is "how it is enabled".
-- =====================================================================

-- NOTE: the password complexity checker VERIFY_FUNCTION_11G is installed
-- by 02a_password_verify_function.sql, which must be run BEFORE this
-- script. Calling @?/rdbms/admin/utlpwdmg.sql inline from here breaks the
-- statements that follow it (the nested script leaves the SQL*Plus buffer
-- in a state where the next CREATE ROLE statements are silently skipped).

create profile khader_prof limit
  -- password limits
  failed_login_attempts     3           -- lock the account after 3 bad passwords
  password_lock_time        1/24        -- ... and keep it locked for 1 hour
  password_life_time        30          -- password expires after 30 days
  password_grace_time       3           -- 3 days of warnings before it hard-expires
  password_reuse_max        5           -- cannot reuse until 5 other passwords have been used
  password_reuse_time       30          -- ... and 30 days have passed
  password_verify_function  verify_function_11g   -- complexity rules
  -- kernel/resource limits (need RESOURCE_LIMIT=TRUE)
  sessions_per_user         2           -- at most 2 concurrent sessions
  idle_time                 15          -- kill a session idle for 15 minutes
  connect_time              120         -- maximum session length, 2 hours
  logical_reads_per_session 100000;

-- =====================================================================
-- 3. ROLES  (least privilege: three tiers, granted separately)
-- =====================================================================
-- IMPORTANT: never put a "--" comment after the ";" on the same line.
-- SQL*Plus then silently skips the statement - no output, no error.
-- khader_read_rl      : read the non-sensitive table only
-- khader_write_rl     : modify the non-sensitive table
-- khader_sensitive_rl : read the sensitive tables
create role khader_read_rl;
create role khader_write_rl;
create role khader_sensitive_rl;

grant create session                       to khader_read_rl;
grant select on khader.employees           to khader_read_rl;

grant insert, update, delete on khader.employees to khader_write_rl;

grant select on khader.salaries            to khader_sensitive_rl;
grant select on khader.cards               to khader_sensitive_rl;

-- =====================================================================
-- 2. PASSWORD-AUTHENTICATED USER
-- Verified by Oracle itself: the password hash is stored in the DB.
-- =====================================================================
create user khader_pwd identified by "Khader#120191118"
  default tablespace users
  quota 5m on users
  profile khader_prof;

-- deliberately NOT granted khader_sensitive_rl, so the negative test
-- in 03_project1_tests.sql has something to fail on.
grant khader_read_rl  to khader_pwd;
grant khader_write_rl to khader_pwd;

-- =====================================================================
-- 1. EXTERNALLY AUTHENTICATED USER
-- ---------------------------------------------------------------------
-- Oracle trusts the operating system to have authenticated the user, so
-- no Oracle password is stored or typed. The Oracle username must be
-- OS_AUTHENT_PREFIX || <os username>. Here OS_AUTHENT_PREFIX = 'ops$'
-- and the OS account is khader, so the user must be OPS$KHADER.
-- The OS account is created separately (see 02b_create_os_user.sh).
-- =====================================================================
create user ops$khader identified externally
  default tablespace users
  quota 5m on users
  profile khader_prof;

-- =====================================================================
-- 5. BIND USERS TO ROLES
-- =====================================================================
-- ops$khader is the only account allowed to read the sensitive tables
grant khader_read_rl      to ops$khader;
grant khader_sensitive_rl to ops$khader;

exit
