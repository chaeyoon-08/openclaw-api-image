FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Node.js 22 + 기본 도구 설치
RUN apt-get update && apt-get install -y \
    curl \
    git \
    ca-certificates \
    build-essential \
    python3 \
    && curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# OpenClaw 설치
ENV PATH="/root/.npm-global/bin:$PATH"
RUN npm config set prefix '/root/.npm-global'
RUN npm install -g openclaw@latest

# OpenClaw 워크스페이스 초기화
RUN openclaw setup --workspace /workspace

# agents/skills 내장 (run 버전 핵심: 이미지에 포함)
COPY agents/ /workspace/agents/
COPY skills/ /workspace/skills/

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
