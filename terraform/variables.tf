variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"

  validation {
    condition     = contains(["t2.micro", "t3.micro", "t2.small"], var.instance_type)
    error_message = "Instance type must be free-tier eligible: t2.micro, t3.micro, or t2.small."
  }
}

variable "docker_image" {
  description = "Docker image to deploy (e.g. user/artac-app:latest)"
  type        = string
}

variable "app_port" {
  description = "Application port"
  type        = number
  default     = 8080

  validation {
    condition     = var.app_port >= 1024 && var.app_port <= 65535
    error_message = "Application port must be between 1024 and 65535."
  }
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

variable "github_repo" {
  description = "GitHub repository (owner/repo) for automatic secret updates"
  type        = string
}
