import './public-path';
import main from '../trucolors/main';

import { start } from '../trucolors/common';
import { loadLocale } from '../trucolors/locales';
import { loadPolyfills } from '../trucolors/polyfills';

start();

loadPolyfills()
  .then(loadLocale)
  .then(main)
  .catch((e: unknown) => {
    console.error(e);
  });
