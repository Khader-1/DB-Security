# Database Security — Practical Projects

**Student:** خضر محمد خضر خضير — 120191118
**Course:** أمن قواعد البيانات (Database Security) — ISSE
**Instructor:** م. أحمد شعث
**Date:** 19 August 2026

All three practical projects, executed on a real Oracle Database 11g instance.
Every command and every output in the reports is captured from an actual run —
nothing is transcribed by hand or reconstructed.

---

## 🎥 Video walkthroughs

| Project | Video |
|---|---|
| 1 — Authentication & Authorization | https://youtu.be/r57LtRwGKN8 |
| 2 — Auditing & Monitoring | https://youtu.be/Af34GMC5h3o |
| 3 — Backup & Disaster Recovery | https://youtu.be/JtilfhnOMl8 |

> **Note on the audio.** The terminal sessions were recorded first, and the
> narration was recorded separately afterwards and synchronised to them. This
> was done for audio quality — narrating while typing produces keyboard noise
> and long silences during command execution. The terminal output itself is
> unedited: every command and every result is exactly as it ran.

---

## 📄 Reports

| Report | Pages |
|---|---|
| [Project 1 — Authentication & Authorization](reports/Project1_Report.pdf) | 13 |
| [Project 2 — Auditing & Monitoring](reports/Project2_Report.pdf) | 12 |
| [Project 3 — Backup & Disaster Recovery](reports/Project3_Report.pdf) | 11 |
| [Short Exam](reports/ShortExam_Report.pdf) | 3 |
| [Very Short Exam](reports/VeryShortExam_Report.pdf) | 2 |

Markdown sources are alongside the PDFs. Screenshots in `reports/screens/`
are frames taken from the recorded sessions, so they show the real terminal
at the exact moment each step ran.

---

## 🖥️ Environment

| | |
|---|---|
| Database | Oracle Database 11g Express Edition 11.2.0.2.0 — 64bit Production |
| SID | `XE` |
| Tools | SQL\*Plus 11.2.0.2.0, RMAN 11.2.0.2.0 |
| Host | Linux x86_64 container |

> **Note on the host.** Oracle 11g XE is an amd64-only build. On Apple Silicon it
> cannot run under container-level emulation — Rosetta gets as far as starting the
> listener, then the instance dies with `ORA-45301: XE Edition single instance
> violation error` at `sxecheck4`, because XE's licensing self-check does not
> survive binary translation. It runs correctly inside a full x86_64 virtual
> machine, where the kernel is genuinely x86. `--shm-size=2g` is also mandatory,
> otherwise `MEMORY_TARGET` fails against Docker's default 64 MB `/dev/shm`
> (`ORA-00845`).

---

## Project 1 — Authentication & Authorization

Creates two users that authenticate in fundamentally different ways, a profile,
three roles following least privilege, and proves that permitted operations
succeed while unauthorized ones fail.

| Requirement | Implementation |
|---|---|
| Externally authenticated user | `OPS$KHADER` — `IDENTIFIED EXTERNALLY` |
| Password authenticated user | `KHADER_PWD` — `IDENTIFIED BY` |
| Roles with appropriate privileges | `KHADER_READ_RL`, `KHADER_WRITE_RL`, `KHADER_SENSITIVE_RL` |
| Profile + how it is enabled | `KHADER_PROF` + `RESOURCE_LIMIT = TRUE` |
| Users bound to roles | `DBA_ROLE_PRIVS` |
| Allowed succeeds / denied fails | `SELECT`/`INSERT` succeed, `ORA-00942` on the sensitive tables |

**Points worth knowing:**

- A profile has two kinds of limits. **Password limits always apply.**
  **Resource limits (`SESSIONS_PER_USER`, `IDLE_TIME`, …) are silently ignored
  unless `RESOURCE_LIMIT = TRUE`** — that is the answer to "how is it enabled".
- The denial is `ORA-00942: table or view does not exist`, **not** "insufficient
  privileges". Oracle hides the *existence* of an object from anyone without
  privilege on it, so an attacker cannot enumerate sensitive table names from
  error messages. `DESCRIBE` fails the same way with `ORA-04043`.
- The OS account behind `OPS$KHADER` is deliberately **not** in the `dba` group.
  Membership would allow `sqlplus / AS SYSDBA` and bypass the whole authorization
  model. `$ORACLE_HOME/bin/sqlplus` is mode `-rwxr-x--x`, so no extra group is needed.

## Project 2 — Auditing & Monitoring

Standard auditing into the database with the SQL text retained, two independent
mechanisms over the sensitive data, and three layers protecting the audit records.

| Requirement | Implementation |
|---|---|
| Audit trail in the DB, with SQL text | `AUDIT_TRAIL = db_extended` |
| Less sensitive data | `AUDIT … ON KHADER.EMPLOYEES BY ACCESS` |
| Two mechanisms for sensitive data | standard auditing **+** `:OLD`/`:NEW` trigger |
| Auditing trigger | `KHADER.TRG_SALARIES_AUDIT` |
| Protect audit records from the DBA | audit `SYS.AUD$`, OS-level trail, append-only trigger |
| Analysis | `DBA_AUDIT_TRAIL` + `SECAUD.SALARY_AUDIT_LOG` |

**Why the two mechanisms are complementary, not redundant:**

| | Standard auditing | Trigger |
|---|---|---|
| Captures `SELECT` | ✅ | ❌ DML only |
| Shows the values before/after | ❌ statement only | ✅ `OLD_SALARY` → `NEW_SALARY` |
| Needs code | ❌ | ✅ |

Standard auditing answers *who did what, and when*; the trigger answers
*what value changed, and to what*.

**On the limits of the protection** — stated plainly because it is the honest
answer: a DBA holds `ALTER ANY TRIGGER` and `DROP ANY TABLE` and can disable the
in-database layers. Real separation of duties needs Oracle Database Vault or
Audit Vault, neither of which exists in XE (`V$OPTION` reports `FALSE`). The
strongest control actually available here is the OS-level trail written to
`AUDIT_FILE_DEST`, outside the database.

## Project 3 — Backup & Disaster Recovery

ARCHIVELOG mode, full RMAN backup with control file autobackup, then a real
disaster: the datafile is deleted from disk while the database is running.

| Requirement | Implementation |
|---|---|
| ARCHIVELOG mode | `NOARCHIVELOG` → `ARCHIVELOG` |
| RMAN configuration | retention, channels, backup optimization |
| Control file autobackup | `CONFIGURE CONTROLFILE AUTOBACKUP ON` |
| Full backup | `BACKUP DATABASE PLUS ARCHIVELOG` |
| Disaster recovery | `rm users.dbf` → `RESTORE` + `RECOVER` |

**The core distinction:** `RESTORE` copies the datafile back from the backup —
but it comes back *as it was when the backup was taken*. `RECOVER` then applies
the archived redo logs written since, bringing it into step with the rest of the
database. In `NOARCHIVELOG` mode those logs would not exist and everything after
the backup would be lost. That is what ARCHIVELOG mode is for.

**Proof the recovery was genuine:** row `1004` and `dept = 'Security'` on employee
`1001` were written during the Project 1 and 2 test runs, *after* the backup.
They are present after recovery — so the redo was really applied, rather than an
old copy of the file simply being dropped back into place.

---

## ⚠️ Express Edition limitations encountered

Both were verified against the live instance, not assumed:

| Feature | Status | Evidence |
|---|---|---|
| Fine-Grained Auditing (`DBMS_FGA`) | unavailable | `ORA-00439: feature not enabled` |
| Flashback Database | unavailable | `V$OPTION` → `FALSE` |
| Oracle Database Vault | unavailable | `V$OPTION` → `FALSE` |

Both are Enterprise Edition features. FGA is covered in the course material, but
the Project 2 brief requires the auditing trigger *"إن كانت مدعومة في بيئة العمل"*
(if supported in your environment), and the two mechanisms implemented are exactly
the pair shown in the course file `Old New Value Auditing.txt`. Project 3 never
requires Flashback — ARCHIVELOG plus RMAN restore/recover covers every stated
requirement.

## 🐛 Version-specific issues found

Worth recording, since two of these appear in the course material and fail on 11g:

| Issue | Detail |
|---|---|
| `AUDIT_TRAIL = 'DB,EXTENDED'` | `ORA-00096` on 11g — the accepted value is `db_extended` |
| `AUDIT GRANT, REVOKE BY ACCESS` | `ORA-00956` — the correct form is `AUDIT SYSTEM GRANT` |
| `GENERATED AS IDENTITY` | 12c and later only — a `SEQUENCE` is required on 11g |
| `INSERTING`/`UPDATING` inside SQL | PL/SQL predicates; using them in a `CASE` inside `VALUES` gives `ORA-00920` |
| A `--` comment after `;` in SQL\*Plus | the statement is silently skipped — no output, no error |
| Numeric-only password | rejected by `VERIFY_FUNCTION_11G` (`ORA-28003` / `ORA-20001`) |

---

## 📂 Layout

```
reports/      the three reports (PDF + Markdown) and their screenshots
sql/          every script, in execution order
output/       raw captured output of each run
sessions/     the exact commands typed in each recorded session
```

Scripts run in order: `00_instance_config` → `01_app_schema` →
`02a_password_verify_function` → `02_project1` → `03_project1_tests` →
`04_project2` → `05_project2_tests` → `06_project3_archivelog` →
`07_project3_backup` → `08a_simulate_disaster` → `08_project3_disaster`.
`00b_reset.sql` returns the database to a clean state so the whole sequence
can be replayed.
