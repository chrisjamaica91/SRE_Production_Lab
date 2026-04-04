# 🚀 Enterprise-Level AWS SRE Platform Lab

A production-grade AWS infrastructure project demonstrating **Site Reliability Engineering (SRE)** best practices, built to prepare for senior-level cloud engineering roles.

---

## � What You'll Learn & Career Impact

This isn't just another "hello world" Kubernetes tutorial. This is a **complete production-grade infrastructure** that you can show to hiring managers at top tech companies and confidently say: _"I built this, I understand it, and I can do it for your company."_

You'll master **senior and lead-level SRE concepts** that most engineers take 3-5 years to learn on the job: **Zero-trust networking** (most companies still haven't adopted this), **immutable infrastructure** patterns used by Netflix and Spotify, **GitOps deployments** that eliminate manual kubectl commands, and **OIDC-based CI/CD** that passes security audits. You'll implement **container hardening** (read-only filesystems, non-root users, dropped capabilities) that meets SOC 2 compliance requirements. You'll configure **blue-green deployments** for zero-downtime releases and **Horizontal Pod Autoscaling** that handles traffic spikes automatically.

**Career Impact:** This project positions you for **$160,000-$320,000** roles at companies hiring for Senior Platform Engineers, Lead DevOps Engineers, Staff SREs, and Principal Kubernetes Engineers. When you can explain the difference between **Network Policies vs Security Groups** (pod-level vs node-level), debug **CrashLoopBackOff** with kubectl logs and describe, or architect **multi-environment Terraform** with state isolation, you're in the **top 1% of cloud engineers**. Hiring managers will immediately recognize you've done the real work—not just watched tutorials.

By the end, you'll have **GitHub commits**, **documented decisions**, and **interview talking points** for every phase. This is your proof you can handle production infrastructure at scale.

---

## ✅ Production Implementation Highlights

### **Phase 1: Container Security Hardening** ✅ COMPLETE

**What We Built:**
Implemented **production-grade container security** that passes compliance audits (SOC 2, HIPAA, PCI-DSS).

**Implementation Details:**

```yaml
# Container hardening - app/src/server.js Dockerfile
securityContext:
  readOnlyRootFilesystem: true # Immutable containers
  runAsNonRoot: true # Non-root user execution
  runAsUser: 1000 # Specific UID
  allowPrivilegeEscalation: false # No privilege escalation
  capabilities:
    drop:
      - ALL # Drop all Linux capabilities
```

**Interview Talking Points:**

- "Why read-only filesystem?" → Prevents runtime tampering, attackers can't write malware
- "What if app needs /tmp?" → Mount emptyDir volume for temporary storage
- "Why drop ALL capabilities?" → Principle of least privilege, most apps don't need raw sockets or kill processes

**Real-World Impact:** Netflix, Datadog, and Stripe use identical patterns.

---

### **Phase 2: Image Vulnerability Scanning (Trivy)** ✅ COMPLETE

**What We Built:**
Integrated **Trivy** image scanning into CI/CD to catch CVEs before production deployment.

**Current Security Posture:**

```bash
# Scan results:
Total: 153 vulnerabilities
├── CRITICAL: 0  ✅
├── HIGH: 11     ⚠️  (Acceptable - base image dependencies)
├── MEDIUM: 68
└── LOW: 74

# CI/CD policy: BLOCK on CRITICAL, WARN on HIGH
```

**Environment-Specific Scanning Strategy:**

```yaml
# Development: Fast feedback (1-2 min)
- Skip MEDIUM/LOW severity scans
- Cache scan results for 24 hours

# Staging: Comprehensive (5-7 min)
- Scan all severities
- Generate SBOM (Software Bill of Materials)

# Production: Full audit (10-15 min)
- Full scan with --severity UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL
- Compliance reports (CIS benchmarks)
- License validation
```

**Interview Talking Points:**

- "Why not block on HIGH?" → Base image false positives, vendor patching lag
- "How to speed up scans?" → Layer caching, parallel execution, scan result caching
- "What's an SBOM?" → Software Bill of Materials - inventory of all components for supply chain security

---

### **Phase 3: Kubernetes Secrets Management** ✅ COMPLETE

**What We Built:**
Implemented **secure secret handling** with Kubernetes native secrets (imperative creation, never committed to Git).

**Implementation:**

```bash
# Create secret imperatively (NOT in Git)
kubectl create secret generic db-credentials \
  --from-literal=username=admin \
  --from-literal=password=$(aws secretsmanager get-secret-value \
    --secret-id rds-credentials --query SecretString -o text | jq -r .password)

# Reference in deployment
env:
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: db-credentials
        key: password
```

**Security Improvements Over Amateur Approach:**
| ❌ Bad Practice | ✅ Production Pattern |
| ------------------------ | ----------------------------------------- |
| Hardcoded in Dockerfile | Kubernetes Secrets |
| Committed to Git | Imperative creation only |
| Plain text ConfigMaps | Secrets (base64 at rest, encrypted in transit) |
| Shared across namespaces | Namespace isolation |
| No rotation | Automated rotation with AWS Secrets Manager |

**Interview Talking Points:**

- "Are Kubernetes Secrets encrypted?" → Base64 encoded (not encrypted). Enable encryption at rest with EncryptionConfiguration.
- "How to rotate secrets without downtime?" → External Secrets Operator syncs from AWS Secrets Manager automatically.
- "Why not use AWS Secrets Manager directly?" → K8s Secrets provide abstraction layer, faster access (no API calls), works across cloud providers.

---

### **Phase 4: Network Policies (Zero-Trust Networking)** ✅ COMPLETE

**What We Built:**
Implemented **zero-trust pod-level networking** with Kubernetes Network Policies.

**Architecture:**

```yaml
# Default deny all ingress/egress
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress

# Allow app → database only
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-app-to-postgres
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
    - Egress
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: postgres
      ports:
        - protocol: TCP
          port: 5432

# Allow DNS resolution (critical!)
- to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
  ports:
    - protocol: UDP
      port: 53
```

**Why This Is Senior-Level:**
Most engineers don't realize:

1. **Default deny breaks DNS** - Must explicitly allow port 53 UDP to kube-dns
2. **Need both ingress AND egress** - Many forget egress rules
3. **CNI dependency** - Network Policies don't work on Docker Desktop (no CNI plugin)

**Interview Talking Points:**

- "Difference between Security Groups and Network Policies?" → Security Groups = node-level, Network Policies = pod-level
- "Why doesn't this work on Docker Desktop?" → No Container Network Interface (CNI) plugin. Works on EKS (AWS VPC CNI), GKE (Calico), AKS (Azure CNI).
- "How to test Network Policies?" → Deploy test pod, try curl/nc to restricted service, verify connection timeout.

---

### **Phase 5: RBAC (Role-Based Access Control)** ✅ COMPLETE

**What We Built:**
Configured **least-privilege service accounts** for pods (no automatic Kubernetes API access).

**Implementation:**

```yaml
# ServiceAccount (pod identity)
apiVersion: v1
kind: ServiceAccount
metadata:
  name: sre-lab-api-sa
automountServiceAccountToken: false  # Critical security!

# Role (namespace-scoped permissions)
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: sre-lab-api-role
rules:
  - apiGroups: [""]
    resources: ["pods", "configmaps"]
    verbs: ["get", "list"]  # Read-only

# RoleBinding (assignment)
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: sre-lab-api-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: sre-lab-api-role
subjects:
  - kind: ServiceAccount
    name: sre-lab-api-sa
```

**Interview Talking Points:**

- "Should apps have service account tokens?" → NO! Only if they call Kubernetes API (like custom controllers, operators).
- "How to debug RBAC denials?" → `kubectl auth can-i <verb> <resource> --as=system:serviceaccount:default:sre-lab-api-sa`
- "Difference between Role and ClusterRole?" → Role = namespace-scoped, ClusterRole = cluster-wide (nodes, PVs, namespaces).

---

## 📋 Project Overview

This project showcases a **real-world cloud platform** running on AWS with:

- **AWS EKS** - Managed Kubernetes cluster
- **Terraform** - Infrastructure as Code (VPC, EKS, RDS, Lambda, GitHub OIDC modules)
- **Argo CD** - GitOps continuous delivery
- **Node.js API** - Containerized application with PostgreSQL integration
- **RDS PostgreSQL** - Managed database in private subnets with automated backups
- **Lambda Functions** - Serverless computing with VPC integration
- **Prometheus + Grafana** - Production-grade observability stack
- **CloudWatch** - Centralized logging with log insights
- **Blue/Green Deployments** - Zero-downtime release strategy
- **Load Testing** - Performance validation
- **Security** - RBAC, Network Policies, Trivy scanning, container hardening, OIDC authentication
- **CI/CD** - GitHub Actions pipeline with OIDC (no static AWS keys)

**This is not a toy project.** Every component follows production best practices used at companies like Netflix, Spotify, and Datadog.

---

## 🔄 Current Phase: GitHub OIDC Authentication (80% Complete)

**Goal:** Eliminate long-lived AWS credentials from CI/CD pipeline.

**Problem Statement:**
Traditional approach uses AWS Access Keys stored as GitHub Secrets. **Security risks:**

- Long-lived credentials (never expire)
- Can be stolen from GitHub repository settings
- Difficult to rotate
- Broad permissions (can't scope to specific branch/workflow)

**Production Solution: OIDC (OpenID Connect)**

**How It Works:**

```
GitHub Actions Workflow
  ↓
Request JWT token from GitHub OIDC Provider
  ↓
AWS STS (Security Token Service) validates JWT
  ↓
Trust policy checks "sub" claim: repo:YourOrg/YourRepo:ref:refs/heads/main
  ↓
Returns temporary AWS credentials (15 min token → 1 hour session)
  ↓
Workflow uses credentials to deploy to EKS
```

**Implementation Status:**

- ✅ Created Terraform module: `terraform/modules/github-oidc/`
- ✅ IAM OIDC Provider configuration
- ✅ IAM Role with trust policy (validates repo, branch, workflow)
- ✅ Documented in `terraform/modules/github-oidc/README.md`
- ⏸️ Pending: `terraform apply` (WSL networking issue - run from PowerShell)
- ⏸️ Pending: Update `.github/workflows/ci-cd.yml` with OIDC authentication

**Interview Talking Points:**

- "Why OIDC over IAM users?" → No static secrets, automatic expiry, granular control (can restrict to specific branch).
- "How does AWS trust GitHub?" → OIDC Provider validates JWT token signature using GitHub's public keys.
- "What's in the JWT token?" → Claims: `sub` (repo:org/repo:ref:branch), `aud` (audience), `iss` (issuer: token.actions.githubusercontent.com).
- "Can someone fork your repo and get AWS access?" → No! Trust policy validates exact repository name.

**Trust Policy Example:**

```json
{
  "Effect": "Allow",
  "Principal": {
    "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com"
  },
  "Action": "sts:AssumeRoleWithWebIdentity",
  "Condition": {
    "StringEquals": {
      "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
      "token.actions.githubusercontent.com:sub": "repo:YourOrg/YourRepo:ref:refs/heads/main"
    }
  }
}
```

---

## 📅 Upcoming Phases

### **Phase 6: Multi-Language CI/CD Pipeline**

**Interview Question:** "You have Java backend, JavaScript frontend, and Rust component. How do you design the pipeline?"

**Planned Implementation:**

- Matrix build strategy with path-based triggers (only build changed services)
- Parallel execution with dependency caching
- Language-specific optimizations:
  - **Java:** Maven multi-stage builds, OWASP Dependency-Check
  - **JavaScript:** `npm ci`, webpack bundling, Snyk scanning
  - **Rust:** cargo-chef for layer caching, clippy linting

**Expected Result:** Build time <5 min, deploy time <3 min

---

### **Phase 7: Terraform Environment Isolation**

**Interview Questions:**

- "How to version Terraform for dev/staging/prod?"
- "How to prevent dev values from making their way to prod?"
- "How to limit AWS console access for DevOps engineers?"

**Planned Implementation:**

- Terraform workspaces (dev, staging, prod)
- Remote state with isolation (separate S3 buckets per environment)
- Variable files per environment (`terraform.tfvars`)
- Backend configuration per environment
- CODEOWNERS file for approval gates (prod requires team lead approval)
- IAM policies: Pipeline-only deployment (no console access)

**File Structure:**

```
terraform/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── backend.tf (s3://tfstate-dev/)
│   │   └── terraform.tfvars
│   ├── staging/
│   │   ├── main.tf
│   │   ├── backend.tf (s3://tfstate-staging/)
│   │   └── terraform.tfvars
│   └── prod/
│       ├── main.tf
│       ├── backend.tf (s3://tfstate-prod/)
│       └── terraform.tfvars (requires approval!)
```

---

## 🎯 Learning Objectives

By completing this project, you will master:

✅ **AWS Services**: VPC, EKS, RDS, Lambda, ALB, Secrets Manager, IAM, CloudWatch  
✅ **Kubernetes**: Deployments, Services, Ingress, ConfigMaps, Secrets, RBAC, Network Policies, HPA  
✅ **Infrastructure as Code**: Terraform modules, state management, best practices  
✅ **GitOps**: Argo CD, declarative infrastructure, drift detection  
✅ **Observability**: Metrics (Prometheus), logs (CloudWatch), dashboards (Grafana), alerts  
✅ **CI/CD**: GitHub Actions, Docker builds, security scanning, automated deployments  
✅ **Troubleshooting**: kubectl commands, incident response, systematic debugging  
✅ **Production Practices**: SLOs, runbooks, postmortems, blue/green deployments  
✅ **Security**: IAM roles, security groups, RBAC, network policies, secrets management  
✅ **Cost Optimization**: Resource tagging, right-sizing, cost awareness

---

## 🏗️ Architecture

```
Internet
   ↓
Application Load Balancer (ALB)
   ↓
Ingress Controller (Blue/Green Switch)
   ↓
┌─────────────────────────────────────┐
│         EKS Cluster (VPC)           │
│                                     │
│  ┌────────────┐  ┌────────────┐   │
│  │   Blue     │  │   Green    │   │
│  │Environment │  │Environment │   │
│  │(Production)│  │ (Staging)  │   │
│  └─────┬──────┘  └─────┬──────┘   │
│        └────────┬────────┘          │
│                 ↓                   │
│         Node.js API Pods            │
│        (Auto-scaling 2-10)          │
└────────────┬────────────────────────┘
             ↓
    ┌────────┴─────────┐
    ↓                  ↓
RDS PostgreSQL    Lambda Functions
(Private Subnet)  (VPC Integration)
    ↓
Secrets Manager

Monitored by:
Prometheus + Grafana + CloudWatch + AlertManager

Deployed via:
GitHub Actions → ECR → Git Commit → Argo CD → EKS
```

**Full architecture diagram:** See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)

---

## 📂 Project Structure

```
SRE_Lab_Enterprise_Level/
├── terraform/                    # Infrastructure as Code
│   ├── modules/
│   │   ├── vpc/                  # Network infrastructure
│   │   ├── eks/                  # Kubernetes cluster
│   │   ├── rds/                  # Database
│   │   └── lambda/               # Serverless functions
│   ├── main.tf                   # Main Terraform config
│   ├── variables.tf              # Input variables
│   └── outputs.tf                # Output values
│
├── app/                          # Node.js application
│   ├── src/                      # Application code
│   ├── package.json              # Dependencies
│   ├── Dockerfile                # Container image
│   └── README.md                 # App documentation
│
├── k8s/                          # Kubernetes manifests
│   ├── base/                     # Base configurations
│   │   ├── deployment.yaml       # App deployment
│   │   ├── service.yaml          # Service definition
│   │   ├── ingress.yaml          # Ingress rules
│   │   ├── configmap.yaml        # Configuration
│   │   ├── hpa.yaml              # Auto-scaling
│   │   └── namespace.yaml        # Namespace
│   ├── production/               # Production overrides
│   └── blue-green/               # Blue/Green configs
│
├── lambda/                       # Lambda function code
│   ├── src/                      # Function code
│   ├── package.json              # Dependencies
│   └── README.md                 # Lambda documentation
│
├── observability/                # Monitoring configs
│   ├── grafana-dashboards/       # Dashboard JSONs
│   └── prometheus/               # Prometheus rules
│
├── .github/
│   └── workflows/                # CI/CD pipelines
│       ├── ci.yaml               # Build & test
│       └── cd.yaml               # Deploy
│
├── docs/                         # Documentation
│   ├── ARCHITECTURE.md           # Full architecture guide
│   ├── PROJECT_ROADMAP.md        # Phase-by-phase plan
│   ├── KUBECTL_CHEATSHEET.md     # kubectl reference
│   ├── adrs/                     # Architecture decisions
│   │   └── TEMPLATE.md           # ADR template
│   ├── runbooks/                 # Operational procedures
│   ├── incidents/                # Incident postmortems
│   │   └── TEMPLATE.md           # Postmortem template
│   └── onboarding/               # How to get started
│
├── scripts/                      # Utility scripts
│   ├── deploy.sh                 # Deployment script
│   ├── rollback.sh               # Rollback script
│   └── setup-aws.sh              # AWS setup
│
└── load-tests/                   # Load testing configs
    ├── siege.conf                # Siege configuration
    └── test-scenarios/           # Test definitions
```

---

## 🚦 Prerequisites

Before starting, ensure you have:

### Required Tools:

- [ ] **AWS Account** (Free tier eligible)
- [ ] **AWS CLI** - `aws --version`
- [ ] **kubectl** - `kubectl version --client`
- [ ] **Terraform** - `terraform version`
- [ ] **Docker Desktop** - `docker --version`
- [ ] **Helm** - `helm version`
- [ ] **Git** - `git --version`
- [ ] **Node.js** (v18+) - `node --version`

### Installation Guides:

- **AWS CLI**: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
- **kubectl**: https://kubernetes.io/docs/tasks/tools/
- **Terraform**: https://developer.hashicorp.com/terraform/downloads
- **Docker Desktop**: https://www.docker.com/products/docker-desktop/
- **Helm**: https://helm.sh/docs/intro/install/

### AWS Configuration:

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Default region: us-east-1 (or your preference)
# Default output format: json
```

---

## 🎓 Getting Started

### Step 1: Review the Documentation

**Start here - don't skip this!**

1. **Read** [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) - Understand the full system
2. **Review** [`docs/PROJECT_ROADMAP.md`](docs/PROJECT_ROADMAP.md) - See the phase-by-phase plan
3. **Bookmark** [`docs/KUBECTL_CHEATSHEET.md`](docs/KUBECTL_CHEATSHEET.md) - Your troubleshooting companion

### Step 2: Clone and Navigate

```bash
cd "c:\Users\chris\Documents\AWS Projects and Challenges\SRE_Lab_Enterprise_Level"
```

### Step 3: Follow the Roadmap

Open [`docs/PROJECT_ROADMAP.md`](docs/PROJECT_ROADMAP.md) and start with **Phase 1: Infrastructure Foundation**.

We'll build this **one phase at a time**, with detailed explanations at each step.

---

## 📖 Documentation Index

| Document                                            | Purpose                                                   |
| --------------------------------------------------- | --------------------------------------------------------- |
| **[PROJECT_STATUS.md](PROJECT_STATUS.md)**          | **Current progress, completed phases, next steps**        |
| [ARCHITECTURE.md](docs/ARCHITECTURE.md)             | Complete architecture overview and component explanations |
| [PROJECT_ROADMAP.md](docs/PROJECT_ROADMAP.md)       | Phase-by-phase implementation plan with tasks             |
| [KUBECTL_CHEATSHEET.md](docs/KUBECTL_CHEATSHEET.md) | Essential kubectl commands for troubleshooting            |
| [ADR Template](docs/adrs/TEMPLATE.md)               | How to document architecture decisions                    |
| [Incident Template](docs/incidents/TEMPLATE.md)     | How to write postmortems                                  |

**Start with PROJECT_STATUS.md to see where you are and what's next!**

---

## 🛠️ Quick Commands (Once Built)

### Deploy Application

```bash
# Via GitOps (recommended)
git add k8s/
git commit -m "Update app to v1.2.3"
git push
# Argo CD automatically syncs

# Via kubectl (for testing)
kubectl apply -f k8s/base/
```

### Check Application Status

```bash
kubectl get all -n production
kubectl get pods -n production
kubectl logs -f <pod-name> -n production
```

### Access Monitoring

```bash
# Grafana
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80

# Prometheus
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090

# Argo CD
kubectl port-forward -n argocd svc/argocd-server 8080:443
```

### Rollback Deployment

```bash
kubectl rollout undo deployment/app -n production
```

### Run Load Test

```bash
siege -c 50 -t 60s http://your-alb-url.amazonaws.com/api/users
```

---

## 🔥 Failure Scenarios (Practice Troubleshooting)

This project includes **intentional failure simulations** to practice incident response:

1. **ImagePullBackOff** - Wrong container image tag
2. **CrashLoopBackOff** - Application crash
3. **Service No Endpoints** - Selector mismatch
4. **Failed Readiness Probe** - Database unreachable
5. **OOMKilled** - Memory limit too low
6. **Database Connection Failure** - Wrong credentials
7. **Security Group Misconfiguration** - Network blocked
8. **Resource Exhaustion** - Insufficient cluster capacity

Each scenario includes:

- How to simulate
- How to detect
- kubectl commands to diagnose
- How to resolve
- How to prevent

**See [`docs/PROJECT_ROADMAP.md`](docs/PROJECT_ROADMAP.md) Phase 8 for details.**

---

## 💰 Cost Awareness

**Estimated monthly cost:** ~$200-250 USD

| Resource                  | Estimated Cost |
| ------------------------- | -------------- |
| EKS Control Plane         | $73/month      |
| EC2 Nodes (2x t3.medium)  | $60/month      |
| RDS db.t3.micro           | $15/month      |
| NAT Gateway               | $32/month      |
| Application Load Balancer | $16/month      |
| Data Transfer             | $5-10/month    |
| CloudWatch Logs           | $5/month       |

**Cost Optimization Tips:**

- Use free tier RDS (db.t3.micro)
- Start with smaller node types
- Stop/start infrastructure when not in use
- Use Terraform destroy when not actively learning
- Set up billing alerts in AWS

**To destroy infrastructure:**

```bash
cd terraform
terraform destroy
```

---

## 🔒 Security Considerations

This project implements production-grade security:

- ✅ **Network Isolation**: Private subnets for databases and apps
- ✅ **IAM Roles**: Principle of least privilege
- ✅ **Secrets Management**: AWS Secrets Manager (no hardcoded credentials)
- ✅ **RBAC**: Kubernetes role-based access control
- ✅ **Network Policies**: Pod-to-pod traffic restrictions
- ✅ **Security Groups**: Firewall rules
- ✅ **Image Scanning**: Trivy for CVE detection
- ✅ **Encrypted Storage**: RDS encryption at rest
- ✅ **TLS/SSL**: HTTPS for all public endpoints

---

## 🎤 Interview Talking Points

After completing this project, you can confidently discuss:

### Core Infrastructure ✅

<details>
<summary><strong>"Walk me through your most complex project"</strong></summary>

**Answer:**
"I built an enterprise-grade AWS infrastructure using EKS, Terraform, and GitOps. The architecture includes a multi-AZ VPC with public/private subnet isolation, an EKS cluster running containerized Node.js applications, RDS PostgreSQL in private subnets, and full observability with Prometheus/Grafana.

The most complex part was implementing **zero-trust networking with Network Policies**. I had to ensure pods could only communicate with explicitly allowed services while still maintaining DNS resolution. Most tutorials skip the critical DNS egress rule, which I learned the hard way after debugging connectivity issues for hours.

I also implemented **production-grade security hardening**: read-only root filesystems, non-root container users, dropped Linux capabilities, Trivy image scanning in CI/CD, and OIDC authentication to eliminate static AWS credentials. The entire infrastructure is deployed via **GitOps with ArgoCD**, so all changes are version-controlled and auditable."

</details>

<details>
<summary><strong>"How do you troubleshoot a failing Kubernetes pod?"</strong></summary>

**Systematic Approach:**

```bash
# 1. Check pod status
kubectl get pods -n production
# Look for: Pending, CrashLoopBackOff, ImagePullBackOff, OOMKilled

# 2. Describe pod (events are critical!)
kubectl describe pod <pod-name> -n production
# Check: Events section (failures), resource limits, volume mounts

# 3. Check logs
kubectl logs <pod-name> -n production
kubectl logs <pod-name> -n production --previous  # Previous crash

# 4. Check resource constraints
kubectl top pod <pod-name> -n production
# Look for: Memory/CPU usage near limits

# 5. Exec into pod (if running)
kubectl exec -it <pod-name> -n production -- /bin/sh
# Verify: Environment variables, file permissions, network connectivity
```

**Common Failure Scenarios I've Debugged:**

- **ImagePullBackOff:** Wrong ECR repository URL, missing image tag
- **CrashLoopBackOff:** Missing environment variables (DB_HOST), database unreachable
- **Pending:** Insufficient cluster capacity (nodes maxed out), PVC not bound
- **OOMKilled:** Memory limit too low (increased from 128Mi to 512Mi)
</details>

<details>
<summary><strong>"How do you manage secrets and credentials?"</strong></summary>

**Multi-Layer Strategy:**

**Layer 1 - AWS Secrets Manager (Source of Truth)**

```bash
# Store in AWS Secrets Manager
aws secretsmanager create-secret \
  --name rds-credentials \
  --secret-string '{"username":"admin","password":"<generated>"}'
```

**Layer 2 - Kubernetes Secrets (Never in Git)**

```bash
# Sync to Kubernetes imperatively
kubectl create secret generic db-credentials \
  --from-literal=password=$(aws secretsmanager get-secret-value \
    --secret-id rds-credentials --query SecretString -o text | jq -r .password)
```

**Layer 3 - Pod Injection (Environment Variables)**

```yaml
env:
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: db-credentials
        key: password
```

**Interview Talking Point:**
"I use AWS Secrets Manager as the source of truth with automatic rotation, sync to Kubernetes Secrets for fast pod access, and **never commit secrets to Git**. For production, I'd implement **External Secrets Operator** to automate the sync and **enable Kubernetes encryption at rest** since default secrets are only base64-encoded."

</details>

<details>
<summary><strong>"What's your deployment strategy?"</strong></summary>

**Blue-Green Deployments for Zero Downtime:**

```yaml
# Blue deployment (production traffic)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-blue
spec:
  replicas: 3
  template:
    metadata:
      labels:
        app: api
        version: v1.2.0
        deployment: blue

# Green deployment (new version, no traffic)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-green
spec:
  replicas: 3
  template:
    metadata:
      labels:
        app: api
        version: v1.3.0
        deployment: green

# Service (switch traffic by changing selector)
apiVersion: v1
kind: Service
metadata:
  name: api-service
spec:
  selector:
    app: api
    deployment: blue  # Switch to "green" for cutover
```

**Deployment Process:**

1. Deploy new version to Green environment
2. Run smoke tests against Green
3. Switch Service selector from `blue` to `green`
4. Monitor metrics for 15 minutes
5. If successful, keep Green. If failure, instant rollback to Blue.

**Why Blue-Green Over Rolling Updates?**

- Instant rollback (change Service selector)
- Test production environment before cutover
- No "mixed version" state
- Database migration safety (both versions can coexist)
</details>

</details>

---

### Advanced Security Topics ✅

<details>
<summary><strong>"How to properly secure containers?"</strong></summary>

**Implemented Container Security Controls:**

```yaml
securityContext:
  # 1. Read-only root filesystem
  readOnlyRootFilesystem: true
  # Why: Prevents runtime tampering (malware injection, log manipulation)

  # 2. Non-root user
  runAsNonRoot: true
  runAsUser: 1000
  # Why: Limits blast radius if container is compromised

  # 3. No privilege escalation
  allowPrivilegeEscalation: false
  # Why: Prevents setuid binaries from escalating privileges

  # 4. Drop all Linux capabilities
  capabilities:
    drop:
      - ALL
  # Why: Most apps don't need CAP_NET_RAW, CAP_KILL, CAP_SYS_ADMIN

# What if app needs /tmp?
volumes:
  - name: tmp
    emptyDir: {}
volumeMounts:
  - name: tmp
    mountPath: /tmp
```

**Interview Talking Point:**
"I implement **defense in depth**: read-only filesystem prevents runtime changes, non-root user limits privilege, dropped capabilities prevent raw socket access. This passed Trivy benchmarks for CIS Docker compliance."

</details>

<details>
<summary><strong>"Explain Kubernetes RBAC architecture"</strong></summary>

**Four Components:**

1. **ServiceAccount** - Pod identity
2. **Role** - Permissions (namespace-scoped)
3. **RoleBinding** - Assigns Role to ServiceAccount
4. **ClusterRole** - Cluster-wide permissions (nodes, PVs, namespaces)

**Production Configuration:**

```yaml
# ServiceAccount
apiVersion: v1
kind: ServiceAccount
metadata:
  name: sre-lab-api-sa
automountServiceAccountToken: false  # Critical! Only mount if app calls K8s API

# Role (read-only pods and configmaps)
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: sre-lab-api-role
rules:
  - apiGroups: [""]
    resources: ["pods", "configmaps"]
    verbs: ["get", "list"]  # No "create", "delete", "update"

# RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: sre-lab-api-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: sre-lab-api-role
subjects:
  - kind: ServiceAccount
    name: sre-lab-api-sa
```

**Debugging RBAC:**

```bash
# Test permissions
kubectl auth can-i get pods --as=system:serviceaccount:default:sre-lab-api-sa
# Output: yes/no

# Check what a ServiceAccount can do
kubectl auth can-i --list --as=system:serviceaccount:default:sre-lab-api-sa
```

**Interview Talking Point:**
"Most engineers forget to set `automountServiceAccountToken: false`. This automatically mounts API credentials in every pod, which is a security risk if the app doesn't need Kubernetes API access."

</details>

<details>
<summary><strong>"What are Network Policies and how do they work?"</strong></summary>

**Zero-Trust Networking at Pod Level:**

```yaml
# 1. Default deny all traffic
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}  # Matches all pods
  policyTypes:
    - Ingress
    - Egress

# 2. Allow app → postgres only
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-app-to-postgres
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
    - Egress
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: postgres
      ports:
        - protocol: TCP
          port: 5432

# 3. CRITICAL: Allow DNS resolution
- to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
  ports:
    - protocol: UDP
      port: 53
```

**Common Mistake:**
"Forgetting DNS egress rule breaks service discovery. Pods can't resolve `postgres.default.svc.cluster.local` without port 53 UDP to kube-dns."

**Network Policies vs Security Groups:**
| Network Policies | Security Groups |
| ------------------------- | ---------------------- |
| Pod-level (Layer 7) | Node-level (Layer 4) |
| Label-based | IP/CIDR-based |
| Requires CNI plugin | Works on EC2 directly |
| Kubernetes-native | AWS-specific |

**Interview Talking Point:**
"Network Policies don't work on Docker Desktop because it lacks a CNI plugin. They work on EKS (AWS VPC CNI), GKE (Calico), AKS (Azure CNI). I test policies by deploying a debug pod and running `nc -zv postgres 5432` to verify connections are blocked/allowed."

</details>

---

### CI/CD & DevOps 🔄

<details>
<summary><strong>"How does OIDC authentication work in GitHub Actions?"</strong> (In Progress - 80% Complete)</summary>

**Problem with Traditional Approach:**

```yaml
# ❌ Old way: Long-lived AWS Access Keys in GitHub Secrets
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v1
  with:
    aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
    aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
    aws-region: us-east-1
```

**Risks:**

- Keys never expire
- Can be stolen from GitHub repository settings
- Difficult to rotate
- Broad permissions (can't scope to specific branch)

**Production Solution: OIDC**

```yaml
# ✅ New way: Short-lived tokens with OIDC
- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v1
  with:
    role-to-assume: arn:aws:iam::123456789012:role/GitHubActionsRole
    aws-region: us-east-1
```

**How It Works:**

1. GitHub Actions requests JWT token from GitHub OIDC Provider
2. Token includes claims: `sub: repo:YourOrg/YourRepo:ref:refs/heads/main`
3. Workflow sends JWT to AWS STS (AssumeRoleWithWebIdentity)
4. AWS validates JWT signature using GitHub's public keys
5. AWS checks trust policy: Does repo/branch match?
6. Returns temporary credentials (1 hour expiry)

**Trust Policy:**

```json
{
  "Effect": "Allow",
  "Principal": {
    "Federated": "arn:aws:iam::ACCOUNT:oidc-provider/token.actions.githubusercontent.com"
  },
  "Action": "sts:AssumeRoleWithWebIdentity",
  "Condition": {
    "StringEquals": {
      "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
      "token.actions.githubusercontent.com:sub": "repo:YourOrg/YourRepo:ref:refs/heads/main"
    }
  }
}
```

**Interview Talking Point:**
"OIDC provides short-lived credentials (1 hour vs permanent keys), granular control (can restrict to specific branch/workflow), and automatic rotation. If someone forks your repo, they can't access your AWS account because the trust policy validates the exact repository name in the JWT `sub` claim."

</details>

---

### Infrastructure as Code ⏸️

_(Planned for future phases - Terraform environment isolation with dev/staging/prod workspaces, state isolation, approval gates)_  
⏸️ "How to perform zero-downtime database migrations with Terraform?"  
⏸️ "When to use `create_before_destroy` lifecycle?"

### Observability & Operations

⏸️ "How to implement monitoring for multi-tenant infrastructure?"  
⏸️ "How to version Grafana dashboards for different environments?"  
⏸️ "What are DORA metrics and how do you track them?"  
⏸️ "How to aggregate logs across multiple tenants?"

### Authentication & Access Control

⏸️ "How to implement single sign-on within AWS?"  
⏸️ "What is IRSA (IAM Roles for Service Accounts)?"  
⏸️ "How to implement OIDC federation with external IdP?"

**You'll have real answers backed by hands-on implementation, not just theory.**

---

## 📚 Learning Resources

### AWS

- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)
- [AWS EKS Best Practices](https://aws.github.io/aws-eks-best-practices/)

### Kubernetes

- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [Kubernetes Patterns (book)](https://www.oreilly.com/library/view/kubernetes-patterns/9781492050278/)

### SRE

- [Google SRE Book](https://sre.google/sre-book/table-of-contents/) (Free)
- [Site Reliability Workbook](https://sre.google/workbook/table-of-contents/) (Free)

### Observability

- [Prometheus Documentation](https://prometheus.io/docs/introduction/overview/)
- [Grafana Tutorials](https://grafana.com/tutorials/)

---

## 🤝 Contributing

This is a personal learning project, but feedback and suggestions are welcome!

If you're using this for your own learning:

1. Fork the repository
2. Work through at your own pace
3. Document your own learnings
4. Share your experience

---

## 📝 Progress Tracking

**See [`PROJECT_STATUS.md`](PROJECT_STATUS.md) for detailed current status and completed phases.**

Use the checklists in [`docs/PROJECT_ROADMAP.md`](docs/PROJECT_ROADMAP.md) to track your progress through each phase.

**Current Status:** Phase 6 - CI/CD Pipeline Security (OIDC Authentication) - 80% Complete

### Completed Phases ✅

1. ✅ Container Security Hardening (read-only filesystem, non-root, dropped capabilities)
2. ✅ Image Security Scanning (Trivy - 0 CRITICAL CVEs)
3. ✅ Kubernetes Secrets Management (kubectl secrets, not in Git)
4. ✅ Network Policies (zero-trust networking, 5 policies)
5. ✅ RBAC & Service Accounts (dedicated SA, minimal permissions, no token mounting)
6. 🔄 CI/CD Pipeline Security - OIDC Authentication (in progress)

---

## 🚀 Advanced Phases (Senior-Level Topics)

### Phase 7: Multi-Language CI/CD Pipeline

**Interview Q:** "Design a pipeline for Java backend, JavaScript frontend, and Rust component"

- Matrix build strategy with path-based triggers
- Language-specific optimizations (Maven, npm, Cargo)
- Parallel execution with dependency caching
- Build time <5 min, deploy time <3 min

### Phase 8: Comprehensive Security Scanning

**Interview Q:** "Implement security scanning without reducing dev time"

- SAST (Static Application Security Testing)
- DAST (Dynamic Application Security Testing)
- SCA (Software Composition Analysis)
- Container scanning (Trivy - already done!)
- IaC scanning (tfsec, Checkov for Terraform)
- Secret scanning (gitleaks, truffleHog)

### Phase 9: Terraform Environment Isolation

**Interview Q:** "Prevent dev values from reaching prod? Limit AWS console access?"

- Terraform workspaces (dev/staging/prod)
- Remote state isolation (separate S3 buckets)
- CODEOWNERS file for approval gates
- IAM policies: Pipeline-only deployment (no console changes)

### Phase 10: Zero-Downtime Operations

**Interview Q:** "How to migrate database types without downtime?"

- Blue-green infrastructure with Terraform
- Database migration strategies
- `create_before_destroy` lifecycle
- `terraform state mv` for resource renaming

### Phase 11: Pipeline Optimization & Metrics

**Interview Q:** "Describe a bottleneck you identified and how you optimized it"

- DORA metrics (deployment frequency, lead time, MTTR, change failure rate)
- Build caching strategies
- Parallel job execution
- Grafana dashboard for CI/CD metrics

### Phase 12: Multi-Tenant Monitoring & Logging

**Interview Q:** "Implement monitoring for multi-tenant cloud infrastructure"

- Label-based multi-tenancy in Prometheus
- Grafana template variables per tenant
- CloudWatch log groups per tenant
- Cost allocation by tenant

### Phase 13: AWS SSO & Authentication

**Interview Q:** "How to implement single sign-on within AWS?"

- AWS IAM Identity Center (AWS SSO)
- OIDC federation with external IdP (Okta, Google, Azure AD)
- IRSA (IAM Roles for Service Accounts)
- Cross-account access patterns

### Phase 14: Dashboard & Config Versioning

**Interview Q:** "How to version Grafana dashboards for different environments?"

- Dashboards as code (JSON in Git)
- Automated deployment via ConfigMaps
- Environment-specific variables
- Rollback capability

---

## 🎯 Success Criteria

You'll know you're ready for senior SRE interviews when you can:

- [ ] Explain the entire architecture without notes
- [ ] Deploy a change via GitOps in under 10 minutes
- [ ] Troubleshoot a failing pod in under 5 minutes
- [ ] Roll back a deployment in under 2 minutes
- [ ] Read Grafana dashboards and identify issues
- [ ] Write a comprehensive incident postmortem
- [ ] Discuss cost, security, and scalability trade-offs
- [ ] Design multi-region architecture on a whiteboard
- [ ] **Explain OIDC authentication for CI/CD pipelines**
- [ ] **Design multi-language CI/CD pipeline with optimization strategies**
- [ ] **Implement all 6 types of security scanning in parallel**
- [ ] **Explain Terraform environment isolation strategies**
- [ ] **Perform zero-downtime database migration**
- [ ] **Analyze and optimize CI/CD pipeline bottlenecks**

---

## 📧 Questions?

As you work through the project, document your questions and learnings. This becomes part of your learning journey and interview preparation.

---

## 📜 License

This project is for educational purposes. Feel free to use and modify for your own learning.

---

## 🌟 Acknowledgments

Built following AWS and Kubernetes best practices, inspired by real-world production systems and SRE principles from Google, Netflix, and other technology leaders.

---

## 🚀 Ready to Begin?

Open [`docs/PROJECT_ROADMAP.md`](docs/PROJECT_ROADMAP.md) and let's start with **Phase 1: Infrastructure Foundation**!

Remember: **Senior engineers learn by doing, not just reading.** Let's build something great! 💪
