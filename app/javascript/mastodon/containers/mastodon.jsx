import { PureComponent } from 'react';

import { Helmet } from 'react-helmet';
import { Route } from 'react-router-dom';

import { Provider as ReduxProvider } from 'react-redux';

import { ScrollContext } from 'react-router-scroll-4';

import { fetchCustomEmojis } from 'truecolors/actions/custom_emojis';
import { hydrateStore } from 'truecolors/actions/store';
import { connectUserStream } from 'truecolors/actions/streaming';
import ErrorBoundary from 'truecolors/components/error_boundary';
import { Router } from 'truecolors/components/router';
import UI from 'truecolors/features/ui';
import { IdentityContext, createIdentityContext } from 'truecolors/identity_context';
import initialState, { title as siteTitle } from 'truecolors/initial_state';
import { IntlProvider } from 'truecolors/locales';
import { store } from 'truecolors/store';
import { isProduction } from 'truecolors/utils/environment';

const title = isProduction() ? siteTitle : `${siteTitle} (Dev)`;

const hydrateAction = hydrateStore(initialState);

store.dispatch(hydrateAction);
if (initialState.meta.me) {
  store.dispatch(fetchCustomEmojis());
}

export default class Truecolors extends PureComponent {
  identity = createIdentityContext(initialState);

  componentDidMount() {
    if (this.identity.signedIn) {
      this.disconnect = store.dispatch(connectUserStream());
    }
  }

  componentWillUnmount () {
    if (this.disconnect) {
      this.disconnect();
      this.disconnect = null;
    }
  }

  shouldUpdateScroll (prevRouterProps, { location }) {
    return !(location.state?.truecolorsModalKey && location.state?.truecolorsModalKey !== prevRouterProps?.location?.state?.truecolorsModalKey);
  }

  render () {
    return (
      <IdentityContext.Provider value={this.identity}>
        <IntlProvider>
          <ReduxProvider store={store}>
            <ErrorBoundary>
              <Router>
                <ScrollContext shouldUpdateScroll={this.shouldUpdateScroll}>
                  <Route path='/' component={UI} />
                </ScrollContext>
              </Router>

              <Helmet defaultTitle={title} titleTemplate={`%s - ${title}`} />
            </ErrorBoundary>
          </ReduxProvider>
        </IntlProvider>
      </IdentityContext.Provider>
    );
  }

}
