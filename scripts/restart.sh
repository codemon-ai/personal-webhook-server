#!/bin/bash

# Claude Code Webhook Server 재시작 스크립트

echo "🔄 Claude Code Webhook Server 재시작 중..."

# 프로젝트 디렉토리로 이동
cd "$(dirname "$0")/.."

# 재빌드 (선택적)
if [ "$1" == "--build" ]; then
    echo "📦 재빌드 중..."
    npm run build
fi

pm2 restart cc-webhook

echo "✅ 서버가 재시작되었습니다!"
echo ""
echo "📝 로그 확인: pm2 logs cc-webhook"
