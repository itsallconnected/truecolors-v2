import { ModerationWarning } from 'truecolors/features/notifications/components/moderation_warning';
import type { NotificationGroupModerationWarning } from 'truecolors/models/notification_group';

export const NotificationModerationWarning: React.FC<{
  notification: NotificationGroupModerationWarning;
  unread: boolean;
}> = ({ notification: { moderationWarning }, unread }) => (
  <ModerationWarning
    action={moderationWarning.action}
    id={moderationWarning.id}
    unread={unread}
  />
);
