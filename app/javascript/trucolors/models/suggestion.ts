import type { ApiSuggestionJSON } from 'truecolors/api_types/suggestions';

export interface Suggestion extends Omit<ApiSuggestionJSON, 'account'> {
  account_id: string;
}

export const createSuggestion = (
  serverJSON: ApiSuggestionJSON,
): Suggestion => ({
  sources: serverJSON.sources,
  account_id: serverJSON.account.id,
});
