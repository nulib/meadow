import {
  ApolloClient,
  ApolloLink,
  HttpLink,
  InMemoryCache,
} from "@apollo/client";
import { GraphQLWsLink } from "@apollo/client/link/subscriptions";
import { createClient } from "graphql-ws";
import { resolvers, typeDefs } from "./client-local";

import fetch from "node-fetch";
import { hasSubscription } from "@jumpn/utils-graphql";
import { setContext } from "@apollo/client/link/context";

// Create an HTTP link that fetches GraphQL results over an HTTP
// connection from the Phoenix app's GraphQL API endpoint URL.
const httpLink = new HttpLink({
  uri: "/api/graphql",
  fetch,
});

// Create a WebSocket client using the graphql-ws protocol
// with keepalive pings to maintain connection stability
const wsClient = createClient({
  url: `${window.location.protocol === "https:" ? "wss:" : "ws:"}//${window.location.host}/graphql/ws/websocket`,
  keepAlive: 15000, // Send keepalive pings every 15 seconds
  retryAttempts: 5,
  shouldRetry: () => true,
  lazy: false, // Establish connection immediately
  on: {
    connected: () => console.log("WebSocket connected"),
    closed: () => console.log("WebSocket closed"),
    error: (error) => console.error("WebSocket error:", error),
  },
});

// Create a WebSocket link that sends GraphQL subscriptions over
// the graphql-ws protocol with built-in keepalive support
const wsLink = new GraphQLWsLink(wsClient);

// Create a link that determines which transport to use
// depending on what type of GraphQL operation is being sent.
// If it's a subscription, send it over the WebSocket link.
// Otherwise, if it's a query or mutation, send it over the HTTP link.
const link = new ApolloLink.split(
  (operation) => hasSubscription(operation.query),
  wsLink,
  httpLink
);

// Create the Apollo Client instance.
const client = new ApolloClient({
  link: link,
  cache: new InMemoryCache({
    typePolicies: {
      ControlledValue: {
        keyFields: ["id", "hint"],
      },
      FileSet: {
        fields: {
          coreMetadata: { merge: false },
        },
      },
    },
  }),
  typeDefs,
  resolvers,
});

export default client;
