variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed to connect via SSH"
  type        = string
}

variable "domain_name" {
  description = "The main domain name (e.g. paleon-lab-health.com)"
  type        = string
  default     = "paleon-lab-health.com"
}

variable "project_name" {
  description = "Name for resources"
  type        = string
  default     = "paleon-site2"
}
