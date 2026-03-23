export interface FeedbackEntry {
  action: 'approve' | 'reject';
  comment: string;
  attachment_path?: string;
  timestamp: string;
}

export interface QueueItem {
  id: string;
  component_name: string;
  screenshot_path: string;
  code_snippet: string;
  viewport: string;
  status: 'pending' | 'approved' | 'rejected';
  feedback_history: FeedbackEntry[];
  created_at: string;
}

export type ConnectionStatus = 'connected' | 'disconnected' | 'connecting';
