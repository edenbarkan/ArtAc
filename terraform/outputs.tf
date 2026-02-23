output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.app_server.public_ip
}

output "instance_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.app_server.public_dns
}

output "application_url" {
  description = "URL to access the application"
  value       = "http://${aws_instance.app_server.public_ip}:${var.app_port}"
}

output "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions OIDC (set as AWS_ROLE_ARN secret)"
  value       = aws_iam_role.github_actions.arn
}
