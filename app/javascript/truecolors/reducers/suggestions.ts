import { createReducer, isAnyOf } from '@reduxjs/toolkit';

import {
  blockAccountSuccess,
  muteAccountSuccess,
} from 'truecolors/actions/accounts';
import { blockDomainSuccess } from 'truecolors/actions/domain_blocks';
import {
  fetchSuggestions,
  dismissSuggestion,
} from 'truecolors/actions/suggestions';
import { createSuggestion } from 'truecolors/models/suggestion';
import type { Suggestion } from 'truecolors/models/suggestion';

interface State {
  items: Suggestion[];
  isLoading: boolean;
}

const initialState: State = {
  items: [],
  isLoading: false,
};

export const suggestionsReducer = createReducer(initialState, (builder) => {
  builder.addCase(fetchSuggestions.pending, (state) => {
    state.isLoading = true;
  });

  builder.addCase(fetchSuggestions.fulfilled, (state, action) => {
    state.items = action.payload.map(createSuggestion);
    state.isLoading = false;
  });

  builder.addCase(fetchSuggestions.rejected, (state) => {
    state.isLoading = false;
  });

  builder.addCase(dismissSuggestion.pending, (state, action) => {
    state.items = state.items.filter(
      (x) => x.account_id !== action.meta.arg.accountId,
    );
  });

  builder.addCase(blockDomainSuccess, (state, action) => {
    state.items = state.items.filter(
      (x) =>
        !action.payload.accounts.some((account) => account.id === x.account_id),
    );
  });

  builder.addMatcher(
    isAnyOf(blockAccountSuccess, muteAccountSuccess),
    (state, action) => {
      state.items = state.items.filter(
        (x) => x.account_id !== action.payload.relationship.id,
      );
    },
  );
});
