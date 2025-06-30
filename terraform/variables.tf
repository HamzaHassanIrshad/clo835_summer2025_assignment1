variable "region" {
  default = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  default = "t3.large"
}

variable "ami_id" {
  description = "Amazon Linux 2 AMI for us-east-1"
  default     = "ami-0c101f26f147fa7fd"
}

variable "key_name" {
  description = "Name of the SSH key pair to use for the instance"
  default = "clo835-key"
}

variable "root_block_device_size" {
  description = "Root EBS volume size in GB"
  default = 50
}
