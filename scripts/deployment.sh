#!/bin/bash

# Step 1: Deploy the Job and wait for the Job to Complete
kubectl apply -f ../k8s/job.yaml
kubectl wait --for=condition=complete --timeout=30s job/spdk

# Step 2: Retrieve the Job's Output
POD_NAME=$(kubectl get pods --selector=job-name=spdk --output=jsonpath='{.items[*].metadata.name}')
FREE_HUGEPAGE_MEMORY_MB=$(kubectl logs $POD_NAME)
echo "Free hugepage memory: $FREE_HUGEPAGE_MEMORY_MB MB"

# Step 3: Patch the Deployment Manifest
yq eval '.spec.template.spec.containers[].resources.requests.hugepages-2Mi = "'${FREE_HUGEPAGE_MEMORY_MB}Mi'"' -i ../k8s/deployment.yaml
yq eval '.spec.template.spec.containers[].resources.limits.hugepages-2Mi = "'${FREE_HUGEPAGE_MEMORY_MB}Mi'"' -i ../k8s/deployment.yaml
yq eval '.spec.template.spec.containers[].args = ["./entrypoint.sh $NRHUGE $DRIVER_OVERRIDE '${FREE_HUGEPAGE_MEMORY_MB}'"]' -i ../k8s/deployment.yaml

# Step 4: Deploy the Updated Manifest and wait for it to be available
kubectl apply -f ../k8s/deployment.yaml
kubectl wait --for=condition=available --timeout=120s deployment/spdk

# Step 5: Retrieve the deployment logs
POD_NAME=$(kubectl get pods --selector=app=spdk --output=jsonpath='{.items[*].metadata.name}')
kubectl logs $POD_NAME
