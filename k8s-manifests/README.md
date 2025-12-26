# Kubernetes Manifests

This directory contains Kubernetes manifests for deploying a sample nginx application to verify the EKS cluster is functional.

## Deployment

After your EKS cluster is created and you've configured kubectl, deploy the sample application:

```bash
# Apply the deployment
kubectl apply -f nginx-deployment.yaml

# Apply the service
kubectl apply -f nginx-service.yaml

# Check deployment status
kubectl get deployments
kubectl get pods
kubectl get services

# Get the LoadBalancer URL (may take a few minutes to provision)
kubectl get service nginx-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Test the application
curl http://$(kubectl get service nginx-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
```

## Cleanup

To remove the sample application:

```bash
kubectl delete -f nginx-service.yaml
kubectl delete -f nginx-deployment.yaml
```

