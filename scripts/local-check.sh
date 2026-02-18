#!/bin/bash
set -euo pipefail

APP_PORT=8080
BASE_URL="http://localhost:${APP_PORT}"
PASS=0
FAIL=0

check() {
  local name="$1"
  local url="$2"
  local expected="$3"

  response=$(curl -s -o /dev/null -w "%{http_code}" "${url}" 2>/dev/null || echo "000")

  if [ "${response}" = "${expected}" ]; then
    echo "  PASS  ${name} (${url}) -> ${response}"
    PASS=$((PASS + 1))
  else
    echo "  FAIL  ${name} (${url}) -> ${response} (expected ${expected})"
    FAIL=$((FAIL + 1))
  fi
}

echo "=== Health Check: ArtAc App ==="
echo ""

# Check endpoints
check "Welcome page" "${BASE_URL}/" "200"
check "API Health"   "${BASE_URL}/api/health" "200"
check "Actuator"     "${BASE_URL}/actuator/health" "200"

# Check response body for /api/health
echo ""
echo "--- /api/health response ---"
curl -s "${BASE_URL}/api/health" 2>/dev/null | python3 -m json.tool 2>/dev/null || echo "  (could not reach endpoint)"

# Docker container status
echo ""
echo "--- Docker status ---"
docker ps --filter "name=artac-app" --format "  Container: {{.Names}}  Status: {{.Status}}  Ports: {{.Ports}}" 2>/dev/null || echo "  (no container running)"

# Summary
echo ""
echo "=== Results: ${PASS} passed, ${FAIL} failed ==="

if [ "${FAIL}" -gt 0 ]; then
  exit 1
fi
