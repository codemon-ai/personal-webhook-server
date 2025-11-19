#!/bin/bash

# Claude Code Webhook Server 중지 스크립트

echo "⏹️  Claude Code Webhook Server 중지 중..."

pm2 stop cc-webhook

echo "✅ 서버가 중지되었습니다!"
echo ""
echo "💡 서버를 다시 시작하려면: ./scripts/start.sh"
