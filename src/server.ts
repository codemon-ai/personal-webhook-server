import express, { Request, Response } from 'express';
import dotenv from 'dotenv';
import { SlackNotifier } from './slackClient';
import { WebhookPayload, WebhookResponse } from './types';

// 환경 변수 로드
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;
const SLACK_WEBHOOK_URL = process.env.SLACK_WEBHOOK_URL;

// JSON 파싱 미들웨어
app.use(express.json());

// Slack Webhook URL 검증
if (!SLACK_WEBHOOK_URL) {
  console.error('❌ 오류: SLACK_WEBHOOK_URL 환경 변수가 설정되지 않았습니다.');
  console.error('   .env 파일에 SLACK_WEBHOOK_URL을 설정해주세요.');
  process.exit(1);
}

const slackNotifier = new SlackNotifier(SLACK_WEBHOOK_URL);

/**
 * 헬스 체크 엔드포인트
 */
app.get('/health', (req: Request, res: Response) => {
  res.json({ status: 'ok', message: 'Claude Code Webhook Server is running' });
});

/**
 * 웹훅 엔드포인트 - Claude Code에서 호출
 */
app.post('/webhook', async (req: Request, res: Response) => {
  try {
    const payload: WebhookPayload = req.body;

    // 페이로드 검증
    if (!payload.type || !payload.projectName || !payload.taskSummary || !payload.timestamp) {
      const response: WebhookResponse = {
        success: false,
        message: '필수 필드가 누락되었습니다 (type, projectName, taskSummary, timestamp)'
      };
      return res.status(400).json(response);
    }

    // Slack으로 알림 전송
    console.log(`📨 알림 전송 중: [${payload.projectName}] ${payload.taskSummary}`);
    await slackNotifier.sendNotification(payload);
    console.log(`✅ 알림 전송 완료`);

    const response: WebhookResponse = {
      success: true,
      message: 'Slack 알림이 성공적으로 전송되었습니다',
      slackMessageSent: true
    };

    res.json(response);
  } catch (error) {
    console.error('❌ Slack 알림 전송 실패:', error);

    const response: WebhookResponse = {
      success: false,
      message: error instanceof Error ? error.message : '알 수 없는 오류가 발생했습니다',
      slackMessageSent: false
    };

    res.status(500).json(response);
  }
});

/**
 * 404 핸들러
 */
app.use((req: Request, res: Response) => {
  res.status(404).json({ error: 'Not Found' });
});

/**
 * 서버 시작
 */
app.listen(PORT, () => {
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('🚀 Claude Code Webhook Server 시작됨');
  console.log(`📍 포트: ${PORT}`);
  console.log(`🔗 엔드포인트: http://localhost:${PORT}/webhook`);
  console.log(`💬 Slack 연동: ${SLACK_WEBHOOK_URL ? '✅ 설정됨' : '❌ 미설정'}`);
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
});

export default app;
