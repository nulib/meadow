import { ApolloClient } from "apollo-client";
import { ApolloLink } from "apollo-link";
import { InMemoryCache } from "apollo-cache-inmemory";
import { HttpLink } from "apollo-link-http";
import { setContext } from "apollo-link-context";
import { hasSubscription } from "@jumpn/utils-graphql";
import * as AbsintheSocket from "@absinthe/socket";
import { createAbsintheSocketLink } from "@absinthe/socket-apollo-link";
import { Socket as PhoenixSocket } from "phoenix";

// Create an HTTP link that fetches GraphQL results over an HTTP
// connection from the Phoenix app's GraphQL API endpoint URL.
const httpLink = new HttpLink({ uri: "/api/graphql" });

// Create a WebSocket link that sends GraphQL subscriptions over
// a WebSocket. It connects to the Phoenix app's socket URL
// so subscriptions flow through Phoenix channels.
const absintheSocketLink = createAbsintheSocketLink(
  AbsintheSocket.create(new PhoenixSocket("/socket"))
);

// Create a link that sets the context of the GraphQL request.
// If an authentication token exists in local storage, put
// the token in the "Authorization" request header.
const authLink = setContext((_, { headers }) => {
  const token = localStorage.getItem("auth-token");
  return {
    headers: {
      ...headers,
      authorization: token ? `Bearer ${token}` : ""
    }
  };
});

// Create a link that determines which transport to use
// depending on what type of GraphQL operation is being sent.
// If it's a subscription, send it over the WebSocket link.
// Otherwise, if it's a query or mutation, send it over the HTTP link.
const link = new ApolloLink.split(
  operation => hasSubscription(operation.query),
  absintheSocketLink,
  httpLink
);

// Create the Apollo Client instance.
const client = new ApolloClient({
  link: link,
  cache: new InMemoryCache()
});

export default client;
