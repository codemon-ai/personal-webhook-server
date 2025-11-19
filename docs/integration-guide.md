# 다른 프로젝트에서 연동 가이드

이 문서는 맥미니에서 실행 중인 Personal Webhook Server에 다른 프로젝트를 연동하는 방법을 설명합니다.

## 접근 방법

### 1. 로컬 접근 (맥미니 내부)

맥미니에서 실행되는 프로젝트의 경우:

- **URL**: `http://localhost:4000/webhook`
- **사용 예**: 맥미니에서 직접 작업하는 모든 프로젝트

### 2. 로컬 네트워크 접근 (같은 Wi-Fi의 다른 기기)

같은 네트워크에 있는 다른 맥북, 아이맥 등에서 접근:

**맥미니의 로컬 IP 확인:**
```bash
# 방법 1: ifconfig 사용
ifconfig | grep "inet " | grep -v 127.0.0.1

# 방법 2: 시스템 환경설정
# 시스템 환경설정 > 네트워크 > Wi-Fi > 고급 > TCP/IP
```

일반적으로 `192.168.x.x` 형태입니다 (예: `192.168.0.100`)

- **URL**: `http://192.168.x.x:4000/webhook` (x.x는 실제 IP)
- **사용 예**: 다른 맥북에서 작업하는 프로젝트, 같은 Wi-Fi의 다른 기기

**방화벽 설정 확인:**
```bash
# macOS 방화벽 상태 확인
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate

# 필요시 포트 4000 허용 (방화벽이 켜져있는 경우)
# 시스템 환경설정 > 보안 및 개인정보 보호 > 방화벽 > 방화벽 옵션
```

### 3. 외부 네트워크 접근 (집 밖에서)

#### 옵션 A: Tailscale (권장)

무료 VPN 서비스로 안전하게 맥미니에 접근:

```bash
# 1. Tailscale 설치 (맥미니)
brew install tailscale
sudo tailscaled

# 2. Tailscale 로그인
tailscale up

# 3. Tailscale IP 확인
tailscale ip -4
```

- **URL**: `http://[tailscale-ip]:4000/webhook` (예: `http://100.x.x.x:4000/webhook`)
- **장점**: 무료, 안전, 쉬운 설정
- **단점**: 클라이언트도 Tailscale 설치 필요

#### 옵션 B: ngrok (임시 테스트용)

임시 퍼블릭 URL 생성:

```bash
# 1. ngrok 설치
brew install ngrok

# 2. 터널 생성
ngrok http 4000

# 출력된 URL 사용 (예: https://abc123.ngrok.io/webhook)
```

- **URL**: ngrok이 제공하는 임시 URL
- **장점**: 설정 간단, 즉시 사용 가능
- **단점**:
  - 무료 플랜은 URL이 매번 변경됨 (재시작 시)
  - 세션 시간 제한 있음 (8시간)
  - 보안 취약 (퍼블릭 URL)
- **비용**:
  - 무료 플랜: 기본 기능 사용 가능, URL 랜덤
  - 유료 플랜 ($8/월~): 고정 도메인, 무제한 세션

#### 옵션 C: 포트 포워딩 (권장하지 않음)

라우터에서 4000번 포트를 맥미니로 포워딩:

- **URL**: `http://[공인IP]:4000/webhook`
- **장점**: 별도 서비스 불필요
- **단점**: 보안 위험, 공인 IP 필요, 라우터 설정 필요

### 접근 방법 비교

| 방법 | 사용 위치 | URL 예시 | 난이도 | 보안 | 비용 |
|------|----------|----------|--------|------|------|
| 로컬 | 맥미니 내부 | `localhost:4000` | ⭐ 쉬움 | ✅ 안전 | 무료 |
| 로컬 네트워크 | 같은 Wi-Fi | `192.168.x.x:4000` | ⭐⭐ 보통 | ✅ 안전 | 무료 |
| Tailscale | 어디서나 | `100.x.x.x:4000` | ⭐⭐⭐ 보통 | ✅ 매우 안전 | 무료 |
| ngrok | 어디서나 | `abc.ngrok.io` | ⭐ 쉬움 | ⚠️ 주의 | 무료* |
| 포트 포워딩 | 어디서나 | `공인IP:4000` | ⭐⭐⭐⭐ 어려움 | ❌ 위험 | 무료 |

> *ngrok 무료 플랜은 URL이 매번 변경되고 세션 제한이 있음. 고정 URL이 필요하면 유료($8/월~)

### 보안 고려사항

외부에서 접근할 경우 보안을 강화하는 것이 좋습니다:

1. **API 키 인증 추가** (향후 개선 사항)
2. **HTTPS 사용** (Let's Encrypt + Caddy/nginx)
3. **IP 화이트리스트** (특정 IP만 허용)
4. **VPN 사용** (Tailscale 권장)

현재 버전은 인증이 없으므로, 외부 노출 시 누구나 Slack 알림을 보낼 수 있습니다.

## 서버 정보 (로컬)

- **호스트**: `localhost` (맥미니 로컬)
- **포트**: `4000`
- **엔드포인트**: `http://localhost:4000/webhook`
- **메서드**: `POST`
- **Content-Type**: `application/json`

## API 스펙

### 요청 형식

#### 공통 필드

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `type` | string | ✅ | 알림 타입: `task_start`, `task_complete`, `task_error` |
| `projectName` | string | ✅ | 프로젝트 이름 (Slack에 표시됨) |
| `taskSummary` | string | ✅ | 작업 요약 설명 |
| `timestamp` | string | ✅ | ISO 8601 형식의 타임스탬프 |

#### 알림 타입별 추가 필드

**작업 완료 (`task_complete`)**
| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `duration` | number | ❌ | 작업 소요 시간 (밀리초) |
| `changedFiles` | array | ❌ | 변경된 파일 목록 |

**에러 발생 (`task_error`)**
| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| `error` | string | ❌ | 에러 메시지 |

### 응답 형식

```json
{
  "success": true,
  "message": "Slack 알림이 성공적으로 전송되었습니다",
  "slackMessageSent": true
}
```

에러 발생 시:
```json
{
  "success": false,
  "message": "에러 메시지",
  "slackMessageSent": false
}
```

## 사용 방법

### 1. cURL로 직접 호출

#### 작업 시작 알림

```bash
curl -X POST http://localhost:4000/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "type": "task_start",
    "projectName": "my-project",
    "taskSummary": "데이터베이스 마이그레이션 실행 중",
    "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")'"
  }'
```

#### 작업 완료 알림

```bash
curl -X POST http://localhost:4000/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "type": "task_complete",
    "projectName": "my-project",
    "taskSummary": "API 서버 빌드 및 배포 완료",
    "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")'",
    "duration": 120000,
    "changedFiles": [
      {"path": "src/api/server.ts", "status": "modified"},
      {"path": "dist/server.js", "status": "added"}
    ]
  }'
```

#### 에러 알림

```bash
curl -X POST http://localhost:4000/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "type": "task_error",
    "projectName": "my-project",
    "taskSummary": "테스트 실패",
    "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")'",
    "error": "Test suite failed: 3 tests failed out of 25"
  }'
```

### 2. Bash 스크립트에서 사용

각 프로젝트에 다음과 같은 함수를 추가하세요:

```bash
#!/bin/bash

WEBHOOK_URL="http://localhost:4000/webhook"
PROJECT_NAME="your-project-name"  # 프로젝트 이름으로 변경

# 작업 시작 알림
notify_start() {
    local task_summary="$1"
    curl -s -X POST "$WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "{
            \"type\": \"task_start\",
            \"projectName\": \"$PROJECT_NAME\",
            \"taskSummary\": \"$task_summary\",
            \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")\"
        }" > /dev/null
}

# 작업 완료 알림
notify_complete() {
    local task_summary="$1"
    local duration="$2"
    curl -s -X POST "$WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "{
            \"type\": \"task_complete\",
            \"projectName\": \"$PROJECT_NAME\",
            \"taskSummary\": \"$task_summary\",
            \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")\",
            \"duration\": $duration
        }" > /dev/null
}

# 에러 알림
notify_error() {
    local task_summary="$1"
    local error_message="$2"
    curl -s -X POST "$WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "{
            \"type\": \"task_error\",
            \"projectName\": \"$PROJECT_NAME\",
            \"taskSummary\": \"$task_summary\",
            \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")\",
            \"error\": \"$error_message\"
        }" > /dev/null
}

# 사용 예제
notify_start "빌드 시작"
npm run build
if [ $? -eq 0 ]; then
    notify_complete "빌드 완료" 5000
else
    notify_error "빌드 실패" "npm build command failed"
fi
```

### 3. Claude Code Hook 설정

각 프로젝트의 `.claude/` 디렉토리에 hook을 설정하여 자동 알림을 보낼 수 있습니다.

#### 방법 A: user-prompt-submit-hook (작업 시작 감지)

`.claude/user-prompt-submit-hook` 파일 생성:

```bash
#!/bin/bash

WEBHOOK_URL="http://localhost:4000/webhook"
PROJECT_NAME=$(basename "$(pwd)")
USER_INPUT="${CLAUDE_USER_INPUT:-작업 수행 중}"

# 긴 작업 키워드
LONG_TASK_KEYWORDS=("build" "test" "deploy" "install" "빌드" "테스트" "배포")

# 긴 작업 감지
is_long_task=false
for keyword in "${LONG_TASK_KEYWORDS[@]}"; do
    if echo "$USER_INPUT" | grep -qi "$keyword"; then
        is_long_task=true
        break
    fi
done

# 알림 전송
if [ "$is_long_task" = true ]; then
    curl -s -X POST "$WEBHOOK_URL" \
        -H "Content-Type: application/json" \
        -d "{
            \"type\": \"task_start\",
            \"projectName\": \"$PROJECT_NAME\",
            \"taskSummary\": \"$USER_INPUT\",
            \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")\"
        }" > /dev/null 2>&1
fi

exit 0
```

실행 권한 부여:
```bash
chmod +x .claude/user-prompt-submit-hook
```

#### 방법 B: 수동 스크립트 호출

프로젝트에 `notify.sh` 스크립트 생성:

```bash
#!/bin/bash

WEBHOOK_URL="http://localhost:4000/webhook"
PROJECT_NAME=$(basename "$(pwd)")

case "${1:-}" in
    start)
        curl -s -X POST "$WEBHOOK_URL" \
            -H "Content-Type: application/json" \
            -d "{
                \"type\": \"task_start\",
                \"projectName\": \"$PROJECT_NAME\",
                \"taskSummary\": \"${2:-작업 시작}\",
                \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")\"
            }"
        ;;
    complete)
        curl -s -X POST "$WEBHOOK_URL" \
            -H "Content-Type: application/json" \
            -d "{
                \"type\": \"task_complete\",
                \"projectName\": \"$PROJECT_NAME\",
                \"taskSummary\": \"${2:-작업 완료}\",
                \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")\",
                \"duration\": ${3:-0}
            }"
        ;;
    error)
        curl -s -X POST "$WEBHOOK_URL" \
            -H "Content-Type: application/json" \
            -d "{
                \"type\": \"task_error\",
                \"projectName\": \"$PROJECT_NAME\",
                \"taskSummary\": \"${2:-에러 발생}\",
                \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")\",
                \"error\": \"${3:-알 수 없는 오류}\"
            }"
        ;;
    *)
        echo "사용법: $0 {start|complete|error} [메시지] [추가정보]"
        exit 1
        ;;
esac
```

사용:
```bash
./notify.sh start "빌드 시작"
npm run build && ./notify.sh complete "빌드 완료" 5000
```

### 4. npm scripts에 통합

`package.json`에 알림을 추가:

```json
{
  "scripts": {
    "build": "npm run notify:start && tsc && npm run notify:complete",
    "notify:start": "curl -s -X POST http://localhost:4000/webhook -H 'Content-Type: application/json' -d '{\"type\":\"task_start\",\"projectName\":\"my-project\",\"taskSummary\":\"빌드 시작\",\"timestamp\":\"'$(date -u +\"%Y-%m-%dT%H:%M:%S.000Z\")'\"}' || true",
    "notify:complete": "curl -s -X POST http://localhost:4000/webhook -H 'Content-Type: application/json' -d '{\"type\":\"task_complete\",\"projectName\":\"my-project\",\"taskSummary\":\"빌드 완료\",\"timestamp\":\"'$(date -u +\"%Y-%m-%dT%H:%M:%S.000Z\")'\"}' || true"
  }
}
```

### 5. Python에서 사용

```python
import requests
from datetime import datetime, timezone

WEBHOOK_URL = "http://localhost:4000/webhook"
PROJECT_NAME = "my-python-project"

def notify_slack(notification_type, task_summary, **kwargs):
    payload = {
        "type": notification_type,
        "projectName": PROJECT_NAME,
        "taskSummary": task_summary,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        **kwargs
    }

    try:
        response = requests.post(WEBHOOK_URL, json=payload, timeout=5)
        response.raise_for_status()
        return True
    except Exception as e:
        print(f"알림 전송 실패: {e}")
        return False

# 사용 예제
notify_slack("task_start", "데이터 처리 시작")

# 작업 수행
try:
    # ... 작업 코드 ...
    notify_slack("task_complete", "데이터 처리 완료", duration=5000)
except Exception as e:
    notify_slack("task_error", "데이터 처리 실패", error=str(e))
```

### 6. Node.js/JavaScript에서 사용

```javascript
const WEBHOOK_URL = 'http://localhost:4000/webhook';
const PROJECT_NAME = 'my-node-project';

async function notifySlack(type, taskSummary, options = {}) {
  const payload = {
    type,
    projectName: PROJECT_NAME,
    taskSummary,
    timestamp: new Date().toISOString(),
    ...options
  };

  try {
    const response = await fetch(WEBHOOK_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    });

    if (!response.ok) {
      throw new Error(`HTTP ${response.status}`);
    }

    return true;
  } catch (error) {
    console.error('알림 전송 실패:', error);
    return false;
  }
}

// 사용 예제
await notifySlack('task_start', '서버 빌드 시작');

try {
  // ... 작업 코드 ...
  await notifySlack('task_complete', '서버 빌드 완료', { duration: 3000 });
} catch (error) {
  await notifySlack('task_error', '서버 빌드 실패', { error: error.message });
}
```

## 트러블슈팅

### 웹훅 서버 상태 확인

```bash
# 서버가 실행 중인지 확인
curl http://localhost:4000/health

# 예상 응답: {"status":"ok","message":"Claude Code Webhook Server is running"}
```

### 서버가 응답하지 않는 경우

1. **서버가 실행 중인지 확인**
   ```bash
   pm2 status cc-webhook
   ```

2. **서버 재시작**
   ```bash
   cd /Users/coffeemon/workspace/cc-webhook
   ./scripts/restart.sh
   ```

3. **로그 확인**
   ```bash
   pm2 logs cc-webhook
   ```

### 포트 문제

만약 4000번 포트가 다른 프로세스에서 사용 중이면:

```bash
# 포트 사용 확인
lsof -i :4000

# 웹훅 서버의 포트 변경 (서버 측)
# /Users/coffeemon/workspace/cc-webhook/.env 에서 PORT 수정
```

### 알림이 Slack에 도착하지 않는 경우

1. 웹훅 서버의 로그 확인: `pm2 logs cc-webhook`
2. Slack Webhook URL이 올바른지 확인
3. 테스트 요청을 수동으로 보내서 서버 응답 확인

## 참고사항

- **타임아웃**: 웹훅 요청은 5초 타임아웃 권장
- **에러 처리**: 알림 실패 시 프로젝트 실행을 중단하지 않도록 처리
- **프로젝트 이름**: 알아보기 쉬운 고유한 이름 사용
- **긴 작업**: 5분 이상 걸리는 작업에만 시작 알림 권장

## 추가 지원

문제가 있거나 새로운 기능이 필요하면 웹훅 서버 저장소의 README를 참고하세요.
