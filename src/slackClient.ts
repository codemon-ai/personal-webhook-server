import { IncomingWebhook } from '@slack/webhook';
import { WebhookPayload, NotificationType } from './types';

/**
 * Slack 메시지 전송 클라이언트
 */
export class SlackNotifier {
  private webhook: IncomingWebhook;

  constructor(webhookUrl: string) {
    this.webhook = new IncomingWebhook(webhookUrl);
  }

  /**
   * 작업 알림을 Slack으로 전송
   */
  async sendNotification(payload: WebhookPayload): Promise<void> {
    const message = this.formatMessage(payload);
    await this.webhook.send(message);
  }

  /**
   * Slack 메시지 포맷팅
   */
  private formatMessage(payload: WebhookPayload) {
    const { type, projectName, taskSummary, timestamp, duration, changedFiles, error } = payload;

    // 이모지 선택
    let emoji = '✅';
    let title = '작업 완료';
    let color = 'good';

    if (type === NotificationType.TASK_START) {
      emoji = '🚀';
      title = '작업 시작';
      color = '#439FE0';
    } else if (type === NotificationType.TASK_ERROR) {
      emoji = '❌';
      title = '에러 발생';
      color = 'danger';
    }

    // 기본 필드
    const fields: any[] = [
      {
        title: '프로젝트',
        value: projectName,
        short: true
      },
      {
        title: '시간',
        value: new Date(timestamp).toLocaleString('ko-KR', { timeZone: 'Asia/Seoul' }),
        short: true
      }
    ];

    // 소요 시간 추가 (완료 시)
    if (duration !== undefined) {
      const durationText = this.formatDuration(duration);
      fields.push({
        title: '소요 시간',
        value: durationText,
        short: true
      });
    }

    // 변경된 파일 추가
    if (changedFiles && changedFiles.length > 0) {
      const filesText = changedFiles
        .slice(0, 10) // 최대 10개만 표시
        .map(f => `\`${f.status}\` ${f.path}`)
        .join('\n');

      const moreFiles = changedFiles.length > 10 ? `\n...외 ${changedFiles.length - 10}개` : '';

      fields.push({
        title: `변경된 파일 (${changedFiles.length}개)`,
        value: filesText + moreFiles,
        short: false
      });
    }

    // 에러 메시지 추가
    if (error) {
      fields.push({
        title: '에러 내용',
        value: `\`\`\`${error}\`\`\``,
        short: false
      });
    }

    return {
      text: `${emoji} *${title}*`,
      attachments: [
        {
          color,
          fallback: `${title}: ${projectName} - ${taskSummary}`,
          fields: [
            {
              title: '작업 내용',
              value: taskSummary,
              short: false
            },
            ...fields
          ],
          footer: 'Claude Code 알림',
          ts: Math.floor(new Date(timestamp).getTime() / 1000).toString()
        }
      ]
    };
  }

  /**
   * 소요 시간을 읽기 쉬운 형태로 변환
   */
  private formatDuration(ms: number): string {
    const seconds = Math.floor(ms / 1000);
    const minutes = Math.floor(seconds / 60);
    const hours = Math.floor(minutes / 60);

    if (hours > 0) {
      return `${hours}시간 ${minutes % 60}분`;
    } else if (minutes > 0) {
      return `${minutes}분 ${seconds % 60}초`;
    } else {
      return `${seconds}초`;
    }
  }
}
