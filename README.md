# 🚀 Enterprise-Level AWS SRE Platform Lab

A production-grade AWS infrastructure project demonstrating **Site Reliability Engineering (SRE)** best practices, built to prepare for senior-level cloud engineering roles.

---

## 📋 Project Overview

This project showcases a **real-world cloud platform** running on AWS with:

- **AWS EKS** - Managed Kubernetes cluster
- **Terraform** - Infrastructure as Code
- **Argo CD** - GitOps continuous delivery
- **Node.js API** - Containerized application with database integration
- **RDS PostgreSQL** - Managed database in private subnets
- **Lambda Functions** - Serverless computing with VPC integration
- **Prometheus + Grafana** - Full observability and monitoring
- **CloudWatch** - Centralized logging
- **Blue/Green Deployments** - Zero-downtime release strategy
- **Load Testing** - Performance validation with Siege
- **Security** - RBAC, Network Policies, Secrets Manager, Trivy scanning
- **CI/CD** - GitHub Actions pipeline with automated testing

**This is not a toy project.** It's designed to simulate real production infrastructure and demonstrate the skills needed for senior SRE interviews.

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

### Core Infrastructure

✅ "Walk me through your most complex project"  
✅ "How do you troubleshoot a failing Kubernetes pod?"  
✅ "Describe your CI/CD pipeline"  
✅ "How do you monitor applications in production?"  
✅ "Tell me about a production incident you handled"  
✅ "How do you manage secrets and credentials?"  
✅ "What's your deployment strategy?"  
✅ "How do you ensure zero-downtime deployments?"  
✅ "How does your application connect to the database?"  
✅ "How do you optimize cloud costs?"

### Advanced Security Topics

✅ "How to properly secure CI/CD pipelines?"  
✅ "How to properly secure containers?"  
✅ "How to implement security scanning without reducing dev time?"  
✅ "Explain Kubernetes RBAC architecture"  
✅ "What are Network Policies and how do they work?"  
✅ "Are Kubernetes Secrets encrypted? How to improve security?"

### CI/CD & DevOps

🔄 "How does OIDC authentication work in GitHub Actions?" (In Progress)  
⏸️ "Design a CI/CD pipeline for Java backend, JavaScript frontend, and Rust component"  
⏸️ "What types of security scans should be in a pipeline?"  
⏸️ "How to parallelize scans without slowing development?"  
⏸️ "Describe a bottleneck you identified and how you optimized it"

### Infrastructure as Code

⏸️ "How to version Terraform for dev/staging/prod environments?"  
⏸️ "How to prevent dev values from making their way to prod?"  
⏸️ "How to limit AWS console access for DevOps engineers?"  
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
