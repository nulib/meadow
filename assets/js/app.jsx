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
  apiKey: process.env.HONEYBADGER_API_KEY || "DO_NOT_REPORT",
  environment: process.env.HONEYBADGER_ENVIRONMENT || "dev",
  revision: process.env.HONEYBADGER_REVISION || "1.0",
};

const honeybadger = Honeybadger.configure(config);

setupFontAwesome();

ReactDOM.render(
  <ErrorBoundary honeybadger={honeybadger}>
    <ApolloProvider client={client}>
      <Root />
    </ApolloProvider>
  </ErrorBoundary>,
  document.getElementById("react-app")
);
