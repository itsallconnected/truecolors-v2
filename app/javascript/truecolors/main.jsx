import { createRoot } from 'react-dom/client';

import Truecolors from './containers/truecolors.jsx';

import { setupBrowserNotifications } from 'truecolors/actions/notifications';
import { me } from 'truecolors/initial_state';
import * as perf from 'truecolors/performance';
import ready from 'truecolors/ready';
import { store } from 'truecolors/store';

import { isProduction } from './utils/environment';

/**
 * @returns {Promise<void>}
 */
function main() {
  perf.start('main()');

  return ready(async () => {
    const mountNode = document.getElementById('truecolors');
    const props = JSON.parse(mountNode.getAttribute('data-props'));

    const root = createRoot(mountNode);
    root.render(<Truecolors {...props} />);
    store.dispatch(setupBrowserNotifications());

    if (isProduction() && me && 'serviceWorker' in navigator) {
      const { Workbox } = await import('workbox-window');
      const wb = new Workbox('/sw.js');
      /** @type {ServiceWorkerRegistration} */
      let registration;

      try {
        registration = await wb.register();
      } catch (err) {
        console.error(err);
      }

      if (registration && 'Notification' in window && Notification.permission === 'granted') {
        const registerPushNotifications = await import('truecolors/actions/push_notifications');

        store.dispatch(registerPushNotifications.register());
      }
    }

    perf.stop('main()');
  });
}

export default main;
