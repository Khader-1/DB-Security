-- =====================================================================
-- 00 - Instance configuration (prerequisite for Projects 1 and 2)
-- Run as: sqlplus sys/oracle@localhost:1521/XE as sysdba
--
-- AUDIT_TRAIL and AUDIT_SYS_OPERATIONS are STATIC parameters: they can
-- only be changed with SCOPE=SPFILE and take effect after a restart.
-- RESOURCE_LIMIT is dynamic and applies immediately.
-- =====================================================================
set echo on
set linesize 140

-- Project 2: write the audit trail into the database (SYS.AUD$) AND keep
-- the literal SQL text of every audited statement. Without the EXTENDED
-- part, SQLTEXT/SQLBIND in DBA_AUDIT_TRAIL stay NULL.
-- NOTE: on 11g the accepted value is db_extended. The 'DB,EXTENDED' form
-- raises ORA-00096 here (valid values: extended, xml, db_extended,
-- false, true, none, os, db).
alter system set audit_trail = 'db_extended' scope = spfile;

-- Project 2: audit privileged (SYSDBA/SYSOPER) activity to OS files.
-- These land outside the database, so a DBA cannot delete them with SQL.
alter system set audit_sys_operations = TRUE scope = spfile;

-- Project 1: without this, the kernel resource limits in a PROFILE
-- (SESSIONS_PER_USER, IDLE_TIME, CONNECT_TIME...) are parsed but ignored.
-- Password limits work regardless.
alter system set resource_limit = TRUE scope = both;

exit
