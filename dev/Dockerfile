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
ENV PATH="/root/.npm-global/bin:$PATH"
RUN npm config set prefix '/root/.npm-global'
RUN npm install -g openclaw

# agents/skills 없음 — 컨테이너 시작 시 레포를 git clone해서 사용

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
