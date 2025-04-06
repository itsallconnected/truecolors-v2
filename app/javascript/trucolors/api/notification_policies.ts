import { apiRequestGet, apiRequestPut } from 'truecolors/api';
import type { NotificationPolicyJSON } from 'truecolors/api_types/notification_policies';

export const apiGetNotificationPolicy = () =>
  apiRequestGet<NotificationPolicyJSON>('v2/notifications/policy');

export const apiUpdateNotificationsPolicy = (
  policy: Partial<NotificationPolicyJSON>,
) => apiRequestPut<NotificationPolicyJSON>('v2/notifications/policy', policy);
