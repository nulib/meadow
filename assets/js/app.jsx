import "../styles/app.scss";
import "phoenix_html";
import isUndefined from "lodash.isundefined";
import React from "react";
import ReactDOM from "react-dom";
import Root from "./screens/Root";
import setupFontAwesome from "./font-awesome-setup";
import Honeybadger from "@honeybadger-io/js";
import ErrorBoundary from "@honeybadger-io/react";

// GraphQL-specific
import { ApolloProvider } from "@apollo/client";
import client from "./client";

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

setupFontAwesome();

ReactDOM.render(
  <ErrorBoundary honeybadger={honeybadger}>
    <ApolloProvider client={client}>
      <Root />
    </ApolloProvider>
  </ErrorBoundary>,
  document.getElementById("react-app")
);
