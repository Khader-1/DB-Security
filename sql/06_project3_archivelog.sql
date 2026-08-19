-- =====================================================================
-- PROJECT 3 - Oracle Database 11g Backup & Disaster Recovery
-- PART 1 of 3: Backup Configuration (إعدادات النسخ الاحتياطي)
--
-- Run as SYSDBA, connected LOCALLY (bequeath), not through the listener:
--     sqlplus / as sysdba
-- A STARTUP/SHUTDOWN cannot be issued over a normal TNS connection.
--
-- Follows the sequence used in the course file "Flashback database.txt".
-- =====================================================================
set echo on
set linesize 140

-- ---------------------------------------------------------------------
-- 1. Where do the archived redo logs and the autobackups go?
--    The Fast Recovery Area is the standard destination. Without it,
--    archiving falls back to $ORACLE_HOME/dbs, which is not a sane
--    place for a production backup.
-- ---------------------------------------------------------------------
alter system set db_recovery_file_dest_size = 3G scope = both;
alter system set db_recovery_file_dest = '/u01/app/oracle/fast_recovery_area' scope = both;

show parameter db_recovery_file_dest

-- ---------------------------------------------------------------------
-- 2. Current state - the database starts in NOARCHIVELOG mode.
--    In that mode the redo logs are overwritten in a circle, so only a
--    COLD (consistent) backup is possible and point-in-time recovery is
--    impossible. ARCHIVELOG mode is what makes RMAN online backup and
--    real recovery work at all.
-- ---------------------------------------------------------------------
select log_mode from v$database;

-- ---------------------------------------------------------------------
-- 3. Switch to ARCHIVELOG. This REQUIRES the database to be MOUNTED
--    but not OPEN.
-- ---------------------------------------------------------------------
shutdown immediate;

startup mount;

alter database archivelog;

alter database open;

-- ---------------------------------------------------------------------
-- 4. Verify
-- ---------------------------------------------------------------------
select log_mode from v$database;

archive log list;

-- Force a log switch so at least one archived log exists to back up
alter system switch logfile;
alter system archive log current;

select sequence#, name, status from v$archived_log order by sequence#;

exit
