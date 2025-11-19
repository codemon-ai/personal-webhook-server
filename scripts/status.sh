#!/bin/bash

# Claude Code Webhook Server 상태 확인 스크립트

echo "📊 서버 상태 확인"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

pm2 status cc-webhook

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💡 상세 정보: pm2 info cc-webhook"
echo "📝 로그 확인: pm2 logs cc-webhook"
