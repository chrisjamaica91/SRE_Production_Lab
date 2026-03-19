# 📊 Project Status & Learning Progress

**Last Updated:** March 18, 2026  
**Current Phase:** CI/CD Pipeline Security Foundation (OIDC Authentication)

---

## ✅ COMPLETED PHASES

### Phase 1: Container Security Hardening

- **Status:** ✅ Complete
- **Completed:** Security contexts, read-only filesystem, non-root user
- **Files Modified:**
  - `app/Dockerfile` - Multi-stage build, Node 20 Alpine 3.22
  - `helm/sre-lab-api/templates/blue-deployment.yaml` - Security contexts
  - `helm/sre-lab-api/templates/green-deployment.yaml` - Security contexts

**Key Learnings:**

- Read-only root filesystem with writable volumes (/tmp, /root/.npm)
- Dropped ALL capabilities
- seccomp profile: RuntimeDefault
- runAsNonRoot: true, runAsUser: 1001

**Interview Talking Points:**

- "Why read-only filesystems?" → Prevents malware persistence
- "How to handle npm install?" → emptyDir volumes for writable paths

---

### Phase 2: Image Security Scanning

- **Status:** ✅ Complete
- **Tool:** Trivy 0.48.3
- **Results:** 0 CRITICAL, 11 HIGH (npm dependencies only)

**Key Learnings:**

- Distinguish base image CVEs from app CVEs
- Risk-based decision making (npm CVEs acceptable)
- Fast scanning patterns for CI/CD

**Interview Talking Points:**

- "How to scan without slowing dev?" → Parallel scans, cached results, exit codes
- "When to fail builds?" → CRITICAL = fail, HIGH = warn + review

---

### Phase 3: Kubernetes Secrets Management

- **Status:** ✅ Complete
- **Approach:** Imperative kubectl secrets (not in Git)

**Files Created:**

- Secrets: `postgres-admin-secret`, `app-db-secret`
- Modified: `helm/sre-lab-api/templates/postgres.yaml` - secretKeyRef

**Key Learnings:**

- ConfigMaps vs Secrets (when to use each)
- Base64 encoding ≠ encryption
- Separation of admin vs app credentials
- secretRef vs valueFrom.secretKeyRef

**Interview Talking Points:**

- "Are Kubernetes Secrets secure?" → No! Base64 only. Need encryption at rest or external store.
- "How to manage secrets across environments?" → Namespace-scoped secrets, AWS Secrets Manager for prod

---

### Phase 4: Network Policies

- **Status:** ✅ Complete
- **Note:** Created policies but not enforced (Docker Desktop lacks CNI)

**Files Created:**

- `helm/sre-lab-api/templates/networkpolicy-default-deny.yaml`
- `helm/sre-lab-api/templates/networkpolicy-allow-dns.yaml`
- `helm/sre-lab-api/templates/networkpolicy-postgres.yaml`
- `helm/sre-lab-api/templates/networkpolicy-app-ingress.yaml`

**Architecture:**

```
1. Default Deny All         → Block everything
2. Allow DNS                → Pods can resolve names
3. Allow App → PostgreSQL   → Bidirectional (ingress + egress)
4. Allow Ingress → App      → External traffic
```

**Key Learnings:**

- Zero-trust networking model
- Ingress vs Egress (need both for bidirectional)
- Pod selectors and namespace selectors
- CNI requirement (Calico, Cilium, AWS VPC CNI)

**Interview Talking Points:**

- "Why doesn't Docker Desktop enforce?" → No CNI plugin. Works on EKS/GKE/AKS.
- "Difference between Security Groups and Network Policies?" → SG = node-level, NP = pod-level

---

### Phase 5: RBAC & Service Accounts

- **Status:** ✅ Complete

**Files Created:**

- `helm/sre-lab-api/templates/serviceaccount.yaml`
- `helm/sre-lab-api/templates/role.yaml`
- `helm/sre-lab-api/templates/rolebinding.yaml`

**Key Configuration:**

- ServiceAccount: `sre-lab-api-sa`
- Role: Read-only pods and configmaps
- **automountServiceAccountToken: false** ← Critical security!

**Key Learnings:**

- ServiceAccount = pod identity
- Role = permissions (namespace-scoped)
- RoleBinding = assignment
- ClusterRole = cluster-wide permissions

**Interview Talking Points:**

- "Should apps have service account tokens?" → No! Only if they call K8s API.
- "How to debug RBAC?" → `kubectl auth can-i <verb> <resource> --as=system:serviceaccount:NS:SA`

---

## 🔄 IN-PROGRESS PHASES

### Phase 6: CI/CD Pipeline Security - OIDC Authentication

- **Status:** 🔄 In Progress (80% complete)
- **Goal:** Eliminate long-lived AWS credentials from GitHub Actions

**Files Created:**

- ✅ `terraform/modules/github-oidc/variables.tf`
- ✅ `terraform/modules/github-oidc/main.tf`
- ✅ `terraform/modules/github-oidc/outputs.tf`
- ✅ `terraform/modules/github-oidc/README.md`
- ⏸️ Updated `terraform/main.tf` (module integration)

**Next Steps:**

1. Fix WSL networking issue (run terraform from PowerShell)
2. Run `terraform init` and `terraform apply`
3. Copy output role ARN
4. Update `.github/workflows/ci-cd.yml` to use OIDC
5. Test authentication flow

**Key Concepts:**

- OIDC = OpenID Connect (identity layer over OAuth 2.0)
- JWT token with claims (repo, branch, workflow)
- Short-lived credentials (15 min token → 1 hour AWS creds)
- Trust policy with `sub` claim validation

**Interview Talking Points:**

- "Why OIDC over IAM users?" → No static secrets, automatic expiry, granular control
- "How does trust policy work?" → Validates `sub` claim: `repo:org/repo:ref:refs/heads/branch`

---

## 📋 UPCOMING PHASES (Planned)

### Phase 7: Multi-Language CI/CD Pipeline

**Interview Question:** "You have Java backend, JavaScript frontend, and Rust component. How do you design the pipeline?"

**Implementation Plan:**

- Create sample services (backend-java/, frontend-js/, rust-service/)
- Matrix build strategy with path-based triggers
- Parallel execution with dependency caching
- Language-specific optimizations:
  - Java: Maven multi-stage, OWASP Dependency-Check
  - JavaScript: npm ci, webpack, Snyk
  - Rust: cargo-chef, clippy

**Expected Result:** Build time <5 min, deploy time <3 min

---

### Phase 8: Comprehensive Security Scanning Suite

**Interview Question:** "How to implement security scanning without reducing dev time?"

**Scan Types to Implement:**

1. **SAST** (Static Application Security Testing) - Code vulnerabilities
2. **DAST** (Dynamic Application Security Testing) - Running app testing
3. **SCA** (Software Composition Analysis) - Dependency vulnerabilities
4. **Container Scanning** - Image CVE detection (Trivy - already done!)
5. **IaC Scanning** - Terraform security (tfsec, Checkov)
6. **Secret Scanning** - Leaked credentials (gitleaks, truffleHog)

**Strategy:**

- Parallel scan execution
- Cached results (don't rescan unchanged code)
- Fail-fast on CRITICAL
- Warn on HIGH with review process

---

### Phase 9: Terraform Environment Isolation

**Interview Questions:**

- "How to version Terraform for dev/staging/prod?"
- "Prevent dev values from reaching prod?"
- "How to limit AWS console access?"

**Implementation Plan:**

- Terraform workspaces (dev, staging, prod)
- Remote state with isolation (separate S3 buckets/paths)
- Variable files per environment
- Backend configuration per environment
- CODEOWNERS file for approval gates
- IAM policies: Pipeline-only deployment (no console access)

**File Structure:**

```
terraform/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── backend.tf (s3://tfstate-dev/)
│   │   └── terraform.tfvars
│   ├── staging/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── backend.tf (s3://tfstate-staging/)
│   │   └── terraform.tfvars
│   └── prod/
│       ├── main.tf
│       ├── variables.tf
│       ├── backend.tf (s3://tfstate-prod/)
│       └── terraform.tfvars (approval required!)
```

---

### Phase 10: Zero-Downtime Operations

**Interview Question:** "How to migrate database types without downtime?"

**Topics:**

- Blue-green infrastructure with Terraform
- Database migration strategies
- `create_before_destroy` lifecycle
- `terraform state mv` for resource renaming
- Health checks and traffic switching

**Scenario:**

- Migrate from RDS PostgreSQL to Aurora PostgreSQL
- Zero customer impact
- Full rollback capability

---

### Phase 11: Pipeline Optimization & Metrics

**Interview Question:** "Describe a bottleneck you identified in a CI/CD pipeline and how you optimized it"

**Metrics to Track:**

- Build time (target: <5 min)
- Deploy time (target: <3 min)
- Time to feedback (target: <2 min for failing tests)
- Deployment frequency (DORA metric)
- Change failure rate (DORA metric)
- Mean time to recovery (DORA metric)

**Optimizations:**

- Docker layer caching
- Dependency caching (npm, Maven, Cargo)
- Parallel job execution
- Build matrix strategy
- Incremental builds

**Dashboard:**

- Grafana dashboard for CI/CD metrics
- Trend analysis
- SLO tracking

---

### Phase 12: Multi-Tenant Monitoring & Logging

**Interview Question:** "Implement monitoring for multi-tenant cloud infrastructure"

**Architecture:**

```
Prometheus (metrics)
├── Tenant A namespace labels
├── Tenant B namespace labels
└── Tenant C namespace labels

Grafana (dashboards)
├── Variables: Select tenant
└── Panels filtered by tenant label

CloudWatch (logs)
├── Log groups per tenant
├── Log insights queries
└── Alarms per tenant
```

**Key Concepts:**

- Label-based multi-tenancy
- Prometheus relabeling
- Grafana template variables
- Log aggregation strategies
- Cost allocation by tenant

---

### Phase 13: AWS SSO & Authentication

**Interview Question:** "How to implement single sign-on within AWS?"

**Implementation:**

- AWS IAM Identity Center (successor to AWS SSO)
- OIDC federation with external IdP (Okta, Google, Azure AD)
- Service-to-service authentication (IRSA - IAM Roles for Service Accounts)
- Cross-account access

**Use Cases:**

- Engineers authenticate via Google Workspace
- Temporary credentials (no long-lived keys)
- Centralized user management
- MFA enforcement

---

### Phase 14: Dashboard & Config Versioning

**Interview Question:** "How to version Grafana dashboards for different environments?"

**Approach: Dashboards as Code**

```
observability/
├── grafana-dashboards/
│   ├── application-metrics.json
│   ├── infrastructure-metrics.json
│   └── slo-dashboard.json
├── terraform/
│   └── grafana-provisioning.tf  # Deploy dashboards via ConfigMap
└── helm/
    └── templates/
        └── grafana-dashboards-configmap.yaml
```

**Benefits:**

- Version controlled in Git
- Automatic deployment with infrastructure
- Environment-specific variables
- Rollback capability
- Review process (PRs)

---

## 🎯 INTERVIEW QUESTIONS MASTERED

### CI/CD Security

✅ How to properly secure CI/CD pipelines?
✅ How to properly secure containers?
✅ How to implement security scanning without reducing dev time?

### Multi-Language Pipelines

⏸️ Design pipeline for Java/JavaScript/Rust application (Next phase)

### Infrastructure Security

✅ Network Policies (zero-trust networking)
✅ RBAC (service accounts, roles, bindings)
✅ Secrets management (ConfigMaps vs Secrets)

### Terraform Best Practices

⏸️ Environment isolation (workspaces, state management)
⏸️ Prevent dev values in prod
⏸️ Limit console access (pipeline-only deployment)

### Operations

⏸️ Zero-downtime database migrations
⏸️ Blue-green infrastructure with Terraform
⏸️ Pipeline bottleneck optimization

### Observability

⏸️ Multi-tenant monitoring
⏸️ Dashboard versioning
⏸️ Log aggregation strategies

### Authentication

⏸️ AWS SSO/IAM Identity Center
⏸️ OIDC federation
⏸️ IRSA (IAM Roles for Service Accounts)

---

## 📝 KEY LEARNINGS & NOTES

### Security Best Practices

1. **Defense in Depth** - Multiple layers (container, network, RBAC, secrets)
2. **Least Privilege** - Grant minimum necessary permissions
3. **Immutable Infrastructure** - Read-only filesystems prevent tampering
4. **Separation of Concerns** - Admin vs app credentials, prod vs dev
5. **Zero Trust** - Default deny, selective allow

### Kubernetes Patterns

1. **Sidecar Pattern** - Helper containers (log shipping, proxies)
2. **Init Containers** - Pre-startup tasks (DB migrations, secret fetch)
3. **ConfigMap + Secret** - ConfigMap for non-sensitive, Secret for sensitive
4. **Label Strategies** - app, version, environment, tenant
5. **Health Checks** - Liveness (restart if dead), readiness (traffic routing)

### Terraform Patterns

1. **Module Composition** - Reusable infrastructure components
2. **Remote State** - S3 backend with locking (DynamoDB)
3. **Workspaces** - Environment separation
4. **Variable Files** - `.tfvars` per environment
5. **Output Values** - Share data between modules

---

## 🔄 SESSION NOTES

**Current Blocker:** WSL networking issue preventing `terraform init`

**Solution:** Run Terraform from PowerShell instead of WSL

```powershell
cd "C:\Users\chris\Documents\AWS Projects and Challenges\SRE_Lab_Enterprise_Level\terraform"
terraform init
terraform apply
```

**After restart:**

1. Open PowerShell
2. Navigate to terraform directory
3. Run `terraform init`
4. Run `terraform plan` to preview
5. Run `terraform apply` to create OIDC provider
6. Copy output role ARN
7. Update `.github/workflows/ci-cd.yml` with OIDC configuration
8. Test pipeline authentication

---

## 📚 RESOURCES & REFERENCES

### Documentation Created

- ✅ Container security contexts documented
- ✅ Network policies explained (5 policies)
- ✅ RBAC architecture documented
- ✅ OIDC module with full README

### External Resources

- [GitHub Actions OIDC](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [AWS IAM OIDC Identity Providers](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_providers_create_oidc.html)
- [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Kubernetes RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)

---

## 💡 NEXT SESSION PLAN

1. **Immediate:** Fix Terraform networking, apply OIDC module
2. **Short-term:** Update GitHub Actions to use OIDC
3. **Medium-term:** Multi-language pipeline implementation
4. **Long-term:** Complete all 14 phases

**Estimated Timeline:**

- Phase 6 (OIDC): 1-2 hours remaining
- Phase 7 (Multi-lang): 3-4 hours
- Phase 8 (Security scanning): 2-3 hours
- Phase 9 (Terraform isolation): 2 hours
- Phase 10-14: 8-10 hours total

**Total to completion:** ~20-25 hours of focused work

---

## 🎯 SUCCESS METRICS

**Technical Skills:**

- ✅ 5 security layers implemented
- ✅ 0 CRITICAL vulnerabilities
- ⏸️ CI/CD pipeline with OIDC (90% complete)
- ⏸️ Multi-environment deployment strategy (planned)

**Interview Readiness:**

- ✅ Can explain container security hardening
- ✅ Can explain Kubernetes security (RBAC, Network Policies, Secrets)
- ⏸️ Can explain CI/CD security (OIDC in progress)
- ⏸️ Can explain multi-language pipeline design
- ⏸️ Can explain Terraform best practices
- ⏸️ Can explain zero-downtime operations

**Confidence Level:**

- Container Security: ⭐⭐⭐⭐⭐ (Expert)
- K8s Security: ⭐⭐⭐⭐⭐ (Expert)
- CI/CD Security: ⭐⭐⭐⭐ (Advanced - completing OIDC)
- Terraform: ⭐⭐⭐ (Intermediate - improving)
- Multi-language Pipelines: ⭐⭐ (Learning)

---

**Remember:** This is a marathon, not a sprint. You're building **senior-level, production-grade** knowledge. Every phase completed makes you more interview-ready! 💪
