provider "aws" {
  region = var.region
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# ECR Repositories
resource "aws_ecr_repository" "app" {
  name                 = "webapp"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository" "db" {
  name                 = "mysql"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_security_group" "clo835_sg" {
  name        = "clo835-assignment2-sg"
  description = "Allow SSH, HTTP, HTTPS, and NodePort range access"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS"
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Application Port"
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "NodePort Range"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "clo835-assignment2-sg"
  }
}

resource "aws_instance" "k8s_cluster" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.clo835_sg.id]
  iam_instance_profile        = "LabInstanceProfile"
  subnet_id                   = data.aws_subnets.default.ids[0]

  root_block_device {
    volume_size = var.root_block_device_size
    volume_type = "gp2"
  }

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker git curl wget
              
              # Start and enable Docker
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ec2-user
              
              # Install kubectl
              curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
              chmod +x kubectl
              mv kubectl /usr/local/bin/
              
              # Install kind
              curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
              chmod +x ./kind
              mv ./kind /usr/local/bin/
              
              # Install AWS CLI v2
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              ./aws/install
              
              # Configure AWS CLI
              aws configure set default.region ${var.region}
              
              # Create kind cluster configuration
              cat > kind-config.yaml << 'KINDEOF'
              kind: Cluster
              apiVersion: kind.x-k8s.io/v1alpha4
              nodes:
              - role: control-plane
                extraPortMappings:
                - containerPort: 30000
                  hostPort: 30000
                  protocol: TCP
              KINDEOF
              
              # Create kind cluster
              kind create cluster --name clo835-cluster --config kind-config.yaml
              
              # Configure kubectl
              kind export kubeconfig --name clo835-cluster
              
              # Create namespaces
              kubectl create namespace web
              kubectl create namespace db
              
              # Get ECR login token and create secret
              aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${aws_ecr_repository.app.repository_url}
              aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${aws_ecr_repository.db.repository_url}
              
              # Create ECR secret
              kubectl create secret docker-registry regcred \
                --docker-server=${aws_ecr_repository.app.repository_url} \
                --docker-username=AWS \
                --docker-password=$(aws ecr get-login-password --region ${var.region}) \
                --namespace=web
              
              kubectl create secret docker-registry regcred \
                --docker-server=${aws_ecr_repository.db.repository_url} \
                --docker-username=AWS \
                --docker-password=$(aws ecr get-login-password --region ${var.region}) \
                --namespace=db
              EOF

  tags = {
    Name = "clo835-k8s-cluster"
    Project = "clo835-assignment2"
  }
}