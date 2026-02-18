# ArtAc - DevOps Demo Application

## Overview
A Spring Boot REST API demonstrating a full DevOps pipeline: CI/CD with GitHub Actions, containerization with Docker, and infrastructure provisioned with Terraform on AWS.

## Architecture
GitHub → GitHub Actions → Docker Hub → AWS EC2

## Prerequisites
- Java 21
- Docker
- AWS account (free tier)
- Docker Hub account
- Terraform >= 1.0
- AWS CLI configured

## Project Structure
(paste the directory tree from the plan)

## Quick Start

### Run Locally
./gradlew bootRun

### Run Tests
./gradlew test

### Endpoints
| Endpoint | Description |
|---|---|
| GET / | Welcome message |
| GET /api/health | JSON health status |
| GET /actuator/health | Spring Actuator health |

## Scripts

| Script | Description |
|---|---|
| `./scripts/local-deploy.sh` | Runs tests, builds JAR, builds Docker image, starts container on port 8080 |
| `./scripts/local-check.sh` | Checks all endpoints, shows health response, Docker status, pass/fail summary |

### Usage
```bash
# Full local deploy (test + build + Docker)
./scripts/local-deploy.sh

# Verify everything is running
./scripts/local-check.sh
```

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
(describe what Terraform provisions, how to bootstrap S3 backend)

## Design Decisions
(justify Spring Boot, Gradle, GitHub Actions, multi-stage Docker, S3 backend)

## Production Improvements
(list: custom VPC, ALB, HTTPS, ECS/EKS, restricted SSH, image scanning, CloudWatch)

## Cleanup
terraform destroy