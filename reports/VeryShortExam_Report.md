# تقرير الامتحان القصير جدًا — Very Short Exam

| | |
|---|---|
| **المقرر** | أمن قواعد البيانات — Database Security |
| **الطالب** | خضر محمد خضر خضير |
| **الرقم الجامعي** | 120191118 |
| **مدرّس المقرر** | م. أحمد شعث |
| **البيئة** | Oracle Database 11g Express Edition 11.2.0.2.0 |

---

## المطلوب

إنشاء مستخدم باسم `2026`، ومنحه صلاحية الاتصال بقاعدة البيانات — ويجوز منحه الدور
`Ucas_rl` المُنشأ سابقًا في الامتحان السابق — ثم إثبات نجاح تسجيل الدخول.

---

## 1. إنشاء المستخدم

```sql
CREATE USER "2026" IDENTIFIED BY "Ucas#2026"
  DEFAULT TABLESPACE users
  QUOTA 5M ON users;
```

```
User created.
```

> **نقطة مهمة:** اسم المستخدم `2026` يبدأ برقم، وهو بذلك **ليس معرّفًا صالحًا**
> (Identifier) في Oracle. فالمعرّف العادي يجب أن يبدأ بحرف.
> ولذلك وجب وضعه بين **علامتَي تنصيص مزدوجتين** ليُعامل كـ Quoted Identifier.
> وبدونها ينتج الخطأ:
> ```
> ORA-00911: invalid character
> ```
> وترتّب على ذلك أن اسم المستخدم يبقى مخزَّنًا كما هو `2026`،
> ويجب وضعه بين علامتَي تنصيص في كل استخدام لاحق.

---

## 2. منح صلاحية الاتصال

استُخدم الدور `Ucas_rl` المُنشأ في الامتحان السابق، وهو يحمل `CREATE SESSION`
و`CONNECT` — وهذا ما تسمح به ورقة الامتحان صراحةً:

```sql
GRANT Ucas_rl TO "2026";
```

```
Grant succeeded.
```

**التحقق:**

```sql
SELECT username, authentication_type, account_status
  FROM dba_users WHERE username = '2026';

SELECT granted_role FROM dba_role_privs WHERE grantee = '2026';
```

```
USERNAME     AUTHENTICATION_TYPE  ACCOUNT_STATUS
------------ -------------------- --------------
2026         PASSWORD             OPEN

GRANTED_ROLE
------------
UCAS_RL
```

`AUTHENTICATION_TYPE = PASSWORD` أي أن هذا المستخدم — بخلاف مستخدم الامتحان السابق —
تتحقّق Oracle من هويته بكلمة مرور مخزّنة داخل قاعدة البيانات.

---

## 3. إثبات نجاح تسجيل الدخول

```bash
sqlplus "2026"/"Ucas#2026"@localhost:1521/XE
```

```sql
SHOW USER
SELECT 'USER 2026 CONNECTED SUCCESSFULLY' AS proof FROM dual;
```

```
USER is "2026"

PROOF
--------------------------------
USER 2026 CONNECTED SUCCESSFULLY
```

✅ **تم تسجيل الدخول بنجاح بالمستخدم `2026`.**

---

## الخلاصة

| المتطلب | الحالة | الدليل |
|---|---|---|
| إنشاء مستخدم باسم `2026` | ✅ | `User created.` مع وضع الاسم بين علامتَي تنصيص |
| منح صلاحية الاتصال | ✅ | `GRANT Ucas_rl TO "2026"` |
| إثبات نجاح الدخول | ✅ | `USER is "2026"` |

**أهم نقطة في هذا الامتحان** هي التعامل مع اسم المستخدم الذي يبدأ برقم:
فهو يتطلّب Quoted Identifier، وإلا فشل الأمر من أساسه.
