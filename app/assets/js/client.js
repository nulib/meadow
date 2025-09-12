import {
  ApolloClient,
  ApolloLink,
  HttpLink,
  InMemoryCache,
} from "@apollo/client";
import { Defer20220824Handler } from "@apollo/client/incremental";
import { LocalState } from "@apollo/client/local-state";
import { resolvers, typeDefs } from "./client-local";

import { Socket as PhoenixSocket } from "phoenix";
import fetch from "node-fetch";
import { hasSubscription } from "@jumpn/utils-graphql";
import { setContext } from "@apollo/client/link/context";

// The following packages don't work well with esbuild when imported; the workaround
// is to require them https://github.com/absinthe-graphql/absinthe-socket/issues/59
// import * as AbsintheSocket from "@absinthe/socket";
// import { createAbsintheSocketLink } from "@absinthe/socket-apollo-link";
const AbsintheSocket = require("@absinthe/socket");
const { createAbsintheSocketLink } = require("@absinthe/socket-apollo-link");

// Create an HTTP link that fetches GraphQL results over an HTTP
// connection from the Phoenix app's GraphQL API endpoint URL.
const httpLink = new HttpLink({
  uri: "/api/graphql",
  fetch,
});

// Create a WebSocket link that sends GraphQL subscriptions over
// a WebSocket. It connects to the Phoenix app's socket URL
// so subscriptions flow through Phoenix channels.
const absintheSocketLink = createAbsintheSocketLink(
  AbsintheSocket.create(new PhoenixSocket("/socket"))
);

// Create a link that determines which transport to use
// depending on what type of GraphQL operation is being sent.
// If it's a subscription, send it over the WebSocket link.
// Otherwise, if it's a query or mutation, send it over the HTTP link.
const link = ApolloLink.split(
  (operation) => hasSubscription(operation.query),
  absintheSocketLink,
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
  link: new HttpLink({}),

  /*
  Inserted by Apollo Client 3->4 migration codemod.
  If you are not using the `@client` directive in your application,
  you can safely remove this option.
  */
  localState: new LocalState({}),

  /*
  Inserted by Apollo Client 3->4 migration codemod.
  If you are not using the `@defer` directive in your application,
  you can safely remove this option.
  */
  incrementalHandler: new Defer20220824Handler()
});

export default client;
