/** @type {import('ts-jest').JestConfigWithTsJest} */
module.exports = {
  globals: {
    __HONEYBADGER_ENVIRONMENT__: "staging",
    __HONEYBADGER_REVISION__: "1234567",
    __MEADOW_VERSION__: "v1.2.3",
    dataLayer: [],
  },
  moduleFileExtensions: ["ts", "tsx", "js", "jsx"],
  moduleNameMapper: {
    "\\.(jpg|jpeg|png|gif|eot|otf|webp|svg|ttf|woff|woff2|mp4|webm|wav|mp3|m4a|aac|oga)$":
      "<rootDir>/__mocks__/fileMock.js",
    // Handle module aliases
    "^@js/(.*)$": "<rootDir>/js/$1",
  },
  setupFiles: [],
  setupFilesAfterEnv: ["./jest.setup.ts"],
  testEnvironment: "jsdom",
};
