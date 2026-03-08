# 🗺️ Project Roadmap - Enterprise SRE Lab

This roadmap breaks down the entire project into actionable phases and tasks. Check off items as you complete them!

---

## ✅ Phase 0: Prerequisites & Setup

### Tasks:

- [ ] Install AWS CLI
- [ ] Install kubectl
- [ ] Install Terraform
- [ ] Install Docker Desktop
- [ ] Install Helm
- [ ] Configure AWS credentials (`aws configure`)
- [ ] Create AWS account (if needed)
- [ ] Install Visual Studio Code (or preferred editor)
- [ ] Install Git
- [ ] Create GitHub account and repository

### Learning Outcomes:

- Understand the toolchain for AWS/K8s development
- Know how to authenticate with AWS
- Comfortable with terminal/PowerShell

---

## 🏗️ Phase 1: Infrastructure Foundation (Week 1)

### Tasks:

- [ ] Understand Terraform basics
- [ ] Create Terraform project structure
- [ ] Build VPC module
  - [ ] Public subnets (2 AZs)
  - [ ] Private subnets (2 AZs)
  - [ ] Internet Gateway
  - [ ] NAT Gateway
  - [ ] Route Tables
  - [ ] Tag all resources
- [ ] Build EKS module
  - [ ] Cluster configuration
  - [ ] Node groups
  - [ ] IAM roles
  - [ ] Security groups
- [ ] Build RDS module
  - [ ] PostgreSQL configuration
  - [ ] Subnet group (private)
  - [ ] Security group
  - [ ] Backup configuration
- [ ] Create Secrets Manager secret for DB credentials
- [ ] Run `terraform plan`
- [ ] Run `terraform apply`
- [ ] Verify infrastructure in AWS Console

### Learning Outcomes:

- Understand AWS networking (VPC, subnets, routing)
- Understand Infrastructure as Code
- Know how to read Terraform state
- Understand EKS architecture
- Cost awareness for running infrastructure

### kubectl Commands to Learn:

```bash
# Configure kubectl to connect to EKS
aws eks update-kubeconfig --region us-east-1 --name my-cluster

# Verify connection
kubectl cluster-info
kubectl get nodes
kubectl get namespaces
```

### Troubleshooting Practice:

- What if `terraform apply` fails?
- How to read Terraform error messages?
- How to destroy and rebuild infrastructure?

---

## 🔧 Phase 2: Application Development (Week 2)

### Tasks:

- [ ] Set up Node.js project structure
- [ ] Create package.json with dependencies
- [ ] Build Express API with endpoints:
  - [ ] `/health` (liveness)
  - [ ] `/ready` (readiness - checks DB)
  - [ ] `/api/users` (reads from database)
  - [ ] `/api/orders` (reads from database)
  - [ ] `/metrics` (Prometheus format)
  - [ ] `/api/simulate-error` (returns 500)
  - [ ] `/api/simulate-latency?ms=1000`
- [ ] Implement database connection with PostgreSQL
- [ ] Implement structured logging (Winston)
- [ ] Add Prometheus metrics instrumentation
- [ ] Create Dockerfile (multi-stage build)
- [ ] Build Docker image locally
- [ ] Test locally with Docker Compose (app + postgres)
- [ ] Create ECR repository
- [ ] Push image to ECR
- [ ] Create database schema SQL script
- [ ] Seed database with test data

### Learning Outcomes:

- Understand containerization
- Know how Docker layers work
- Understand health vs. readiness checks
- Database connection patterns
- Why structured logging matters

### Commands to Learn:

```bash
# Build image
docker build -t sre-app:v1 .

# Run locally
docker run -p 3000:3000 sre-app:v1

# Test endpoints
curl http://localhost:3000/health
curl http://localhost:3000/ready

# Tag for ECR
docker tag sre-app:v1 <account-id>.dkr.ecr.us-east-1.amazonaws.com/sre-app:v1

# Push to ECR
docker push <account-id>.dkr.ecr.us-east-1.amazonaws.com/sre-app:v1
```

### Troubleshooting Practice:

- What if container won't start?
- How to debug with `docker logs`?
- What if app can't connect to database?

---

## ☸️ Phase 3: Kubernetes Deployment (Week 3)

### Tasks:

- [ ] Create `production` namespace
- [ ] Create Kubernetes manifests:
  - [ ] Deployment (with resources, probes)
  - [ ] Service (ClusterIP)
  - [ ] ConfigMap (non-sensitive config)
  - [ ] Secret (mount from AWS Secrets Manager later)
  - [ ] HorizontalPodAutoscaler
  - [ ] Ingress (ALB Ingress Controller)
- [ ] Install AWS Load Balancer Controller on EKS
- [ ] Deploy application to EKS
- [ ] Verify pods are running
- [ ] Verify service endpoints
- [ ] Access application via LoadBalancer URL
- [ ] Test health and readiness endpoints

### Learning Outcomes:

- Understand Kubernetes objects and relationships
- Pod lifecycle
- Service discovery
- Ingress vs. Service vs. Pod
- Resource requests and limits
- Liveness vs. readiness probes

### kubectl Commands to Master:

```bash
# Create namespace
kubectl create namespace production

# Apply manifests
kubectl apply -f k8s/base/

# Check everything
kubectl get all -n production
kubectl get deploy,svc,pods,ingress -n production

# Describe resources (CRITICAL for troubleshooting)
kubectl describe pod <pod-name> -n production
kubectl describe deployment app -n production
kubectl describe service app -n production

# View logs
kubectl logs <pod-name> -n production
kubectl logs -f <pod-name> -n production  # Follow logs

# Check events (golden for troubleshooting)
kubectl get events -n production --sort-by='.lastTimestamp'

# Check endpoints
kubectl get endpoints -n production

# Execute commands in pod
kubectl exec -it <pod-name> -n production -- /bin/sh

# Port forwarding for testing
kubectl port-forward svc/app 3000:3000 -n production

# Check pod details
kubectl get pod <pod-name> -n production -o wide
kubectl get pod <pod-name> -n production -o yaml

# Rollout commands
kubectl rollout status deployment/app -n production
kubectl rollout history deployment/app -n production
kubectl rollout undo deployment/app -n production
```

### Troubleshooting Practice:

- **Scenario 1:** Pod stuck in Pending
  - Check: `kubectl describe pod`
  - Look for: Insufficient CPU/memory, node selector issues
- **Scenario 2:** Pod CrashLoopBackOff
  - Check: `kubectl logs <pod-name>`
  - Look for: Application errors, missing env vars
- **Scenario 3:** Service has no endpoints
  - Check: `kubectl get endpoints`
  - Look for: Selector mismatch between service and deployment
- **Scenario 4:** Ingress not working
  - Check: `kubectl describe ingress`
  - Look for: Load balancer provisioning, security groups

---

## 🔄 Phase 4: GitOps with Argo CD (Week 4)

### Tasks:

- [ ] Install Argo CD on EKS cluster
- [ ] Access Argo CD UI (port-forward or ingress)
- [ ] Create separate Git repository for manifests (or use `/k8s` folder)
- [ ] Create Argo CD Application resource
- [ ] Configure auto-sync policy
- [ ] Deploy application via Argo CD
- [ ] Make a change to manifest
- [ ] Watch Argo CD auto-sync
- [ ] Practice manual sync
- [ ] Test rollback via Git revert

### Learning Outcomes:

- GitOps principles
- Declarative vs. imperative
- Git as source of truth
- Drift detection
- Audit trail for changes

### Commands to Learn:

```bash
# Install Argo CD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port forward to UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# CLI commands
argocd login localhost:8080
argocd app list
argocd app get <app-name>
argocd app sync <app-name>
```

### Troubleshooting Practice:

- Out-of-sync detection
- Failed sync resolution
- Health status interpretation

---

## 📊 Phase 5: Observability (Week 5)

### Tasks:

- [ ] Install kube-prometheus-stack via Helm
- [ ] Access Grafana UI
- [ ] Access Prometheus UI
- [ ] Verify ServiceMonitor is scraping app metrics
- [ ] Create custom Grafana dashboard:
  - [ ] Request rate
  - [ ] Error rate
  - [ ] Latency (p50, p95, p99)
  - [ ] Pod CPU/Memory
  - [ ] Pod restart count
- [ ] Create alerts in Alertmanager
- [ ] Configure CloudWatch logging for EKS
- [ ] View application logs in CloudWatch
- [ ] Test log queries
- [ ] Generate traffic and watch metrics
- [ ] Trigger an error and watch error rate spike

### Learning Outcomes:

- Metrics vs. logs vs. traces
- Prometheus query language (PromQL)
- The four golden signals
- Alert design
- Dashboard design

### PromQL Queries to Learn:

```promql
# Request rate
rate(http_requests_total[5m])

# Error rate
sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))

# Latency (95th percentile)
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# CPU usage
container_cpu_usage_seconds_total

# Pod restarts
kube_pod_container_status_restarts_total
```

### kubectl Commands:

```bash
# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090

# Check Grafana
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80

# Get Grafana admin password
kubectl get secret -n monitoring kube-prometheus-stack-grafana -o jsonpath="{.data.admin-password}" | base64 -d
```

---

## 🚀 Phase 6: CI/CD Pipeline (Week 6)

### Tasks:

- [ ] Create GitHub Actions workflow
- [ ] Add lint/test steps
- [ ] Add security scanning (Trivy)
- [ ] Add Docker build step
- [ ] Push image to ECR with tag (commit SHA)
- [ ] Update K8s manifest with new image tag
- [ ] Commit manifest change to trigger Argo CD
- [ ] Test full pipeline end-to-end
- [ ] Add status badges to README

### Learning Outcomes:

- CI vs. CD separation
- Build once, deploy many
- Immutable artifacts (Docker images)
- Pipeline as code
- Security in pipelines

### GitHub Actions Structure:

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main]
  pull_request:

jobs:
  test:
    - lint
    - unit tests

  security:
    - Trivy scan

  build:
    - Docker build
    - Push to ECR

  deploy:
    - Update manifest
    - Git commit
    - Argo CD syncs automatically
```

---

## 🔵🟢 Phase 7: Blue/Green Deployment & Load Testing (Week 7)

### Tasks:

- [ ] Create blue deployment manifest
- [ ] Create green deployment manifest
- [ ] Create service that can switch between blue/green
- [ ] Deploy application to blue
- [ ] Blue receives traffic
- [ ] Deploy new version to green
- [ ] Green is running but receives no traffic
- [ ] Install Siege for load testing
- [ ] Run load tests against blue (baseline)
- [ ] Run smoke tests against green
- [ ] Run load tests against green
- [ ] If tests pass, switch service to green
- [ ] Monitor metrics during switch
- [ ] Practice rollback (switch back to blue)

### Learning Outcomes:

- Zero-downtime deployment
- Traffic management
- Load testing methodology
- Performance baselines
- Rollback speed

### Commands to Learn:

```bash
# Siege load test
siege -c 50 -t 60s http://your-app-url/api/users

# Switch traffic (update service selector)
kubectl patch service app -n production -p '{"spec":{"selector":{"version":"green"}}}'

# Switch back
kubectl patch service app -n production -p '{"spec":{"selector":{"version":"blue"}}}'

# Watch pods during test
kubectl get pods -n production -w

# Monitor HPA scaling
kubectl get hpa -n production -w
```

### Load Test Metrics to Analyze:

- Throughput (transactions per second)
- Success rate
- Latency (average, p95, p99)
- Error rate
- Pod CPU/memory during load
- HPA scaling behavior

---

## 🧪 Phase 8: Failure Scenarios & Lambda (Week 8)

### Tasks:

#### Lambda Function:

- [ ] Create Lambda function code (Node.js)
- [ ] Configure to run in VPC
- [ ] Add IAM role with Secrets Manager permissions
- [ ] Connect to RDS
- [ ] Query database
- [ ] Deploy Lambda with Terraform
- [ ] Test Lambda invocation
- [ ] Check CloudWatch logs
- [ ] Troubleshoot any connection issues

#### Failure Simulations:

**1. Wrong Image Tag**

- [ ] Break: Deploy with non-existent image tag
- [ ] Observe: ImagePullBackOff error
- [ ] Troubleshoot: `kubectl describe pod`
- [ ] Fix: Correct image tag
- [ ] Document: Incident postmortem

**2. Failed Readiness Probe**

- [ ] Break: Make `/ready` endpoint return 500
- [ ] Observe: Pod running but not receiving traffic
- [ ] Troubleshoot: `kubectl describe pod`, check endpoints
- [ ] Fix: Restore endpoint
- [ ] Document: Why readiness probes matter

**3. Failed Liveness Probe**

- [ ] Break: Make `/health` endpoint crash
- [ ] Observe: Pod restarts continuously
- [ ] Troubleshoot: `kubectl logs`, watch restart count
- [ ] Fix: Restore endpoint
- [ ] Document: Liveness vs. readiness

**4. Service Selector Mismatch**

- [ ] Break: Change deployment labels without updating service
- [ ] Observe: Service has no endpoints
- [ ] Troubleshoot: `kubectl get endpoints`
- [ ] Fix: Match selectors
- [ ] Document: How services find pods

**5. Database Connection Failure**

- [ ] Break: Wrong DB_HOST environment variable
- [ ] Observe: Pods fail readiness, app errors
- [ ] Troubleshoot: `kubectl logs`, check env vars
- [ ] Fix: Correct configuration
- [ ] Document: ConfigMap vs. Secret

**6. Security Group Misconfiguration**

- [ ] Break: Remove RDS security group inbound rule
- [ ] Observe: Connection timeout
- [ ] Troubleshoot: Check RDS security groups
- [ ] Fix: Restore rule
- [ ] Document: Network troubleshooting

**7. Missing Secret**

- [ ] Break: Delete database credentials secret
- [ ] Observe: Pod can't start or crashes
- [ ] Troubleshoot: `kubectl describe pod`
- [ ] Fix: Recreate secret
- [ ] Document: Secret management

**8. Resource Limits Exceeded**

- [ ] Break: Set very low memory limit
- [ ] Observe: OOMKilled (Out of Memory)
- [ ] Troubleshoot: `kubectl describe pod`, check events
- [ ] Fix: Increase limit
- [ ] Document: Resource management

**9. Node Failure**

- [ ] Break: Manually stop a node or drain it
- [ ] Observe: Pods rescheduled
- [ ] Troubleshoot: Watch pod events
- [ ] Fix: Automatic (K8s handles it)
- [ ] Document: Self-healing

**10. Database Credentials Rotation**

- [ ] Break: Change RDS password without updating secret
- [ ] Observe: Auth errors
- [ ] Troubleshoot: CloudWatch logs, kubectl logs
- [ ] Fix: Update secret, restart pods
- [ ] Document: Secret rotation procedure

### Learning Outcomes:

- Systematic troubleshooting methodology
- Reading pod events and logs
- Understanding state vs. actual
- Common production issues
- Incident response process

---

## 📚 Phase 9: Documentation & Polish (Week 9)

### Tasks:

- [ ] Write comprehensive README.md
- [ ] Create architecture diagram (draw.io, Lucidchart)
- [ ] Write ADRs for key decisions
- [ ] Write runbooks:
  - [ ] Deployment procedure
  - [ ] Rollback procedure
  - [ ] Scaling procedure
  - [ ] Credential rotation
  - [ ] Disaster recovery
- [ ] Write incident postmortems for each failure scenario
- [ ] Create onboarding guide
- [ ] Define and document SLOs
- [ ] Add screenshots to documentation
- [ ] Clean up code and comments
- [ ] Remove any hardcoded values
- [ ] Add .gitignore
- [ ] Verify all secrets are in Secrets Manager
- [ ] Tag final release in Git
- [ ] Practice explaining project out loud

### Documentation Checklist:

- [ ] README with quick start
- [ ] Architecture diagram
- [ ] Component descriptions
- [ ] Setup instructions
- [ ] Troubleshooting guides
- [ ] Cost analysis
- [ ] Security considerations
- [ ] Multi-region discussion
- [ ] Lessons learned

---

## 🎯 Phase 10: Interview Preparation

### Tasks:

- [ ] Create mental map of architecture
- [ ] Practice explaining components without notes
- [ ] Prepare failure scenario stories
- [ ] Practice kubectl commands from memory
- [ ] Create presentation slides (optional)
- [ ] Record demo video (optional)
- [ ] List key takeaways
- [ ] Update resume with project details
- [ ] Update LinkedIn with skills
- [ ] Prepare for common questions:
  - "Walk me through your most complex project"
  - "How do you troubleshoot a failing pod?"
  - "How does your app connect to the database?"
  - "Tell me about a production incident"
  - "How do you monitor your applications?"
  - "What's your deployment strategy?"
  - "How do you handle secrets?"
  - "Explain your CI/CD pipeline"

### Interview Practice Scenarios:

- Draw architecture on whiteboard (or paper)
- Explain pod lifecycle
- Explain service discovery
- Explain how traffic flows from internet to pod
- Explain blue/green deployment
- Explain GitOps workflow
- Troubleshoot scenario presented by interviewer

---

## 🏆 Success Metrics

You're ready for senior SRE interviews when you can:

✅ **Explain**: The entire architecture without looking at notes
✅ **Deploy**: A change end-to-end using GitOps in under 10 minutes
✅ **Troubleshoot**: A failing pod using kubectl in under 5 minutes
✅ **Rollback**: A bad deployment in under 2 minutes
✅ **Interpret**: Grafana dashboards and identify issues
✅ **Describe**: A production incident with timeline, root cause, and resolution
✅ **Discuss**: Cost optimization strategies
✅ **Analyze**: Security concerns and mitigations
✅ **Design**: Multi-region architecture on a whiteboard

---

## 📈 Optional Advanced Extensions

If you want to go even deeper:

- [ ] Add Istio service mesh
- [ ] Implement canary deployments
- [ ] Add distributed tracing (Jaeger)
- [ ] Implement log aggregation (ELK or Loki)
- [ ] Add chaos engineering (Chaos Mesh)
- [ ] Implement external-secrets operator
- [ ] Add cert-manager for TLS
- [ ] Implement GitOps for infrastructure (Atlantis)
- [ ] Add Velero for backups
- [ ] Multi-cluster setup
- [ ] Cross-region replication
- [ ] Spot instance integration
- [ ] Custom metrics for HPA
- [ ] Implement SLI/SLO/SLA dashboard

---

## 🎓 Resources for Learning

### AWS:

- AWS Well-Architected Framework
- AWS EKS Best Practices Guide
- AWS Cost Optimization

### Kubernetes:

- Kubernetes Documentation
- "Kubernetes Up & Running" (book)
- CNCF landscape

### Monitoring:

- Prometheus documentation
- Grafana tutorials
- Google's SRE book (free online)

### Security:

- OWASP Top 10
- CIS Benchmarks
- AWS Security Best Practices

---

## Next Step

Once you've reviewed this roadmap, we'll start with:

**Phase 1: Setting up AWS prerequisites and beginning Terraform infrastructure**

Take your time to understand each phase. We'll work through one task at a time.

Ready to begin Phase 1? Let me know! 🚀
