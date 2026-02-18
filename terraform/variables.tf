variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}

variable "docker_image" {
  description = "Docker image to deploy (e.g. user/artac-app:latest)"
  type        = string
}

variable "app_port" {
  description = "Application port"
  type        = number
  default     = 8080
}

variable "state_bucket_name" {
  description = "S3 bucket name for Terraform state (must be globally unique)"
  type        = string
}

variable "state_lock_table_name" {
  description = "DynamoDB table name for state locking"
  type        = string
  default     = "artac-terraform-locks"
}
