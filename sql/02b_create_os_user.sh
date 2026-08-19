#!/usr/bin/env bash
# =====================================================================
# PROJECT 1 - operating-system account backing the EXTERNALLY
# authenticated Oracle user OPS$KHADER.
#
# Oracle does not create OS accounts; it only trusts them. So the OS
# account must exist with exactly the name that follows the
# OS_AUTHENT_PREFIX ('ops$'), i.e. Oracle user OPS$KHADER <-> OS user
# khader.
#
# Deliberately NOT added to the 'dba' group: membership in dba would let
# this account connect "/ as sysdba" and bypass the whole authorization
# model. $ORACLE_HOME/bin/sqlplus is mode -rwxr-x--x, so "others" can
# already execute it - no extra group is needed.
#
# Run from the host (Docker context = colima-oracle).
# =====================================================================
set -euo pipefail

CONTAINER="${1:-oracle-11g}"

docker exec -u root "$CONTAINER" bash -lc '
  id khader >/dev/null 2>&1 || useradd -m khader
  # let the account find the Oracle client libraries
  cat > /home/khader/.bash_profile <<EOF
export ORACLE_HOME=/u01/app/oracle/product/11.2.0/xe
export ORACLE_SID=XE
export PATH=\$ORACLE_HOME/bin:\$PATH
export LD_LIBRARY_PATH=\$ORACLE_HOME/lib
EOF
  chown khader:khader /home/khader/.bash_profile
  id khader
'
