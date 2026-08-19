#!/usr/bin/env bash
# =====================================================================
# PROJECT 3 - runs the whole backup & disaster-recovery exercise and
# captures every command and its real output into ../output/.
#
# NOTE: STARTUP/SHUTDOWN require a LOCAL (bequeath) connection, so these
# steps use "sqlplus / as sysdba" from inside the container, not a TNS
# connection through the listener.
# =====================================================================
set -uo pipefail

export DOCKER_HOST=unix:///Users/khaderkhudair/.colima/oracle/docker.sock
C="${1:-oracle-11g}"
HERE="$(cd "$(dirname "$0")" && pwd)"
OUT="$HERE/../output"
mkdir -p "$OUT"

# local sysdba (can do startup/shutdown); ORAENV sets the environment
LOCAL='export ORACLE_HOME=/u01/app/oracle/product/11.2.0/xe; export ORACLE_SID=XE; export PATH=$ORACLE_HOME/bin:$PATH;'

banner() { echo; echo "############ $1 ############"; echo; }

banner "0. create the Fast Recovery Area directory"
docker exec -u root "$C" bash -lc \
  'mkdir -p /u01/app/oracle/fast_recovery_area && chown oracle:dba /u01/app/oracle/fast_recovery_area && ls -ld /u01/app/oracle/fast_recovery_area'

banner "1. enable ARCHIVELOG mode"
docker cp "$HERE/06_project3_archivelog.sql" "$C:/tmp/" >/dev/null
docker exec "$C" bash -lc "$LOCAL sqlplus -s / as sysdba @/tmp/06_project3_archivelog.sql" 2>&1 \
  | tee "$OUT/06_archivelog.out" | tail -25

banner "2. RMAN configuration + FULL BACKUP (this is the slow step)"
docker cp "$HERE/07_project3_backup.rman" "$C:/tmp/" >/dev/null
docker exec "$C" bash -lc "$LOCAL rman target / cmdfile=/tmp/07_project3_backup.rman" 2>&1 \
  | tee "$OUT/07_backup.out" | tail -30

banner "3. simulate the disaster (delete users.dbf)"
bash "$HERE/08a_simulate_disaster.sh" "$C" 2>&1 | tee "$OUT/08a_disaster.out" | tail -25

banner "4. restore + recover"
docker cp "$HERE/08_project3_disaster.rman" "$C:/tmp/" >/dev/null
docker exec "$C" bash -lc "$LOCAL rman target / cmdfile=/tmp/08_project3_disaster.rman" 2>&1 \
  | tee "$OUT/08_recover.out" | tail -30

banner "5. verify the data came back"
docker exec -i "$C" bash -lc "$LOCAL sqlplus -s / as sysdba" <<'SQL' 2>&1 | tee "$OUT/09_verify.out"
set pagesize 40 linesize 130
select 'RECOVERED' as status from dual;
select emp_id, full_name, dept from khader.employees order by emp_id;
select file#, name, status from v$datafile order by file#;
select log_mode from v$database;
exit
SQL

banner "PROJECT 3 COMPLETE"
