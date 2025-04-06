import './public-path';

import { start } from '../truecolors/common';
import { loadLocale } from '../truecolors/locales';
import main from '../truecolors/main';
import { loadPolyfills } from '../truecolors/polyfills';

start();

loadPolyfills()
  .then(loadLocale)
  .then(main)
  .catch((e: unknown) => {
    console.error(e);
  });
