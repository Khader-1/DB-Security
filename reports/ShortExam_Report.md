# تقرير الامتحان القصير — Short Exam

| | |
|---|---|
| **المقرر** | أمن قواعد البيانات — Database Security |
| **الطالب** | خضر محمد خضر خضير |
| **الرقم الجامعي** | 120191118 |
| **مدرّس المقرر** | م. أحمد شعث |
| **البيئة** | Oracle Database 11g Express Edition 11.2.0.2.0 |

---

## المطلوب

إنشاء مستخدم Oracle يستطيع الوصول إلى قاعدة البيانات عبر **مصادقة نظام التشغيل**،
وإنشاء دور باسم `Ucas_rl` ومنحه الصلاحيات `CREATE SESSION`, `CONNECT`,
`CREATE ANY TABLE`, `RESOURCE`، ثم منح الدور للمستخدم، وتسجيل الدخول دون إدخال
كلمة مرور لـ Oracle، والتحقق من نجاح الدخول.

---

## 1. التحقق من بادئة المصادقة الخارجية

اسم المستخدم في Oracle يجب أن يساوي `OS_AUTHENT_PREFIX` مضافًا إليه اسم حساب نظام التشغيل:

```sql
SHOW PARAMETER os_authent_prefix
```

```
NAME                 TYPE        VALUE
-------------------- ----------- ------
os_authent_prefix    string      ops$
```

وبما أن حساب نظام التشغيل هو `ucas`، يصبح اسم المستخدم في Oracle هو `OPS$UCAS`.

```bash
# على مستوى نظام التشغيل
useradd -m ucas
```

---

## 2. إنشاء الدور ومنحه الصلاحيات

```sql
CREATE ROLE Ucas_rl;

GRANT create session    TO Ucas_rl;
GRANT connect           TO Ucas_rl;
GRANT create any table  TO Ucas_rl;
GRANT resource          TO Ucas_rl;
```

```
Role created.
Grant succeeded.
Grant succeeded.
Grant succeeded.
Grant succeeded.
```

**التحقق من صلاحيات الدور:**

```sql
SELECT privilege FROM dba_sys_privs WHERE grantee = 'UCAS_RL' ORDER BY privilege;
SELECT granted_role FROM dba_role_privs WHERE grantee = 'UCAS_RL';
```

`CONNECT` و`RESOURCE` هما دوران جاهزان في Oracle، بينما `CREATE SESSION`
و`CREATE ANY TABLE` صلاحيتان نظاميتان — ولذلك يظهران في جدولين مختلفين.

---

## 3. إنشاء المستخدم بمصادقة خارجية ومنحه الدور

```sql
CREATE USER ops$ucas IDENTIFIED EXTERNALLY
  DEFAULT TABLESPACE users
  QUOTA 5M ON users;

GRANT Ucas_rl TO ops$ucas;
```

```
User created.
Grant succeeded.
```

```sql
SELECT username, authentication_type, account_status
  FROM dba_users WHERE username = 'OPS$UCAS';
```

```
USERNAME     AUTHENTICATION_TYPE  ACCOUNT_STATUS
------------ -------------------- --------------
OPS$UCAS     EXTERNAL             OPEN
```

العمود `AUTHENTICATION_TYPE` يساوي `EXTERNAL` — أي أن Oracle **لا تخزّن** كلمة مرور
لهذا المستخدم، بل تثق بنظام التشغيل في التحقق من هويته.

---

## 4. تسجيل الدخول بمصادقة نظام التشغيل — دون كلمة مرور

```bash
# الدخول بحساب نظام التشغيل ucas، ثم تشغيل SQL*Plus بشرطة مائلة فقط
sqlplus /
```

```sql
SHOW USER
SELECT 'LOGGED IN WITHOUT AN ORACLE PASSWORD' AS proof FROM dual;
```

```
USER is "OPS$UCAS"

PROOF
------------------------------------
LOGGED IN WITHOUT AN ORACLE PASSWORD
```

✅ **تم الدخول بنجاح دون إدخال أي اسم مستخدم أو كلمة مرور لـ Oracle.**

---

## 5. التحقق من عمل الصلاحيات الممنوحة

لإثبات أن الدور يعمل فعليًا وليس مجرد منح شكلي:

```sql
CREATE TABLE ucas_test (id NUMBER);
INSERT INTO ucas_test VALUES (1);
COMMIT;
SELECT * FROM ucas_test;
```

```
Table created.

1 row created.

Commit complete.

        ID
----------
         1
```

✅ نجاح إنشاء الجدول يثبت عمل `CREATE ANY TABLE` و`RESOURCE`،
ونجاح الاتصال أصلًا يثبت عمل `CREATE SESSION` و`CONNECT`.

---

## الخلاصة

| المتطلب | الحالة | الدليل |
|---|---|---|
| مستخدم بمصادقة خارجية | ✅ | `OPS$UCAS` — `AUTHENTICATION_TYPE = EXTERNAL` |
| دور باسم `Ucas_rl` | ✅ | `Role created.` |
| منح الصلاحيات الأربع للدور | ✅ | أربع رسائل `Grant succeeded.` |
| منح الدور للمستخدم | ✅ | `DBA_ROLE_PRIVS` |
| الدخول بمصادقة نظام التشغيل | ✅ | `USER is "OPS$UCAS"` بدون كلمة مرور |
| التحقق من نجاح الدخول | ✅ | إنشاء جدول وإدخال بيانات بنجاح |

**ملاحظة أمنية:** لم يُضَف حساب نظام التشغيل `ucas` إلى مجموعة `dba`،
لأن العضوية فيها تتيح الدخول بـ `sqlplus / AS SYSDBA` وتتجاوز نموذج الصلاحيات بالكامل.
