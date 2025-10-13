### HR Data Security Blueprint on Snowflake

This project is a minimal, end‑to‑end blueprint showing how to secure HR data in Snowflake using:
- Tag‑based dynamic data masking for PII
- Row Access Policies (RAP) for fact tables (absences)
- Clear role separation across HR personas (admin, analyst)

It demonstrates how admins see everything, and analysts access masked PII while being blocked from sensitive facts. Row access still ensures employees can only see their own rows when authenticated as themselves (via CURRENT_USER()) and managers can see direct reports per mapping when applicable.

#### What you can achieve
- Create HR roles and a shared warehouse for all personas.
- Provision an `HR` database with two schemas: `PII` (sensitive attributes) and `ABSENCE` (facts + manager mapping).
- Apply tag‑driven masking to columns such as names, emails, and birthdates.
- Enforce row‑level filtering on `ABSENCE.ABSENCES` so managers see only their team’s rows, employees see their own, and analysts see none.
- Seed realistic sample data and test user accounts to validate access.

#### Why this is useful (benefits)
- Least‑privilege by default: Analysts never see raw PII or absence facts.
- Centralized policy management: Tags bind masking policies once and apply wherever the tag is used.
- Consistent, auditable access: RAP enforces row‑level controls directly in Snowflake.
- Easy demos and onboarding: Seeded data and test users make the model easy to showcase.

#### Files overview
- `01_roles_grants.sql`: Creates roles (`HR_ADMIN`, `HR_ANALYST`), a small warehouse, and grants usage.
- `02_db_schemas.sql`: Creates `HR` database and the `PII` and `ABSENCE` schemas; assigns ownership/usage.
- `03_masking_policies.sql`: Defines tags and masking policies for name, email, and birthdate; attaches policies to tags.
- `04_tables.sql`: Creates `PII.USERS`, `ABSENCE.ABSENCES`, and `ABSENCE.MANAGER_MAP`; applies tags and grants.
- `05_row_access_policy.sql`: Creates and attaches `RAP_ABSENCES` enforcing admin/self/manager access.
- `06_seed_data.sql`: Seeds users, absences, and manager mappings.
- `07_test_users.sql`: Creates three Snowflake users and assigns roles for testing.

#### Execution order
1. `01_roles_grants.sql`
2. `02_db_schemas.sql`
3. `03_masking_policies.sql`
4. `04_tables.sql`
5. `05_row_access_policy.sql`
6. `06_seed_data.sql`
7. `07_test_users.sql` (optional but recommended for quick, role‑based testing)

Run these scripts as a powerful role (e.g., `ACCOUNTADMIN` for creation; `SECURITYADMIN` for users/roles) as noted in each file’s comments.

#### How masking behaves
- Names: Full for admins, first‑letter‑only for analysts, null otherwise.
- Email: Full for admins, domain‑only for analysts, null otherwise.
- Birthdate: Full for admins, year‑only (Jan 1) for analysts, null otherwise.

#### How row access behaves on `ABSENCE.ABSENCES`
- Admins: All rows.
- Self‑access: Any user can see their own absence rows where `USERNAME = CURRENT_USER()`.
- Managers: Can see rows for direct reports per `ABSENCE.MANAGER_MAP`.
- Analysts: No rows returned from `ABSENCE.ABSENCES` due to RAP.

#### Quick test guide
After running the scripts, test with the created users (passwords set in `07_test_users.sql`).

As admin (`U_HR_ADMIN`, role `HR_ADMIN`):
```sql
SELECT * FROM HR.PII.USERS;            -- unmasked
SELECT * FROM HR.ABSENCE.ABSENCES;     -- all rows
```

Public grant on `ABSENCE.ABSENCES` allows querying the table, but returned rows are still restricted by RAP:
```sql
-- As any authenticated user
SELECT * FROM HR.ABSENCE.ABSENCES;     -- own rows; direct reports if you manage others
```

As analyst (`U_HR_ANALYST`, role `HR_ANALYST`):
```sql
SELECT * FROM HR.PII.USERS;            -- masked per policies
SELECT * FROM HR.ABSENCE.ABSENCES;     -- 0 rows
```

Join behavior for non‑admins (blocked by RAP):
```sql
SELECT *
FROM HR.PII.USERS u
JOIN HR.ABSENCE.ABSENCES a ON a.USERNAME = u.USERNAME;  -- 0 rows for analysts
```

#### Notes and next steps
- Replace sample passwords and warehouse sizes for production.
- Extend tags/policies for additional PII (phone, address, etc.).
- Consider separate virtual warehouses per persona for workload isolation.
- Add auditing via Access History to monitor policy effectiveness.

#### Additional public users for testing
Created four users with default `PUBLIC` role and the shared warehouse:
- `JDOE`, `ASMITH`, `BCHEN`, `DLEE`

They can run:
```sql
SELECT * FROM HR.ABSENCE.ABSENCES;   -- returns only their own rows; managers see direct reports
```

