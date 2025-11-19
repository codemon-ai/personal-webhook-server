#!/bin/bash

# Claude Code Webhook Server 로그 확인 스크립트

echo "📝 로그를 확인합니다 (Ctrl+C로 종료)..."
echo ""

pm2 logs cc-webhook
