-- =====================================================================
-- 01 - Demo application schema used by BOTH projects
-- Run as SYSDBA.
--
-- Two sensitivity tiers, because Project 2 requires different monitoring
-- for "less sensitive" vs "most sensitive" data:
--   KHADER.EMPLOYEES -> less sensitive  (names, department, email)
--   KHADER.SALARIES  -> most sensitive  (pay figures)
--   KHADER.CARDS     -> most sensitive  (card numbers)
-- =====================================================================
set echo on
set linesize 140

-- ---------- schema owner ----------
-- NOTE: the password must satisfy VERIFY_FUNCTION_11G, which
-- 02a_password_verify_function.sql attaches to the DEFAULT profile
-- (min 8 chars, letter + digit + punctuation, and it must differ from
-- the username). A simple password here fails with
-- ORA-28003 / ORA-20001: Password length less than 8.
create user khader identified by "Khader#2026"
  default tablespace users
  quota unlimited on users;

grant create session, create table, create procedure, create trigger to khader;

-- ---------- less sensitive ----------
create table khader.employees (
  emp_id     number(6)    primary key,
  full_name  varchar2(60) not null,
  dept       varchar2(30),
  email      varchar2(60)
);

-- ---------- most sensitive ----------
create table khader.salaries (
  emp_id       number(6) primary key,
  base_salary  number(10,2) not null,
  bonus        number(10,2)
);

create table khader.cards (
  card_id   number(6) primary key,
  emp_id    number(6),
  card_no   varchar2(19),
  cvv       varchar2(4)
);

-- ---------- sample data ----------
insert into khader.employees values (1001, 'Khader Khudair',  'IT',      'khader@ucas.edu.ps');
insert into khader.employees values (1002, 'Sara Ahmed',      'Finance', 'sara@ucas.edu.ps');
insert into khader.employees values (1003, 'Omar Nabil',      'HR',      'omar@ucas.edu.ps');

insert into khader.salaries values (1001, 4500.00, 500.00);
insert into khader.salaries values (1002, 5200.00, 750.00);
insert into khader.salaries values (1003, 3900.00, 300.00);

insert into khader.cards values (1, 1001, '4111-1111-1111-1111', '123');
insert into khader.cards values (2, 1002, '5500-0000-0000-0004', '456');

commit;

exit
