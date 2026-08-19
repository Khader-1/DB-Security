-- =====================================================================
-- 02a - Install Oracle's supplied password complexity checker.
-- Run as SYSDBA, BEFORE 02_project1.sql.
--
-- utlpwdmg.sql ships with the database. It creates the function
-- VERIFY_FUNCTION_11G, which PROFILE ... PASSWORD_VERIFY_FUNCTION then
-- points at. It also sets that function on the DEFAULT profile.
--
-- Kept in its own file on purpose: running it with @ from inside another
-- script causes the statements after it to be skipped.
-- =====================================================================
@?/rdbms/admin/utlpwdmg.sql

exit
