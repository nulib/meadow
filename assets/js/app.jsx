import "../css/app.css";

import "phoenix_html";

import React from "react";
import ReactDOM from "react-dom";
import Root from "./screens/Root";

// GraphQL-specific
import { ApolloProvider } from "react-apollo";
import client from "./client";

ReactDOM.render(<ApolloProvider client={client}>
  <Root />
</ApolloProvider>,
  document.getElementById("react-app"));
