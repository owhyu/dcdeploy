#!/usr/bin/env bash
set -Eeuo pipefail

: "${AGENT_ENDPOINT:?请设置 AGENT_ENDPOINT}"
: "${AGENT_TOKEN:?请设置 AGENT_TOKEN}"

# DCDeploy 健康检查端口，固定 8000，不需要写环境变量
HEALTH_PORT=8000

# Komari Agent 参数，直接写死在脚本里，不需要写环境变量
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

echo "Starting Komari Agent..."
echo "Endpoint: ${AGENT_ENDPOINT}"

/usr/local/bin/komari-agent \
  --endpoint "${AGENT_ENDPOINT}" \
  --token "${AGENT_TOKEN}" \
  --max-retries "${MAX_RETRIES}" \
  --reconnect-interval "${RECONNECT_INTERVAL}" \
  --interval "${REPORT_INTERVAL}" \
  --info-report-interval "${INFO_REPORT_INTERVAL}" &

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
