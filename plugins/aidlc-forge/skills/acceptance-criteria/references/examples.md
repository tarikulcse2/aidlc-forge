# Worked examples and anti-patterns

**Input:** "Employees should be able to cancel a leave request."
**Analysis found:** `LeaveRequest` with statuses Pending, Approved, Rejected and Cancelled; roles Employee and
Manager; errors returned as status plus code (e.g. `409 leave.overlap`); no cancel endpoint yet; `NotificationService`
emails the employee on approval.

## Business
```markdown
Source: description · Level: Business

## US-NEW1 Cancel my leave request
**As an** Employee **I want** to cancel my own leave request **so that** my balance is restored when plans change.

| # | Given | When | Then |
|---|---|---|---|
| AC1 | my request is Pending, or Approved and not yet started | I cancel it | it shows Cancelled and its days return to my balance |
| AC2 | my leave has already started | I try to cancel it | it isn't cancelled, and I'm told started leave can't be cancelled |
| AC3 | my request is Rejected or already Cancelled | I try to cancel it | nothing changes |
| AC4 | the request belongs to another employee | I try to cancel it | I can't see or cancel it |

## Open questions
- Should the manager be notified when approved leave is cancelled?
```

## Functional
```markdown
Source: description · Level: Functional

## US-NEW1 Cancel my leave request
**As an** Employee **I want** to cancel my own leave request **so that** my balance is restored when plans change.

| # | Given | When | Then |
|---|---|---|---|
| AC1 | my request is **Pending** | I cancel it | status **Cancelled**; its days return to my balance |
| AC2 | my request is **Approved** and starts after today | I cancel it | status **Cancelled**; days returned; my manager is notified [ASSUMPTION: same pattern as the approval email] |
| AC3 | my approved request starts today or earlier | I cancel it | 422 `leave.already_started`; status unchanged |
| AC4 | my request is Rejected or Cancelled | I cancel it | 409 `leave.invalid_status`; status unchanged |
| AC5 | the request isn't mine | I cancel it | 404 `leave.not_found`; nothing changes |
| AC6 | the manager approves it at the same moment | I cancel it | exactly one action wins; the other gets 409 |

## Decisions
| # | Decision |
|---|---|
| D1 | Assumed: the manager is notified when approved leave is cancelled |

## Open questions
- Is there a notice period (e.g. no cancelling the day before)?
- Is a cancellation reason required?
```

## Technical (on top of Functional)
```markdown
## Technical criteria
- API: `POST /api/leaves/{id}/cancel`, no body → 200 with the updated request.
  404 `leave.not_found` (not found or not visible; don't reveal existence) [from code: same pattern as GET /{id}],
  409 `leave.invalid_status`, 422 `leave.already_started` (start date ≤ today via TimeProvider) [ASSUMPTION: codes]
- Data: only `Status` and `CancelledAt` change. The balance is derived from approved requests, so there's no balance write.
- Concurrency: cancel versus approve on the same request → one wins, the other gets 409 (atomic status check).
- Security: only the owner can cancel. The leave reason is never logged.
- Contract changes: add the endpoint and its errors to the contract before implementing.
```
In chat only, the code references: `Domain/LeaveRequest.cs` (statuses), `Features/Leaves/LeaveService.cs` (add
`Cancel`), `Features/Leaves/LeaveEndpoints.cs` (route), `Common/ErrorResults.cs` (code mapping).

## Review example
| AC | Problem | Fix |
|---|---|---|
| US-004 AC2 | "show an appropriate error": people will disagree on "appropriate" | 400 `leave.invalid_dates` [from code: LeaveValidator.cs:22] |
| US-004 AC3 | three actions in one AC | split into AC3 (submit) and AC7 (approve) |
| US-004 – | only the happy path | add AC8: 403 for a non-manager approving |

## Anti-patterns
| Weak | Why it fails | Better |
|---|---|---|
| "The system should work correctly." | not testable | the specific observable outcome |
| "Show an appropriate error." | people will disagree | the real status and code, or an open question |
| a generic "user" when the code has `Employee` and `Manager` | ignores the project | the real roles and terms |
| restarting at US-001 or AC1 in an existing story | breaks IDs, tests and traceability | `US-NEW` placeholders; changed ACs keep their IDs |
| "Save using EF Core" at Business or Functional level | implementation detail | "it appears in my history"; implementation only in Technical criteria |
| one AC with three actions | fails vaguely, hard to automate | separate ACs |
| only the happy path | most bugs live in failure paths | validation, error and permission ACs |
| a confident rule nobody stated | becomes a requirement nobody agreed to | `[ASSUMPTION]` or an open question |
