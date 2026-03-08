# Incident Postmortem Template

A postmortem is a blameless retrospective after an incident. The goal is learning, not punishment.

---

## Incident: [Short Title]

**Incident ID:** INC-YYYY-MM-DD-001

**Severity:** [Critical | High | Medium | Low]

- **Critical:** Complete outage, revenue impact
- **High:** Major degradation, significant user impact
- **Medium:** Partial degradation, some users affected
- **Low:** Minor issue, minimal impact

**Date:** YYYY-MM-DD

**Duration:** [Start time] to [End time] ([Total duration])

**Impact:** [Brief description of user/business impact]

**Status:** [Draft | Under Review | Published]

---

## Summary

[2-3 sentence summary of what happened, why, and how it was resolved]

---

## Timeline (All times in UTC)

| Time  | Event                                                     |
| ----- | --------------------------------------------------------- |
| 14:23 | Deployment of v1.2.5 began                                |
| 14:25 | First alerts: error rate increased to 45%                 |
| 14:26 | On-call engineer paged                                    |
| 14:28 | Engineer investigating logs                               |
| 14:30 | Root cause identified: database connection pool exhausted |
| 14:32 | Decision made to rollback                                 |
| 14:33 | Rollback initiated                                        |
| 14:35 | Rollback complete, error rate returning to normal         |
| 14:38 | Error rate back to baseline (<0.1%)                       |
| 14:40 | Incident declared resolved                                |
| 14:45 | Monitoring for regression                                 |

**Total Impact:** 15 minutes of degraded service (14:25-14:40)

---

## Root Cause

[Detailed explanation of the underlying cause]

**Example:**
The deployment introduced a code change that increased database connections per request from 1 to 3 due to inefficient queries. Our connection pool limit of 100 connections was exhausted within 2 minutes under normal production load (~50 req/sec). New incoming requests couldn't acquire connections and timed out, resulting in 45% error rate.

---

## Detection

**How was the incident detected?**

- [ ] Automated alert
- [ ] User report
- [ ] Monitoring dashboard
- [ ] Other: **\_\_\_**

**Time to detect (TTD):** [Time from actual issue start to detection]

**What worked well:**

- [What helped us detect the issue quickly?]

**What could be improved:**

- [Were there earlier signals we missed?]

---

## Response

**Who responded?**

- On-call engineer: [Name]
- Additional responders: [Names if escalated]

**Time to respond (TTR):** [Time from detection to first engineer engagement]

**What went well:**

- [What was effective in the response?]

**What could be improved:**

- [What slowed us down?]

---

## Resolution

**Resolution method:**

- [x] Rollback to previous version
- [ ] Configuration change
- [ ] Restart services
- [ ] Manual data fix
- [ ] Other: **\_\_\_**

**Time to resolution (TTX):** [Time from detection to full resolution]

**What went well:**

- [What enabled fast resolution?]

**What could be improved:**

- [What made resolution harder than necessary?]

---

## Impact Assessment

### User Impact

- **Users affected:** [Number or percentage]
- **Type of impact:** [Error messages, slow response, unable to access, etc.]
- **User actions required:** [Did users need to retry? Lose data?]

### Business Impact

- **Revenue impact:** [If applicable: $X in lost transactions]
- **SLA impact:** [Did we breach our SLO/SLA?]
- **Reputation impact:** [Social media mentions, support tickets]

### Technical Impact

- **Services affected:** [List of services]
- **Data integrity:** [Was data lost or corrupted?]
- **Dependencies:** [What downstream systems were affected?]

---

## What Went Well

1. [Positive aspect of response]
2. [Another positive]
3. [Technology/process that helped]

**Example:**

1. Rollback was executed in 2 minutes thanks to GitOps
2. Alerts fired immediately when error rate increased
3. Monitoring dashboards clearly showed the database connection spike

---

## What Didn't Go Well

1. [Area for improvement]
2. [Another challenge]
3. [Gap in tooling/process]

**Example:**

1. We didn't test under sufficient load in staging
2. Database connection metrics weren't prominently displayed
3. Runbook for connection pool issues was outdated

---

## Where We Got Lucky

[Things that could have made this worse, but didn't]

**Example:**

1. Incident occurred during low-traffic hours (not peak)
2. Only affected users in one region
3. Database didn't become completely unavailable

---

## Action Items

| ID     | Action                                          | Owner | Priority | Due Date   | Status      |
| ------ | ----------------------------------------------- | ----- | -------- | ---------- | ----------- |
| AI-001 | Add load testing to CI/CD pipeline              | Chris | High     | 2026-03-15 | In Progress |
| AI-002 | Create dashboard for DB connection pool metrics | Chris | High     | 2026-03-10 | Not Started |
| AI-003 | Update runbook for DB connection issues         | Chris | Medium   | 2026-03-12 | Not Started |
| AI-004 | Implement connection pool size alerts           | Chris | High     | 2026-03-08 | Not Started |
| AI-005 | Add database query performance tests            | Chris | Medium   | 2026-03-20 | Not Started |

**Priority Definitions:**

- **Critical:** Must do before next deployment
- **High:** Do within 1 week
- **Medium:** Do within 1 month
- **Low:** Nice to have

---

## Lessons Learned

### Technical Lessons

1. [What did we learn about our systems?]
2. [What gaps did we discover?]

**Example:**

1. Our staging environment doesn't replicate production load accurately
2. Connection pooling configuration wasn't documented
3. We need better database performance monitoring

### Process Lessons

1. [What did we learn about our processes?]
2. [What worked or didn't work?]

**Example:**

1. GitOps rollback is fast, but we need clearer decision criteria
2. Load testing in CI/CD would catch these issues earlier
3. Need better runbooks for database troubleshooting

---

## Supporting Information

### Relevant Dashboards

- [Link to Grafana dashboard during incident]

### Log Excerpts

```
[2026-03-02T14:25:13Z] ERROR: Connection timeout waiting for available connection
[2026-03-02T14:25:14Z] ERROR: Pool exhausted: 100/100 connections in use
[2026-03-02T14:25:15Z] ERROR: Request failed: connect ETIMEDOUT
```

### Metrics/Graphs

[Screenshots of key metrics during incident if available]

### Related Incidents

- INC-2026-02-15-003 (similar DB connection issue)

---

## Communication

**Internal notifications sent:**

- [When and how team was notified]

**External notifications sent:**

- [If customers were notified, when and how]

**Post-incident communication:**

- [Link to customer-facing status page update if applicable]

---

## Follow-up Review

**Review date:** YYYY-MM-DD
**Reviewed by:** [Names]

**Follow-up notes:**

- [Progress on action items]
- [Any new learnings after implementation]

---

## Sign-off

**Author:** [Your name]
**Date:** YYYY-MM-DD
**Reviewed by:** [Reviewer name if applicable]
**Approved by:** [Manager/lead if applicable]

---

## Appendix

### Commands Used

```bash
# Check pod status
kubectl get pods -n production

# View logs
kubectl logs app-7d8f9b5c-xh2k9 -n production

# Check database connections
kubectl exec -it app-7d8f9b5c-xh2k9 -n production -- psql -c "SELECT count(*) FROM pg_stat_activity;"

# Rollback
kubectl rollout undo deployment/app -n production
```

### Configuration Changes

[Any relevant config snippets]

### Reference Documentation

- [Links to related runbooks, ADRs, documentation]
