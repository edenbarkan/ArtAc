# ArtAc - DevOps Demo Application

## Overview
A Spring Boot REST API demonstrating a full DevOps pipeline: CI/CD with GitHub Actions, containerization with Docker, and infrastructure provisioned with Terraform on AWS.

## Architecture
```
                    ┌──────────────────────────────────────────────────┐
                    │                GitHub Actions                     │
                    │                                                   │
  Push to main ───►│  Build & Test ──► Trivy Scan ──► Docker Push      │
                    │                                       │           │
                    │  (PR only)                            ▼           │
                    │  Terraform ◄──┘                 Deploy via SSM    │
                    │  fmt/validate                   + Health Check    │
                    │                                + Auto-Rollback    │
                    └──────────────────────────────────────────────────┘
                                                           │
                    ┌──────────────────────────────────────┼───────────┐
                    │                AWS (Free Tier)        │           │
                    │                                      ▼           │
                    │  ┌───────────────────────────────────────────┐   │
                    │  │ EC2 (t2.micro, Amazon Linux 2023)         │   │
                    │  │  └─ Docker: artac-app (Spring Boot JRE)   │   │
                    │  │     └─ Port 8080, memory=450m, cpus=0.5   │   │
                    │  │  └─ SSM Agent (pre-installed)             │   │
                    │  │  └─ IAM Instance Profile (SSM access)     │   │
                    │  └───────────────────────────────────────────┘   │
                    │                                                   │
                    │  S3 Bucket ──── Terraform State (encrypted)      │
                    │  DynamoDB ───── State Locking                    │
                    │  IAM OIDC ───── GitHub Actions auth (no keys)   │
                    └──────────────────────────────────────────────────┘
```

## Prerequisites
- Java 21
- Docker
- AWS account (free tier)
- Docker Hub account
- Terraform >= 1.0
- AWS CLI configured
- GitHub CLI (`gh`) for Terraform secret updates

## Project Structure
```
ArtAc/
├── .github/workflows/ci-cd.yml    # CI/CD pipeline
├── src/main/java/com/artac/app/   # Java source code
├── src/test/java/com/artac/app/   # Unit + integration tests
├── terraform/                      # Infrastructure as Code
│   ├── main.tf                    # Provider, EC2 instance, locals
│   ├── iam.tf                     # IAM roles, SSM, GitHub OIDC
│   ├── backend.tf                 # S3 state backend
│   ├── variables.tf               # Input variables with validations
│   ├── outputs.tf                 # Output values
│   ├── security-group.tf          # Firewall rules (no SSH)
│   └── user-data.sh               # EC2 bootstrap script
├── Dockerfile                      # Multi-stage Docker build
├── build.gradle                    # Gradle build config
└── README.md
```

## Quick Start

### Run Locally
```bash
./gradlew bootRun
```

### Run Tests
```bash
./gradlew test
```

### Build & Run with Docker
```bash
docker build -t artac-app .
docker run -d -p 8080:8080 --name artac-app artac-app
```

## API Endpoints

| Endpoint | Description |
|---|---|
| `GET /` | Welcome message |
| `GET /api/health` | Health status with build info |
| `GET /actuator/health` | Spring Actuator health |

```bash
$ curl localhost:8080/api/health
{
  "status": "UP",
  "timestamp": "2025-02-23T10:30:00Z",
  "version": "0.0.1-SNAPSHOT",
  "gitCommit": "7bfc5b0",
  "gitBranch": "main"
}
```

## CI/CD Pipeline

The pipeline runs on **GitHub Actions** with 4 jobs:

```
Push to main
    │
    ▼
┌──────────────┐    ┌─────────────────────┐    ┌────────────────────┐
│ Build & Test  │───►│ Build, Scan & Push   │───►│ Deploy via SSM     │
└──────────────┘    └─────────────────────┘    │ + Auto-Rollback    │
                                                └────────────────────┘
Pull Request
    │
    ▼
┌──────────────┐    ┌─────────────────────┐
│ Build & Test  │    │ Terraform Validate   │
└──────────────┘    └─────────────────────┘
```

| Job | Trigger | Description |
|---|---|---|
| **Build & Test** | Every push & PR | Builds with Gradle, runs unit + integration tests |
| **Terraform Validate** | PR only | Checks `terraform fmt`, `init`, `validate` |
| **Build, Scan & Push** | Push to main | Builds Docker image, scans with Trivy (blocks CRITICAL/HIGH CVEs), pushes to Docker Hub |
| **Deploy via SSM** | Push to main | Deploys via AWS SSM (not SSH), auto-rollback on health check failure |

**Required GitHub Secrets:**

| Secret | Description |
|---|---|
| `DOCKERHUB_USERNAME` | Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token |
| `EC2_HOST` | EC2 instance public IP (auto-updated by Terraform) |
| `AWS_ROLE_ARN` | IAM role ARN for GitHub OIDC (from `terraform output`) |

## Docker

Uses a **multi-stage build** for a lightweight image (~230MB):

- **Stage 1 (Builder):** `eclipse-temurin:21-jdk` — compiles with Gradle
- **Stage 2 (Runtime):** `eclipse-temurin:21-jre-alpine` — JRE only

Key features:
- Non-root user (`appuser`) for security
- `HEALTHCHECK` using Spring Actuator endpoint
- JVM container-aware memory settings (`-XX:MaxRAMPercentage=75.0`)
- OCI-standard image labels

## Infrastructure (Terraform)

Terraform provisions the following AWS resources:

| Resource | Purpose |
|---|---|
| EC2 instance (t2.micro) | Runs the Docker container (free tier) |
| IAM Role + Instance Profile | SSM access for EC2 (replaces SSH) |
| IAM OIDC Provider | GitHub Actions authenticates without static credentials |
| IAM Role for GitHub Actions | Scoped to this repo, permissions for SSM + EC2 describe |
| Security Group | Allows inbound on port 8080 only (no SSH needed) |
| S3 Bucket | Terraform state (versioned, encrypted) |
| DynamoDB Table | State locking to prevent concurrent modifications |

### Bootstrap S3 Backend

The S3 backend requires a two-step bootstrap (bucket must exist before Terraform can use it):

1. **Create backend resources** (using local state):
   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars  # Edit with your values
   terraform init
   terraform apply -target=aws_s3_bucket.terraform_state \
                   -target=aws_s3_bucket_versioning.terraform_state \
                   -target=aws_s3_bucket_server_side_encryption_configuration.terraform_state \
                   -target=aws_s3_bucket_public_access_block.terraform_state \
                   -target=aws_dynamodb_table.terraform_locks
   ```

2. **Migrate state to S3** — uncomment the `backend "s3"` block in `main.tf`, then:
   ```bash
   terraform init -migrate-state
   ```

3. **Provision infrastructure:**
   ```bash
   terraform plan
   terraform apply
   ```

4. **Set GitHub secret** from Terraform output:
   ```bash
   gh secret set AWS_ROLE_ARN --body "$(terraform output -raw github_actions_role_arn)"
   ```

> **Note:** `terraform apply` automatically updates the `EC2_HOST` GitHub Secret via the `null_resource`.

## Security

| Feature | Description |
|---|---|
| **SSM instead of SSH** | No port 22 open, IAM-based auth, CloudTrail audited |
| **GitHub OIDC** | No static AWS credentials — short-lived tokens per CI run |
| **Trivy scanning** | Container images scanned for CVEs before push; CRITICAL/HIGH block the pipeline |
| **Non-root container** | Application runs as `appuser`, not root |
| **IAM Instance Profile** | EC2 has minimal permissions (SSM only) |
| **Encrypted state** | S3 backend with AES-256 encryption + versioning |
| **Variable validations** | Terraform prevents non-free-tier instance types and invalid ports |

## Design Decisions

| Decision | Rationale |
|---|---|
| **Spring Boot** | Industry-standard Java framework, built-in Actuator for health checks |
| **Gradle** | Faster builds than Maven, wrapper ensures consistent versions |
| **GitHub Actions** | Free for public repos, native GitHub integration, no infra to manage |
| **Multi-stage Docker** | Final image ~230MB (JRE Alpine) vs ~600MB+ with full JDK |
| **SSM over SSH** | No open ports, IAM auth, auditable — AWS best practice |
| **GitHub OIDC** | Eliminates long-lived AWS credentials in GitHub secrets |
| **Trivy** | Industry-standard free container scanner, shift-left security |
| **Auto-rollback** | Deploy script saves current image, rolls back on health failure |
| **S3 + DynamoDB backend** | Team-safe remote state with locking, versioned and encrypted |
| **Amazon Linux 2023** | SSM agent pre-installed, AWS-optimized, long-term support |
| **Commit SHA image tags** | Every deployment traceable to exact source commit |

## Troubleshooting

| Problem | Solution |
|---|---|
| EC2 unreachable after `terraform apply` | Check security group allows port 8080. Verify instance is running: `aws ec2 describe-instances` |
| SSM command fails | Verify IAM instance profile is attached. Check SSM agent: `aws ssm describe-instance-information` |
| Docker pull fails in user-data | Connect via SSM Session Manager, check `/var/log/user-data.log` |
| CI/CD deploy fails | Check `AWS_ROLE_ARN` secret matches Terraform output. Verify OIDC provider exists |
| Health check fails after deploy | Connect via SSM, run `docker logs artac-app`. Check port 8080 is bound |
| Terraform state lock | Run `terraform force-unlock <LOCK_ID>` (use with caution) |
| Trivy blocks the build | Review vulnerabilities. Use `--ignore-unfixed` or update base image |

## Production Improvements

These are out of scope for this free-tier demo but would be needed in production:

| Improvement | Rationale |
|---|---|
| **VPC with public/private subnets** | Network isolation; app in private subnet behind ALB |
| **Application Load Balancer + HTTPS** | TLS termination, health-based routing, ACM certificate |
| **ECS Fargate** | Managed container orchestration, no EC2 to maintain |
| **Auto Scaling Group** | Horizontal scaling, self-healing on instance failure |
| **CloudWatch Logs + Alarms** | Centralized logging, alerting on error rates |
| **Secrets Manager** | Runtime secrets injection instead of environment variables |
| **WAF** | Web application firewall in front of ALB |
| **GitHub OIDC → assume role** | Already implemented; in production would add condition on specific branches |

## Cleanup

To destroy all AWS resources:
```bash
cd terraform
terraform destroy
```
