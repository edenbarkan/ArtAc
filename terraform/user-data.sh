#!/bin/bash
set -euxo pipefail
exec > /var/log/user-data.log 2>&1

echo "=== ArtAc EC2 Bootstrap - $(date) ==="

# Wait for any existing dnf lock to release
while fuser /var/run/dnf.lock 2>/dev/null; do sleep 5; done

# Install Docker
dnf update -y
dnf install -y docker

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Allow ec2-user to run Docker
usermod -aG docker ec2-user

# Pull image with retry (3 attempts, 10s backoff)
MAX_RETRIES=3
for i in $(seq 1 $MAX_RETRIES); do
  echo "Pull attempt $i of $MAX_RETRIES..."
  if docker pull ${docker_image}; then
    echo "Pull succeeded"
    break
  fi
  if [ "$i" -eq "$MAX_RETRIES" ]; then
    echo "ERROR: Failed to pull image after $MAX_RETRIES attempts"
    exit 1
  fi
  sleep 10
done

# Clean up any existing container
docker stop artac-app 2>/dev/null || true
docker rm artac-app 2>/dev/null || true

# Run with resource limits (t2.micro: 1 vCPU, 1GB RAM)
docker run -d \
  --name artac-app \
  -p ${app_port}:8080 \
  --restart unless-stopped \
  --memory=450m \
  --cpus=0.5 \
  --log-driver=json-file \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  ${docker_image}

# Wait for application to become healthy
echo "Waiting for application to become healthy..."
for i in $(seq 1 12); do
  if curl -sf http://localhost:${app_port}/actuator/health > /dev/null 2>&1; then
    echo "Application is healthy!"
    exit 0
  fi
  echo "Health check attempt $i/12..."
  sleep 10
done

echo "WARNING: Application did not pass health check within 120 seconds"
docker logs artac-app
