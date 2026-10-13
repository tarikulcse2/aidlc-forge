# Project analysis

The goal: ACs that use the system's real vocabulary and rules, and look like the team wrote them. Read in parallel
batches, and stay within the scope.

## 1. Narrow the scope
- **Single app:** the whole repo.
- **Modular monolith or monorepo** (`src/Modules/<Name>`, `apps/*`, `services/*`): match the feature to one module by
  name, route prefix or domain terms. Stay there, plus the shared auth, errors and kernel it depends on.
- **Separate front end and back end:** UI text and field behaviour come from the front end; rules and status codes
  from the back end. Check both for user-facing flows.
- **Not sure which module?** Name the candidates and ask, rather than guessing.

## 2. House style
In an aidlc project, the style is fixed: `US-NNN`, the `| # | Given | When | Then |` table, `ACn`, errors as
`status area.code`, and changed ACs listed with their full new text. Outside aidlc (no `.aidlc/config.yaml`), look
for existing ACs (`docs/**` files named `*stor*`, `*requirement*`, `*spec*`, `*acceptance*`, and `**/*.feature`)
and mirror their format, IDs, error notation and location.

**BDD in use?** Look for `**/*.feature` and step definitions (`*Steps.cs`, `*.steps.ts`, `steps/*.py`,
`*StepDefinitions*`). Note the folder, the tags, and the exact step wording to reuse at the QA level.

## 3. Facts to extract
| What | Extract |
|---|---|
| Domain model | entities, field names and types, required versus optional, status values and allowed transitions |
| Validation | exact limits: lengths, ranges, formats, uniqueness, date rules |
| Behaviour | endpoints and verbs, handlers and services, business logic, side effects (emails, events, jobs, audit) |
| Permissions | roles, policies, ownership checks, and what unauthorised callers get (401, 403 or 404) |
| Messages | exact user-facing text and error codes (also in the contract file) |
| Configuration | configurable limits (sizes, page sizes, timeouts). Note that they're configurable; never copy secrets. |
| Existing tests | what's covered, how tests are named, and step wording to reuse |
| Similar features | patterns to follow (error style, confirmations, pagination) |

Use real values, and note where they came from (`[from code: path:line]`). If the requirement and the code disagree
(the ticket says 10 MB, the validator enforces 5 MB), list it under **Conflicts**.

## 4. Where to look, by stack (the project's stack profile adds detail)
| Stack | Model | Validation | Behaviour / API | Permissions | Messages | Tests |
|---|---|---|---|---|---|---|
| **.NET** | `Domain/`, entities, EF `DbContext`, `Migrations/` | FluentValidation `*Validator.cs`, `[Required]`, `[MaxLength]` | minimal API `Map*` / `*Endpoints.cs`, controllers, MediatR handlers, services | `[Authorize]`, `RequireAuthorization`, policies in `Program.cs` | `*.resx`, error constants, `Error.*` factories | xUnit/NUnit/MSTest; Reqnroll/SpecFlow `.feature` + `*Steps.cs` |
| **Node / TS** | Prisma schema, TypeORM/Sequelize entities, Mongoose | zod, Joi, yup, class-validator | Express/Fastify routes, NestJS controllers, Next.js `api/` | middleware, guards, `@Roles` | i18n JSON | Jest/Vitest, Playwright/Cypress, Cucumber |
| **Python** | Django models, SQLAlchemy | Pydantic, serializers, forms | FastAPI routers, Django views, Flask blueprints | DRF permissions, `Depends(...)` | gettext `.po` | pytest, Behave, pytest-bdd |
| **Java / Kotlin** | JPA `@Entity` | Bean Validation `@NotNull`, `@Size` | Spring `@RestController`, services | Spring Security, `@PreAuthorize` | `messages.properties` | JUnit, Cucumber-JVM |
| **Go** | structs + migrations | `validate:"…"` tags | chi/gin/echo handlers | middleware | constants | `_test.go`, godog |
| **Front end** | API client types | zod/yup form schemas, validators | pages, routes, components | route guards | i18n files | Testing Library, Playwright |

Skip generated and vendored code: `bin/`, `obj/`, `node_modules/`, `dist/`, `vendor/`, `.venv/`.

## 5. Special situations
- **A new feature with no code yet:** follow the closest similar feature and the project's conventions, and say so.
- **A bug ticket:** ACs for the correct behaviour, plus one reproducing AC, plus any regression risk nearby.
- **No codebase:** say so in one line, and write from the requirement alone, flagging everything unstated.
