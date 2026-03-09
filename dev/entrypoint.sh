#!/bin/bash
set -eo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

info()    { echo -e "${GREEN}[INFO]${NC}  $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; }
section() { echo -e "\n${CYAN}▶ $1${NC}"; }

echo ""
echo "=================================================="
echo "  OpenClaw AI 업무 비서팀 (api / dev)"
echo "=================================================="
echo ""

# ── 1. GitHub 환경변수 확인 (필수) ──────────────────────────
section "GitHub 환경변수 확인"

: "${GITHUB_USERNAME:?'GITHUB_USERNAME 이 설정되지 않았습니다 (레포 clone에 필요)'}"
: "${GITHUB_EMAIL:?'GITHUB_EMAIL 이 설정되지 않았습니다'}"
: "${GITHUB_TOKEN:?'GITHUB_TOKEN 이 설정되지 않았습니다 (레포 clone에 필요)'}"

git config --global user.name  "$GITHUB_USERNAME"
git config --global user.email "$GITHUB_EMAIL"
git config --global credential.helper store
echo "https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com" > ~/.git-credentials
chmod 600 ~/.git-credentials
info "Git 설정 완료"

# ── 2. openclaw-api-dev 레포 클론 / 업데이트 ────────────────
section "openclaw-api-dev 레포 준비"

REPO_URL="${OPENCLAW_DEV_REPO:-https://github.com/${GITHUB_USERNAME}/openclaw-api-dev.git}"
REPO_DIR="/workspace/openclaw-api-dev"

if [ -d "$REPO_DIR/.git" ]; then
  info "이미 클론됨 — git pull 로 업데이트 중..."
  git -C "$REPO_DIR" pull
  info "업데이트 완료"
else
  info "클론 중: $REPO_URL"
  git clone "$REPO_URL" "$REPO_DIR"
  info "클론 완료"
fi

# ── 3. OpenClaw 워크스페이스 설정 ───────────────────────────
section "OpenClaw 워크스페이스 설정"

openclaw setup --workspace "$REPO_DIR"
info "워크스페이스 설정 완료"

# ── 4. API 키 감지 및 모델 선택 ─────────────────────────────
section "API 키 감지"

PROVIDER=""
MODEL_ID=""
API_KEY=""

if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
  PROVIDER="anthropic"
  MODEL_ID="claude-sonnet-4-5"
  API_KEY="$ANTHROPIC_API_KEY"
  info "Anthropic API 키 감지됨 → 모델: $MODEL_ID"
elif [ -n "${OPENAI_API_KEY:-}" ]; then
  PROVIDER="openai"
  MODEL_ID="gpt-4o"
  API_KEY="$OPENAI_API_KEY"
  info "OpenAI API 키 감지됨 → 모델: $MODEL_ID"
elif [ -n "${GEMINI_API_KEY:-}" ]; then
  PROVIDER="google"
  MODEL_ID="gemini-2.5-flash"
  API_KEY="$GEMINI_API_KEY"
  info "Gemini API 키 감지됨 → 모델: $MODEL_ID"
else
  error "API 키가 설정되지 않았습니다."
  echo ""
  echo "  셋 중 하나를 설정해 주세요:"
  echo "    ANTHROPIC_API_KEY   (권장: claude-sonnet-4-5)"
  echo "    OPENAI_API_KEY      (gpt-4o)"
  echo "    GEMINI_API_KEY      (gemini-2.5-flash)"
  echo ""
  exit 1
fi

# ── 5. OpenClaw 모델 설정 ────────────────────────────────────
section "OpenClaw 설정"

OPENCLAW_DIR="$HOME/.openclaw"
mkdir -p "$OPENCLAW_DIR"

cat > "$OPENCLAW_DIR/openclaw.json" << EOF
{
  "models": {
    "mode": "merge",
    "providers": {
      "${PROVIDER}": {
        "apiKey": "${API_KEY}"
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "${PROVIDER}/${MODEL_ID}"
      }
    }
  },
  "channels": {
    "telegram": {
      "botToken": "${TELEGRAM_BOT_TOKEN}",
      "dmPolicy": "open",
      "allowFrom": ["*"]
    }
  },
  "env": {
    "GOOGLE_CLIENT_ID": "${GOOGLE_CLIENT_ID}",
    "GOOGLE_CLIENT_SECRET": "${GOOGLE_CLIENT_SECRET}",
    "GOOGLE_REFRESH_TOKEN": "${GOOGLE_REFRESH_TOKEN}"
  },
  "gateway": {
    "mode": "local"
  }
}
EOF
info "openclaw.json 설정 완료 (모델: ${PROVIDER}/${MODEL_ID})"

# ── 6. 에이전트 등록 ─────────────────────────────────────────
section "에이전트 등록"

if [ -f "$REPO_DIR/setup-agent.sh" ]; then
  info "setup-agent.sh 발견 — 실행 중..."
  bash "$REPO_DIR/setup-agent.sh"
else
  info "setup-agent.sh 없음 — 직접 등록 중..."
  for AGENT in orchestrator mail-agent calendar-agent drive-agent; do
    openclaw agents add "$AGENT" \
      --workspace "$REPO_DIR" \
      --model "${PROVIDER}/${MODEL_ID}" \
      --non-interactive \
      2>/dev/null \
      || info "  ${AGENT}: 이미 등록됨 (스킵)"
  done
fi
info "에이전트 등록 완료"

# ── 7. OpenClaw 시작 ─────────────────────────────────────────
section "OpenClaw 시작"

echo ""
echo "=================================================="
echo "  모든 준비 완료. Telegram 봇에 메시지를 보내보세요."
echo "=================================================="
echo ""

exec openclaw start
