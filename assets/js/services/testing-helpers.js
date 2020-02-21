import React from "react";
import { Router } from "react-router-dom";
import { act, render } from "@testing-library/react";
import { createMemoryHistory } from "history";
import { MockedProvider } from "@apollo/react-testing";

/**
 * Testing Library utility function to wrap tested component in React Router history
 * @param {ReactElement} ui A React element
 * @param objectParameters
 * @param objectParameters.route Starting route to feed React Router's history
 * @param objectParameters.history Override the history object if desired
 */
export function renderWithRouter(
  ui,
  {
    route = "/",
    history = createMemoryHistory({ initialEntries: [route] })
  } = {}
) {
  const Wrapper = ({ children }) => (
    <Router history={history}>{children}</Router>
  );

  return {
    ...render(ui, { wrapper: Wrapper }),
    // adding `history` to the returned utilities to allow us
    // to reference it in our tests (just try to avoid using
    // this to test implementation details).
    history
  };
}

/**
 * Testing Library utility function to wrap tested component in Apollo Client's
 * MockProvider along with React Router
 * @param {ReactElement} ui React element
 * @param {Object} objectParameters
 * @param {Array} objectParameters.mocks Apollo Client MockProvider mock
 * @param {String} objectParameters.route Starting route to feed React Router's history
 * @param objectParameters.history Override the history object if desired
 */
export function renderWithRouterApollo(
  ui,
  {
    mocks = [],
    route = "/",
    history = createMemoryHistory({ initialEntries: [route] })
  } = {}
) {
  const Wrapper = ({ children }) => (
    <MockedProvider mocks={mocks} addTypename={false}>
      <Router history={history}>{children}</Router>
    </MockedProvider>
  );

  return {
    ...render(ui, { wrapper: Wrapper })
  };
}

export function renderWithApollo(ui, { mocks = [] }) {
  const Wrapper = ({ children }) => (
    <MockedProvider mocks={mocks} addTypename={false}>
      {children}
    </MockedProvider>
  );

  return {
    ...render(ui, { wrapper: Wrapper })
  };
}

export const mockWork = {
  accessionNumber: "Example-34",
  fileSets: [
    {
      accessionNumber: "Example-34-3",
      id: "01DV4BAEAGKNT5P3GH10X263K1",
      metadata: {
        description: "Lorem Ipsum"
      },
      work: {
        id: "01DV4BAE9NDQHSMRHKM8KC4FNC"
      }
    },
    {
      accessionNumber: "Example-34-4",
      id: "01DV4BAEANHGYQKQ2EPBWJVJSR",
      metadata: {
        description: "Lorem Ipsum"
      },
      work: {
        id: "01DV4BAE9NDQHSMRHKM8KC4FNC"
      }
    }
  ],
  id: "01DV4BAE9NDQHSMRHKM8KC4FNC",
  insertedAt: "2019-12-02T22:22:30",
  descriptiveMetadata: {
    title: null
  },
  updatedAt: "2019-12-02T22:22:30",
  visibility: "RESTRICTED",
  workType: "IMAGE"
};
