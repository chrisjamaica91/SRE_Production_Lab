# kubectl Troubleshooting Cheat Sheet for SRE

This is your go-to reference for troubleshooting Kubernetes issues. **Master these commands.**

---

## 🔧 Basic Commands You'll Use Every Day

### Get Resource Status

```bash
# See everything in a namespace
kubectl get all -n production

# See specific resources
kubectl get pods -n production
kubectl get deployments -n production
kubectl get services -n production
kubectl get ingress -n production

# Wide output shows more info (like node, IP)
kubectl get pods -n production -o wide

# Watch for changes in real-time
kubectl get pods -n production -w
kubectl get pods -n production --watch

# Sort by a field
kubectl get pods --sort-by=.status.startTime
kubectl get events --sort-by=.lastTimestamp
```

---

## 🔍 The Two Most Important Troubleshooting Commands

### 1. DESCRIBE (Your First Tool)

```bash
# Describe a pod (SHOWS EVENTS - critical!)
kubectl describe pod <pod-name> -n production

# Describe deployment
kubectl describe deployment app -n production

# Describe service
kubectl describe service app -n production

# Describe ingress
kubectl describe ingress app -n production

# Describe node
kubectl describe node <node-name>
```

**What to look for in describe output:**

- **Events section**: Shows what happened (pulls, errors, failed health checks)
- **Conditions**: Ready, ContainersReady, PodScheduled status
- **State/Status**: Running, Pending, CrashLoopBackOff, etc.
- **Last State**: If pod crashed, shows exit code and reason

### 2. LOGS (See What the App Says)

```bash
# Get logs from a pod
kubectl logs <pod-name> -n production

# Follow logs (live stream)
kubectl logs -f <pod-name> -n production

# Get previous logs (if pod crashed and restarted)
kubectl logs --previous <pod-name> -n production

# Logs from specific container (if pod has multiple containers)
kubectl logs <pod-name> -c <container-name> -n production

# Last 100 lines
kubectl logs --tail=100 <pod-name> -n production

# Logs from last 1 hour
kubectl logs --since=1h <pod-name> -n production

# All pods with label
kubectl logs -l app=myapp -n production
```

---

## 🚨 Diagnosing Common Issues

### Issue: Pod Stuck in "Pending"

**Symptoms:**

```bash
$ kubectl get pods -n production
NAME                   READY   STATUS    RESTARTS   AGE
app-7d8f9b5c-xh2k9     0/1     Pending   0          2m
```

**Troubleshooting:**

```bash
# Always start with describe
kubectl describe pod app-7d8f9b5c-xh2k9 -n production

# Look for events like:
# - "0/3 nodes available: insufficient memory"
# - "FailedScheduling"
# - "Unschedulable"

# Check node capacity
kubectl get nodes
kubectl describe nodes

# Check resource requests
kubectl get pod app-7d8f9b5c-xh2k9 -n production -o yaml | grep -A 5 resources
```

**Common causes:**

- Insufficient CPU/memory on nodes
- Node selector doesn't match any nodes
- Taints/tolerations mismatch
- Persistent volume claim not bound

---

### Issue: Pod in "CrashLoopBackOff"

**Symptoms:**

```bash
$ kubectl get pods -n production
NAME                   READY   STATUS             RESTARTS   AGE
app-7d8f9b5c-xh2k9     0/1     CrashLoopBackOff   5          3m
```

**Troubleshooting:**

```bash
# Check current logs
kubectl logs app-7d8f9b5c-xh2k9 -n production

# Check previous logs (from before crash)
kubectl logs --previous app-7d8f9b5c-xh2k9 -n production

# Describe to see exit code
kubectl describe pod app-7d8f9b5c-xh2k9 -n production

# Look for:
# - Exit Code in Events
# - Last State: Terminated (reason: Error, exit code: 1)

# Check environment variables
kubectl get pod app-7d8f9b5c-xh2k9 -n production -o yaml | grep -A 10 env:
```

**Common causes:**

- Application error (check logs!)
- Missing environment variable
- Wrong command/args in container spec
- Failed health check causing restart
- Permission issues

---

### Issue: Pod in "ImagePullBackOff"

**Symptoms:**

```bash
$ kubectl get pods -n production
NAME                   READY   STATUS             RESTARTS   AGE
app-7d8f9b5c-xh2k9     0/1     ImagePullBackOff   0          1m
```

**Troubleshooting:**

```bash
# Describe the pod
kubectl describe pod app-7d8f9b5c-xh2k9 -n production

# Look for events:
# - "Failed to pull image"
# - "rpc error: code = Unknown desc = Error response from daemon"
# - Authentication errors

# Check what image is being used
kubectl get pod app-7d8f9b5c-xh2k9 -n production -o jsonpath='{.spec.containers[*].image}'

# Verify image exists in ECR
aws ecr describe-images --repository-name sre-app --region us-east-1
```

**Common causes:**

- Image tag doesn't exist
- ECR authentication failed (check IAM role)
- Wrong image name/URL
- Private registry without pull secret

---

### Issue: Pod Running but Not Ready

**Symptoms:**

```bash
$ kubectl get pods -n production
NAME                   READY   STATUS    RESTARTS   AGE
app-7d8f9b5c-xh2k9     0/1     Running   0          2m
```

**Troubleshooting:**

```bash
# Describe the pod (check readiness probe)
kubectl describe pod app-7d8f9b5c-xh2k9 -n production

# Look for:
# - "Readiness probe failed: HTTP probe failed"
# - "Readiness probe failed: Get http://...: dial tcp: connect: connection refused"

# Check logs for why app isn't ready
kubectl logs app-7d8f9b5c-xh2k9 -n production

# See readiness probe config
kubectl get pod app-7d8f9b5c-xh2k9 -n production -o yaml | grep -A 10 readinessProbe

# Test the endpoint manually
kubectl exec -it app-7d8f9b5c-xh2k9 -n production -- curl localhost:3000/ready
```

**Common causes:**

- Database not reachable
- Readiness endpoint taking too long to respond
- Application not fully initialized
- Wrong port in readiness probe

---

### Issue: Service Not Routing Traffic (No Endpoints)

**Symptoms:**

```bash
$ kubectl get endpoints -n production
NAME   ENDPOINTS   AGE
app    <none>      5m
```

**Troubleshooting:**

```bash
# Check service definition
kubectl describe service app -n production

# Check pod labels
kubectl get pods --show-labels -n production

# Check service selector
kubectl get service app -n production -o yaml | grep -A 5 selector

# Compare selectors to pod labels - THEY MUST MATCH!

# If selectors don't match, update service:
kubectl patch service app -n production -p '{"spec":{"selector":{"app":"myapp"}}}'
```

**Common causes:**

- Service selector doesn't match pod labels
- Pods not ready (failed readiness probe)
- Pods in different namespace
- Typo in label/selector

---

### Issue: Ingress Not Working

**Troubleshooting:**

```bash
# Check ingress status
kubectl get ingress -n production
kubectl describe ingress app -n production

# Check if ingress controller is running
kubectl get pods -n kube-system | grep ingress
kubectl get pods -n ingress-nginx

# Check ingress controller logs
kubectl logs -n ingress-nginx <ingress-controller-pod>

# Verify service is working first
kubectl get svc -n production
kubectl get endpoints -n production

# Test service directly (port forward)
kubectl port-forward svc/app 3000:3000 -n production
# Then test: curl http://localhost:3000

# Check load balancer
kubectl get ingress app -n production -o yaml
# Look for: status.loadBalancer.ingress
```

**Common causes:**

- Ingress controller not installed
- Wrong service name in ingress
- Wrong service port in ingress
- LoadBalancer still provisioning
- Security group blocking traffic

---

## 🔐 Debugging Techniques

### Exec Into a Pod

```bash
# Get a shell in the pod
kubectl exec -it <pod-name> -n production -- /bin/sh
kubectl exec -it <pod-name> -n production -- /bin/bash

# Run one-off commands
kubectl exec <pod-name> -n production -- env
kubectl exec <pod-name> -n production -- cat /etc/resolv.conf
kubectl exec <pod-name> -n production -- curl localhost:3000/health
kubectl exec <pod-name> -n production -- ps aux

# Test network connectivity
kubectl exec <pod-name> -n production -- ping 8.8.8.8
kubectl exec <pod-name> -n production -- nslookup kubernetes.default
kubectl exec <pod-name> -n production -- nc -zv database-service 5432
```

### Debug with a Temp Pod

```bash
# Create a debug pod in the same namespace
kubectl run debug --image=busybox -it --rm -n production -- sh

# Or use nicolaka/netshoot for network debugging
kubectl run debug --image=nicolaka/netshoot -it --rm -n production -- sh

# From debug pod, test service connectivity
> curl http://app-service:3000/health
> nslookup app-service
> ping app-service
```

---

## 📊 Resource and Performance Troubleshooting

### Check Resource Usage

```bash
# Node resource usage
kubectl top nodes

# Pod resource usage
kubectl top pods -n production

# Specific pod usage
kubectl top pod <pod-name> -n production

# If 'top' doesn't work, install metrics-server:
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### Check Resource Requests/Limits

```bash
# See requests and limits
kubectl describe pod <pod-name> -n production | grep -A 5 "Requests"
kubectl describe pod <pod-name> -n production | grep -A 5 "Limits"

# Full resource spec
kubectl get pod <pod-name> -n production -o yaml | grep -A 10 resources:
```

### OOMKilled (Out of Memory)

```bash
# Check for OOMKilled in events
kubectl describe pod <pod-name> -n production | grep -i oom

# Look for:
# - "Reason: OOMKilled"
# - "Exit Code: 137" (OOM signal)

# Check previous logs
kubectl logs --previous <pod-name> -n production

# Solution: Increase memory limit
```

---

## 🔄 Deployment Management

### Check Deployment Status

```bash
# Deployment overview
kubectl get deployment app -n production

# Detailed status
kubectl describe deployment app -n production

# Rollout status
kubectl rollout status deployment/app -n production

# Rollout history
kubectl rollout history deployment/app -n production

# See specific revision
kubectl rollout history deployment/app -n production --revision=2
```

### Rollback

```bash
# Undo last deployment
kubectl rollout undo deployment/app -n production

# Undo to specific revision
kubectl rollout undo deployment/app -n production --to-revision=2

# Pause a rollout
kubectl rollout pause deployment/app -n production

# Resume a rollout
kubectl rollout resume deployment/app -n production
```

### Manual Scaling

```bash
# Scale deployment
kubectl scale deployment app --replicas=5 -n production

# Check HPA status
kubectl get hpa -n production
kubectl describe hpa app -n production
```

---

## 📝 ConfigMaps and Secrets

### Check ConfigMaps

```bash
# List configmaps
kubectl get configmaps -n production

# View configmap
kubectl describe configmap app-config -n production
kubectl get configmap app-config -n production -o yaml
```

### Check Secrets

```bash
# List secrets
kubectl get secrets -n production

# View secret (base64 encoded)
kubectl get secret app-secrets -n production -o yaml

# Decode secret value
kubectl get secret app-secrets -n production -o jsonpath='{.data.DB_PASSWORD}' | base64 -d
```

---

## 🌐 Networking Troubleshooting

### Check Services and Endpoints

```bash
# Services
kubectl get svc -n production

# Endpoints (shows which pod IPs the service routes to)
kubectl get endpoints -n production

# Detailed service info
kubectl describe svc app -n production
```

### DNS Testing

```bash
# Test service DNS from a pod
kubectl exec -it <pod-name> -n production -- nslookup app-service

# Test external DNS
kubectl exec -it <pod-name> -n production -- nslookup google.com

# Check DNS config
kubectl exec -it <pod-name> -n production -- cat /etc/resolv.conf
```

### Port Forwarding (Test Locally)

```bash
# Forward pod port to local machine
kubectl port-forward <pod-name> 3000:3000 -n production

# Forward service port
kubectl port-forward svc/app 3000:3000 -n production

# Then test locally:
curl http://localhost:3000/health
```

---

## 📋 Events (Critical for Troubleshooting)

### View Events

```bash
# All events in namespace
kubectl get events -n production

# Sorted by time
kubectl get events -n production --sort-by='.lastTimestamp'

# Only warnings/errors
kubectl get events -n production --field-selector type=Warning

# Watch events live
kubectl get events -n production -w

# Events for specific pod (use describe instead)
kubectl describe pod <pod-name> -n production
```

---

## 🎯 Quick Diagnostic Checklist

When a pod is not working:

1. **See the status:**

   ```bash
   kubectl get pods -n production
   ```

2. **Describe it (ALWAYS DO THIS):**

   ```bash
   kubectl describe pod <pod-name> -n production
   ```

   - Look at Events section
   - Look at State/Status
   - Look at Conditions

3. **Check logs:**

   ```bash
   kubectl logs <pod-name> -n production
   kubectl logs --previous <pod-name> -n production  # If it restarted
   ```

4. **Check service and endpoints:**

   ```bash
   kubectl get svc -n production
   kubectl get endpoints -n production
   ```

5. **Test connectivity:**

   ```bash
   kubectl exec -it <pod-name> -n production -- curl localhost:3000/health
   ```

6. **Check resource usage:**
   ```bash
   kubectl top pod <pod-name> -n production
   ```

---

## 🚀 Advanced Output Formatting

### JSONPath (Extract Specific Fields)

```bash
# Get pod IP
kubectl get pod <pod-name> -n production -o jsonpath='{.status.podIP}'

# Get pod node
kubectl get pod <pod-name> -n production -o jsonpath='{.spec.nodeName}'

# Get container image
kubectl get pod <pod-name> -n production -o jsonpath='{.spec.containers[0].image}'

# Get all pod IPs
kubectl get pods -n production -o jsonpath='{.items[*].status.podIP}'
```

### YAML/JSON Output

```bash
# Full pod definition in YAML
kubectl get pod <pod-name> -n production -o yaml

# Full pod definition in JSON
kubectl get pod <pod-name> -n production -o json

# Custom columns
kubectl get pods -n production -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,IP:.status.podIP
```

---

## 💡 Pro Tips

### Aliases (Add to your shell profile)

```bash
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgpw='kubectl get pods --watch'
alias kdp='kubectl describe pod'
alias klf='kubectl logs -f'
alias kex='kubectl exec -it'
alias kgn='kubectl get nodes'
alias kga='kubectl get all'
```

### Context and Namespace

```bash
# Get current context
kubectl config current-context

# List all contexts
kubectl config get-contexts

# Switch context
kubectl config use-context my-cluster

# Set default namespace
kubectl config set-context --current --namespace=production

# Now you don't need -n production anymore!
```

---

## 🔥 Emergency Commands (Copy-Paste Ready)

```bash
# Quick overview of entire namespace
kubectl get all -n production

# Check if anything is broken
kubectl get pods -n production | grep -v "Running\|Completed"

# Follow logs from all app pods
kubectl logs -f -l app=myapp -n production

# Delete pod (forces restart)
kubectl delete pod <pod-name> -n production

# Force delete stuck pod
kubectl delete pod <pod-name> -n production --force --grace-period=0

# Restart deployment (rolling restart)
kubectl rollout restart deployment/app -n production

# Scale to zero and back (hard restart)
kubectl scale deployment app --replicas=0 -n production
kubectl scale deployment app --replicas=3 -n production
```

---

## 📚 Remember

**The Troubleshooting Trinity:**

1. `kubectl get` - See the overview
2. `kubectl describe` - See the events and details
3. `kubectl logs` - See what the app is saying

**Master these three, and you'll solve 90% of Kubernetes issues.**

---

## 🎓 Practice Scenarios

Try breaking these things and fixing them:

- [ ] Create a pod with wrong image name → Fix it
- [ ] Create a service with wrong selector → Fix service discovery
- [ ] Set memory limit too low → See OOMKilled → Fix it
- [ ] Break readiness probe → See pod not ready → Fix it
- [ ] Delete a secret → See pod fail → Recreate secret
- [ ] Scale deployment to 10 → Watch HPA respond
- [ ] Create network policy → Break connectivity → Fix it

**The more you break and fix, the better you'll get!**

---

Good luck! 🚀
