#!/bin/bash

# 웹훅 서버 테스트 스크립트
# 사용법: ./test-webhook.sh [all|start|complete|error|menu]

WEBHOOK_URL="http://localhost:3200/webhook"
PROJECT_NAME="테스트 프로젝트"

# 색상 코드
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 헤더 출력
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🧪 Claude Code Webhook 테스트${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 현재 시간 (ISO 8601)
get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%S.000Z"
}

# 1. 작업 시작 알림 테스트
test_task_start() {
    echo -e "${YELLOW}📤 작업 시작 알림 전송 중...${NC}"

    response=$(curl -s -X POST "$WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -w "\nHTTP_CODE:%{http_code}" \
        -d "{
            \"type\": \"task_start\",
            \"projectName\": \"$PROJECT_NAME\",
            \"taskSummary\": \"긴 작업을 시작합니다 (데이터베이스 마이그레이션)\",
            \"timestamp\": \"$(get_timestamp)\"
        }")

    http_code=$(echo "$response" | grep "HTTP_CODE" | cut -d':' -f2)
    body=$(echo "$response" | sed '/HTTP_CODE/d')

    if [ "$http_code" = "200" ]; then
        echo -e "${GREEN}✅ 성공: $body${NC}"
    else
        echo -e "${RED}❌ 실패 (HTTP $http_code): $body${NC}"
    fi
    echo ""
}

# 2. 작업 완료 알림 테스트
test_task_complete() {
    echo -e "${YELLOW}📤 작업 완료 알림 전송 중...${NC}"

    response=$(curl -s -X POST "$WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -w "\nHTTP_CODE:%{http_code}" \
        -d "{
            \"type\": \"task_complete\",
            \"projectName\": \"$PROJECT_NAME\",
            \"taskSummary\": \"새로운 사용자 인증 기능 구현 완료\",
            \"timestamp\": \"$(get_timestamp)\",
            \"duration\": 125000,
            \"changedFiles\": [
                {\"path\": \"src/auth/login.ts\", \"status\": \"added\"},
                {\"path\": \"src/auth/register.ts\", \"status\": \"added\"},
                {\"path\": \"src/middleware/auth.ts\", \"status\": \"modified\"},
                {\"path\": \"src/routes/user.ts\", \"status\": \"modified\"},
                {\"path\": \"tests/auth.test.ts\", \"status\": \"added\"}
            ]
        }")

    http_code=$(echo "$response" | grep "HTTP_CODE" | cut -d':' -f2)
    body=$(echo "$response" | sed '/HTTP_CODE/d')

    if [ "$http_code" = "200" ]; then
        echo -e "${GREEN}✅ 성공: $body${NC}"
    else
        echo -e "${RED}❌ 실패 (HTTP $http_code): $body${NC}"
    fi
    echo ""
}

# 3. 에러 알림 테스트
test_task_error() {
    echo -e "${YELLOW}📤 에러 알림 전송 중...${NC}"

    response=$(curl -s -X POST "$WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -w "\nHTTP_CODE:%{http_code}" \
        -d "{
            \"type\": \"task_error\",
            \"projectName\": \"$PROJECT_NAME\",
            \"taskSummary\": \"TypeScript 컴파일 실패\",
            \"timestamp\": \"$(get_timestamp)\",
            \"error\": \"src/server.ts:42:15 - error TS2345: Argument of type 'string' is not assignable to parameter of type 'number'.\"
        }")

    http_code=$(echo "$response" | grep "HTTP_CODE" | cut -d':' -f2)
    body=$(echo "$response" | sed '/HTTP_CODE/d')

    if [ "$http_code" = "200" ]; then
        echo -e "${GREEN}✅ 성공: $body${NC}"
    else
        echo -e "${RED}❌ 실패 (HTTP $http_code): $body${NC}"
    fi
    echo ""
}

# 4. 헬스 체크 테스트
test_health_check() {
    echo -e "${YELLOW}📤 헬스 체크 요청 중...${NC}"

    response=$(curl -s -X GET "http://localhost:3200/health" \
        -w "\nHTTP_CODE:%{http_code}")

    http_code=$(echo "$response" | grep "HTTP_CODE" | cut -d':' -f2)
    body=$(echo "$response" | sed '/HTTP_CODE/d')

    if [ "$http_code" = "200" ]; then
        echo -e "${GREEN}✅ 서버 상태: 정상${NC}"
        echo -e "   응답: $body"
    else
        echo -e "${RED}❌ 서버 상태: 이상 (HTTP $http_code)${NC}"
    fi
    echo ""
}

# 5. 잘못된 요청 테스트 (필수 필드 누락)
test_invalid_request() {
    echo -e "${YELLOW}📤 잘못된 요청 테스트 (필수 필드 누락)...${NC}"

    response=$(curl -s -X POST "$WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -w "\nHTTP_CODE:%{http_code}" \
        -d "{
            \"type\": \"task_complete\",
            \"projectName\": \"$PROJECT_NAME\"
        }")

    http_code=$(echo "$response" | grep "HTTP_CODE" | cut -d':' -f2)
    body=$(echo "$response" | sed '/HTTP_CODE/d')

    if [ "$http_code" = "400" ]; then
        echo -e "${GREEN}✅ 올바르게 400 에러 반환${NC}"
        echo -e "   응답: $body"
    else
        echo -e "${RED}❌ 예상과 다른 응답 (HTTP $http_code): $body${NC}"
    fi
    echo ""
}

# 6. 여러 파일 변경 테스트 (10개 이상)
test_many_files() {
    echo -e "${YELLOW}📤 많은 파일 변경 알림 테스트 (15개 파일)...${NC}"

    response=$(curl -s -X POST "$WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -w "\nHTTP_CODE:%{http_code}" \
        -d "{
            \"type\": \"task_complete\",
            \"projectName\": \"$PROJECT_NAME\",
            \"taskSummary\": \"대규모 리팩토링 완료\",
            \"timestamp\": \"$(get_timestamp)\",
            \"duration\": 450000,
            \"changedFiles\": [
                {\"path\": \"src/components/Header.tsx\", \"status\": \"modified\"},
                {\"path\": \"src/components/Footer.tsx\", \"status\": \"modified\"},
                {\"path\": \"src/components/Sidebar.tsx\", \"status\": \"modified\"},
                {\"path\": \"src/pages/Home.tsx\", \"status\": \"modified\"},
                {\"path\": \"src/pages/About.tsx\", \"status\": \"modified\"},
                {\"path\": \"src/pages/Contact.tsx\", \"status\": \"modified\"},
                {\"path\": \"src/utils/format.ts\", \"status\": \"modified\"},
                {\"path\": \"src/utils/validation.ts\", \"status\": \"modified\"},
                {\"path\": \"src/hooks/useAuth.ts\", \"status\": \"modified\"},
                {\"path\": \"src/hooks/useData.ts\", \"status\": \"modified\"},
                {\"path\": \"src/api/client.ts\", \"status\": \"modified\"},
                {\"path\": \"src/api/endpoints.ts\", \"status\": \"added\"},
                {\"path\": \"src/types/user.ts\", \"status\": \"modified\"},
                {\"path\": \"src/types/api.ts\", \"status\": \"added\"},
                {\"path\": \"package.json\", \"status\": \"modified\"}
            ]
        }")

    http_code=$(echo "$response" | grep "HTTP_CODE" | cut -d':' -f2)
    body=$(echo "$response" | sed '/HTTP_CODE/d')

    if [ "$http_code" = "200" ]; then
        echo -e "${GREEN}✅ 성공: $body${NC}"
        echo -e "   ${BLUE}💡 Slack에서 \"...외 5개\" 메시지를 확인하세요${NC}"
    else
        echo -e "${RED}❌ 실패 (HTTP $http_code): $body${NC}"
    fi
    echo ""
}

# 7. 순차 테스트 (시작 -> 완료)
test_sequence() {
    echo -e "${BLUE}📋 순차 테스트: 작업 시작 -> 대기 -> 작업 완료${NC}"
    echo ""

    test_task_start

    echo -e "${YELLOW}⏳ 3초 대기 중...${NC}"
    sleep 3
    echo ""

    test_task_complete
}

# 메뉴 표시
show_menu() {
    echo "테스트 항목을 선택하세요:"
    echo ""
    echo "  1) 작업 시작 알림"
    echo "  2) 작업 완료 알림"
    echo "  3) 에러 알림"
    echo "  4) 헬스 체크"
    echo "  5) 잘못된 요청 (400 에러)"
    echo "  6) 많은 파일 변경 (15개)"
    echo "  7) 순차 테스트 (시작 -> 완료)"
    echo "  8) 전체 테스트"
    echo "  0) 종료"
    echo ""
    read -p "선택 (0-8): " choice

    case $choice in
        1) test_task_start ;;
        2) test_task_complete ;;
        3) test_task_error ;;
        4) test_health_check ;;
        5) test_invalid_request ;;
        6) test_many_files ;;
        7) test_sequence ;;
        8) run_all_tests ;;
        0) echo "종료합니다."; exit 0 ;;
        *) echo -e "${RED}잘못된 선택입니다.${NC}"; echo ""; show_menu ;;
    esac

    # 다시 메뉴 표시
    echo ""
    read -p "계속하려면 Enter를 누르세요..."
    echo ""
    show_menu
}

# 전체 테스트 실행
run_all_tests() {
    echo -e "${BLUE}🚀 전체 테스트 시작${NC}"
    echo ""

    test_health_check
    sleep 1

    test_task_start
    sleep 1

    test_task_complete
    sleep 1

    test_task_error
    sleep 1

    test_many_files
    sleep 1

    test_invalid_request

    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ 모든 테스트 완료!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${BLUE}💡 Slack 채널을 확인하여 알림을 확인하세요!${NC}"
    echo ""
}

# 메인 로직
case "${1:-menu}" in
    all)
        run_all_tests
        ;;
    start)
        test_task_start
        ;;
    complete)
        test_task_complete
        ;;
    error)
        test_task_error
        ;;
    health)
        test_health_check
        ;;
    invalid)
        test_invalid_request
        ;;
    many)
        test_many_files
        ;;
    sequence)
        test_sequence
        ;;
    menu)
        show_menu
        ;;
    *)
        echo "사용법: $0 [all|start|complete|error|health|invalid|many|sequence|menu]"
        echo ""
        echo "  all      - 모든 테스트 실행"
        echo "  start    - 작업 시작 알림 테스트"
        echo "  complete - 작업 완료 알림 테스트"
        echo "  error    - 에러 알림 테스트"
        echo "  health   - 헬스 체크 테스트"
        echo "  invalid  - 잘못된 요청 테스트"
        echo "  many     - 많은 파일 변경 테스트"
        echo "  sequence - 순차 테스트 (시작 -> 완료)"
        echo "  menu     - 대화형 메뉴 (기본값)"
        exit 1
        ;;
esac
