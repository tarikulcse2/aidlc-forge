# Levels and output templates

The **level** decides how much goes in. The **shape** is the aidlc house style: `US-NNN` (drafts use `US-NEW1`…),
a `| # | Given | When | Then |` table with `AC1…`, and errors as `status area.code`. Every level produces numbered
ACs, so `/aidlc-forge:planning` can import any of them.

## Business
- **For:** the PO, stakeholders, non-technical reviewers.
- **Content:** 3–6 ACs covering the happy path, the most important rules, and the most likely failure.
- **Language:** plain business terms. No endpoints, status codes or file paths. Real role names and real limits
  from the code are welcome, because they're business facts.
- The **Then** column describes what the user sees. Error codes are added later (Functional and above).

```markdown
Source: <ticket key / description / file> · Level: Business

## US-NEW1 <title>
**As a** <role> **I want** <capability> **so that** <benefit>.

| # | Given | When | Then |
|---|---|---|---|
| AC1 | ... | ... | <observable outcome> |
| AC2 | ... | ... | <the most likely failure, and what the user sees> |

## Open questions
- ...
```

## Functional
- **For:** the whole team.
- **Content:** the full coverage list in SKILL.md step 4: happy path, validation with boundaries, business rules,
  errors (status plus stable code), permissions, edge cases and side effects.
- Put repeated behaviour with different inputs in one AC with the values listed (`status is Rejected or Cancelled`),
  or one row per value.

## Technical
Everything in Functional, plus a `## Technical criteria` section (the planner reads it):
- **API:** method, path, request fields, response shape, and the status for success and for each failure (`400`,
  `401`, `403`, `404`, `409`, `422`, `429`…), using the project's error codes and the contract (`contract` in config)
- **Data:** what's created, updated or deleted, resulting status values, and what must **not** change on failure
  (no partial writes)
- **Security:** authorisation per role, ownership checks, input validation, and no sensitive data in responses or logs
- **Side effects:** events, emails, background jobs, audit entries, cache invalidation
- **Non-functional:** performance, pagination, concurrency, idempotency, only where a requirement or a code limit exists
- **Contract changes:** what must change in the API contract (it's updated first, at planning)

Code references (the files the rules came from, and the files likely to change) are shown in chat only.

## QA
- Functional ACs (the table, for traceability and planning), **plus** a `.feature` file in plain Gherkin: `Feature:`,
  optional `Background:`, `Scenario:` or `Scenario Outline:` + `Examples:`. No markdown inside it.
- **Tags:** the feature gets `@US-NNN` (`@US-NEW1` in drafts) and each scenario gets `@ACn`. Prefix each scenario
  name with `USnnn_ACk ` so the generated test names match the aidlc test-naming rule.
- **Match the project's test setup** (`bdd_framework`, `feature_dir`): same folder and tags, and **reuse existing step
  wording** so steps bind without new code. After the file, list the steps that need new step definitions.
- **No BDD set up:** write standard Gherkin and name the framework that would suit it (Reqnroll for .NET, Cucumber for
  JS or Java, Behave or pytest-bdd for Python, godog for Go).

```gherkin
@US-NEW1
Feature: Cancel a leave request
  As an Employee
  I want to cancel my own leave request
  So that my leave balance is restored when my plans change

  Background:
    Given I am logged in as an Employee

  @AC1
  Scenario: US005_AC1 Cancel a pending request
    Given I have a leave request with status "Pending"
    When I cancel the request
    Then the request status is "Cancelled"
    And the requested days are returned to my leave balance

  @AC4
  Scenario Outline: US005_AC4 Closed requests cannot be cancelled
    Given I have a leave request with status "<status>"
    When I cancel the request
    Then I receive error "<code>"

    Examples:
      | status    | code                 |
      | Rejected  | leave.invalid_status |
      | Cancelled | leave.invalid_status |
```

## Full template (Functional and Technical); drop any section that would be empty
In chat, show all of it. When saving, keep only the sections marked **saved**.

```markdown
Source: <ticket key / description / file> · Level: <Functional | Technical>          ← saved

## Project analysis (brief)                                                           ← chat only
- Scope: <module analysed> · Related code: <key files>
- Rules found: <e.g. "Reason required, max 500 chars" [from code: LeaveRequestValidator.cs:14]>
- Roles: <Employee, Manager> · House style: aidlc table, US-xxx/ACn, status + code

## US-NEW1 <title>                                                                    ← saved
**As a** … **I want** … **so that** …
| # | Given | When | Then |
|---|---|---|---|
| AC1 | ... | ... | ... |

## Changed ACs                                                                        ← saved, if any
| Story / AC | New text |

## Technical criteria                                                                 ← saved (Technical only)
- API: … · Data: … · Security: … · Side effects: … · Contract changes: …

## Code references                                                                    ← chat only (Technical only)
- path/to/file: why it's relevant

## Decisions                                                                          ← saved
| # | Decision |
| D1 | Assumed: … |

## Conflicts                                                                          ← saved
- The requirement says X, the code does Y (path:line). Which is correct?

## Open questions                                                                     ← saved
- ...
```
