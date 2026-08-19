#!/usr/bin/env bash
# =====================================================================
# PROJECT 3 - the DISASTER itself.
#
# Deletes the datafile of the USERS tablespace at the operating-system
# level, exactly the way a real accidental deletion or a disk failure
# would look to the database. Nothing is dropped with SQL - the file
# simply disappears underneath a running instance.
#
# Run from the host with the colima-oracle docker context.
# =====================================================================
set -euo pipefail

CONTAINER="${1:-oracle-11g}"
DATAFILE="/u01/app/oracle/oradata/XE/users.dbf"

echo "=== BEFORE: the datafile exists ==="
docker exec "$CONTAINER" bash -lc "ls -la $DATAFILE"

echo
echo "=== the data that is about to become unreachable ==="
docker exec -i "$CONTAINER" bash -lc \
  'sqlplus -s "sys/oracle@localhost:1521/XE as sysdba"' <<'SQL'
set pagesize 30 linesize 120
select emp_id, full_name, dept from khader.employees order by emp_id;
exit
SQL

echo
echo "=== DISASTER: removing the datafile ==="
docker exec -u root "$CONTAINER" bash -lc "rm -f $DATAFILE"

echo
echo "=== AFTER: the datafile is gone ==="
docker exec "$CONTAINER" bash -lc "ls -la $DATAFILE 2>&1 || true"

echo
echo "=== the instance now fails on that tablespace ==="
docker exec -i "$CONTAINER" bash -lc \
  'sqlplus -s "sys/oracle@localhost:1521/XE as sysdba"' <<'SQL'
set pagesize 30 linesize 140
-- force the buffer cache to go to disk for this tablespace
alter system flush buffer_cache;
select emp_id, full_name from khader.employees order by emp_id;
exit
SQL

echo
echo "Disaster simulated. Now run 08_project3_disaster.rman to recover."
