/* global path */
/*
Preferences | Languages & Frameworks | JavaScript | Webpack | webpack configuration file
jetbrains://WebStorm/settings?name=Languages+%26+Frameworks--JavaScript--Webpack
*/
module.exports = {
  resolve: {
    alias: {
      'truecolors': path.resolve(__dirname, 'app/javascript/truecolors'),
    },
  },
};
