module.exports = {
  globals: {
    __MEADOW_VERSION__: "v1.2.3",
    __HONEYBADGER_REVISION__: "1234567",
    __HONEYBADGER_ENVIRONMENT__: "staging",
    dataLayer: [],
  },
  verbose: true,
  moduleNameMapper: {
    "\\.(jpg|jpeg|png|gif|eot|otf|webp|svg|ttf|woff|woff2|mp4|webm|wav|mp3|m4a|aac|oga)$":
      "<rootDir>/__mocks__/fileMock.js",
    "^@js(.*)$": "<rootDir>/js$1",
  },
  setupFiles: [],
  setupFilesAfterEnv: ["./jest.setup.js"],
  testEnvironment: "jsdom",
};
