#!/bin/bash

# Claude Code Hook 예제
# 이 스크립트를 각 프로젝트의 .claude/ 디렉토리에 복사하여 사용하세요
# 예: .claude/user-prompt-submit-hook

# 웹훅 서버 URL
WEBHOOK_SERVER="http://localhost:3000/webhook"

# 현재 프로젝트 이름 (디렉토리 이름 사용)
PROJECT_NAME=$(basename "$(pwd)")

# Claude Code에서 전달된 사용자 입력 (환경 변수로 전달됨)
USER_INPUT="${CLAUDE_USER_INPUT:-작업 수행 중...}"

# 긴 작업 감지 키워드 (필요에 따라 수정)
LONG_TASK_KEYWORDS=("build" "test" "deploy" "install" "migration" "빌드" "테스트" "배포" "설치")

# 긴 작업인지 확인
is_long_task=false
for keyword in "${LONG_TASK_KEYWORDS[@]}"; do
    if echo "$USER_INPUT" | grep -qi "$keyword"; then
        is_long_task=true
        break
    fi
done

# 긴 작업이면 알림 전송
if [ "$is_long_task" = true ]; then
    curl -X POST "$WEBHOOK_SERVER" \
        -H "Content-Type: application/json" \
        -s -o /dev/null \
        -d "{
            \"type\": \"task_start\",
            \"projectName\": \"$PROJECT_NAME\",
            \"taskSummary\": \"$USER_INPUT\",
            \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")\"
        }"
fi

# Hook은 항상 성공해야 함 (0 반환)
exit 0
