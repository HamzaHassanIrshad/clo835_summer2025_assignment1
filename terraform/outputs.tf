output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.k8s_cluster.public_ip
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.k8s_cluster.id
}

output "app_ecr_repository_url" {
  description = "URL of the application ECR repository"
  value       = aws_ecr_repository.app.repository_url
}

output "db_ecr_repository_url" {
  description = "URL of the database ECR repository"
  value       = aws_ecr_repository.db.repository_url
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ${var.key_name}.pem ec2-user@${aws_instance.k8s_cluster.public_ip}"
}

output "cluster_info" {
  description = "Information about the Kubernetes cluster"
  value = {
    instance_ip = aws_instance.k8s_cluster.public_ip
    app_repo    = aws_ecr_repository.app.repository_url
    db_repo     = aws_ecr_repository.db.repository_url
    region      = var.region
  }
}
