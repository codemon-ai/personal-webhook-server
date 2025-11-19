/**
 * Claude Code 작업 알림 타입 정의
 */

/**
 * 알림 타입
 */
export enum NotificationType {
  TASK_START = 'task_start',      // 긴 작업 시작
  TASK_COMPLETE = 'task_complete', // 작업 완료
  TASK_ERROR = 'task_error'        // 에러 발생
}

/**
 * 변경된 파일 정보
 */
export interface ChangedFile {
  path: string;
  status: 'added' | 'modified' | 'deleted';
}

/**
 * 웹훅 요청 페이로드
 */
export interface WebhookPayload {
  type: NotificationType;
  projectName: string;           // 프로젝트 이름
  taskSummary: string;            // 작업 요약
  timestamp: string;              // 작업 시간 (ISO 8601)
  duration?: number;              // 작업 소요 시간 (밀리초, 완료 시만)
  changedFiles?: ChangedFile[];   // 변경된 파일 목록
  error?: string;                 // 에러 메시지 (에러 시만)
  metadata?: Record<string, any>; // 추가 메타데이터
}

/**
 * 서버 응답
 */
export interface WebhookResponse {
  success: boolean;
  message: string;
  slackMessageSent?: boolean;
}
