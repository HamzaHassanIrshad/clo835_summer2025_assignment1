provider "aws" {
  region = var.region
}

resource "aws_instance" "web" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  associate_public_ip_address = true

  # Use default IAM role already assigned by Learner Lab
  # Do NOT specify iam_instance_profile

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y docker
              service docker start
              usermod -a -G docker ec2-user
              systemctl enable docker
              yum install -y git
              EOF

  tags = {
    Name = "clo835-app-instance"
  }
}
