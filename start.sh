#!/usr/bin/env bash
set -Eeuo pipefail

: "${AGENT_ENDPOINT:?请设置 AGENT_ENDPOINT}"
: "${AGENT_TOKEN:?请设置 AGENT_TOKEN}"

export AGENT_DISABLE_WEB_SSH="${AGENT_DISABLE_WEB_SSH:-true}"
export AGENT_DISABLE_AUTO_UPDATE="${AGENT_DISABLE_AUTO_UPDATE:-true}"
export AGENT_MAX_RETRIES="${AGENT_MAX_RETRIES:-999999}"
export AGENT_RECONNECT_INTERVAL="${AGENT_RECONNECT_INTERVAL:-10}"
export AGENT_INTERVAL="${AGENT_INTERVAL:-5.0}"
export AGENT_INFO_REPORT_INTERVAL="${AGENT_INFO_REPORT_INTERVAL:-15}"

HEALTH_PORT="${HEALTH_PORT:-${PORT:-8000}}"

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

echo "Starting Komari Agent..."
echo "Endpoint: ${AGENT_ENDPOINT}"

/usr/local/bin/komari-agent &

AGENT_PID=$!

shutdown() {
  echo "shutting down gracefully..."
  kill -TERM "${AGENT_PID}" "${HEALTH_PID}" 2>/dev/null || true
  wait "${AGENT_PID}" 2>/dev/null || true
  wait "${HEALTH_PID}" 2>/dev/null || true
  exit 0
}

trap shutdown TERM INT

set +e
wait -n "${AGENT_PID}" "${HEALTH_PID}"
EXIT_CODE=$?
set -e

echo "A child process exited with code ${EXIT_CODE}, stopping container..."
kill -TERM "${AGENT_PID}" "${HEALTH_PID}" 2>/dev/null || true
wait "${AGENT_PID}" 2>/dev/null || true
wait "${HEALTH_PID}" 2>/dev/null || true

exit "${EXIT_CODE}"
