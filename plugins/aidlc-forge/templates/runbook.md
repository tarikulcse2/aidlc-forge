# Runbook: <service>

## Release readiness (deploy gate)
| Check | Status |
|---|---|
| Build (0 warnings) and `test_all` green | |
| Regression report GREEN (date) | |
| Container builds and the health check passes | |
| Security review: no High findings | |
| No ADR or NFR marked "not for production" (list any blockers) | |

## Environments
| Env | Trigger | Approval |
|---|---|---|

## Configuration
| Variable | Default | Notes |
|---|---|---|

## Health and monitoring
## Deploy and rollback
## Incident playbook
1. Collect the error, logs and time window.
2. `/aidlc-forge:requirements Fix: <symptom>` (a lite CR). The fix comes with a regression test named after the story.
