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
echo "  OpenClaw AI 업무 비서팀 (api / run)"
echo "=================================================="
echo ""

# ── 1. GitHub 환경변수 처리 (선택) ──────────────────────────
section "Git 설정"

if [ -n "${GITHUB_USERNAME:-}" ] && [ -n "${GITHUB_EMAIL:-}" ] && [ -n "${GITHUB_TOKEN:-}" ]; then
  git config --global user.name  "$GITHUB_USERNAME"
  git config --global user.email "$GITHUB_EMAIL"
  git config --global credential.helper store
  echo "https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com" > ~/.git-credentials
  chmod 600 ~/.git-credentials
  info "Git 설정 완료"
else
  warn "GITHUB_USERNAME / GITHUB_EMAIL / GITHUB_TOKEN 미설정 — Git 인증 없이 진행"
fi

# ── 2. API 키 감지 및 모델 선택 ─────────────────────────────
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

# ── 3. OpenClaw 모델 설정 ────────────────────────────────────
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

# ── 4. 에이전트 등록 ─────────────────────────────────────────
section "에이전트 등록"

for AGENT in orchestrator mail-agent calendar-agent drive-agent; do
  openclaw agents add "$AGENT" \
    --workspace /workspace \
    --model "${PROVIDER}/${MODEL_ID}" \
    --non-interactive \
    2>/dev/null \
    || info "  ${AGENT}: 이미 등록됨 (스킵)"
done
info "에이전트 등록 완료"

# ── 5. OpenClaw 시작 ─────────────────────────────────────────
section "OpenClaw 시작"

echo ""
echo "=================================================="
echo "  모든 준비 완료. Telegram 봇에 메시지를 보내보세요."
echo "=================================================="
echo ""

exec openclaw start
