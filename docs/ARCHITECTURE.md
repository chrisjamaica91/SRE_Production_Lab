# Enterprise-Level AWS SRE Platform Architecture

## 🎯 Project Overview

This is a **production-grade AWS platform** designed to demonstrate senior-level Site Reliability Engineering skills. It simulates a real-world enterprise cloud infrastructure with full CI/CD, observability, security, and disaster recovery capabilities.

---

## 🏗️ Architecture Diagram (High Level)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              USERS / INTERNET                             │
└───────────────────────────────────┬───────────────────────────────────────┘
                                    │
                                    ▼
                    ┌───────────────────────────────┐
                    │   Application Load Balancer    │
                    │    (ALB - Public Subnets)      │
                    └───────────────┬───────────────┘
                                    │
                    ┌───────────────▼───────────────┐
                    │     Ingress Controller         │
                    │    (NGINX/ALB Ingress)         │
                    └───────────────┬───────────────┘
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        │                                                         │
        ▼                                                         ▼
┌───────────────┐                                        ┌───────────────┐
│  Blue Service │                                        │ Green Service │
│  (Production) │                                        │   (Staging)   │
└───────┬───────┘                                        └───────┬───────┘
        │                                                         │
        │                BLUE/GREEN DEPLOYMENT                    │
        │                                                         │
        └───────────────────────────┬─────────────────────────────┘
                                    │
                        ┌───────────▼──────────────┐
                        │    EKS Cluster (VPC)     │
                        │   Private Subnets        │
                        │                          │
                        │  ┌────────────────────┐  │
                        │  │   Node.js API      │  │
                        │  │   Pods (2-10)      │  │
                        │  │   - Health checks  │  │
                        │  │   - Metrics        │  │
                        │  │   - Auto-scaling   │  │
                        │  └────────┬───────────┘  │
                        └───────────┼───────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
                    ▼               ▼               ▼
            ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
            │     RDS     │  │  Secrets    │  │  CloudWatch │
            │  PostgreSQL │  │  Manager    │  │    Logs     │
            │  (Private)  │  └─────────────┘  └─────────────┘
            └──────┬──────┘
                   │
                   ▼
            ┌─────────────┐
            │   Lambda    │
            │  Function   │
            │  (VPC-based)│
            └─────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                         OBSERVABILITY LAYER                              │
│                                                                          │
│  ┌──────────────┐    ┌──────────────┐     ┌──────────────┐            │
│  │  Prometheus  │───▶│   Grafana    │     │ AlertManager │            │
│  │   (Metrics)  │    │ (Dashboards) │     │   (Alerts)   │            │
│  └──────────────┘    └──────────────┘     └──────────────┘            │
└─────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────┐
│                            GITOPS LAYER                                  │
│                                                                          │
│  ┌──────────────┐    ┌──────────────┐     ┌──────────────┐            │
│  │   GitHub     │───▶│   Argo CD    │────▶│     EKS      │            │
│  │  Repository  │    │  (GitOps)    │     │   Cluster    │            │
│  └──────────────┘    └──────────────┘     └──────────────┘            │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 🔧 Core Components Explained

### 1. **VPC (Virtual Private Cloud)**
**What it is:** Your own isolated network in AWS
**Why we need it:** Security, network isolation, control over IP addressing

**Components:**
- **Public Subnets (2)**: For Load Balancer, NAT Gateway, Bastion (if needed)
  - Internet-facing resources
  - Available in 2 Availability Zones for high availability
  
- **Private Subnets (2)**: For EKS nodes, RDS, Lambda
  - Protected resources that don't need direct internet access
  - Also across 2 AZs for redundancy

- **Internet Gateway**: Allows public subnets to reach the internet
- **NAT Gateway**: Allows private subnets to reach internet (for updates, API calls) without being exposed
- **Route Tables**: Direct traffic appropriately between subnets

**Senior Insight:** Multi-AZ deployment is critical for production. If one data center fails, your app keeps running.

---

### 2. **EKS (Elastic Kubernetes Service)**
**What it is:** Managed Kubernetes cluster
**Why we need it:** Container orchestration, scaling, self-healing, declarative infrastructure

**Components:**
- **Control Plane**: Managed by AWS (API server, etcd, scheduler)
- **Worker Nodes**: EC2 instances running your containers (we manage these)
- **Node Groups**: Auto-scaling groups of worker nodes
- **Pod Security**: RBAC, Network Policies, Security Contexts

**Our Configuration:**
- 2-5 nodes (t3.medium or t3.large)
- Across 2 AZs
- Managed node groups for easier maintenance

**Senior Insight:** EKS abstracts away control plane management. You focus on apps, AWS handles K8s upgrades.

---

### 3. **Application (Node.js API)**
**What it is:** RESTful API service
**Why we need it:** Something realistic to deploy, monitor, and troubleshoot

**Endpoints:**
- `GET /health` - Liveness probe (always returns 200 if app is running)
- `GET /ready` - Readiness probe (checks DB connection, returns 200 if ready)
- `GET /api/users` - Fetch users from database
- `GET /api/orders` - Fetch orders from database
- `GET /metrics` - Prometheus metrics endpoint
- `GET /api/simulate-error` - Intentionally return 500 (for testing)
- `GET /api/simulate-latency?ms=1000` - Add artificial delay (for testing)

**Technologies:**
- Node.js + Express
- PostgreSQL client (pg library)
- Prometheus client (prom-client)
- Winston for structured JSON logging

**Senior Insight:** Real apps need health checks. Liveness = "is it alive?" Readiness = "is it ready to serve traffic?"

---

### 4. **RDS PostgreSQL**
**What it is:** Managed relational database
**Why we need it:** Persistent data storage, demonstrates database connectivity

**Configuration:**
- PostgreSQL 15
- db.t3.micro (Free tier eligible during testing)
- Private subnets only (not internet accessible)
- Automated backups enabled (7-day retention)
- Multi-AZ for production (optional for learning)
- Encrypted at rest

**Database Schema:**
```sql
users table:
  - id (primary key)
  - name
  - email
  - created_at

orders table:
  - id (primary key)
  - user_id (foreign key)
  - product
  - amount
  - created_at
```

**Senior Insight:** Never expose databases to the internet. Always use security groups to restrict access to only authorized sources (EKS nodes, Lambda).

---

### 5. **Lambda Function**
**What it is:** Serverless compute function
**Why we need it:** Shows you understand serverless + VPC + database connectivity

**Purpose:**
- Runs inside VPC (to access RDS)
- Retrieves DB credentials from Secrets Manager
- Queries database for analytics
- Returns results
- Logs everything to CloudWatch

**Trigger Options:**
- EventBridge scheduled rule (runs every hour)
- API Gateway (HTTP endpoint)
- Manual invocation

**Senior Insight:** Lambda in VPC needs VPC endpoints or NAT Gateway to access AWS services. Cold starts are slower with VPC. This is a common interview question.

---

### 6. **Secrets Manager**
**What it is:** Secure storage for sensitive data
**Why we need it:** Never hardcode credentials. Period.

**What we store:**
- RDS database username/password
- API keys (if needed)
- Third-party service credentials

**How it's used:**
- EKS pods read secrets via IAM roles (IRSA - IAM Roles for Service Accounts)
- Lambda retrieves secrets at runtime
- Terraform stores initial secret, apps retrieve it
- Automatic rotation (advanced feature we can add later)

**Senior Insight:** Using Secrets Manager + IAM roles means no credentials in code or environment variables. This is production-grade security.

---

### 7. **Argo CD (GitOps)**
**What it is:** Kubernetes continuous delivery tool
**Why we need it:** Git as the single source of truth for deployments

**How it works:**
1. You commit K8s manifests to Git
2. Argo CD watches the repository
3. When changes detected, Argo CD syncs to cluster
4. Automatic drift detection (if someone manually changes cluster, Argo CD flags it)

**Workflows:**
- **Auto-sync**: Argo automatically applies Git changes to cluster
- **Manual sync**: You approve changes before deployment
- **Rollback**: Revert Git commit, Argo CD auto-deploys previous version

**Senior Insight:** GitOps means auditable deployments. Every change has a Git commit. You can see who changed what and when. This is critical for compliance.

---

### 8. **Blue/Green Deployment**
**What it is:** Zero-downtime deployment strategy
**Why we need it:** Deploy safely without impacting users

**How it works:**
1. **Blue** = current production environment (receiving live traffic)
2. **Green** = new version being deployed/tested
3. Deploy green environment
4. Run smoke tests and load tests against green
5. If tests pass, switch ingress to route traffic to green
6. Monitor for issues
7. If issues found, switch back to blue instantly
8. If stable, decommission blue (or keep as rollback option)

**Kubernetes Implementation:**
- Two separate Deployments: `app-blue`, `app-green`
- One Service with selector that points to active color
- Ingress routes traffic based on Service
- Switch by updating Service selector

**Senior Insight:** Blue/green is instant rollback. Canary is gradual rollout. Both are production strategies. We'll implement blue/green first, can add canary later.

---

### 9. **Observability Stack**

#### **Prometheus**
**What it is:** Time-series metrics database
**Why we need it:** Collect, store, and query metrics

**What we monitor:**
- Request rate (requests per second)
- Error rate (% of 5xx responses)
- Latency (p50, p95, p99 response times)
- CPU/memory usage per pod
- Database connection pool metrics
- Pod restart count

**Installation:** Via Helm chart (kube-prometheus-stack)

#### **Grafana**
**What it is:** Visualization and dashboards
**Why we need it:** See metrics in beautiful, actionable dashboards

**Dashboards we'll create:**
- Application performance (RED metrics: Rate, Errors, Duration)
- Kubernetes cluster health
- Node resource utilization
- Database performance
- Deployment success rate
- Blue/Green traffic distribution

#### **CloudWatch Logs**
**What it is:** AWS native logging service
**Why we need it:** Centralized log aggregation

**What we log:**
- Application logs (structured JSON)
- Lambda function logs
- EKS control plane logs
- LoadBalancer access logs

**Senior Insight:** The "golden signals" are latency, traffic, errors, and saturation. Monitor these and you catch 90% of issues.

---

### 10. **CI/CD Pipeline (GitHub Actions)**

**Pipeline Flow:**
```
Developer pushes code
    ↓
GitHub Actions triggered
    ↓
Run linting & tests
    ↓
Security scan (Trivy/Snyk)
    ↓
Build Docker image
    ↓
Tag with commit SHA
    ↓
Push to Amazon ECR
    ↓
Update K8s manifest in Git (image tag)
    ↓
Commit manifest change
    ↓
Argo CD detects change
    ↓
Argo CD deploys to green environment
    ↓
Run smoke tests
    ↓
Run load tests (Siege)
    ↓
If pass → Switch traffic to green
    ↓
Monitor metrics
    ↓
If stable → Complete
If issues → Rollback to blue
```

**Senior Insight:** Separation of concerns. CI builds and tests, CD deploys. Argo CD owns deployment, GitHub Actions owns build. This is modern DevOps.

---

## 🔐 Security Components

### 1. **IAM Roles and Policies**
- **EKS Node Role**: Permissions for nodes to join cluster, pull images from ECR
- **EKS Pod Roles (IRSA)**: Individual permissions per pod (principle of least privilege)
- **Lambda Execution Role**: Access to Secrets Manager, RDS, CloudWatch
- **Terraform State Role**: Permissions to create infrastructure

### 2. **Security Groups (Firewalls)**
```
ALB Security Group:
  Inbound: Port 80/443 from 0.0.0.0/0 (internet)
  Outbound: To EKS nodes

EKS Nodes Security Group:
  Inbound: From ALB, from other EKS nodes
  Outbound: To RDS, to internet (via NAT)

RDS Security Group:
  Inbound: Port 5432 only from EKS nodes and Lambda
  Outbound: None needed

Lambda Security Group:
  Inbound: None
  Outbound: To RDS, to Secrets Manager (via VPC endpoint)
```

### 3. **RBAC (Role-Based Access Control)**
Kubernetes-level permissions:
- Service Accounts for pods
- Roles/ClusterRoles defining permissions
- RoleBindings connecting accounts to roles

**Example:**
- `app-service-account`: Can read ConfigMaps and Secrets in `production` namespace
- `argocd-service-account`: Can create/update/delete all resources

### 4. **Network Policies**
Kubernetes network segmentation:
- Pods in `production` namespace can only talk to RDS and internet
- Pods in `monitoring` namespace can scrape metrics from all namespaces
- Deny all other traffic by default

### 5. **Security Scanning**
- **Trivy**: Scans Docker images for CVEs before deployment
- **Snyk**: Scans source code for vulnerabilities
- Fail pipeline if critical vulnerabilities found

---

## 💰 Cost Tracking & Optimization

### **Tagging Strategy**
All resources tagged with:
```
Environment: production
Project: sre-lab
ManagedBy: terraform
CostCenter: engineering
Owner: your-name
```

### **Cost Awareness**
- Use AWS Cost Explorer to track spending by tag
- Set up billing alerts (e.g., alert if monthly spend > $50)
- Right-sizing: Start with t3.small nodes, scale up only if needed
- Spot instances for non-production workloads (optional advanced topic)

### **Estimated Monthly Cost (Minimal Configuration)**
- EKS Cluster Control Plane: ~$73
- EC2 Nodes (2x t3.medium): ~$60
- RDS db.t3.micro: ~$15 (or free tier)
- NAT Gateway: ~$32
- Load Balancer: ~$16
- Data Transfer: ~$5-10
- **Total: ~$200/month** (can be reduced with free tier and optimization)

**Senior Insight:** Senior engineers are cost-conscious. Always consider cost vs. benefit.

---

## 🌍 Multi-Region Considerations

**Why Multi-Region?**
- Disaster recovery
- Global low-latency access
- Regulatory compliance (data residency)

**What We'd Need for Multi-Region:**
1. **Active-Passive:**
   - Primary region serves traffic
   - Secondary region has standby infrastructure
   - Failover via Route53 health checks
   - RDS cross-region read replicas

2. **Active-Active (Advanced):**
   - Both regions serve traffic
   - Route53 geo-routing
   - Bidirectional database replication
   - Consistent state management (complex!)

**For This Project:**
- We'll design for single region (us-east-1 or your preferred)
- Document multi-region architecture in ADR
- Show you understand the concepts (interview gold)

---

## 📊 SLIs, SLOs, and SLAs

### **Service Level Indicators (SLIs)**
What we measure:
- API request success rate
- API latency (p95, p99)
- Pod availability
- Database query time

### **Service Level Objectives (SLOs)**
Our targets:
- 99.9% availability (43 min downtime/month)
- 95% of requests complete in < 200ms
- 99% of requests complete in < 500ms
- Error rate < 0.1%

### **Service Level Agreements (SLAs)**
What we promise customers (typically SLO - buffer):
- 99.5% availability
- If we miss, customer gets refund/credit

**Senior Insight:** SLOs drive architecture decisions. If you promise 99.9%, you need redundancy, monitoring, and fast incident response.

---

## 🚀 Deployment Workflow

### **Normal Deployment Flow**
1. Developer creates feature branch
2. Writes code + tests
3. Opens Pull Request
4. GitHub Actions runs tests + security scan
5. Code review + approval
6. Merge to `main`
7. GitHub Actions builds image, pushes to ECR
8. Updates K8s manifest with new image tag
9. Commits manifest to `gitops` repo
10. Argo CD detects change
11. Deploys to green environment
12. Health checks pass
13. Load tests run (Siege)
14. Metrics look good
15. Switch traffic to green
16. Monitor for 30 minutes
17. If stable, mark deployment complete
18. Old blue environment kept for 24h as rollback

### **Rollback Flow**
1. Incident detected (alerts firing)
2. Grep Git history for last working commit
3. Revert manifest to previous image tag
4. Commit revert
5. Argo CD automatically deploys old version
6. Traffic restored
7. Post-incident review

**Time to rollback: < 2 minutes**

---

## 🔥 Failure Scenarios We'll Simulate

To practice troubleshooting, we'll intentionally break things:

### **Application Failures**
- Wrong environment variable
- Database connection failure
- Memory leak simulation
- Crash loop (bad code)

### **Deployment Failures**
- Wrong image tag
- Failed readiness probe (app not ready)
- Failed liveness probe (app crashed)
- Missing ConfigMap/Secret

### **Networking Failures**
- Service selector mismatch (pods not receiving traffic)
- Wrong target port
- Security group misconfiguration
- DNS resolution issues

### **Database Failures**
- Wrong credentials
- Database unreachable
- Connection pool exhausted
- Simulate with RDS reboot

### **Infrastructure Failures**
- Node goes down
- NAT Gateway unavailable
- Cluster out of capacity

For each, we'll document:
- Symptoms
- Detection method
- Troubleshooting steps
- kubectl commands used
- Resolution
- Prevention strategy

---

## 📖 Documentation Structure

### **Architecture Decision Records (ADRs)**
Documents why we made specific choices:
- ADR-001: Why EKS over ECS?
- ADR-002: Why PostgreSQL over MySQL?
- ADR-003: Why Argo CD over Jenkins for CD?
- ADR-004: Why blue/green over canary?
- ADR-005: Why Prometheus over CloudWatch alone?

### **Runbooks**
Step-by-step procedures:
- How to deploy the application
- How to roll back a deployment
- How to scale the cluster
- How to rotate database credentials
- How to restore from backup

### **Incident Postmortems**
After each simulated failure:
- What happened
- Timeline
- Root cause
- Resolution
- Action items
- What we learned

### **Onboarding Guide**
How a new engineer would:
- Set up their local environment
- Understand the architecture
- Deploy a change
- Access monitoring
- Troubleshoot issues

---

## 🎯 Success Criteria

You'll know this project is successful when you can:

✅ Explain the architecture to a technical interviewer without notes
✅ Deploy a change end-to-end via GitOps
✅ Troubleshoot a failing pod deployment using kubectl
✅ Roll back a bad deployment in under 2 minutes
✅ Read Grafana dashboards and identify issues
✅ Explain IAM roles, security groups, and network policies
✅ Answer "how does your app connect to the database?" confidently
✅ Discuss cost optimization strategies
✅ Describe a realistic incident and how you'd respond

---

## 🛠️ Tools & Technologies You'll Master

- **AWS**: VPC, EKS, RDS, Lambda, Secrets Manager, IAM, CloudWatch, ALB
- **Kubernetes**: Deployments, Services, Ingress, ConfigMaps, Secrets, RBAC, Network Policies, HPA
- **Terraform**: Infrastructure as Code, modules, state management
- **Docker**: Building images, ECR
- **Argo CD**: GitOps, sync strategies
- **Prometheus/Grafana**: Metrics, queries (PromQL), dashboards, alerts
- **kubectl**: The command-line tool you'll use constantly
- **GitHub Actions**: CI/CD pipelines, secrets, workflows
- **Load Testing**: Siege, analyzing results
- **Security**: Trivy/Snyk scanning, RBAC, IAM

---

## 📅 Estimated Timeline

**Total: 6-8 weeks (working part-time)**

- Week 1: Phase 1 - Terraform infrastructure
- Week 2: Phase 2 - Application development
- Week 3: Phase 3 - EKS deployment
- Week 4: Phase 4 - Argo CD + GitOps
- Week 5: Phase 5 - Observability
- Week 6: Phase 6 - CI/CD pipeline
- Week 7: Phase 7 - Load testing + Blue/Green
- Week 8: Phase 8 - Failure scenarios + Lambda

**Then:** Polish documentation, create diagrams, prepare for interviews

---

## 💡 Interview Talking Points

After completing this, you can say:

> "I built a production-grade AWS platform using EKS, Terraform, and GitOps with Argo CD. The architecture includes an auto-scaling Node.js API behind an ALB, RDS PostgreSQL in private subnets, Lambda functions with VPC integration, and full observability with Prometheus and Grafana. I implemented blue/green deployments with automated load testing and rollback capabilities. The entire infrastructure is defined as code, tagged for cost tracking, secured with RBAC and network policies, and monitored with SLOs. I simulated and documented multiple failure scenarios, practicing incident response and troubleshooting with kubectl. The project demonstrates end-to-end understanding of production cloud platforms."

**That's a senior-level answer.**

---

## Next Steps

Ready to start building? We'll begin with:
**Phase 1: Setting Up Terraform and AWS Foundation**

Let me know when you're ready to proceed! 🚀
