variable "region" {
  default = "us-east-1"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "ami_id" {
  description = "Amazon Linux 2 AMI for us-east-1"
  default     = "ami-0c101f26f147fa7fd"
}

variable "key_name" {
  default = "clo835-key"
}
