#!/bin/bash

# ngrok 퍼블릭 URL 확인 스크립트

echo "🌐 ngrok 터널 URL 확인 중..."
echo ""

# ngrok API를 통해 현재 활성화된 터널 정보 가져오기
NGROK_API="http://localhost:4040/api/tunnels"

if ! curl -s "$NGROK_API" > /dev/null 2>&1; then
    echo "❌ ngrok이 실행 중이지 않거나 API에 접근할 수 없습니다."
    echo ""
    echo "확인 사항:"
    echo "  1. ngrok이 실행 중인지 확인: pm2 status cc-webhook-ngrok"
    echo "  2. ngrok 로그 확인: pm2 logs cc-webhook-ngrok"
    echo "  3. ngrok 재시작: pm2 restart cc-webhook-ngrok"
    exit 1
fi

# JSON 파싱하여 퍼블릭 URL 추출
TUNNELS=$(curl -s "$NGROK_API" | grep -o '"public_url":"[^"]*"' | cut -d'"' -f4)

if [ -z "$TUNNELS" ]; then
    echo "⚠️  활성화된 터널을 찾을 수 없습니다."
    echo ""
    echo "ngrok 로그를 확인하세요:"
    echo "  pm2 logs cc-webhook-ngrok"
    exit 1
fi

echo "✅ 활성화된 ngrok 터널:"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for url in $TUNNELS; do
    if [[ $url == https* ]]; then
        WEBHOOK_URL="${url}/webhook"
        echo "🔗 HTTPS: $url"
        echo "📨 Webhook: $WEBHOOK_URL"
        echo ""
    fi
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 다른 프로젝트에서 이 URL을 사용하여 알림을 보낼 수 있습니다."
echo ""
echo "테스트 명령어:"
echo "  curl -X POST $WEBHOOK_URL \\"
echo "    -H \"Content-Type: application/json\" \\"
echo "    -d '{\"type\":\"task_complete\",\"projectName\":\"test\",\"taskSummary\":\"테스트\",\"timestamp\":\"'$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")'\"}'"
echo ""
echo "📊 ngrok 웹 UI: http://localhost:4040"
