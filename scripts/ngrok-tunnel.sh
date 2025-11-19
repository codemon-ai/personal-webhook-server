#!/bin/bash

# ngrok 터널 스크립트
# PM2에서 실행되어 웹훅 서버를 외부에 노출

# 환경 변수 로드
if [ -f "$(dirname "$0")/../.env" ]; then
    export $(cat "$(dirname "$0")/../.env" | grep -v '^#' | xargs)
fi

# ngrok authtoken 확인
if [ -z "$NGROK_AUTHTOKEN" ]; then
    echo "❌ 오류: NGROK_AUTHTOKEN 환경 변수가 설정되지 않았습니다."
    echo "   .env 파일에 NGROK_AUTHTOKEN을 설정해주세요."
    exit 1
fi

# ngrok 설치 확인
if ! command -v ngrok &> /dev/null; then
    echo "❌ 오류: ngrok이 설치되지 않았습니다."
    echo "   설치: brew install ngrok"
    exit 1
fi

# authtoken 설정
echo "🔑 ngrok authtoken 설정 중..."
ngrok config add-authtoken "$NGROK_AUTHTOKEN"

# 포트 확인
PORT=${PORT:-4000}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 ngrok 터널 시작"
echo "📍 로컬 포트: $PORT"

# 고정 도메인 사용 (설정된 경우)
if [ -n "$NGROK_DOMAIN" ]; then
    echo "🔗 고정 도메인: $NGROK_DOMAIN"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ngrok http --domain="$NGROK_DOMAIN" "$PORT"
else
    echo "🔗 랜덤 도메인 사용"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    ngrok http "$PORT"
fi
