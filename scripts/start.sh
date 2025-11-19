#!/bin/bash

# Claude Code Webhook Server 시작 스크립트

echo "🚀 Claude Code Webhook Server 시작 중..."

# 프로젝트 디렉토리로 이동
cd "$(dirname "$0")/.."

# 환경 변수 로드
if [ -f ".env" ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# 빌드 확인
if [ ! -d "dist" ]; then
    echo "📦 빌드 파일이 없습니다. 빌드를 시작합니다..."
    npm run build
fi

# logs 디렉토리 생성
mkdir -p logs

# ngrok 설치 확인
NGROK_ENABLED=false
if [ -n "$NGROK_AUTHTOKEN" ]; then
    if command -v ngrok &> /dev/null; then
        NGROK_ENABLED=true
        echo "🌐 ngrok 터널이 함께 시작됩니다..."
    else
        echo "⚠️  ngrok이 설치되지 않았습니다. 로컬에서만 접근 가능합니다."
        echo "   설치: brew install ngrok"
    fi
fi

# PM2로 서버 시작
pm2 start ecosystem.config.js

echo ""
echo "✅ 서버가 시작되었습니다!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 서버 관리 명령어"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  상태 확인:    pm2 status"
echo "  로그 확인:    pm2 logs cc-webhook"
echo "  재시작:      pm2 restart cc-webhook"
echo "  중지:        pm2 stop cc-webhook"

if [ "$NGROK_ENABLED" = true ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🌐 ngrok 관리"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  URL 확인:    ./scripts/ngrok-url.sh"
    echo "  로그 확인:   pm2 logs cc-webhook-ngrok"
    echo "  재시작:      pm2 restart cc-webhook-ngrok"
    echo "  중지:        pm2 stop cc-webhook-ngrok"
    echo ""
    echo "💡 잠시 후 ngrok URL을 확인하세요:"
    echo "   ./scripts/ngrok-url.sh"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💡 부팅 시 자동 시작 설정"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "   pm2 startup && pm2 save"
echo ""
