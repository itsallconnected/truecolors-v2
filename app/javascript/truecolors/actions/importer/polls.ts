import { createAction } from '@reduxjs/toolkit';

import type { Poll } from 'truecolors/models/poll';

export const importPolls = createAction<{ polls: Poll[] }>(
  'poll/importMultiple',
);
