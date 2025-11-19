#!/bin/bash

# Claude Code 작업 완료 알림 전송 예제 스크립트
# 각 프로젝트의 .claude/ 디렉토리 또는 스크립트에서 사용 가능

# 설정
WEBHOOK_SERVER="http://localhost:3000/webhook"
PROJECT_NAME="my-awesome-project"  # 프로젝트 이름으로 변경하세요

# 작업 시작 시간 (밀리초)
START_TIME=$(date +%s%3N)

# 함수: 작업 시작 알림
send_task_start() {
    local task_summary="$1"

    curl -X POST "$WEBHOOK_SERVER" \
        -H "Content-Type: application/json" \
        -d "{
            \"type\": \"task_start\",
            \"projectName\": \"$PROJECT_NAME\",
            \"taskSummary\": \"$task_summary\",
            \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")\"
        }"
}

# 함수: 작업 완료 알림
send_task_complete() {
    local task_summary="$1"
    local changed_files="$2"  # JSON 배열 문자열

    local end_time=$(date +%s%3N)
    local duration=$((end_time - START_TIME))

    curl -X POST "$WEBHOOK_SERVER" \
        -H "Content-Type: application/json" \
        -d "{
            \"type\": \"task_complete\",
            \"projectName\": \"$PROJECT_NAME\",
            \"taskSummary\": \"$task_summary\",
            \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")\",
            \"duration\": $duration,
            \"changedFiles\": $changed_files
        }"
}

# 함수: 에러 알림
send_task_error() {
    local task_summary="$1"
    local error_message="$2"

    curl -X POST "$WEBHOOK_SERVER" \
        -H "Content-Type: application/json" \
        -d "{
            \"type\": \"task_error\",
            \"projectName\": \"$PROJECT_NAME\",
            \"taskSummary\": \"$task_summary\",
            \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")\",
            \"error\": \"$error_message\"
        }"
}

# 사용 예제
case "${1:-}" in
    start)
        send_task_start "빌드 및 테스트 실행 중..."
        ;;
    complete)
        # Git 변경 파일 목록 가져오기
        changed_files=$(git diff --name-status HEAD | awk '{printf "{\"path\":\"%s\",\"status\":\"%s\"},", $2, ($1=="M"?"modified":($1=="A"?"added":"deleted"))}' | sed 's/,$//')
        changed_files="[${changed_files}]"

        send_task_complete "빌드 및 테스트 완료" "$changed_files"
        ;;
    error)
        send_task_error "빌드 실패" "${2:-알 수 없는 오류}"
        ;;
    *)
        echo "사용법: $0 {start|complete|error [error_message]}"
        exit 1
        ;;
esac
