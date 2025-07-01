# CLO835 Assignment 2 - Kubernetes Deployment

This project demonstrates the deployment of a containerized Flask application with MySQL database on a local Kubernetes cluster using kind (Kubernetes in Docker) running on an Amazon EC2 instance.

## Learning Outcomes Covered

- Evaluate the applicability of containerization approach and viability of publicly/privately hosted containers orchestration platform for the business needs of the organization.
- Design, implement and deploy containerized applications to address cost optimization, high availability, and scalability requirements of business applications.
- Evaluate and recommend networking, persistent storage, and IAM (Identity and Access Management) solutions to achieve the desired level of infrastructure and applications security.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    AWS Cloud                                │
│  ┌─────────────────┐    ┌─────────────────┐                 │
│  │   Amazon ECR    │    │   Amazon EC2    │                 │
│  │                 │    │                 │                 │
│  │ ┌─────────────┐ │    │ ┌─────────────┐ │                 │
│  │ │ clo835-app  │ │    │ │ Kind Cluster│ │                 │
│  │ │ Repository  │ │    │ │             │ │                 │
│  │ └─────────────┘ │    │ │ ┌─────────┐ │ │                 │
│  │ ┌─────────────┐ │    │ │ │ Web App │ │ │                 │
│  │ │ clo835-db   │ │    │ │ │ Pods    │ │ │                 │
│  │ │ Repository  │ │    │ │ └─────────┘ │ │                 │
│  │ └─────────────┘ │    │ │ ┌─────────┐ │ │                 │
│  └─────────────────┘    │ │ │MySQL Pod│ │ │                 │
│                         │ │ └─────────┘ │ │                 │
│                         │ └─────────────┘ │                 │
│                         └─────────────────┘                 │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform installed
- Docker installed (for local development)
- SSH key pair for EC2 access

## Step-by-Step Deployment Guide

### Step 1: Prepare Your Environment

1. **Clone the repository:**
   ```bash
   git clone https://github.com/HamzaHassanIrshad/clo835_summer2025_assignment1.git
   cd clo835_summer2025_assignment1
   ```

2. **Create SSH key pair (if not exists):**
   ```bash
   ssh-keygen -t rsa -b 2048 -f ~/.ssh/clo835-key -N ""
   ```

3. **Import SSH key to AWS:**
   ```bash
   aws ec2 import-key-pair \
     --key-name clo835-key \
     --public-key-material fileb://~/.ssh/clo835-key.pub \
     --region us-east-1
   ```

### Step 2: Deploy Infrastructure with Terraform

1. **Navigate to Terraform directory:**
   ```bash
   cd terraform
   ```

2. **Initialize Terraform:**
   ```bash
   terraform init
   ```

3. **Review the plan:**
   ```bash
   terraform plan
   ```

4. **Apply the infrastructure:**
   ```bash
   terraform apply
   ```

5. **Note the outputs:**
   ```bash
   terraform output
   ```

### Step 3: Build and Push Docker Images

1. **Get ECR login token:**
   ```bash
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $(terraform output -raw app_ecr_repository_url)
   ```

2. **Build application image:**
   ```bash
   docker build -t $(terraform output -raw app_ecr_repository_url):latest .
   ```

3. **Build database image:**
   ```bash
   docker build -t $(terraform output -raw db_ecr_repository_url):latest -f Dockerfile_mysql .
   ```

4. **Push images to ECR:**
   ```bash
   docker push $(terraform output -raw app_ecr_repository_url):latest
   docker push $(terraform output -raw db_ecr_repository_url):latest
   ```

### Step 4: Connect to EC2 Instance

1. **SSH into the instance:**
   ```bash
   ssh -i ~/.ssh/clo835-key ec2-user@$(terraform output -raw instance_public_ip)
   ```

2. **Verify cluster is running:**
   ```bash
   kubectl cluster-info
   kubectl get nodes
   ```

### Step 5: Deploy Applications to Kubernetes

1. **Create namespaces (if not already created):**
   ```bash
   kubectl create namespace web
   kubectl create namespace db
   ```

2. **Deploy MySQL first:**
   ```bash
   kubectl apply -f k8s-manifests/mysql-pod.yaml
   kubectl apply -f k8s-manifests/mysql-svc.yaml
   ```

3. **Deploy web application:**
   ```bash
   kubectl apply -f k8s-manifests/webapp-pod.yaml
   kubectl apply -f k8s-manifests/webapp-svc.yaml
   ```

4. **Verify deployments:**
   ```bash
   kubectl get pods -n web
   kubectl get pods -n db
   kubectl get services -n web
   kubectl get services -n db
   ```

### Step 6: Test the Application

1. **Port forward to test locally:**
   ```bash
   kubectl port-forward -n web service/webapp-service 8080:8080
   ```

2. **Access the application:**
   - Open browser: http://localhost:8080
   - Or use curl: `curl http://localhost:8080`

3. **Test NodePort access:**
   ```bash
   curl http://$(terraform output -raw instance_public_ip):30000
   ```

### Step 7: Deploy ReplicaSets and Deployments

1. **Deploy ReplicaSets:**
   ```bash
   kubectl apply -f k8s-manifests/mysql-rs.yaml
   kubectl apply -f k8s-manifests/webapp-rs.yaml
   ```

2. **Deploy Deployments:**
   ```bash
   kubectl apply -f k8s-manifests/mysql-deployment.yaml
   kubectl apply -f k8s-manifests/webapp-deployment.yaml
   ```

3. **Verify scaling:**
   ```bash
   kubectl get replicasets -n web
   kubectl get replicasets -n db
   kubectl get deployments -n web
   kubectl get deployments -n db
   ```

### Step 8: Update Application Version

1. **Update the image tag in deployment:**
   ```bash
   kubectl set image deployment/web-app-deployment web-app=$(terraform output -raw app_ecr_repository_url):v2 -n web
   ```

2. **Verify rolling update:**
   ```bash
   kubectl rollout status deployment/web-app-deployment -n web
   kubectl get pods -n web
   ```

## Assignment Requirements Checklist

### 1. Local K8s Cluster Verification
- [ ] Cluster is running on Amazon EC2 instance
- [ ] Single node cluster confirmed
- [ ] All basic K8s components are healthy
- [ ] API server IP documented

### 2. Application Deployment
- [ ] MySQL and web applications deployed as pods
- [ ] Applications can listen on same port (different namespaces)
- [ ] Server response verified
- [ ] Application logs examined

### 3. ReplicaSets
- [ ] Web application ReplicaSet with 3 replicas
- [ ] MySQL ReplicaSet with 1 replica
- [ ] Proper labels used (app: employees, app: mysql)

### 4. Deployments
- [ ] MySQL and web application deployments created
- [ ] Labels from ReplicaSets used as selectors
- [ ] Deployment relationship with ReplicaSets verified

### 5. Services
- [ ] Web application exposed on NodePort 30000
- [ ] MySQL exposed using ClusterIP
- [ ] Application accessible via curl and browser

### 6. Application Updates
- [ ] Image version updated in deployment
- [ ] New version deployed successfully
- [ ] Rolling update verified

## Important Notes

### Service Types Explanation

**Web Application - NodePort:**
- Allows external access to the application
- Maps a port on all nodes to the service
- Required for external users to access the web application

**MySQL - ClusterIP:**
- Internal service only accessible within the cluster
- Provides load balancing between pods
- Secure as it's not exposed externally

### Port Configuration
- Both applications can listen on the same port (8080) because they run in different namespaces
- Kubernetes namespaces provide isolation, allowing multiple services to use the same port

### ECR Authentication
The Terraform configuration automatically creates ECR secrets for both namespaces, allowing the cluster to pull images from ECR.

## Troubleshooting

### Common Issues

1. **ECR Authentication Errors:**
   ```bash
   kubectl delete secret regcred -n web
   kubectl delete secret regcred -n db
   # Recreate secrets using the commands in the user_data script
   ```

2. **Pod Startup Issues:**
   ```bash
   kubectl describe pod <pod-name> -n <namespace>
   kubectl logs <pod-name> -n <namespace>
   ```

3. **Service Connection Issues:**
   ```bash
   kubectl get endpoints -n <namespace>
   kubectl describe service <service-name> -n <namespace>
   ```

### Useful Commands

```bash
# Check cluster status
kubectl cluster-info
kubectl get nodes

# Check all resources
kubectl get all -n web
kubectl get all -n db

# Check events
kubectl get events -n web
kubectl get events -n db

# Check logs
kubectl logs -f deployment/web-app-deployment -n web
kubectl logs -f deployment/mysql-deployment -n db
```

## Cleanup

To destroy all resources:
```bash
cd terraform
terraform destroy
```

## Repository Information

- **Repository:** https://github.com/HamzaHassanIrshad/clo835_summer2025_assignment1
- **Branch:** main (use main branch for assignment 1 completion)
- **Dev Branch:** Contains experimental changes

## Support

For issues or questions, please refer to the troubleshooting section or create an issue in the repository.