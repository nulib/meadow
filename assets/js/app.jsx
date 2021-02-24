import "../styles/app.scss";
import "phoenix_html";
import React from "react";
import ReactDOM from "react-dom";
import Root from "./screens/Root";
import setupFontAwesome from "./font-awesome-setup";

// GraphQL-specific
import { ApolloProvider } from "@apollo/client";
import client from "./client";

setupFontAwesome();

ReactDOM.render(
  <ApolloProvider client={client}>
    <Root />
  </ApolloProvider>,
  document.getElementById("react-app")
);
