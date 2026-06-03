FROM ubuntu:24.04

ARG KOMARI_AGENT_VERSION=latest

ENV DEBIAN_FRONTEND=noninteractive \
    HEALTH_PORT=8000

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates wget bash python3; \
    arch="$(uname -m)"; \
    case "$arch" in \
      x86_64) agent_arch="amd64" ;; \
      aarch64|arm64) agent_arch="arm64" ;; \
      i386|i686) agent_arch="386" ;; \
      armv7*|armv6*) agent_arch="arm" ;; \
      *) echo "Unsupported architecture: $arch" >&2; exit 1 ;; \
    esac; \
    if [ "$KOMARI_AGENT_VERSION" = "latest" ]; then \
      download_url="https://github.com/komari-monitor/komari-agent/releases/latest/download/komari-agent-linux-${agent_arch}"; \
    else \
      download_url="https://github.com/komari-monitor/komari-agent/releases/download/${KOMARI_AGENT_VERSION}/komari-agent-linux-${agent_arch}"; \
    fi; \
    echo "Downloading Komari Agent from: ${download_url}"; \
    wget -qO /usr/local/bin/komari-agent "$download_url"; \
    chmod +x /usr/local/bin/komari-agent; \
    mkdir -p /www; \
    printf "ok\n" > /www/index.html; \
    printf "ok\n" > /www/healthz; \
    rm -rf /var/lib/apt/lists/*

COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

EXPOSE 8000

ENTRYPOINT ["/usr/local/bin/start.sh"]
