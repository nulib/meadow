import "../styles/app.scss";
import "phoenix_html";
import React from "react";
import ReactDOM from "react-dom";
import Root from "./screens/Root";
import setupFontAwesome from "./font-awesome-setup";
import Honeybadger from "@honeybadger-io/js";
import ErrorBoundary from "@honeybadger-io/react";

// GraphQL-specific
import { ApolloProvider } from "@apollo/client";
import client from "./client";

const config = {
  apiKey: __HONEYBADGER_API_KEY__,
  environment: __HONEYBADGER_ENVIRONMENT__,
  revision: __HONEYBADGER_REVISION__,
};

const honeybadger = Honeybadger
  .configure(config)
  .setContext({ meadow_version: __MEADOW_VERSION__ });

setupFontAwesome();

ReactDOM.render(
  <ErrorBoundary honeybadger={honeybadger}>
    <ApolloProvider client={client}>
      <Root />
    </ApolloProvider>
  </ErrorBoundary>,
  document.getElementById("react-app")
);
