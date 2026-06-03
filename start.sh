#!/usr/bin/env bash
set -Eeuo pipefail

: "${AGENT_ENDPOINT:?Environment variable AGENT_ENDPOINT is required}"
: "${AGENT_TOKEN:?Environment variable AGENT_TOKEN is required}"

HEALTH_PORT=8000
MAX_RETRIES=999999
RECONNECT_INTERVAL=10
REPORT_INTERVAL=5.0
INFO_REPORT_INTERVAL=15

mkdir -p /www
printf "ok\n" > /www/index.html
printf "ok\n" > /www/healthz

echo "Starting health server on 0.0.0.0:${HEALTH_PORT}..."

python3 -m http.server "${HEALTH_PORT}" \
  --bind 0.0.0.0 \
  --directory /www \
  >/tmp/health-server.log 2>&1 &

HEALTH_PID=$!

sleep 1

if ! kill -0 "${HEALTH_PID}" 2>/dev/null; then
  echo "Health server failed to start."
  echo "Health server log:"
  cat /tmp/health-server.log 2>/dev/null || true
  exit 1
fi

STOPPING=0
AGENT_PID=""

shutdown() {
  STOPPING=1
  echo "shutting down gracefully..."

  if [[ -n "${AGENT_PID}" ]]; then
    kill -TERM "${AGENT_PID}" 2>/dev/null || true
  fi

  kill -TERM "${HEALTH_PID}" 2>/dev/null || true

  if [[ -n "${AGENT_PID}" ]]; then
    wait "${AGENT_PID}" 2>/dev/null || true
  fi

  wait "${HEALTH_PID}" 2>/dev/null || true
  exit 0
}

trap shutdown TERM INT

echo "Starting Komari Agent..."
echo "Endpoint: ${AGENT_ENDPOINT}"
echo "WebSSH: enabled"
echo "Auto update: enabled"

while true; do
  /usr/local/bin/komari-agent \
    --endpoint "${AGENT_ENDPOINT}" \
    --token "${AGENT_TOKEN}" \
    --max-retries "${MAX_RETRIES}" \
    --reconnect-interval "${RECONNECT_INTERVAL}" \
    --interval "${REPORT_INTERVAL}" \
    --info-report-interval "${INFO_REPORT_INTERVAL}" &

  AGENT_PID=$!

  set +e
  wait "${AGENT_PID}"
  EXIT_CODE=$?
  set -e

  if [[ "${STOPPING}" -eq 1 ]]; then
    exit 0
  fi

  echo "Komari Agent exited with code ${EXIT_CODE}."

  if ! kill -0 "${HEALTH_PID}" 2>/dev/null; then
    echo "Health server is not running, exiting."
    cat /tmp/health-server.log 2>/dev/null || true
    exit 1
  fi

  echo "Restarting Komari Agent in 5 seconds..."
  sleep 5
done
