# Personal Webhook Server

개인 프로젝트 작업 완료 시 Slack으로 알림을 보내주는 중앙 웹훅 서버입니다.

## 특징

- ✅ **작업 완료 알림** - 작업이 성공적으로 완료되면 알림
- 🚀 **작업 시작 알림** - 시간이 오래 걸리는 작업 시작 시 알림
- ❌ **에러 알림** - 작업 중 오류 발생 시 즉시 알림
- 📁 **프로젝트 구분** - 여러 프로젝트를 하나의 서버로 관리
- 📊 **상세 정보** - 프로젝트명, 작업 요약, 소요 시간, 변경된 파일 목록 포함

## 시스템 구조

```
┌─────────────────┐
│  프로젝트 A     │
│  (.claude/)     │───┐
└─────────────────┘   │
                      │
┌─────────────────┐   │    ┌──────────────────┐    ┌─────────────┐
│  프로젝트 B     │   ├───▶│  웹훅 서버       │───▶│   Slack     │
│  (.claude/)     │───┤    │  (cc-webhook)    │    │  워크스페이스│
└─────────────────┘   │    └──────────────────┘    └─────────────┘
                      │
┌─────────────────┐   │
│  프로젝트 C     │   │
│  (.claude/)     │───┘
└─────────────────┘
```

## 설치 및 설정

### 1. 의존성 설치

```bash
npm install

# PM2 전역 설치 (상시 운영용)
npm install -g pm2
```

### 2. Slack Webhook URL 발급

1. [Slack API](https://api.slack.com/messaging/webhooks) 페이지로 이동
2. 워크스페이스 선택 및 Incoming Webhook 생성
3. 알림을 받을 채널 선택
4. Webhook URL 복사

### 3. 환경 변수 설정

```bash
# .env.example을 .env로 복사
cp .env.example .env

# .env 파일 편집
nano .env
```

`.env` 파일에 Slack Webhook URL 입력:

```env
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
PORT=4000
```

### 4. 서버 실행

#### 개발/테스트 모드
```bash
npm run dev
```

#### 상시 운영 (PM2 사용 - 권장)

**처음 시작:**
```bash
# 빌드 및 PM2로 시작
npm run build
./scripts/start.sh
```

**맥미니 부팅 시 자동 시작 설정:**
```bash
pm2 startup
pm2 save
```

**서버 관리 명령어:**
```bash
./scripts/status.sh      # 서버 상태 확인
./scripts/logs.sh        # 로그 확인
./scripts/restart.sh     # 서버 재시작
./scripts/stop.sh        # 서버 중지
```

#### 외부 접근 설정 (ngrok)

외부 네트워크에서도 웹훅 서버에 접근하려면 ngrok을 사용하세요:

**1. ngrok 설치:**
```bash
brew install ngrok
```

**2. 환경 변수 설정:**

`.env` 파일에 ngrok authtoken 추가:
```env
NGROK_AUTHTOKEN=your_authtoken_here

# 선택사항: 고정 도메인 (유료 플랜)
# NGROK_DOMAIN=your-domain.ngrok.app
```

**3. 서버 시작:**

ngrok authtoken이 설정되어 있으면 `./scripts/start.sh` 실행 시 자동으로 ngrok 터널도 함께 시작됩니다.

**4. 퍼블릭 URL 확인:**
```bash
./scripts/ngrok-url.sh
```

출력 예시:
```
✅ 활성화된 ngrok 터널:

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔗 HTTPS: https://abc123.ngrok.io
📨 Webhook: https://abc123.ngrok.io/webhook

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

이제 어디서든 이 URL로 알림을 보낼 수 있습니다!

서버가 실행되면 다음과 같은 메시지가 표시됩니다:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Personal Webhook Server 시작됨
📍 포트: 4000
🔗 엔드포인트: http://localhost:4000/webhook
💬 Slack 연동: ✅ 설정됨
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## 각 프로젝트에서 사용하기

### 방법 1: Claude Code Hook 사용 (권장)

각 프로젝트의 `.claude/` 디렉토리에 hook 스크립트를 설정합니다.

```bash
# 프로젝트 디렉토리로 이동
cd /path/to/your/project

# .claude 디렉토리 생성 (없는 경우)
mkdir -p .claude

# 예제 hook 스크립트 복사
cp /path/to/personal-webhook-server/examples/claude-hook-example.sh .claude/user-prompt-submit-hook

# 실행 권한 부여
chmod +x .claude/user-prompt-submit-hook
```

### 방법 2: 수동 알림 스크립트

직접 스크립트에서 호출하려면:

```bash
# 예제 스크립트 복사
cp /path/to/cc-webhook/examples/send-notification.sh ./

# 실행 권한 부여
chmod +x send-notification.sh

# 사용
./send-notification.sh start                    # 작업 시작 알림
./send-notification.sh complete                 # 작업 완료 알림
./send-notification.sh error "에러 메시지"      # 에러 알림
```

### 방법 3: 작업 래퍼 (자동 알림)

작업 전후로 자동으로 알림을 보내는 래퍼:

```bash
# 예제 래퍼 복사
cp /path/to/cc-webhook/examples/task-wrapper.sh ./

# 실행 권한 부여
chmod +x task-wrapper.sh

# 사용 예제
./task-wrapper.sh "빌드 및 테스트" "npm run build && npm test"
./task-wrapper.sh "배포" "npm run deploy"
```

## API 사용법

### 엔드포인트

```
POST http://localhost:3000/webhook
```

### 요청 형식

#### 작업 시작 알림

```json
{
  "type": "task_start",
  "projectName": "my-project",
  "taskSummary": "빌드 및 테스트 실행 중...",
  "timestamp": "2025-11-15T10:30:00.000Z"
}
```

#### 작업 완료 알림

```json
{
  "type": "task_complete",
  "projectName": "my-project",
  "taskSummary": "빌드 및 테스트 완료",
  "timestamp": "2025-11-15T10:35:00.000Z",
  "duration": 300000,
  "changedFiles": [
    {
      "path": "src/server.ts",
      "status": "modified"
    },
    {
      "path": "src/types.ts",
      "status": "added"
    }
  ]
}
```

#### 에러 알림

```json
{
  "type": "task_error",
  "projectName": "my-project",
  "taskSummary": "빌드 실패",
  "timestamp": "2025-11-15T10:35:00.000Z",
  "error": "TypeScript compilation error in src/server.ts:42"
}
```

### cURL 예제

```bash
curl -X POST http://localhost:3000/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "type": "task_complete",
    "projectName": "my-awesome-project",
    "taskSummary": "새로운 기능 구현 완료",
    "timestamp": "2025-11-15T10:35:00.000Z",
    "duration": 120000,
    "changedFiles": [
      {"path": "src/feature.ts", "status": "added"},
      {"path": "src/app.ts", "status": "modified"}
    ]
  }'
```

## Slack 메시지 포맷

알림은 다음과 같은 형태로 Slack에 전송됩니다:

```
✅ 작업 완료

작업 내용
새로운 기능 구현 완료

프로젝트              시간
my-awesome-project    2025-11-15 19:35:00

소요 시간
2분 0초

변경된 파일 (2개)
`added` src/feature.ts
`modified` src/app.ts

Claude Code 알림
```

## 프로젝트 구조

```
cc-webhook/
├── src/
│   ├── server.ts        # Express 서버 (웹훅 엔드포인트)
│   ├── slackClient.ts   # Slack 메시지 전송 로직
│   └── types.ts         # TypeScript 타입 정의
├── scripts/
│   ├── start.sh         # PM2 서버 시작
│   ├── stop.sh          # PM2 서버 중지
│   ├── restart.sh       # PM2 서버 재시작
│   ├── status.sh        # PM2 서버 상태 확인
│   └── logs.sh          # PM2 로그 확인
├── examples/
│   ├── send-notification.sh      # 수동 알림 스크립트
│   ├── claude-hook-example.sh    # Claude Code hook 예제
│   └── task-wrapper.sh           # 작업 래퍼 스크립트
├── docs/
│   └── integration-guide.md      # 다른 프로젝트 연동 가이드
├── dist/                # 컴파일된 JavaScript (빌드 후)
├── logs/                # PM2 로그 파일 (자동 생성)
├── ecosystem.config.js  # PM2 설정 파일
├── package.json
├── tsconfig.json
├── .env.example
├── .gitignore
└── README.md
```

## 다른 프로젝트에서 연동하기

상세한 연동 가이드는 [`docs/integration-guide.md`](docs/integration-guide.md)를 참고하세요.

**빠른 시작:**

```bash
# 다른 프로젝트에서 알림 보내기
curl -X POST http://localhost:4000/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "type": "task_complete",
    "projectName": "my-project",
    "taskSummary": "작업 완료",
    "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")'"
  }'
```

## 트러블슈팅

### 서버가 시작되지 않아요

- `.env` 파일에 `SLACK_WEBHOOK_URL`이 올바르게 설정되었는지 확인하세요
- 포트 4000이 이미 사용 중인 경우 `.env`에서 `PORT`를 변경하세요
- PM2 상태 확인: `./scripts/status.sh`

### Slack 알림이 오지 않아요

- 웹훅 서버가 실행 중인지 확인하세요: `pm2 status cc-webhook`
- Slack Webhook URL이 유효한지 확인하세요
- 서버 로그 확인: `./scripts/logs.sh` 또는 `pm2 logs cc-webhook`

### Hook이 작동하지 않아요

- Hook 스크립트에 실행 권한이 있는지 확인하세요 (`chmod +x`)
- Hook 스크립트의 `WEBHOOK_SERVER` URL이 올바른지 확인하세요 (포트 4000)
- Claude Code가 hook을 지원하는지 확인하세요

### PM2 관련 문제

- PM2가 설치되어 있는지 확인: `pm2 --version`
- PM2 프로세스 목록 확인: `pm2 list`
- PM2 재시작: `./scripts/restart.sh`

## 맥미니 상시 운영 설정

이 서버는 맥미니에서 24시간 상시 운영하도록 설계되었습니다.

### 초기 설정

```bash
# 1. 빌드
npm run build

# 2. PM2로 서버 시작
./scripts/start.sh

# 3. 부팅 시 자동 시작 설정
pm2 startup
pm2 save

# 4. 상태 확인
./scripts/status.sh
```

### 일상 관리

```bash
# 서버 상태 확인
./scripts/status.sh

# 로그 확인
./scripts/logs.sh

# 서버 재시작 (코드 변경 후)
npm run build && ./scripts/restart.sh --build

# 서버 중지
./scripts/stop.sh
```

### 포트 정보

- **기본 포트**: 4000
- **엔드포인트**: `http://localhost:4000/webhook`
- **헬스 체크**: `http://localhost:4000/health`

## 라이센스

MIT

## 기여

이슈나 PR은 언제든지 환영합니다!
