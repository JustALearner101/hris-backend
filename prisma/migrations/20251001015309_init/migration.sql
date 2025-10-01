-- ========================================================
-- SCHEMAS
-- ========================================================
CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS time;
CREATE SCHEMA IF NOT EXISTS payroll;
CREATE SCHEMA IF NOT EXISTS finance;
CREATE SCHEMA IF NOT EXISTS asset;
CREATE SCHEMA IF NOT EXISTS talent;
CREATE SCHEMA IF NOT EXISTS comm;
CREATE SCHEMA IF NOT EXISTS audit;

-- ========================================================
-- AUTH SCHEMA
-- ========================================================
CREATE TABLE auth.users (
                            id TEXT PRIMARY KEY,
                            tenant_id TEXT NOT NULL,
                            email TEXT NOT NULL UNIQUE,
                            password_hash TEXT NOT NULL,
                            role TEXT NOT NULL,
                            created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                            updated_at TIMESTAMP(3) NOT NULL,
                            deleted_at TIMESTAMP(3),
                            version INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE auth.roles (
                            id TEXT PRIMARY KEY,
                            tenant_id TEXT NOT NULL,
                            name TEXT NOT NULL,
                            permissions JSONB NOT NULL,
                            created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                            updated_at TIMESTAMP(3) NOT NULL,
                            deleted_at TIMESTAMP(3),
                            version INTEGER NOT NULL DEFAULT 1
);

-- ========================================================
-- CORE SCHEMA
-- ========================================================
CREATE TABLE core.tenant (
                             id TEXT PRIMARY KEY,
                             name TEXT NOT NULL,
                             created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                             updated_at TIMESTAMP(3) NOT NULL,
                             deleted_at TIMESTAMP(3),
                             version INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE core.entity (
                             id TEXT PRIMARY KEY,
                             tenant_id TEXT NOT NULL REFERENCES core.tenant(id),
                             name TEXT NOT NULL,
                             timezone TEXT NOT NULL DEFAULT 'Asia/Jakarta',
                             created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                             updated_at TIMESTAMP(3) NOT NULL,
                             deleted_at TIMESTAMP(3),
                             version INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE core.department (
                                 id TEXT PRIMARY KEY,
                                 tenant_id TEXT NOT NULL,
                                 entity_id TEXT REFERENCES core.entity(id),
                                 name TEXT NOT NULL,
                                 parent_id TEXT REFERENCES core.department(id),
                                 created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                 updated_at TIMESTAMP(3) NOT NULL,
                                 deleted_at TIMESTAMP(3),
                                 version INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE core.position (
                               id TEXT PRIMARY KEY,
                               tenant_id TEXT NOT NULL,
                               entity_id TEXT REFERENCES core.entity(id),
                               department_id TEXT REFERENCES core.department(id),
                               title TEXT NOT NULL,
                               grade_id TEXT,
                               created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                               updated_at TIMESTAMP(3) NOT NULL,
                               deleted_at TIMESTAMP(3),
                               version INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE core.grade (
                            id TEXT PRIMARY KEY,
                            tenant_id TEXT NOT NULL,
                            entity_id TEXT REFERENCES core.entity(id),
                            code TEXT NOT NULL,
                            description TEXT,
                            created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                            updated_at TIMESTAMP(3) NOT NULL,
                            deleted_at TIMESTAMP(3),
                            version INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE core.employee (
                               id TEXT PRIMARY KEY,
                               tenant_id TEXT NOT NULL,
                               entity_id TEXT REFERENCES core.entity(id),
                               employee_no TEXT NOT NULL,
                               first_name TEXT NOT NULL,
                               last_name TEXT,
                               email TEXT UNIQUE,
                               nik TEXT,
                               npwp TEXT,
                               hire_date TIMESTAMP(3) NOT NULL,
                               created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                               updated_at TIMESTAMP(3) NOT NULL,
                               deleted_at TIMESTAMP(3),
                               version INTEGER NOT NULL DEFAULT 1,
                               CONSTRAINT uq_employee_per_tenant UNIQUE (tenant_id, employee_no)
);

CREATE TABLE core.employment (
                                 id TEXT PRIMARY KEY,
                                 tenant_id TEXT NOT NULL,
                                 entity_id TEXT REFERENCES core.entity(id),
                                 employee_id TEXT REFERENCES core.employee(id),
                                 position_id TEXT REFERENCES core.position(id),
                                 start_date DATE NOT NULL,
                                 end_date DATE,
                                 status TEXT NOT NULL CHECK (status IN ('ACTIVE','TERMINATED','SUSPENDED')),
                                 created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                 updated_at TIMESTAMP(3) NOT NULL,
                                 deleted_at TIMESTAMP(3),
                                 version INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE core.compensation (
                                   id TEXT PRIMARY KEY,
                                   tenant_id TEXT NOT NULL,
                                   entity_id TEXT REFERENCES core.entity(id),
                                   employee_id TEXT REFERENCES core.employee(id),
                                   base_salary NUMERIC(15,2) NOT NULL,
                                   currency TEXT NOT NULL DEFAULT 'IDR',
                                   allowances JSONB,
                                   effective_date DATE NOT NULL,
                                   created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                   updated_at TIMESTAMP(3) NOT NULL,
                                   deleted_at TIMESTAMP(3),
                                   version INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE core.document (
                               id TEXT PRIMARY KEY,
                               tenant_id TEXT NOT NULL,
                               entity_id TEXT REFERENCES core.entity(id),
                               employee_id TEXT REFERENCES core.employee(id),
                               type TEXT NOT NULL,
                               file_url TEXT NOT NULL,
                               signed BOOLEAN DEFAULT FALSE,
                               created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                               updated_at TIMESTAMP(3) NOT NULL,
                               deleted_at TIMESTAMP(3),
                               version INTEGER NOT NULL DEFAULT 1
);

-- ========================================================
-- TIME SCHEMA
-- ========================================================
CREATE TABLE time.attendance_event (
                                       id TEXT PRIMARY KEY,
                                       tenant_id TEXT NOT NULL,
                                       entity_id TEXT,
                                       employee_id TEXT REFERENCES core.employee(id),
                                       type TEXT NOT NULL CHECK (type IN ('CLOCK_IN','CLOCK_OUT')),
                                       occurred_at TIMESTAMP(3) NOT NULL,
                                       source TEXT,
                                       geo JSONB,
                                       created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                       updated_at TIMESTAMP(3) NOT NULL,
                                       deleted_at TIMESTAMP(3),
                                       version INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE time.shift (
                            id TEXT PRIMARY KEY,
                            tenant_id TEXT NOT NULL,
                            entity_id TEXT,
                            name TEXT NOT NULL,
                            start_time TIME NOT NULL,
                            end_time TIME NOT NULL,
                            created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                            updated_at TIMESTAMP(3) NOT NULL,
                            deleted_at TIMESTAMP(3),
                            version INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE time.schedule (
                               id TEXT PRIMARY KEY,
                               tenant_id TEXT NOT NULL,
                               entity_id TEXT,
                               employee_id TEXT REFERENCES core.employee(id),
                               shift_id TEXT REFERENCES time.shift(id),
                               date DATE NOT NULL,
                               created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                               updated_at TIMESTAMP(3) NOT NULL,
                               deleted_at TIMESTAMP(3),
                               version INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE time.timesheet (
                                id TEXT PRIMARY KEY,
                                tenant_id TEXT NOT NULL,
                                entity_id TEXT,
                                employee_id TEXT REFERENCES core.employee(id),
                                period_start DATE NOT NULL,
                                period_end DATE NOT NULL,
                                total_hours NUMERIC(10,2),
                                overtime_hours NUMERIC(10,2),
                                created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                updated_at TIMESTAMP(3) NOT NULL,
                                deleted_at TIMESTAMP(3),
                                version INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE time.overtime (
                               id TEXT PRIMARY KEY,
                               tenant_id TEXT NOT NULL,
                               entity_id TEXT,
                               employee_id TEXT REFERENCES core.employee(id),
                               date DATE NOT NULL,
                               hours NUMERIC(10,2) NOT NULL,
                               reason TEXT,
                               approved BOOLEAN DEFAULT FALSE,
                               created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                               updated_at TIMESTAMP(3) NOT NULL,
                               deleted_at TIMESTAMP(3),
                               version INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE time.leave_policy (
                                   id TEXT PRIMARY KEY,
                                   tenant_id TEXT NOT NULL,
                                   entity_id TEXT,
                                   name TEXT NOT NULL,
                                   type TEXT NOT NULL,
                                   accrual NUMERIC(10,2),
                                   carry_over BOOLEAN DEFAULT TRUE,
                                   created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                   updated_at TIMESTAMP(3) NOT NULL,
                                   deleted_at TIMESTAMP(3),
                                   version INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE time.leave_balance (
                                    id TEXT PRIMARY KEY,
                                    tenant_id TEXT NOT NULL,
                                    entity_id TEXT,
                                    employee_id TEXT REFERENCES core.employee(id),
                                    policy_id TEXT REFERENCES time.leave_policy(id),
                                    balance NUMERIC(10,2) NOT NULL DEFAULT 0,
                                    created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                    updated_at TIMESTAMP(3) NOT NULL,
                                    deleted_at TIMESTAMP(3),
                                    version INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE time.leave_request (
                                    id TEXT PRIMARY KEY,
                                    tenant_id TEXT NOT NULL,
                                    entity_id TEXT,
                                    employee_id TEXT REFERENCES core.employee(id),
                                    policy_id TEXT REFERENCES time.leave_policy(id),
                                    start_date DATE NOT NULL,
                                    end_date DATE NOT NULL,
                                    status TEXT NOT NULL CHECK (status IN ('PENDING','APPROVED','REJECTED')),
                                    reason TEXT,
                                    created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                    updated_at TIMESTAMP(3) NOT NULL,
                                    deleted_at TIMESTAMP(3),
                                    version INTEGER NOT NULL DEFAULT 1
);

-- ========================================================
-- PAYROLL SCHEMA
-- ========================================================
CREATE TABLE payroll.pay_group (
                                   id TEXT PRIMARY KEY,
                                   tenant_id TEXT NOT NULL,
                                   entity_id TEXT,
                                   name TEXT NOT NULL,
                                   frequency TEXT NOT NULL,
                                   created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                   updated_at TIMESTAMP(3) NOT NULL,
                                   deleted_at TIMESTAMP(3),
                                   version INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE payroll.payroll_run (
                                     id TEXT PRIMARY KEY,
                                     tenant_id TEXT NOT NULL,
                                     entity_id TEXT,
                                     pay_group_id TEXT REFERENCES payroll.pay_group(id),
                                     period_start DATE NOT NULL,
                                     period_end DATE NOT NULL,
                                     payout_date DATE NOT NULL,
                                     status TEXT NOT NULL CHECK (status IN ('PENDING','PROCESSING','COMPLETED','FAILED')),
                                     created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                     updated_at TIMESTAMP(3) NOT NULL,
                                     deleted_at TIMESTAMP(3),
                                     version INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE payroll.payslip (
                                 id TEXT PRIMARY KEY,
                                 tenant_id TEXT NOT NULL,
                                 entity_id TEXT,
                                 payroll_run_id TEXT REFERENCES payroll.payroll_run(id),
                                 employee_id TEXT REFERENCES core.employee(id),
                                 gross_amount NUMERIC(15,2) NOT NULL,
                                 net_amount NUMERIC(15,2) NOT NULL,
                                 file_url TEXT,
                                 created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                 updated_at TIMESTAMP(3) NOT NULL,
                                 deleted_at TIMESTAMP(3),
                                 version INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE payroll.tax_component (
                                       id TEXT PRIMARY KEY,
                                       tenant_id TEXT NOT NULL,
                                       entity_id TEXT,
                                       name TEXT NOT NULL,
                                       rate NUMERIC(6,4) NOT NULL,
                                       created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                       updated_at TIMESTAMP(3) NOT NULL,
                                       deleted_at TIMESTAMP(3),
                                       version INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE payroll.bpjs_component (
                                        id TEXT PRIMARY KEY,
                                        tenant_id TEXT NOT NULL,
                                        entity_id TEXT,
                                        type TEXT NOT NULL,
                                        rate NUMERIC(6,4) NOT NULL,
                                        ceiling NUMERIC(15,2),
                                        created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                        updated_at TIMESTAMP(3) NOT NULL,
                                        deleted_at TIMESTAMP(3),
                                        version INTEGER NOT NULL DEFAULT 1
);

-- ========================================================
-- FINANCE SCHEMA
-- ========================================================
CREATE TABLE finance.expense_report (
                                        id TEXT PRIMARY KEY,
                                        tenant_id TEXT NOT NULL,
                                        entity_id TEXT,
                                        employee_id TEXT REFERENCES core.employee(id),
                                        title TEXT NOT NULL,
                                        total_amount NUMERIC(15,2) NOT NULL,
                                        currency TEXT NOT NULL DEFAULT 'IDR',
                                        status TEXT NOT NULL CHECK (status IN ('PENDING','APPROVED','REJECTED')),
                                        created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                        updated_at TIMESTAMP(3) NOT NULL,
                                        deleted_at TIMESTAMP(3),
                                        version INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE finance.expense_item (
                                      id TEXT PRIMARY KEY,
                                      tenant_id TEXT NOT NULL,
                                      entity_id TEXT,
                                      report_id TEXT REFERENCES finance.expense_report(id),
                                      category TEXT NOT NULL,
                                      amount NUMERIC(15,2) NOT NULL,
                                      currency TEXT NOT NULL DEFAULT 'IDR',
                                      description TEXT,
                                      created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                      updated_at TIMESTAMP(3) NOT NULL,
                                      deleted_at TIMESTAMP(3),
                                      version INTEGER NOT NULL DEFAULT 1
);

-- ========================================================
-- ASSET SCHEMA
-- ========================================================
CREATE TABLE asset.asset (
                             id TEXT PRIMARY KEY,
                             tenant_id TEXT NOT NULL,
                             entity_id TEXT,
                             name TEXT NOT NULL,
                             type TEXT NOT NULL,
                             serial_no TEXT,
                             purchase_date DATE,
                             depreciation_years INT,
                             created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                             updated_at TIMESTAMP(3) NOT NULL,
                             deleted_at TIMESTAMP(3),
                             version INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE asset.asset_assignment (
                                        id TEXT PRIMARY KEY,
                                        tenant_id TEXT NOT NULL,
                                        entity_id TEXT,
                                        asset_id TEXT REFERENCES asset.asset(id),
                                        employee_id TEXT REFERENCES core.employee(id),
                                        assigned_date DATE NOT NULL,
                                        return_date DATE,
                                        created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                        updated_at TIMESTAMP(3) NOT NULL,
                                        deleted_at TIMESTAMP(3),
                                        version INTEGER NOT NULL DEFAULT 1
);

-- ========================================================
-- TALENT SCHEMA
-- ========================================================
CREATE TABLE talent.candidate (
                                  id TEXT PRIMARY KEY,
                                  tenant_id TEXT NOT NULL,
                                  entity_id TEXT,
                                  name TEXT NOT NULL,
                                  email TEXT NOT NULL,
                                  phone TEXT,
                                  status TEXT NOT NULL DEFAULT 'APPLIED',
                                  created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                  updated_at TIMESTAMP(3) NOT NULL,
                                  deleted_at TIMESTAMP(3),
                                  version INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE talent.application (
                                    id TEXT PRIMARY KEY,
                                    tenant_id TEXT NOT NULL,
                                    entity_id TEXT,
                                    candidate_id TEXT REFERENCES talent.candidate(id),
                                    position_id TEXT REFERENCES core.position(id),
                                    status TEXT NOT NULL CHECK (status IN ('APPLIED','INTERVIEW','OFFER','HIRED','REJECTED')),
                                    created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                    updated_at TIMESTAMP(3) NOT NULL,
                                    deleted_at TIMESTAMP(3),
                                    version INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE talent.interview (
                                  id TEXT PRIMARY KEY,
                                  tenant_id TEXT NOT NULL,
                                  entity_id TEXT,
                                  application_id TEXT REFERENCES talent.application(id),
                                  scheduled_at TIMESTAMP(3) NOT NULL,
                                  result TEXT,
                                  created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                  updated_at TIMESTAMP(3) NOT NULL,
                                  deleted_at TIMESTAMP(3),
                                  version INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE talent.offer (
                              id TEXT PRIMARY KEY,
                              tenant_id TEXT NOT NULL,
                              entity_id TEXT,
                              application_id TEXT REFERENCES talent.application(id),
                              offered_salary NUMERIC(15,2) NOT NULL,
                              currency TEXT NOT NULL DEFAULT 'IDR',
                              status TEXT NOT NULL CHECK (status IN ('SENT','ACCEPTED','DECLINED')),
                              created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                              updated_at TIMESTAMP(3) NOT NULL,
                              deleted_at TIMESTAMP(3),
                              version INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE talent.goal (
                             id TEXT PRIMARY KEY,
                             tenant_id TEXT NOT NULL,
                             entity_id TEXT,
                             employee_id TEXT REFERENCES core.employee(id),
                             title TEXT NOT NULL,
                             description TEXT,
                             due_date DATE,
                             created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                             updated_at TIMESTAMP(3) NOT NULL,
                             deleted_at TIMESTAMP(3),
                             version INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE talent.kpi (
                            id TEXT PRIMARY KEY,
                            tenant_id TEXT NOT NULL,
                            entity_id TEXT,
                            employee_id TEXT REFERENCES core.employee(id),
                            metric TEXT NOT NULL,
                            target NUMERIC(10,2),
                            score NUMERIC(10,2),
                            created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                            updated_at TIMESTAMP(3) NOT NULL,
                            deleted_at TIMESTAMP(3),
                            version INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE talent.review (
                               id TEXT PRIMARY KEY,
                               tenant_id TEXT NOT NULL,
                               entity_id TEXT,
                               employee_id TEXT REFERENCES core.employee(id),
                               reviewer_id TEXT REFERENCES core.employee(id),
                               rating NUMERIC(3,2),
                               comments TEXT,
                               created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                               updated_at TIMESTAMP(3) NOT NULL,
                               deleted_at TIMESTAMP(3),
                               version INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE talent.feedback (
                                 id TEXT PRIMARY KEY,
                                 tenant_id TEXT NOT NULL,
                                 entity_id TEXT,
                                 from_employee_id TEXT REFERENCES core.employee(id),
                                 to_employee_id TEXT REFERENCES core.employee(id),
                                 message TEXT NOT NULL,
                                 created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                 updated_at TIMESTAMP(3) NOT NULL,
                                 deleted_at TIMESTAMP(3),
                                 version INTEGER NOT NULL DEFAULT 1
);

-- ========================================================
-- COMM SCHEMA
-- ========================================================
CREATE TABLE comm.notification (
                                   id TEXT PRIMARY KEY,
                                   tenant_id TEXT NOT NULL,
                                   entity_id TEXT,
                                   recipient_id TEXT REFERENCES core.employee(id),
                                   type TEXT NOT NULL,
                                   message TEXT NOT NULL,
                                   status TEXT NOT NULL CHECK (status IN ('SENT','READ')),
                                   created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                   updated_at TIMESTAMP(3) NOT NULL,
                                   deleted_at TIMESTAMP(3),
                                   version INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE comm.task (
                           id TEXT PRIMARY KEY,
                           tenant_id TEXT NOT NULL,
                           entity_id TEXT,
                           assignee_id TEXT REFERENCES core.employee(id),
                           title TEXT NOT NULL,
                           status TEXT NOT NULL CHECK (status IN ('OPEN','IN_PROGRESS','DONE')),
                           due_date DATE,
                           created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                           updated_at TIMESTAMP(3) NOT NULL,
                           deleted_at TIMESTAMP(3),
                           version INTEGER NOT NULL DEFAULT 1
);
CREATE TABLE comm.checklist (
                                id TEXT PRIMARY KEY,
                                tenant_id TEXT NOT NULL,
                                entity_id TEXT,
                                task_id TEXT REFERENCES comm.task(id),
                                item TEXT NOT NULL,
                                checked BOOLEAN DEFAULT FALSE,
                                created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                updated_at TIMESTAMP(3) NOT NULL,
                                deleted_at TIMESTAMP(3),
                                version INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE comm.announcement (
                                   id TEXT PRIMARY KEY,
                                   tenant_id TEXT NOT NULL,
                                   entity_id TEXT,
                                   title TEXT NOT NULL,
                                   body TEXT NOT NULL,
                                   published_at TIMESTAMP(3),
                                   audience JSONB, -- e.g. { roles: [...], departments: [...] }
                                   created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                   updated_at TIMESTAMP(3) NOT NULL,
                                   deleted_at TIMESTAMP(3),
                                   version INTEGER NOT NULL DEFAULT 1
);

-- ========================================================
-- AUDIT SCHEMA
-- ========================================================
CREATE TABLE audit.audit_event (
                                   id TEXT PRIMARY KEY,
                                   tenant_id TEXT NOT NULL,
                                   entity_id TEXT,
                                   source TEXT NOT NULL, -- service or component
                                   event_type TEXT NOT NULL,
                                   payload JSONB,
                                   occurred_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                   created_at TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
                                   version INTEGER NOT NULL DEFAULT 1
);

-- ========================================================
-- COMMON INDEXES (tenant / entity)
-- ========================================================
-- Indexes for faster tenant-scoped queries (common pattern)
CREATE INDEX IF NOT EXISTS idx_core_employee_tenant ON core.employee(tenant_id);
CREATE INDEX IF NOT EXISTS idx_core_employment_tenant ON core.employment(tenant_id);
CREATE INDEX IF NOT EXISTS idx_core_compensation_tenant ON core.compensation(tenant_id);
CREATE INDEX IF NOT EXISTS idx_time_attendance_tenant ON time.attendance_event(tenant_id);
CREATE INDEX IF NOT EXISTS idx_time_timesheet_tenant ON time.timesheet(tenant_id);
CREATE INDEX IF NOT EXISTS idx_payroll_run_tenant ON payroll.payroll_run(tenant_id);
CREATE INDEX IF NOT EXISTS idx_finance_expense_tenant ON finance.expense_report(tenant_id);
CREATE INDEX IF NOT EXISTS idx_asset_asset_tenant ON asset.asset(tenant_id);
CREATE INDEX IF NOT EXISTS idx_talent_candidate_tenant ON talent.candidate(tenant_id);
CREATE INDEX IF NOT EXISTS idx_comm_notification_tenant ON comm.notification(tenant_id);
CREATE INDEX IF NOT EXISTS idx_audit_event_tenant ON audit.audit_event(tenant_id);

-- ========================================================
-- OPTIONAL: UNIQUE CONSTRAINTS / BUSINESS KEYS
-- ========================================================
-- Unique npwp / nik per tenant if desired (commented: enable if you want to enforce)
-- CREATE UNIQUE INDEX IF NOT EXISTS uq_employee_npwp_tenant ON core.employee(tenant_id, npwp) WHERE npwp IS NOT NULL;
-- CREATE UNIQUE INDEX IF NOT EXISTS uq_employee_nik_tenant ON core.employee(tenant_id, nik) WHERE nik IS NOT NULL;

-- Unique role name per tenant
CREATE UNIQUE INDEX IF NOT EXISTS uq_roles_name_tenant ON auth.roles(tenant_id, name);

-- ========================================================
-- SAMPLE FOREIGN KEY SAFEGUARDS (ensure referenced schemas exist)
-- ========================================================
-- Note: PostgreSQL will enforce FK references defined above. If you plan on bulk-importing data
-- ensure parent records exist or temporarily disable FK checks during import.

-- ========================================================
-- END OF MIGRATION
-- ========================================================

