import { Provider } from 'react-redux';

import { fetchCustomEmojis } from 'truecolors/actions/custom_emojis';
import { fetchServer } from 'truecolors/actions/server';
import { hydrateStore } from 'truecolors/actions/store';
import { Router } from 'truecolors/components/router';
import Compose from 'truecolors/features/standalone/compose';
import initialState from 'truecolors/initial_state';
import { IntlProvider } from 'truecolors/locales';
import { store } from 'truecolors/store';

if (initialState) {
  store.dispatch(hydrateStore(initialState));
}

store.dispatch(fetchCustomEmojis());
store.dispatch(fetchServer());

const ComposeContainer = () => (
  <IntlProvider>
    <Provider store={store}>
      <Router>
        <Compose />
      </Router>
    </Provider>
  </IntlProvider>
);

export default ComposeContainer;
