import "../styles/app.scss";

// GraphQL-specific
import { ApolloProvider } from "@apollo/client";
import ErrorBoundary from "@honeybadger-io/react";
import Honeybadger from "@honeybadger-io/js";
import React from "react";
import Root from "./screens/Root";
import client from "./client";
import { createRoot } from "react-dom/client";
import isUndefined from "lodash.isundefined";

const ifDefined = (value, fallback) => (isUndefined(value) ? fallback : value);

const config = {
  apiKey: ifDefined(__HONEYBADGER_API_KEY__, "DO_NOT_REPORT"),
  environment: ifDefined(__HONEYBADGER_ENVIRONMENT__, "dev"),
  revision: ifDefined(__HONEYBADGER_REVISION__, "unknown"),
};

const honeybadger = Honeybadger.configure(config).setContext({
  meadow_version: ifDefined(__MEADOW_VERSION__, "unknown"),
  tags: "frontend",
});

const container = document.getElementById("react-app");
const root = createRoot(container);
root.render(
  <ErrorBoundary honeybadger={honeybadger}>
    <ApolloProvider client={client}>
      <Root />
    </ApolloProvider>
  </ErrorBoundary>
);
