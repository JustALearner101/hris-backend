# Project Guidelines — Backend (NestJS)

For HRIS All-In-One — modular monolith (module-per-folder), end-to-end, detailed. Compiled based on NestJS best practices + the architecture you already have.

Hello — this is a complete and detailed project backend guide for your team. I wrote it in a practical style so it's easy to implement: from bootstrapping the project to release & daily operations. If you want, I can also export this to PDF &/or generate a skeleton repo + starter files (module, repo, service, controller) so it can run directly.

## 1. Summary & Design Principles

Main technologies: NestJS 10 (TypeScript), Prisma (Postgres 16), Redis, Kafka, Keycloak.

Architecture: Modular Monolith (module-per-domain) — each module (core-hr, payroll, attendance, ...) has its own folder and consistent substructure: model, vo, repo, service, controller.

Goals: maintainable, testable, audit-ready, easy to split into microservices if needed.

Security & compliance: RLS pattern in DB, field encryption for PII, MFA/Keycloak for admin/finance, OWASP ASVS L2.

Development workflow: trunk-based development; short feature branches; strict CI checks (lint, typecheck, unit, contract).

Main architecture references & guidelines refer to official NestJS documentation for module patterns, providers, pipes, interceptors, etc. (docs.nestjs.com) — apply official NestJS concepts during implementation.

## 2. Repository Structure (Global)

Example top-level tree — required structure:

```
hris-backend/
├── src/
│   ├── modules/
│   │   ├── core-hr/
│   │   │   ├── model/
│   │   │   ├── vo/
│   │   │   ├── repo/
│   │   │   ├── service/
│   │   │   ├── controller/
│   │   │   └── core-hr.module.ts
│   │   ├── payroll/
│   │   └── attendance/
│   ├── common/              # pipes, interceptors, filters, dtos shared
│   ├── config/              # env + schema + validators
│   ├── infra/               # prisma client wrapper, kafka producer, redis client
│   ├── events/              # event schemas & producers/consumers
│   ├── main.ts
│   └── app.module.ts
├── prisma/
│   └── schema.prisma
├── test/                    # integration & e2e tests
├── .github/workflows/
├── Dockerfile
└── package.json
```

Note: each module must be registered in src/modules/index.ts (or imported via AppModule) for easy review.

## 3. Internal Structure per Module (Standard)

Each module follows a Domain-Driven pattern → separating technical framework from domain.

```
modules/<module>/
├── model/          # domain entities / prisma wrappers (immutable mapping)
├── vo/             # value objects (email, money, moneyId, etc)
├── dto/            # DTOs for inbound/outbound validation (class-validator)
├── repo/           # repository interface & impl (Prisma/SQL)
│   ├── employee.repository.interface.ts
│   └── employee.prisma.repository.ts
├── service/        # domain services (interface + impl)
│   ├── employee.service.interface.ts
│   └── employee.service.impl.ts
├── controller/     # REST controllers (thin controllers)
├── mapper/         # mapping model <-> dto/service if needed
└── <module>.module.ts
```

Principles:

Thin controllers, fat services (business rules in services).

Repos handle persistence; services handle transactions & rules.

Use interfaces for repo & service → easy mocking in tests. Since TS interfaces disappear at runtime, use constant tokens (Symbol/string) for DI.

## 4. Dependency Injection & Provider Pattern (NestJS)

Token pattern: use const EMPLOYEE_REPOSITORY = Symbol('EMPLOYEE_REPOSITORY') or const string for DI token.

Provider registration example:

```typescript
// core-hr.module.ts
@Module({
  controllers: [EmployeeController],
  providers: [
    PrismaService,
    { provide: EMPLOYEE_REPOSITORY, useClass: EmployeePrismaRepository },
    { provide: EMPLOYEE_SERVICE,   useClass: EmployeeServiceImpl },
  ],
  exports: [EMPLOYEE_SERVICE],
})
export class CoreHrModule {}
```

During tests, easily override providers with useClass/useValue in testing module.

## 5. Model & Database (Prisma) — Table Conventions & Migrations

Standard table principles:

id: String @id @default(uuid()) → use UUID v7 if available/desired.

tenant_id: String

entity_id: String?

created_at: DateTime @default(now())

updated_at: DateTime @updatedAt

deleted_at: DateTime? (soft delete)

version: Int @default(1) (optimistic lock)

Example Prisma snippet:

```prisma
model Employee {
  id         String   @id @default(uuid())
  tenant_id  String
  entity_id  String?
  employee_no String
  first_name String
  last_name  String?
  email      String?  @unique
  nik        String?
  npwp       String?
  hire_date  DateTime
  created_at DateTime @default(now())
  updated_at DateTime @updatedAt
  deleted_at DateTime?
  version    Int      @default(1)
  @@index([tenant_id])
  @@unique([tenant_id, employee_no])
}
```

Migration policy (PR → Release):

PR must include migration plan in PR description if DB change.

Additive changes OK. Destructive changes require 2-step migration (A: add new field, B: backfill + switch reads, C: remove).

Migrations applied by CI release job: npx prisma migrate deploy (NOT auto-run on app boot).

Large backfills run as background jobs with throttle.

## 6. API Design Conventions

Base path versioning: /api/v1/...

Pagination: page (>=1), page_size (default 50, max 200)

Filtering: filters[field]=op:value (op in eq,ne,gt,lt,like,in)

Idempotency: Idempotency-Key header on POST/PUT ops that create resources; server cache results for 24 hours.

ETag on GET; use If-Match for update.

Error format (consistent):

```json
{
  "code": "E_VALID_001",
  "message": "Validation failed",
  "details": [{ "field": "email", "error": "invalid" }],
  "correlation_id": "..."
}
```

Security: Bearer token (OIDC/Keycloak), scopes per resource.

Rate limit: default 120 rpm per token; stricter on login/endpoints.

## 7. Events & Contracts

Event bus: Kafka (recommended) with schema registry (Avro/JSON Schema).

Event envelope: every event must contain:

```json
{
  "id": "evt_...",
  "type": "employee.created",
  "occurred_at": "2025-09-01T02:00:00Z",
  "tenant_id": "...",
  "entity_id": "...",
  "correlation_id": "...",
  "causation_id": "...",
  "data": {}
}
```

Versioning & compatibility: new fields additive only; use schema compatibility checks in CI.

Provide OpenAPI + event contract publishing for consumers.

## 8. Authentication & Authorization

IdP: Keycloak (OIDC/SAML). Use JWT introspection or token verification library.

Service-to-Service: short-lived mTLS or signed service tokens.

Authorization model: RBAC + policy engine (OPA/oso) for complex rules (e.g., payroll approvals).

Admin & Finance: require MFA (TOTP/WebAuthn).

## 9. Validation, DTOs & Pipes

Use class-validator + class-transformer.

Global pipes in main.ts:

```typescript
app.useGlobalPipes(new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }));
```

DTOs live under /dto/ per module. Map DTO → VO/Domain model in service/mapper layer.

## 10. Logging, Correlation & Observability

### Logging

Structured JSON logs; mask PII. Fields: timestamp, level, msg, service, tenant_id, user_id, correlation_id, span_id, trace_id, meta.

Use a logger library compatible with NestJS (Winston or Pino). Example structure:

```json
{
  "ts":"2025-09-01T00:00:00Z",
  "level":"info",
  "msg":"employee.created",
  "service":"core-hr",
  "tenant_id":"t-123",
  "correlation_id":"corr-abc",
  "meta": { "employee_id": "e-1" }
}
```

### Correlation

Inject middleware that assigns correlation_id (from incoming header or generate new) and attach to request context and logs.

### Tracing & Metrics

Instrument with OpenTelemetry (NestJS instrumentations).

Expose Prometheus metrics (latency, error rate, queue depth).

Sentry for error capture; Grafana + Prometheus for dashboards.

## 11. Testing Strategy

Unit tests: Jest. Mock repos/services using provider overrides.

Integration tests: Supertest + test DB (docker compose or ephemeral DB). Use prisma migrate dev + seed for test data.

Contract tests: Publish OpenAPI spec; run consumer contract tests (Pact/OpenAPI validator).

E2E tests: Playwright / Supertest for critical flows (hire→payroll→payslip).

Performance tests: k6 for load tests (payroll throughput, attendance ingestion).

Security tests: SAST (Semgrep/CodeQL), dependency scans (Snyk), DAST (OWASP ZAP on staging).

Coverage: Unit coverage target ≥ 70% for critical modules (payroll, attendance).

### How to Run

```bash
pnpm install

pnpm prisma migrate dev (local)

pnpm test (unit)

pnpm test:integration (integration)

pnpm test:e2e (e2e)
```

## 12. CI / CD (GitHub Actions Recommended)

### PR Pipeline (on pull_request):

Checkout, setup Node (Node 20), pnpm install

Lint, Typecheck

Unit tests

Contract checks (OpenAPI diff if API changed)

SCA & security scanners (Snyk, Trivy)

Build artifact (optional)

### Merge Pipeline (main):

Re-run all checks

Build container image + sign

Publish artifact

Deploy to staging (blue/green or ephemeral)

Run smoke & e2e on staging

Publish OpenAPI & contract docs

### Release Pipeline (manual):

Tag release

Run DB migration job with pre-backup

Canary deploy (10% → 50% → 100%) OR canary via feature flags

Monitor metrics for 30+ min before full promotion

Auto-rollback on critical errors (error rate > threshold)

Secrets in CI: use HashiCorp Vault or GitHub Secrets + short-lived creds.

## 13. Release Rules for Payroll & Finance (Critical)

Payroll changes need extra gates:

Payroll dry-run on staging with sample dataset & reconciliation by Finance.

Release window (non-business hours) for production DB migration if destructive.

Backup snapshot + checksum before migration.

Feature flag gating for rollout & ability to rollback fast.

Approval signoff by Finance + DevOps before enabling.

## 14. Security Checklist (Pre-Merge & Pre-Release)

SAST & dependency scan green.

No secrets in repo.

MFA enabled for admin accounts.

RBAC + OPA rules reviewed for changes in authorization.

DAST on staging (no critical findings).

Field encryption for PII in DB.

Secrets rotation policy documented.

## 15. Observability & Runbooks

Provide runbooks for: payroll stuck, stuck DB migration, event queue backlog, incident response.

Alerts: error spikes, latency increase, auth failures, payroll reconciliation mismatch.

Define SLOs: e.g., Employee CRUD P95 <300ms, Payroll run 5k employees <20min.

## 16. Code Style, Linting & Commit Conventions

TypeScript rules: strict: true in tsconfig.

Use ESLint + Prettier. Share .eslintrc, .prettierrc.

Import ordering: absolute first, then relative.

Commit message: Conventional Commits (feat:, fix:, chore:, etc).

PR description must include: purpose, API contract changes, DB migration plan (if any), acceptance checklist.

## 17. Documentation & API Publishing

OpenAPI (Swagger) is generated from NestJS controllers and exposed at runtime:
- Swagger UI: http://localhost:3000/api/docs
- OpenAPI JSON: http://localhost:3000/api/docs-json
- Auth: Use the Authorize button in Swagger UI with a Bearer token (JWT). The Authorization header is persisted across requests.

Authoring guidelines:
- Add @ApiTags('module-name') on controllers to organize groups.
- Decorate DTOs with @ApiProperty and use class-validator for accurate schema.
- Use @ApiBearerAuth('bearer') on secured controllers/routes when appropriate.

CI publishing:
- During release, fetch the JSON from /api/docs-json and publish as an artifact (e.g., openapi.json) for consumers.
- Contract checks: compare the new spec with the previous release using an OpenAPI diff tool and fail on breaking changes.

Maintain architecture docs (SRS, runbooks) inside repo docs/.

Each module must have README: responsibilities, API endpoints, events produced/consumed, owner contact.

## 18. Multi-Tenant & Security DB Enforcement

Tenant enforcement: always require tenant_id in API requests; add Prisma middleware to inject tenant constraint where possible.

RLS: enable Postgres RLS per tenant_id for additional protection.

Audit: write audit events to Kafka + append to WORM S3 for at least 7 years.

## 19. Example Code Snippets (Quick Reference)

main.ts (bootstrap patterns):

```typescript
async function bootstrap() {
  const app = await NestFactory.create(AppModule, { logger: new PinoLogger() });
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
  app.useGlobalInterceptors(new LoggingInterceptor());
  app.setGlobalPrefix('api/v1');
  await app.listen(process.env.PORT || 3000);
}
```

Correlation ID middleware (outline):

```typescript
@Injectable()
export class CorrelationMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction) {
    const correlation = req.headers['x-correlation-id'] || randomUUID();
    // attach to request context, response header, and logger
    res.setHeader('x-correlation-id', correlation);
    (req as any).correlationId = correlation;
    next();
  }
}
```

Repository interface token:

```typescript
// tokens.ts
export const EMPLOYEE_REPOSITORY = Symbol('EMPLOYEE_REPOSITORY');
export const EMPLOYEE_SERVICE = Symbol('EMPLOYEE_SERVICE');
```

## 20. PR Checklist (Required)

- Lint & Typecheck green
- Unit tests pass (and coverage threshold met for changed modules)
- Integration/contract tests green (if API changed)
- Migration plan included (if DB changed)
- Security scan & dependency scan green
- At least 1 code owner approval (2 for payroll/finance)
- Updated OpenAPI (if API changed)
- README/module docs updated (if behavior changed)

## 21. Onboarding Checklist for New Dev

Pull .env.example, ask infra to provision dev creds (dont use prod creds)

pnpm install → npx prisma migrate dev --name init → pnpm start:dev

Run tests locally: pnpm test

Read module README & run local seed data

## 22. Ops & DR Summary

Daily encrypted backups + WAL for PITR.

DR region with RTO ≤ 1 hour; regular restore drills.

Rotate keys per policy; revoke compromised keys immediately.

## 23. Helpful Conventions / Small Rules

Keep controllers small (max 10 endpoints per controller file if logical).

Services should not import controllers.

Avoid using any; prefer explicit domain types.

For time, store UTC in DB; render by tz in frontend. Keep timezone on entity row.

## 24. Appendix: Quick Start Commands

```bash
# deps
pnpm install

# prisma
npx prisma generate
npx prisma migrate dev --name init
npx prisma db seed

# dev
pnpm start:dev

# lint & test
pnpm lint
pnpm test
pnpm test:integration
pnpm build
```