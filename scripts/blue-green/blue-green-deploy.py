#!/usr/bin/env python3
"""
Blue/Green Deployment Script for Kubernetes

This script orchestrates zero-downtime deployments by:
1. Validating the new version (green) is healthy
2. Switching traffic from old version (blue) to new version
3. Verifying the switch was successful
4. Rolling back automatically if any checks fail

Usage:
    python blue-green-deploy.py --config config.yaml

Author: Chris
Date: 2026-03-11
"""

import sys
import time
import argparse
from typing import Dict, List, Optional, Tuple
import yaml
import requests
from kubernetes import client, config as k8s_config
from kubernetes.client.rest import ApiException


# ANSI color codes for pretty output
class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    RESET = '\033[0m'
    BOLD = '\033[1m'


def print_success(message: str):
    """Print success message in green"""
    print(f"{Colors.GREEN}✅ {message}{Colors.RESET}")


def print_error(message: str):
    """Print error message in red"""
    print(f"{Colors.RED}❌ {message}{Colors.RESET}")


def print_warning(message: str):
    """Print warning message in yellow"""
    print(f"{Colors.YELLOW}⚠️  {message}{Colors.RESET}")


def print_info(message: str):
    """Print info message in blue"""
    print(f"{Colors.BLUE}ℹ️  {message}{Colors.RESET}")


def print_step(message: str):
    """Print step header"""
    print(f"\n{Colors.BOLD}{Colors.CYAN}{'='*60}{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.CYAN}{message}{Colors.RESET}")
    print(f"{Colors.BOLD}{Colors.CYAN}{'='*60}{Colors.RESET}")


def load_config(config_path: str) -> Dict:
    """
    Load configuration from YAML file
    
    Args:
        config_path: Path to config.yaml
        
    Returns:
        Dictionary with configuration
    """
    print_step("📄 Loading Configuration")
    
    try:
        with open(config_path, 'r') as f:
            config = yaml.safe_load(f)
        
        print_info(f"Config file: {config_path}")
        print_info(f"Namespace: {config.get('namespace', 'N/A')}")
        print_info(f"Current version: {config.get('current_version', 'N/A')}")
        print_info(f"Target version: {config.get('target_version', 'N/A')}")
        print_success("Configuration loaded successfully")
        
        return config
        
    except FileNotFoundError:
        print_error(f"Config file not found: {config_path}")
        sys.exit(1)
    except yaml.YAMLError as e:
        print_error(f"Invalid YAML in config file: {e}")
        sys.exit(1)


def init_kubernetes() -> Tuple[client.CoreV1Api, client.AppsV1Api]:
    """
    Initialize Kubernetes API clients
    
    Returns:
        Tuple of (CoreV1Api, AppsV1Api) clients
    """
    print_step("🔌 Connecting to Kubernetes")
    
    try:
        # Load kubeconfig (same file kubectl uses)
        k8s_config.load_kube_config()
        
        # Create API clients
        v1 = client.CoreV1Api()
        apps_v1 = client.AppsV1Api()
        
        # Verify connection by listing namespaces
        namespaces = v1.list_namespace(limit=1)
        
        # Get current context
        contexts, active_context = k8s_config.list_kube_config_contexts()
        print_info(f"Connected to context: {active_context['name']}")
        print_success("Kubernetes connection established")
        
        return v1, apps_v1
        
    except Exception as e:
        print_error(f"Failed to connect to Kubernetes: {e}")
        print_info("Make sure kubectl is configured and working")
        print_info("Test with: kubectl cluster-info")
        sys.exit(1)


def check_deployment_exists(
    apps_v1: client.AppsV1Api,
    namespace: str,
    deployment_name: str
) -> bool:
    """
    Check if a deployment exists in the namespace
    
    Args:
        apps_v1: Kubernetes Apps API client
        namespace: Namespace to check in
        deployment_name: Name of the deployment
        
    Returns:
        True if deployment exists, False otherwise
        
    Why this matters:
        If you try to switch traffic to a deployment that doesn't exist,
        the service will have NO endpoints and all traffic will fail.
        This is a critical safety check.
    """
    try:
        deployment = apps_v1.read_namespaced_deployment(
            name=deployment_name,
            namespace=namespace
        )
        print_info(f"Deployment '{deployment_name}' found")
        return True
        
    except ApiException as e:
        if e.status == 404:
            print_error(f"Deployment '{deployment_name}' not found in namespace '{namespace}'")
            return False
        else:
            # Some other error (permissions, network, etc.)
            print_error(f"Error checking deployment: {e}")
            raise

def check_pods_ready(
    v1: client.CoreV1Api,
    apps_v1: client.AppsV1Api,
    namespace: str,
    deployment_name: str
) -> bool:
    """
    Check if all pods in a deployment are ready
    
    Args:
        v1: Kubernetes Core API client
        apps_v1: Kubernetes Apps API client
        namespace: Namespace to check
        deployment_name: Name of the deployment
        
    Returns:
        True if all pods ready, False otherwise
        
    What we're checking:
        1. Desired replicas vs actual replicas
        2. Ready replicas vs total replicas
        3. Individual pod status
        4. Container restart counts
    """
    
    # Step 1: Get the deployment
    try:
        deployment = apps_v1.read_namespaced_deployment(
            name=deployment_name,
            namespace=namespace
        )
    except ApiException as e:
        print_error(f"Cannot read deployment: {e}")
        return False
    
    # Step 2: Check replica counts
    desired_replicas = deployment.spec.replicas
    ready_replicas = deployment.status.ready_replicas or 0
    available_replicas = deployment.status.available_replicas or 0
    
    print_info(f"Deployment: {deployment_name}")
    print_info(f"  Desired replicas:   {desired_replicas}")
    print_info(f"  Available replicas: {available_replicas}")
    print_info(f"  Ready replicas:     {ready_replicas}")
    
    # Check if all replicas are ready
    if ready_replicas < desired_replicas:
        print_error(f"Only {ready_replicas}/{desired_replicas} replicas are ready")
        return False
    
    # Step 3: Get pods for this deployment
    # We use label selectors to find pods belonging to this deployment
    labels = deployment.spec.selector.match_labels
    label_selector = ",".join([f"{k}={v}" for k, v in labels.items()])
    
    print_info(f"  Label selector: {label_selector}")
    
    try:
        pods = v1.list_namespaced_pod(
            namespace=namespace,
            label_selector=label_selector
        )
    except ApiException as e:
        print_error(f"Cannot list pods: {e}")
        return False
    
    if not pods.items:
        print_error(f"No pods found for deployment {deployment_name}")
        return False
    
    # Step 4: Check each pod
    print_info(f"  Found {len(pods.items)} pod(s)")
    
    all_healthy = True
    for pod in pods.items:
        pod_name = pod.metadata.name
        pod_phase = pod.status.phase
        
        # Check pod phase (should be "Running")
        if pod_phase != "Running":
            print_error(f"    ❌ Pod {pod_name} is in phase: {pod_phase}")
            all_healthy = False
            continue
        
        # Check container statuses
        if not pod.status.container_statuses:
            print_error(f"    ❌ Pod {pod_name} has no container status")
            all_healthy = False
            continue
        
        for container_status in pod.status.container_statuses:
            container_name = container_status.name
            is_ready = container_status.ready
            restart_count = container_status.restart_count
            
            if not is_ready:
                print_error(f"    ❌ Pod {pod_name} container '{container_name}' not ready")
                all_healthy = False
            elif restart_count > 0:
                print_warning(f"    ⚠️  Pod {pod_name} has {restart_count} restart(s)")
                # Restarts might be okay if pod is stable now, but worth noting
            else:
                print_success(f"    ✅ Pod {pod_name} healthy")
    
    return all_healthy

def run_preflight_checks(
    v1: client.CoreV1Api,
    apps_v1: client.AppsV1Api,
    config: Dict
) -> bool:
    """
    Run all pre-flight checks before switching traffic
    
    Args:
        v1: Kubernetes Core API client
        apps_v1: Kubernetes Apps API client
        config: Configuration dictionary
        
    Returns:
        True if all checks pass, False otherwise
        
    This is the orchestration function that runs all safety checks
    before we switch traffic to the new version.
    """
    print_step("🔍 Running Pre-Flight Checks")
    
    namespace = config['namespace']
    target_deployment = config['target_version']
    deployment_name = config[f'{target_deployment}_deployment']
    
    print_info(f"Target deployment: {deployment_name}")
    print_info(f"Namespace: {namespace}")
    print()
    
    # Check 1: Does deployment exist?
    print_info("Check 1: Deployment existence...")
    if not check_deployment_exists(apps_v1, namespace, deployment_name):
        print_error("Pre-flight check failed: Deployment does not exist")
        return False
    print_success("✓ Deployment exists")
    print()
    
    # Check 2: Are all pods ready?
    print_info("Check 2: Pod readiness...")
    if not check_pods_ready(v1, apps_v1, namespace, deployment_name):
        print_error("Pre-flight check failed: Not all pods are ready")
        return False
    print_success("✓ All pods ready")
    print()
    
    # All checks passed!
    print_success("🎉 All pre-flight checks passed!")
    print_info(f"Safe to switch traffic to {target_deployment}")
    
    return True

def switch_traffic(
    v1: client.CoreV1Api,
    namespace: str,
    service_name: str,
    from_version: str,
    to_version: str,
    dry_run: bool = False
) -> bool:
    """
    Switch service traffic from one version to another
    
    Args:
        v1: Kubernetes Core API client
        namespace: Namespace containing the service
        service_name: Name of the service to update
        from_version: Current version (e.g., 'blue')
        to_version: Target version (e.g., 'green')
        dry_run: If True, don't actually make changes
        
    Returns:
        True if switch succeeded, False otherwise
        
    How it works:
        Updates the service's selector to route traffic to target version.
        This is done via a strategic merge patch on the service object.
        
    Why this is safe:
        - Atomic operation (all or nothing)
        - Near-instant (metadata update only)
        - Existing connections can finish gracefully
        - New connections go to new version immediately
    """
    print_step(f"🔄 Switching Traffic: {from_version} → {to_version}")
    
    if dry_run:
        print_warning("DRY RUN: Would switch traffic but not making actual changes")
        print_info(f"Would update service '{service_name}' selector to version={to_version}")
        return True
    
    # Build the patch to update service selector
    # We only change the 'version' label in the selector
    # Other labels (like 'app') remain unchanged
    patch = {
        "spec": {
            "selector": {
                "version": to_version
            }
        }
    }
    
    print_info(f"Updating service '{service_name}' selector to version={to_version}")
    
    try:
        # Patch the service
        # This is a strategic merge patch - merges with existing config
        v1.patch_namespaced_service(
            name=service_name,
            namespace=namespace,
            body=patch
        )
        
        print_success(f"✓ Service selector updated to: version={to_version}")
        print_info(f"Traffic is now routing to {to_version} pods")
        return True
        
    except ApiException as e:
        print_error(f"Failed to update service: {e}")
        print_error(f"Status code: {e.status}")
        return False

def verify_endpoints(
    v1: client.CoreV1Api,
    namespace: str,
    service_name: str,
    expected_version: str,
    timeout: int = 30
) -> bool:
    """
    Verify that service endpoints point to the expected version
    
    Args:
        v1: Kubernetes Core API client
        namespace: Namespace containing the service
        service_name: Name of the service
        expected_version: Version we expect endpoints to point to
        timeout: Max seconds to wait for endpoints to update
        
    Returns:
        True if endpoints match expected version, False otherwise
        
    Why this matters:
        After updating the service selector, Kubernetes needs a moment
        to update the endpoint list. This function waits and verifies
        that the endpoints actually changed to the target pods.
        
    How Kubernetes updates endpoints:
        1. Service selector changes (instant)
        2. Endpoints controller notices the change
        3. Controller finds pods matching new selector
        4. Controller updates Endpoints object (1-5 seconds)
        5. kube-proxy updates iptables rules (1-5 seconds)
        
    This function verifies step 4 completed successfully.
    """
    print_step("🔍 Verifying Endpoint Updates")
    
    print_info(f"Waiting for endpoints to point to {expected_version} pods...")
    print_info(f"Timeout: {timeout}s")
    
    start_time = time.time()
    
    while True:
        elapsed = time.time() - start_time
        
        # Check if we've exceeded timeout
        if elapsed > timeout:
            print_error(f"❌ Timeout after {timeout}s waiting for endpoints to update")
            print_warning("Endpoints may still be propagating, but exceeded wait time")
            return False
        
        try:
            # Get the endpoints for this service
            endpoints = v1.read_namespaced_endpoints(
                name=service_name,
                namespace=namespace
            )
            
            # Check if we have any endpoints at all
            if not endpoints.subsets:
                print_warning(f"No endpoint subsets found yet (elapsed: {elapsed:.1f}s)")
                time.sleep(2)
                continue
            
            # Check each endpoint address
            all_correct = True
            endpoint_count = 0
            wrong_version_pods = []
            
            for subset in endpoints.subsets:
                if not subset.addresses:
                    continue
                    
                for address in subset.addresses:
                    endpoint_count += 1
                    
                    # Get the pod this endpoint points to
                    if not address.target_ref:
                        print_warning(f"Endpoint {address.ip} has no target reference")
                        all_correct = False
                        continue
                    
                    pod_name = address.target_ref.name
                    
                    # Get the pod to check its labels
                    try:
                        pod = v1.read_namespaced_pod(
                            name=pod_name,
                            namespace=namespace
                        )
                        
                        pod_version = pod.metadata.labels.get('version', 'unknown')
                        
                        if pod_version == expected_version:
                            print_success(f"  ✅ Endpoint {pod_name} is {expected_version}")
                        else:
                            print_error(f"  ❌ Endpoint {pod_name} is {pod_version}, expected {expected_version}")
                            all_correct = False
                            wrong_version_pods.append(pod_name)
                            
                    except ApiException as e:
                        print_error(f"Cannot read pod {pod_name}: {e}")
                        all_correct = False
            
            # Check if we found any endpoints at all
            if endpoint_count == 0:
                print_warning(f"No endpoint addresses found yet (elapsed: {elapsed:.1f}s)")
                time.sleep(2)
                continue
            
            # If all endpoints are correct, we're done!
            if all_correct:
                print_success(f"✓ All {endpoint_count} endpoint(s) verified")
                print_info(f"Verification completed in {elapsed:.1f}s")
                return True
            
            # Otherwise wait and try again
            print_warning(f"Endpoints not fully updated yet, retrying... (elapsed: {elapsed:.1f}s)")
            if wrong_version_pods:
                print_warning(f"  Pods with wrong version: {', '.join(wrong_version_pods)}")
            time.sleep(2)
            
        except ApiException as e:
            if e.status == 404:
                print_warning(f"Service endpoints not found yet (elapsed: {elapsed:.1f}s)")
                time.sleep(2)
                continue
            else:
                print_error(f"Error checking endpoints: {e}")
                return False

def run_smoke_tests(
    v1: client.CoreV1Api,
    namespace: str,
    service_name: str,
    config: Dict
) -> bool:
    """
    Run smoke tests against the newly active version
    
    Args:
        v1: Kubernetes Core API client
        namespace: Namespace
        service_name: Service name
        config: Configuration dict with smoke test definitions
        
    Returns:
        True if all smoke tests pass, False otherwise
        
    What are smoke tests?
        Quick, basic checks that the new version is responding correctly.
        These run AFTER traffic has switched to validate the deployment.
        
    Why called "smoke tests"?
        Origin: Hardware testing - "turn it on and see if smoke comes out"
        In software: "Does it basically work? Or is it on fire?"
        
    Not the same as:
        - Unit tests (test individual functions)
        - Integration tests (test component interactions)
        - Load tests (test performance under load)
        
    Smoke tests answer: "Is the app alive and responding?"
    """
    print_step("🧪 Running Smoke Tests")
    
    # Get smoke test configurations
    smoke_tests = config.get('smoke_tests', [])
    
    if not smoke_tests:
        print_warning("No smoke tests configured in config.yaml")
        print_info("Skipping smoke tests (not recommended for production)")
        return True
    
    # Wait a moment for traffic to settle
    delay = config.get('timeouts', {}).get('smoke_test_delay', 2)
    if delay > 0:
        print_info(f"Waiting {delay}s for traffic to settle...")
        time.sleep(delay)
    
    # Get service details for testing
    try:
        service = v1.read_namespaced_service(
            name=service_name,
            namespace=namespace
        )
        
        cluster_ip = service.spec.cluster_ip
        service_port = service.spec.ports[0].port
        
        print_info(f"Testing service at {cluster_ip}:{service_port}")
        
    except ApiException as e:
        print_error(f"Cannot read service: {e}")
        return False
    
    # Run each smoke test
    print_info(f"Running {len(smoke_tests)} smoke test(s)...")
    print()
    
    all_passed = True
    passed_count = 0
    failed_count = 0
    
    for i, test in enumerate(smoke_tests, 1):
        path = test.get('path', '/')
        expected_status = test.get('expected_status', 200)
        timeout_test = test.get('timeout', 5)
        
        url = f"https://{cluster_ip}:{service_port}{path}"
        
        print_info(f"Test {i}/{len(smoke_tests)}: GET {path}")
        print_info(f"  URL: {url}")
        print_info(f"  Expected status: {expected_status}")
        
        try:
            response = requests.get(url, timeout=timeout_test)
            
            # Check status code
            if response.status_code == expected_status:
                print_success(f"  ✅ Response: {response.status_code} (expected {expected_status})")
                
                # Show first 100 chars of response for debugging
                response_preview = response.text[:100].replace('\n', ' ')
                if response_preview:
                    print_info(f"  Preview: {response_preview}...")
                
                passed_count += 1
            else:
                print_error(f"  ❌ Response: {response.status_code} (expected {expected_status})")
                print_error(f"  Response body: {response.text[:200]}")
                all_passed = False
                failed_count += 1
                
        except requests.exceptions.Timeout:
            print_error(f"  ❌ Request timed out after {timeout_test}s")
            print_error(f"  This usually means:")
            print_error(f"    - App is slow to respond")
            print_error(f"    - App is stuck/deadlocked")
            print_error(f"    - Network connectivity issue")
            all_passed = False
            failed_count += 1
            
        except requests.exceptions.ConnectionError as e:
            print_error(f"  ❌ Connection failed: {e}")
            print_error(f"  This usually means:")
            print_error(f"    - No pods are running")
            print_error(f"    - Service endpoints are empty")
            print_error(f"    - Network policy blocking traffic")
            all_passed = False
            failed_count += 1
            
        except requests.exceptions.RequestException as e:
            print_error(f"  ❌ Request failed: {e}")
            all_passed = False
            failed_count += 1
        
        print()  # Blank line between tests
    
    # Summary
    print_step("📊 Smoke Test Results")
    print_info(f"Total tests: {len(smoke_tests)}")
    print_success(f"Passed: {passed_count}")
    if failed_count > 0:
        print_error(f"Failed: {failed_count}")
    
    if all_passed:
        print_success("✅ All smoke tests passed!")
        print_info("New version is responding correctly")
    else:
        print_error("❌ Some smoke tests failed")
        print_warning("New version may not be functioning correctly")
    
    return all_passed

def main():
    """
    Main orchestration function
    
    Workflow:
        1. Load configuration
        2. Connect to Kubernetes
        3. Run pre-flight checks (deployment exists, pods ready)
        4. Switch traffic to target version
        5. Verify endpoints updated correctly
        6. Run smoke tests
        7. If any step fails → automatic rollback
        8. Report success/failure
        
    Exit codes:
        0 = Success
        1 = Failure (pre-flight, deployment, or tests failed)
    """
    parser = argparse.ArgumentParser(
        description='Blue/Green Deployment for Kubernetes',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
    Examples:
    python blue-green-deploy.py --config config.yaml
    python blue-green-deploy.py --config config.yaml --dry-run
            """
    )
    parser.add_argument(
        '--config',
        default='config.yaml',
        help='Path to configuration file (default: config.yaml)'
    )
    parser.add_argument(
        '--dry-run',
        action='store_true',
        help='Show what would happen without making changes'
    )
    parser.add_argument(
        '--skip-smoke-tests',
        action='store_true',
        help='Skip smoke tests (useful for local Docker Desktop where ClusterIP is not reachable)'
    )
    
    args = parser.parse_args()
    
    # Print banner
    print(f"\n{Colors.BOLD}{Colors.CYAN}")
    print("╔════════════════════════════════════════════════════════════╗")
    print("║         Blue/Green Deployment Orchestrator                 ║")
    print("║         Zero-Downtime Kubernetes Deployment                ║")
    print("╚════════════════════════════════════════════════════════════╝")
    print(f"{Colors.RESET}\n")
    
    if args.dry_run:
        print_warning("DRY RUN MODE - No changes will be made")
    
    if args.skip_smoke_tests:
        print_warning("SMOKE TESTS DISABLED - Endpoint verification only")
    
    # Step 1: Load config
    print_step("Step 1: Loading configuration")
    config = load_config(args.config)
    
    # Extract key values
    namespace = config['namespace']
    service_name = config['service_name']
    current_version = config['current_version']
    target_version = config['target_version']
    
    print_info(f"Namespace: {namespace}")
    print_info(f"Service: {service_name}")
    print_info(f"Current version: {Colors.BLUE}{current_version}{Colors.RESET}")
    print_info(f"Target version: {Colors.GREEN}{target_version}{Colors.RESET}")
    print()
    
    # Step 2: Connect to Kubernetes
    print_step("Step 2: Connecting to Kubernetes")
    v1, apps_v1 = init_kubernetes()
    print()
    
    # Step 3: Run pre-flight checks
    print_step("Step 3: Running pre-flight checks")
    checks_passed = run_preflight_checks(v1, apps_v1, config)
    
    if not checks_passed:
        print_error("❌ Pre-flight checks failed. Aborting deployment.")
        print_info("Fix the issues and try again.")
        return 1
    
    print_success("✅ All pre-flight checks passed")
    print()
    
    # Step 4: Switch traffic
    print_step(f"Step 4: Switching traffic from {current_version} → {target_version}")
    
    traffic_switched = switch_traffic(
        v1=v1,
        namespace=namespace,
        service_name=service_name,
        to_version=target_version,
        from_version=current_version,
        dry_run=args.dry_run
    )
    
    if not traffic_switched:
        print_error("❌ Failed to switch traffic")
        return 1
    
    print()
    
    # If dry-run, stop here
    if args.dry_run:
        print_success("✅ Dry run completed successfully")
        print_info("Run without --dry-run to execute the deployment")
        return 0
    
    # Step 5: Verify endpoints updated
    print_step("Step 5: Verifying endpoints")
    
    endpoint_timeout = config.get('health_check', {}).get('endpoint_timeout', 30)
    
    endpoints_verified = verify_endpoints(
        v1=v1,
        namespace=namespace,
        service_name=service_name,
        expected_version=target_version,
        timeout=endpoint_timeout
    )
    
    if not endpoints_verified:
        print_error("❌ Endpoint verification failed")
        print_warning("ROLLING BACK to previous version")
        
        # Rollback: switch traffic back to current version
        rollback_success = switch_traffic(
            v1=v1,
            namespace=namespace,
            service_name=service_name,
            to_version=current_version,
            from_version=target_version,
            dry_run=False
        )
        
        if rollback_success:
            print_success(f"✅ Rolled back to {current_version}")
        else:
            print_error(f"❌ ROLLBACK FAILED - Manual intervention required!")
            print_error(f"Run: kubectl patch svc {service_name} -n {namespace} -p '{{\"spec\":{{\"selector\":{{\"version\":\"{current_version}\"}}}}}}'")
        
        return 1
    
    print()
    
    # Step 6: Run smoke tests
    print_step("Step 6: Running smoke tests")
    
    if args.skip_smoke_tests:
        print_warning("Skipping smoke tests (--skip-smoke-tests flag set)")
        print_info("Note: On Docker Desktop, ClusterIP is not reachable from WSL")
        print_info("In production EKS, remove this flag to run smoke tests")
        smoke_tests_passed = True
    else:
        smoke_tests_passed = run_smoke_tests(v1, namespace, service_name, config)
    
    if not smoke_tests_passed:
        print_error("❌ Smoke tests failed")
        print_warning("ROLLING BACK to previous version")
        
        # Rollback
        rollback_success = switch_traffic(
            v1=v1,
            namespace=namespace,
            service_name=service_name,
            to_version=current_version,
            from_version=target_version,
            dry_run=False
        )
        
        if rollback_success:
            print_success(f"✅ Rolled back to {current_version}")
            # Verify rollback endpoints
            verify_endpoints(v1, namespace, service_name, current_version, timeout=30)
        else:
            print_error(f"❌ ROLLBACK FAILED - Manual intervention required!")
        
        return 1
    
    print()
    
    # Success!
    print(f"\n{Colors.BOLD}{Colors.GREEN}")
    print("╔════════════════════════════════════════════════════════════╗")
    print("║                 DEPLOYMENT SUCCESSFUL! ✅                  ║")
    print("╚════════════════════════════════════════════════════════════╝")
    print(f"{Colors.RESET}\n")
    
    print_success(f"Traffic successfully switched to: {target_version}")
    print_info(f"Service '{service_name}' is now routing to {target_version} pods")
    print()
    
    print_step("Next steps:")
    print_info("1. Monitor application metrics in Grafana")
    print_info("2. Check logs for any errors:")
    print_info(f"   kubectl logs -l version={target_version} -n {namespace} --tail=100 -f")
    print_info("3. If issues arise, rollback with:")
    print_info(f"   python {sys.argv[0]} --config {args.config}")
    print_info(f"   (Update config.yaml: current_version={target_version}, target_version={current_version})")
    print_info("")
    print_info("4. Once stable, you can scale down the old version:")
    print_info(f"   kubectl scale deployment sre-lab-api-{current_version} --replicas=0 -n {namespace}")
    print()
    
    return 0

if __name__ == "__main__":
    sys.exit(main())

