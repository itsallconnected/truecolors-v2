import { apiRequestGet } from 'truecolors/api';
import type {
  ApiSearchType,
  ApiSearchResultsJSON,
} from 'truecolors/api_types/search';

export const apiGetSearch = (params: {
  q: string;
  resolve?: boolean;
  type?: ApiSearchType;
  limit?: number;
  offset?: number;
}) =>
  apiRequestGet<ApiSearchResultsJSON>('v2/search', {
    ...params,
  });
