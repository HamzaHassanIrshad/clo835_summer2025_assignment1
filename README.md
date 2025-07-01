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

**Note:** The `requirements.txt` file contains Python dependencies (Flask, PyMySQL, etc.) that are automatically installed during the Docker image build process. No manual installation of these dependencies is required.

### Installing Terraform on Amazon Linux

If you're working on an Amazon Linux EC2 instance or Cloud9 environment, install Terraform using these commands:

```bash
# Install yum-utils and shadow-utils (required for HashiCorp repository)
sudo yum install -y yum-utils shadow-utils

# Add HashiCorp repository
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo

# Install Terraform
sudo yum -y install terraform

# Verify installation
terraform --version
```

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

### Step 3: Connect to EC2 Instance and Build/Push Docker Images

1. **SSH into the EC2 instance:**
   ```bash
   ssh -i ~/.ssh/clo835-key ec2-user@<EC2_PUBLIC_IP>
   ```

2. **Install Docker on EC2 (if not already installed):**
   ```bash
   # Update system
   sudo yum update -y
   
   # Install Docker
   sudo yum install -y docker
   sudo systemctl start docker
   sudo systemctl enable docker
   sudo usermod -a -G docker ec2-user
   
   # Log out and back in for group changes to take effect
   exit
   ```
   
   **Reconnect to EC2:**
   ```bash
   ssh -i ~/.ssh/clo835-key ec2-user@<EC2_PUBLIC_IP>
   ```

3. **Clone the repository on EC2:**
   ```bash
   git clone https://github.com/HamzaHassanIrshad/clo835_summer2025_assignment1.git
   cd clo835_summer2025_assignment1
   ```

5. **Get ECR login token:**
4. **Get ECR login token:**
   ```bash
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ECR_REPO_URI>
   ```
   > **Note:** Do not append `/webapp` or `/mysql` at the end of the ECR URI. Use the repository URI exactly as provided by AWS ECR. This format is confirmed to work.

6. **Build application image:**
5. **Build application image:**
   ```bash
   docker build -t <ECR_REPO_URI>:latest .
   ```

7. **Build database image:**
6. **Build database image:**
   ```bash
   docker build -t <ECR_REPO_URI>:latest -f Dockerfile_mysql .
   ```

8. **Push images to ECR:**
7. **Push images to ECR:**
   ```bash
   docker push <ECR_REPO_URI>:latest
   docker push <ECR_REPO_URI>:latest
   ```

**Note:** The Dockerfile automatically installs all Python dependencies from `requirements.txt` during the image build process, so no manual installation is required.

### Step 4: Install Kubernetes Tools on EC2 Instance

1. **SSH into the instance (if not already connected):**
   ```bash
   ssh -i ~/.ssh/clo835-key ec2-user@<EC2_PUBLIC_IP>
   ```

2. **Install kubectl:**
   ```bash
   curl -LO https://dl.k8s.io/release/v1.30.1/bin/linux/amd64/kubectl
   curl -LO "https://dl.k8s.io/release/v1.30.1/bin/linux/amd64/kubectl"
   chmod +x kubectl
   sudo mv kubectl /usr/local/bin/kubectl
   kubectl version --client
   ```

3. **Install kind:**
   ```bash
   curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.29.0/kind-linux-amd64
   chmod +x ./kind
   sudo mv ./kind /usr/local/bin/kind
   kind version
   ```

5. **Create kind cluster:**
4. **Create kind cluster:**
   ```bash
   # Create kind cluster configuration
   cat > kind-config.yaml << 'EOF'
   kind: Cluster
   apiVersion: kind.x-k8s.io/v1alpha4
   nodes:
   - role: control-plane
     extraPortMappings:
     - containerPort: 30000
       hostPort: 30000
       protocol: TCP
   EOF
   
   # Create kind cluster
   kind create cluster --name clo835-cluster --config kind-config.yaml
   
   # Configure kubectl
   kind export kubeconfig --name clo835-cluster
   
   # Verify cluster is running
   kubectl cluster-info
   kubectl get nodes
   ```

6. **Create namespaces:**
5. **Create namespaces:**
   ```bash
   kubectl create namespace web
   kubectl create namespace db
   ```

7. **Create ECR secrets:**
6. **Create ECR secrets:**
   ```bash
   # Login to ECR
   aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ECR_REPO_URI>
   
   # Create secrets for both namespaces
   kubectl create secret docker-registry regcred \
     --docker-server=<ECR_REPO_URI> \
     --docker-username=AWS \
     --docker-password=$(aws ecr get-login-password --region us-east-1) \
     --namespace=web
   
   kubectl create secret docker-registry regcred \
     --docker-server=<ECR_REPO_URI> \
     --docker-username=AWS \
     --docker-password=$(aws ecr get-login-password --region us-east-1) \
     --namespace=db
   ```

### Step 5: Deploy Applications to Kubernetes

1. **Copy manifests to EC2 instance (from your local machine):**
   ```bash
   scp -i ~/.ssh/clo835-key -r k8s-manifests ec2-user@<EC2_PUBLIC_IP>:~/
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
   curl http://<EC2_PUBLIC_IP>:30000
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
   kubectl set image deployment/web-app-deployment web-app=<ECR_REPO_APP_URI>:v2 -n web
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

### Why EC2 Instead of Cloud9?
- **Storage:** EC2 instances provide more storage space for building and pushing Docker images
- **Performance:** Better performance for Docker operations compared to Cloud9
- **Cost:** More cost-effective for resource-intensive operations
- **Flexibility:** Full control over the environment and tools installation

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