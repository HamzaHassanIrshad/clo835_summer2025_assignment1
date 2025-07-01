variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance (Amazon Linux 2023)"
  type        = string
  default     = "ami-0c02fb55956c7d316" # Amazon Linux 2023 in us-east-1
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = "clo835-key"
}

variable "root_block_device_size" {
  description = "Size of the root block device in GB"
  type        = number
  default     = 20
}
