#!/usr/bin/env bash
set -euo pipefail

: "${KOMARI_ENDPOINT:?请设置 KOMARI_ENDPOINT}"
: "${KOMARI_TOKEN:?请设置 KOMARI_TOKEN}"

echo "Starting Komari Agent..."
echo "Endpoint: ${KOMARI_ENDPOINT}"

# 如果不需要远程终端/远程命令，建议加 --disable-web-ssh
# shellcheck disable=SC2086
exec /usr/local/bin/komari-agent \
  -e "$KOMARI_ENDPOINT" \
  -t "$KOMARI_TOKEN" \
  ${KOMARI_EXTRA_ARGS:-}
