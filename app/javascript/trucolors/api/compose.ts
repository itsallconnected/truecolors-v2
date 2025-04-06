import { apiRequestPut } from 'truecolors/api';
import type { ApiMediaAttachmentJSON } from 'truecolors/api_types/media_attachments';

export const apiUpdateMedia = (
  id: string,
  params?: { description?: string; focus?: string },
) => apiRequestPut<ApiMediaAttachmentJSON>(`v1/media/${id}`, params);
