# ArtAc - DevOps Demo Application

## Overview
A Spring Boot REST API demonstrating a full DevOps pipeline: CI/CD with GitHub Actions, containerization with Docker, and infrastructure provisioned with Terraform on AWS.

## Architecture
```
GitHub → GitHub Actions → Docker Hub → AWS EC2
```

## Prerequisites
- Java 21
- Docker
- AWS account (free tier)
- Docker Hub account
- Terraform >= 1.0
- AWS CLI configured

## Project Structure
```
ArtAc/
├── .github/workflows/ci-cd.yml    # CI/CD pipeline
├── src/main/java/com/artac/app/   # Java source code
├── src/test/java/com/artac/app/   # Unit tests
├── terraform/                      # Infrastructure as Code
│   ├── main.tf                    # Provider, EC2 instance
│   ├── backend.tf                 # S3 state backend
│   ├── variables.tf               # Input variables
│   ├── outputs.tf                 # Output values
│   ├── security-group.tf          # Firewall rules
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

### Endpoints
| Endpoint | Description |
|---|---|
| `GET /` | Welcome message |
| `GET /api/health` | JSON health status |
| `GET /actuator/health` | Spring Actuator health |

## CI/CD Pipeline

The pipeline runs on **GitHub Actions** and consists of 3 jobs:

```
Push to main
    │
    ▼
┌──────────────┐     ┌───────────────────┐     ┌──────────────┐
│ Build & Test  │────▶│ Docker Build/Push  │────▶│ Deploy to EC2│
└──────────────┘     └───────────────────┘     └──────────────┘
```

| Job | Trigger | Description |
|---|---|---|
| **Build & Test** | Every push & PR | Checks out code, builds with Gradle, runs unit tests, uploads JAR artifact |
| **Docker Build/Push** | Push to main only | Builds multi-stage Docker image, pushes to Docker Hub with commit SHA + `latest` tags |
| **Deploy to EC2** | Push to main only | SSHs into EC2, pulls new image, restarts container, verifies health endpoint |

**Required GitHub Secrets:**

| Secret | Description |
|---|---|
| `DOCKERHUB_USERNAME` | Docker Hub username |
| `DOCKERHUB_TOKEN` | Docker Hub access token |
| `EC2_HOST` | EC2 instance public IP |
| `EC2_SSH_PRIVATE_KEY` | SSH private key for EC2 access |

## Docker

Uses a **multi-stage build** for a lightweight image (~230MB):

- **Stage 1 (Builder):** `eclipse-temurin:21-jdk` — compiles the application with Gradle
- **Stage 2 (Runtime):** `eclipse-temurin:21-jre-alpine` — runs with JRE only

Key features:
- Non-root user (`appuser`) for security
- `HEALTHCHECK` using Spring Actuator endpoint
- JVM container-aware memory settings (`-XX:MaxRAMPercentage=75.0`)

### Build & Run Locally
```bash
docker build -t artac-app .
docker run -d -p 8080:8080 --name artac-app artac-app
curl localhost:8080/api/health
```

## Infrastructure (Terraform)

Terraform provisions the following AWS resources:

| Resource | Purpose |
|---|---|
| EC2 instance (t2.micro) | Runs the Docker container (free tier) |
| Security Group | Allows inbound on ports 22 (SSH) and 8080 (app) |
| S3 Bucket | Stores Terraform state (versioned, encrypted) |
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

> **Note:** `terraform apply` automatically updates the `EC2_HOST` GitHub Secret with the new EC2 public IP, keeping the CI/CD deploy job in sync.

## Design Decisions

| Decision | Rationale |
|---|---|
| **Spring Boot** | Industry-standard Java framework, built-in Actuator for health checks, fast setup |
| **Gradle** | Faster builds than Maven, Groovy DSL is concise, wrapper ensures consistent versions |
| **GitHub Actions** | Free for public repos, native GitHub integration, no infrastructure to manage (vs Jenkins) |
| **Multi-stage Docker build** | Final image ~230MB (JRE Alpine) vs ~600MB+ with full JDK; minimal attack surface |
| **S3 + DynamoDB backend** | Team-safe remote state with locking; versioned and encrypted for audit/rollback |
| **Amazon Linux 2023** | Latest AWS-optimized OS, long-term support, native AWS tooling |
| **Commit SHA image tags** | Every deployment traceable to exact source commit |

## Production Improvements

- Custom VPC with public/private subnets
- Application Load Balancer (ALB) with HTTPS (ACM certificate)
- ECS/EKS instead of bare EC2 for container orchestration
- Restricted SSH CIDR (not 0.0.0.0/0)
- Container image vulnerability scanning (Trivy, Snyk)
- CloudWatch logging and monitoring with alerts
- Auto-scaling group for high availability
- Secrets Manager for sensitive configuration

## Cleanup

To destroy all AWS resources:
```bash
cd terraform
terraform destroy
```
