#!/bin/bash

# 작업 래퍼 스크립트
# Claude Code 작업 전후로 자동 알림을 전송하는 래퍼
# 사용법: ./task-wrapper.sh "작업 설명" "실행할 명령어"

WEBHOOK_SERVER="http://localhost:3000/webhook"
PROJECT_NAME=$(basename "$(pwd)")

TASK_SUMMARY="${1:-작업 수행 중}"
COMMAND="${2:-echo 'No command specified'}"

START_TIME=$(date +%s%3N)
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

# 작업 시작 알림
echo "📨 작업 시작 알림 전송 중..."
curl -X POST "$WEBHOOK_SERVER" \
    -H "Content-Type: application/json" \
    -s -o /dev/null \
    -d "{
        \"type\": \"task_start\",
        \"projectName\": \"$PROJECT_NAME\",
        \"taskSummary\": \"$TASK_SUMMARY\",
        \"timestamp\": \"$TIMESTAMP\"
    }"

# 명령어 실행
echo "🚀 작업 실행: $COMMAND"
eval "$COMMAND"
EXIT_CODE=$?

END_TIME=$(date +%s%3N)
DURATION=$((END_TIME - START_TIME))
END_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")

# 변경된 파일 목록 가져오기 (Git 사용 시)
if git rev-parse --git-dir > /dev/null 2>&1; then
    CHANGED_FILES=$(git diff --name-status HEAD 2>/dev/null | awk '{
        status = ($1=="M" ? "modified" : ($1=="A" ? "added" : "deleted"));
        printf "{\"path\":\"%s\",\"status\":\"%s\"},", $2, status
    }' | sed 's/,$//')
    CHANGED_FILES="[${CHANGED_FILES}]"
else
    CHANGED_FILES="[]"
fi

# 결과에 따라 완료 또는 에러 알림
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ 작업 완료 알림 전송 중..."
    curl -X POST "$WEBHOOK_SERVER" \
        -H "Content-Type: application/json" \
        -s -o /dev/null \
        -d "{
            \"type\": \"task_complete\",
            \"projectName\": \"$PROJECT_NAME\",
            \"taskSummary\": \"$TASK_SUMMARY\",
            \"timestamp\": \"$END_TIMESTAMP\",
            \"duration\": $DURATION,
            \"changedFiles\": $CHANGED_FILES
        }"
    echo "✅ 작업이 성공적으로 완료되었습니다!"
else
    echo "❌ 에러 알림 전송 중..."
    curl -X POST "$WEBHOOK_SERVER" \
        -H "Content-Type: application/json" \
        -s -o /dev/null \
        -d "{
            \"type\": \"task_error\",
            \"projectName\": \"$PROJECT_NAME\",
            \"taskSummary\": \"$TASK_SUMMARY\",
            \"timestamp\": \"$END_TIMESTAMP\",
            \"error\": \"명령어 실행 실패 (종료 코드: $EXIT_CODE)\"
        }"
    echo "❌ 작업이 실패했습니다 (종료 코드: $EXIT_CODE)"
fi

exit $EXIT_CODE
