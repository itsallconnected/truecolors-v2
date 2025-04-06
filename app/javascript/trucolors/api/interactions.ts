import { apiRequestPost } from 'truecolors/api';
import type { Status, StatusVisibility } from 'truecolors/models/status';

export const apiReblog = (statusId: string, visibility: StatusVisibility) =>
  apiRequestPost<{ reblog: Status }>(`v1/statuses/${statusId}/reblog`, {
    visibility,
  });

export const apiUnreblog = (statusId: string) =>
  apiRequestPost<Status>(`v1/statuses/${statusId}/unreblog`);
