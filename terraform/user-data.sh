#!/bin/bash
set -euxo pipefail
exec > /var/log/user-data.log 2>&1

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

# Pull and run the application container
docker pull ${docker_image}
docker run -d \
  --name artac-app \
  -p ${app_port}:8080 \
  --restart unless-stopped \
  ${docker_image}
