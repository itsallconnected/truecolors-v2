import './public-path';
import { createRoot } from 'react-dom/client';

import { afterInitialRender } from 'truecolors/hooks/useRenderSignal';

import { start } from '../truecolors/common';
import { Status } from '../truecolors/features/standalone/status';
import { loadPolyfills } from '../truecolors/polyfills';
import ready from '../truecolors/ready';

start();

function loaded() {
  const mountNode = document.getElementById('truecolors-status');

  if (mountNode) {
    const attr = mountNode.getAttribute('data-props');

    if (!attr) return;

    const props = JSON.parse(attr) as { id: string; locale: string };
    const root = createRoot(mountNode);

    root.render(<Status {...props} />);
  }
}

function main() {
  ready(loaded).catch((error: unknown) => {
    console.error(error);
  });
}

loadPolyfills()
  .then(main)
  .catch((error: unknown) => {
    console.error(error);
  });

interface SetHeightMessage {
  type: 'setHeight';
  id: string;
  height: number;
}

function isSetHeightMessage(data: unknown): data is SetHeightMessage {
  if (
    data &&
    typeof data === 'object' &&
    'type' in data &&
    data.type === 'setHeight'
  )
    return true;
  else return false;
}

window.addEventListener('message', (e) => {
  // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition -- typings are not correct, it can be null in very rare cases
  if (!e.data || !isSetHeightMessage(e.data) || !window.parent) return;

  const data = e.data;

  // Only set overflow to `hidden` once we got the expected `message` so the post can still be scrolled if
  // embedded without parent Javascript support
  document.body.style.overflow = 'hidden';

  // We use a timeout to allow for the React page to render before calculating the height
  afterInitialRender(() => {
    window.parent.postMessage(
      {
        type: 'setHeight',
        id: data.id,
        height: document.getElementsByTagName('html')[0]?.scrollHeight,
      },
      '*',
    );
  });
});
