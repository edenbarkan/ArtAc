#!/bin/bash
set -euo pipefail

APP_NAME="artac-app"
APP_PORT=8080

echo "=== Local Deploy: ${APP_NAME} ==="

# Step 1: Run tests
echo "[1/4] Running tests..."
./gradlew test --quiet
echo "  Tests passed."

# Step 2: Build the application
echo "[2/4] Building application..."
./gradlew bootJar --quiet
echo "  Build complete."

# Step 3: Build Docker image
echo "[3/4] Building Docker image..."
docker build -t ${APP_NAME} .
echo "  Image built: $(docker images ${APP_NAME} --format '{{.Size}}')"

# Step 4: Stop existing container and start new one
echo "[4/4] Starting container on port ${APP_PORT}..."
docker stop ${APP_NAME} 2>/dev/null || true
docker rm ${APP_NAME} 2>/dev/null || true
docker run -d \
  --name ${APP_NAME} \
  -p ${APP_PORT}:8080 \
  --restart unless-stopped \
  ${APP_NAME}

echo ""
echo "=== Deploy complete ==="
echo "App running at: http://localhost:${APP_PORT}"
echo "Run './scripts/local-check.sh' to verify."
