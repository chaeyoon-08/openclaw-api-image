FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Node.js 20 + 기본 도구 설치
RUN apt-get update && apt-get install -y \
    curl \
    git \
    ca-certificates \
    && curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# OpenClaw 설치
RUN npm install -g openclaw

# OpenClaw 워크스페이스 초기화
RUN openclaw setup --workspace /workspace

# agents/skills 내장 (run 버전 핵심: 이미지에 포함)
COPY agents/ /workspace/agents/
COPY skills/ /workspace/skills/

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
