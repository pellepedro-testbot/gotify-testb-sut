#!/bin/bash
set -euo pipefail

GOTIFY_URL="http://localhost:8080"
ADMIN_USER="admin"
ADMIN_PASS="testbot-admin"

# Wait for server to be ready
echo "Waiting for gotify server at ${GOTIFY_URL}..." >&2
timeout=300
elapsed=0
until curl -sf "${GOTIFY_URL}/health" > /dev/null 2>&1; do
  if [ "$elapsed" -ge "$timeout" ]; then
    echo "Timeout: gotify server did not become healthy within ${timeout}s" >&2
    exit 1
  fi
  sleep 5
  elapsed=$((elapsed + 5))
done
echo "Server is ready" >&2

# Create a client token using HTTP Basic auth
echo "Creating testbot client token..." >&2
RESPONSE=$(curl -sf -X POST "${GOTIFY_URL}/client" \
  -H "Content-Type: application/json" \
  -u "${ADMIN_USER}:${ADMIN_PASS}" \
  -d '{"name": "testbot-client"}') || { echo "Failed to create client token" >&2; exit 1; }

TOKEN=$(echo "$RESPONSE" | jq -r '.token')

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "Unexpected response: $RESPONSE" >&2
  exit 1
fi

# Seed test applications and messages for list endpoint coverage
echo "Seeding test data..." >&2
for i in 1 2 3; do
  APP_RESPONSE=$(curl -sf -X POST "${GOTIFY_URL}/application" \
    -H "Content-Type: application/json" \
    -H "X-Gotify-Key: ${TOKEN}" \
    -d "{\"name\": \"testbot-app-${i}\", \"description\": \"Testbot application ${i}\"}" 2>/dev/null) || { echo "seed app ${i} failed" >&2; continue; }

  APP_TOKEN=$(echo "$APP_RESPONSE" | jq -r '.token' 2>/dev/null) || continue

  if [ -n "$APP_TOKEN" ] && [ "$APP_TOKEN" != "null" ]; then
    for j in 1 2 3; do
      curl -sf -X POST "${GOTIFY_URL}/message" \
        -H "Content-Type: application/json" \
        -H "X-Gotify-Key: ${APP_TOKEN}" \
        -d "{\"title\": \"Test message ${j}\", \"message\": \"Testbot message ${j} for app ${i}\", \"priority\": ${j}}" \
        > /dev/null 2>&1 || echo "seed message ${j} for app ${i} failed" >&2
    done
  fi
done
echo "Seeding complete" >&2

# Print the client token to stdout (captured by testbot as auth credential)
echo "$TOKEN"
