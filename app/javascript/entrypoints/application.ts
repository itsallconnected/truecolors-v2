import './public-path';
import main from 'truecolors/main';

import { start } from '../truecolors/common';
import { loadLocale } from '../truecolors/locales';
import { loadPolyfills } from '../truecolors/polyfills';

start();

loadPolyfills()
  .then(loadLocale)
  .then(main)
  .catch((e: unknown) => {
    console.error(e);
  });
