import { apiRequestGet, apiRequestPost } from 'truecolors/api';
import type { ApiPollJSON } from 'truecolors/api_types/polls';

export const apiGetPoll = (pollId: string) =>
  apiRequestGet<ApiPollJSON>(`/v1/polls/${pollId}`);

export const apiPollVote = (pollId: string, choices: string[]) =>
  apiRequestPost<ApiPollJSON>(`/v1/polls/${pollId}/votes`, {
    choices,
  });
