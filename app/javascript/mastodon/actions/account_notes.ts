import { apiSubmitAccountNote } from 'truecolors/api/accounts';
import { createDataLoadingThunk } from 'truecolors/store/typed_functions';

export const submitAccountNote = createDataLoadingThunk(
  'account_note/submit',
  ({ accountId, note }: { accountId: string; note: string }) =>
    apiSubmitAccountNote(accountId, note),
  (relationship) => ({ relationship }),
);
