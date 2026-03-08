# Architecture Decision Record Template

Use this template when documenting important architectural decisions.

---

## ADR-XXX: [Title of Decision]

**Status:** [Proposed | Accepted | Deprecated | Superseded]

**Date:** YYYY-MM-DD

**Deciders:** [Your name or team]

**Context:** (1-2 paragraphs)

---

### Decision

[What is the change that we're proposing and/or doing?]

---

### Rationale

[Why are we making this decision? What problem does it solve?]

---

### Consequences

**Positive:**

- [What becomes easier or better?]
- [What problems does this solve?]

**Negative:**

- [What becomes harder?]
- [What trade-offs are we accepting?]

**Neutral:**

- [Other implications that aren't clearly positive or negative]

---

### Alternatives Considered

#### Alternative 1: [Name]

- Description: [What was considered?]
- Pros: [Benefits]
- Cons: [Drawbacks]
- Reason for rejection: [Why not chosen?]

#### Alternative 2: [Name]

- Description:
- Pros:
- Cons:
- Reason for rejection:

---

### Implementation Notes

[Any technical details about how to implement this decision]

---

### Related Decisions

- Links to other ADRs that relate to this one

---

## Example ADR

---

## ADR-001: Use EKS Instead of Self-Managed Kubernetes

**Status:** Accepted

**Date:** 2026-03-02

**Deciders:** Chris (SRE Lab Project)

---

### Decision

We will use Amazon EKS (Elastic Kubernetes Service) for our Kubernetes cluster rather than self-managing Kubernetes on EC2 instances.

---

### Rationale

As a learning project focused on SRE practices, we want to spend time on:

- Application deployment and troubleshooting
- Observability and monitoring
- CI/CD and GitOps
- Incident response

We do NOT want to spend time on:

- Kubernetes control plane upgrades
- etcd backups and management
- Control plane high availability
- Certificate management for K8s components

EKS allows us to focus on the SRE skills that matter most for landing a senior role, while AWS handles the undifferentiated heavy lifting.

---

### Consequences

**Positive:**

- Control plane managed by AWS (99.95% SLA)
- Automatic control plane upgrades available
- Integration with AWS services (IAM, ALB, EBS)
- Reduces operational complexity
- Industry-standard choice (most companies use managed K8s)
- More time to focus on application-layer concerns

**Negative:**

- Monthly cost (~$73 for control plane)
- Less visibility into control plane operations
- Slight vendor lock-in to AWS
- Won't learn control plane management deeply

**Neutral:**

- Worker nodes still require management
- Must still understand K8s architecture even if we don't operate control plane

---

### Alternatives Considered

#### Alternative 1: Self-Managed Kubernetes (kubeadm/kops)

- Description: Deploy K8s control plane and workers on EC2
- Pros:
  - Full control over all components
  - No EKS fee
  - Deep learning opportunity
- Cons:
  - Complex to maintain
  - Time-consuming
  - Single point of failure without HA setup
  - Distracts from SRE focus
- Reason for rejection: Too much operational overhead for a learning project focused on SRE, not K8s administration

#### Alternative 2: ECS (Elastic Container Service)

- Description: Use AWS's native container orchestration
- Pros:
  - Simpler than Kubernetes
  - Tightly integrated with AWS
  - No control plane cost
- Cons:
  - Not Kubernetes (most companies use K8s)
  - Won't learn kubectl skills
  - Less relevant for SRE interviews
  - Smaller ecosystem
- Reason for rejection: Kubernetes skills are more valuable in the job market and are what we need for senior SRE roles

#### Alternative 3: Local Kubernetes (kind/minikube)

- Description: Run K8s locally on laptop
- Pros:
  - Free
  - Easy to destroy and rebuild
  - Fast iteration
- Cons:
  - Not "real" AWS infrastructure
  - Can't demonstrate cloud networking skills
  - No cloud provider integrations
  - Doesn't feel production-like
- Reason for rejection: Need real cloud experience for interviews, not just K8s concepts

---

### Implementation Notes

- Use Terraform to provision EKS cluster
- Start with version 1.28 or later
- Use managed node groups (not self-managed or Fargate initially)
- Enable control plane logging to CloudWatch
- Deploy in 2 availability zones minimum
- Configure IRSA (IAM Roles for Service Accounts)

---

### Related Decisions

- ADR-002: Choice of AWS region (affects latency and cost)
- ADR-005: Why managed node groups over Fargate
