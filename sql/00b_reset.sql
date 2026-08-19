-- =====================================================================
-- 00b - Reset. Drops everything the two projects create, so the demo
-- can be replayed from a clean state (useful when recording the video).
-- Run as SYSDBA. Safe to run when the objects do not exist yet.
-- =====================================================================
set serveroutput on
declare
  procedure run(p_sql varchar2) is
  begin
    execute immediate p_sql;
    dbms_output.put_line('OK   : '||p_sql);
  exception when others then
    dbms_output.put_line('skip : '||p_sql||' -> '||sqlerrm);
  end;
begin
  -- Project 2 objects first (they depend on Project 1 users)
  run('noaudit select, insert, update, delete on khader.employees');
  run('noaudit select, insert, update, delete on khader.salaries');
  run('drop trigger khader.trg_salaries_audit');
  run('drop trigger secaud.trg_protect_salary_log');
  run('drop user secaud cascade');
  -- Project 1 objects
  run('drop user khader_pwd cascade');
  run('drop user ops$khader cascade');
  run('drop role khader_read_rl');
  run('drop role khader_write_rl');
  run('drop role khader_sensitive_rl');
  run('drop profile khader_prof cascade');
  -- demo schema
  run('drop user khader cascade');
end;
/
exit
