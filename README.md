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
(describe the 3 GitHub Actions jobs)

## Docker
(describe the multi-stage build, how to build/run locally)

## Infrastructure (Terraform)
(describe what Terraform provisions, how to bootstrap S3 backend)

## Design Decisions
(justify Spring Boot, Gradle, GitHub Actions, multi-stage Docker, S3 backend)

## Production Improvements
(list: custom VPC, ALB, HTTPS, ECS/EKS, restricted SSH, image scanning, CloudWatch)

## Cleanup
terraform destroy