# openclaw-api-image

**AI 업무 비서팀** — Telegram 봇 하나로 Gmail·Google Calendar·Google Drive를 AI가 처리합니다.

OpenClaw 기반 오케스트레이션 멀티 에이전트 구조.
Claude / GPT-4o / Gemini 외부 API를 사용하므로 **GPU 없이 일반 서버에서 바로 실행**됩니다.

> Docker 이미지 버전 — 환경변수만 넣으면 바로 실행됩니다.
> 스크립트 설치 버전은 [openclaw-api-dev](https://github.com/your-org/openclaw-api-dev)를 참고하세요.

---

## run vs dev

| | run | dev |
|---|---|---|
| 대상 | 비개발자 | 개발자 |
| agents/skills | 이미지 내장 | 레포 git clone |
| GitHub 자격증명 | 선택 | 필수 |
| 이미지 빌드 | GitHub Actions 자동 | GitHub Actions 자동 |
| 커스터마이징 | 이미지 재빌드 필요 | 레포 수정 후 재시작 |

---

## 지원 모델

| 우선순위 | 환경변수 | 모델 | 특징 |
|---|---|---|---|
| 1순위 | `ANTHROPIC_API_KEY` | `claude-sonnet-4-5` | OpenClaw 공식 추천, 프롬프트 인젝션 저항 최강 |
| 2순위 | `OPENAI_API_KEY` | `gpt-4o` | 검증된 안정성, 높은 인지도 |
| 3순위 | `GEMINI_API_KEY` | `gemini-2.5-flash` | 저비용 선택지 |

여러 키가 설정되어 있으면 우선순위 높은 것 하나만 사용됩니다.

> **DeepSeek은 지원하지 않습니다.** 데이터가 외부로 전송되는 프라이버시 이슈로 인해 업무용 에이전트(이메일·일정·문서 접근)에 적합하지 않습니다.

---

## 빠른 시작

### run — 비개발자용

```bash
# 1. .env 작성
cat > .env << 'EOF'
# API 키 (셋 중 하나)
ANTHROPIC_API_KEY=sk-ant-...
# OPENAI_API_KEY=sk-...
# GEMINI_API_KEY=AI...

# Telegram
TELEGRAM_BOT_TOKEN=your-bot-token

# Google OAuth
GOOGLE_CLIENT_ID=your-client-id
GOOGLE_CLIENT_SECRET=your-client-secret
GOOGLE_REFRESH_TOKEN=your-refresh-token

# GitHub (선택)
# GITHUB_USERNAME=your-github-id
# GITHUB_EMAIL=your@email.com
# GITHUB_TOKEN=your-github-token
EOF

# 2. 실행
cd run
docker compose --env-file ../.env up -d
```

### dev — 개발자용

```bash
# 1. .env 작성
cat > .env << 'EOF'
# GitHub (필수)
GITHUB_USERNAME=your-github-id
GITHUB_EMAIL=your@email.com
GITHUB_TOKEN=your-github-token

# API 키 (셋 중 하나)
ANTHROPIC_API_KEY=sk-ant-...

# Telegram
TELEGRAM_BOT_TOKEN=your-bot-token

# Google OAuth
GOOGLE_CLIENT_ID=your-client-id
GOOGLE_CLIENT_SECRET=your-client-secret
GOOGLE_REFRESH_TOKEN=your-refresh-token

# 선택 — 기본값: https://github.com/$GITHUB_USERNAME/openclaw-api-dev.git
# OPENCLAW_DEV_REPO=https://github.com/your-org/openclaw-api-dev.git
EOF

# 2. 실행
cd dev
docker compose --env-file ../.env up -d
```

---

## GitHub Actions 자동 빌드

ollama-image와 달리 이미지 크기가 작아 **run/dev 모두 GitHub Actions로 자동 빌드**됩니다.

| 워크플로우 | 트리거 | 이미지 |
|---|---|---|
| `build-run.yml` | `run/**` 변경 또는 수동 | `ghcr.io/{owner}/openclaw-api-image-run` |
| `build-dev.yml` | `dev/**` 변경 또는 수동 | `ghcr.io/{owner}/openclaw-api-image-dev` |

이 레포를 fork하면 자신의 ghcr.io 네임스페이스에 자동으로 이미지가 빌드됩니다.

---

## Gcube에서 실행하는 방법

```bash
# 1. 서버 접속 후 docker compose 설치 확인
docker compose version

# 2. 이 레포 클론
git clone https://github.com/your-org/openclaw-api-image.git
cd openclaw-api-image

# 3. .env 작성 (위 빠른 시작 참고)

# 4. run 버전 실행
cd run
docker compose --env-file ../.env up -d

# 5. 로그 확인
docker compose logs -f
```

GPU가 필요 없으므로 Gcube의 CPU 전용 인스턴스에서도 실행 가능합니다.

---

## 환경변수

| 변수명 | run | dev | 설명 |
|---|---|---|---|
| `ANTHROPIC_API_KEY` | 셋 중 하나 | 셋 중 하나 | Anthropic API 키 |
| `OPENAI_API_KEY` | 셋 중 하나 | 셋 중 하나 | OpenAI API 키 |
| `GEMINI_API_KEY` | 셋 중 하나 | 셋 중 하나 | Google Gemini API 키 |
| `TELEGRAM_BOT_TOKEN` | 필수 | 필수 | Telegram BotFather에서 발급 |
| `GOOGLE_CLIENT_ID` | 필수 | 필수 | Google Cloud Console에서 발급 |
| `GOOGLE_CLIENT_SECRET` | 필수 | 필수 | Google Cloud Console에서 발급 |
| `GOOGLE_REFRESH_TOKEN` | 필수 | 필수 | OAuth 인증 후 발급 |
| `GITHUB_USERNAME` | 선택 | 필수 | GitHub 사용자명 |
| `GITHUB_EMAIL` | 선택 | 필수 | GitHub 이메일 |
| `GITHUB_TOKEN` | 선택 | 필수 | GitHub Personal Access Token |
| `OPENCLAW_DEV_REPO` | — | 선택 | 클론할 레포 URL (dev만) |

---

## 파일 구조

```
openclaw-api-image/
├── README.md
├── .github/
│   └── workflows/
│       ├── build-run.yml             # run 이미지 GitHub Actions 자동 빌드
│       └── build-dev.yml             # dev 이미지 GitHub Actions 자동 빌드
├── run/                              # 비개발자용
│   ├── Dockerfile
│   ├── docker-compose.yml
│   ├── entrypoint.sh
│   ├── agents/
│   │   ├── orchestrator/AGENTS.md
│   │   ├── mail/AGENTS.md
│   │   ├── calendar/AGENTS.md
│   │   └── drive/AGENTS.md
│   └── skills/
│       ├── gmail/SKILL.md
│       ├── calendar/SKILL.md
│       └── drive/SKILL.md
└── dev/                              # 개발자용
    ├── Dockerfile
    ├── docker-compose.yml
    └── entrypoint.sh
```

---

## 관련 레포

| 레포 | 설명 |
|---|---|
| [openclaw-ollama-dev](https://github.com/your-org/openclaw-ollama-dev) | Ollama 로컬 모델 버전 (GPU 필요, API 비용 없음) |
| [openclaw-ollama-image](https://github.com/your-org/openclaw-ollama-image) | Ollama 버전 Docker 이미지 |
| [openclaw-api-dev](https://github.com/your-org/openclaw-api-dev) | 외부 API 버전 스크립트 설치 |
| openclaw-api-image | 이 레포 — 외부 API 버전 Docker 이미지 |

---

## 라이선스

MIT
