FROM ubuntu:24.04

ARG KOMARI_AGENT_VERSION=latest

RUN set -eux; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      ca-certificates \
      wget \
      bash \
      python3; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
      amd64) agent_arch="amd64" ;; \
      arm64) agent_arch="arm64" ;; \
      armhf|armel) agent_arch="arm" ;; \
      i386) agent_arch="386" ;; \
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
