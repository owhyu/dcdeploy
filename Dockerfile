FROM ubuntu:24.04

ARG KOMARI_AGENT_VERSION=latest
ENV DEBIAN_FRONTEND=noninteractive

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends ca-certificates wget bash; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
      amd64) agent_arch="amd64" ;; \
      arm64) agent_arch="arm64" ;; \
      armhf) agent_arch="arm" ;; \
      i386) agent_arch="386" ;; \
      *) echo "Unsupported architecture: $arch" >&2; exit 1 ;; \
    esac; \
    if [ "$KOMARI_AGENT_VERSION" = "latest" ]; then \
      url="https://github.com/komari-monitor/komari-agent/releases/latest/download/komari-agent-linux-${agent_arch}"; \
    else \
      url="https://github.com/komari-monitor/komari-agent/releases/download/${KOMARI_AGENT_VERSION}/komari-agent-linux-${agent_arch}"; \
    fi; \
    wget -qO /usr/local/bin/komari-agent "$url"; \
    chmod +x /usr/local/bin/komari-agent; \
    rm -rf /var/lib/apt/lists/*

COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

ENTRYPOINT ["/usr/local/bin/start.sh"]
