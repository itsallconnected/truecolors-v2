import { apiRequestGet } from 'truecolors/api';
import type { ApiAccountJSON } from 'truecolors/api_types/accounts';

export const apiGetDirectory = (
  params: {
    order: string;
    local: boolean;
    offset?: number;
  },
  limit = 20,
) =>
  apiRequestGet<ApiAccountJSON[]>('v1/directory', {
    ...params,
    limit,
  });
