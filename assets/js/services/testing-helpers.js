import React from "react";
import { Router } from "react-router-dom";
import { render } from "@testing-library/react";
import { createMemoryHistory } from "history";
import { MockedProvider } from "@apollo/react-testing";
import { ReactiveBase } from "@appbaseio/reactivesearch";
import { resolvers } from "../client-local";

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
    history = createMemoryHistory({ initialEntries: [route] }),
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
    history,
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
    history = createMemoryHistory({ initialEntries: [route] }),
  } = {}
) {
  const Wrapper = ({ children }) => (
    <MockedProvider
      mocks={mocks}
      addTypename={false}
      resolvers={resolvers}
      defaultOptions={{
        watchQuery: { fetchPolicy: "no-cache" },
        query: { fetchPolicy: "no-cache" },
      }}
    >
      <Router history={history}>{children}</Router>
    </MockedProvider>
  );

  return {
    ...render(ui, { wrapper: Wrapper }),
  };
}

export function renderWithApollo(ui, { mocks = [] }) {
  const Wrapper = ({ children }) => (
    <MockedProvider
      mocks={mocks}
      addTypename={false}
      resolvers={resolvers}
      defaultOptions={{
        watchQuery: { fetchPolicy: "no-cache" },
        query: { fetchPolicy: "no-cache" },
      }}
    >
      {children}
    </MockedProvider>
  );

  return {
    ...render(ui, { wrapper: Wrapper }),
  };
}

export const mockWork = {
  accessionNumber: "Example-34",
  administrativeMetadata: {
    preservationLevel: {
      id: "0",
      label: "Level 0",
    },
    status: {
      id: "DONE",
      label: "Done",
    },
  },
  collection: {
    id: "147238",
    name: "Collection Name",
  },
  fileSets: [
    {
      accessionNumber: "Example-34-3",
      role: "AM",
      id: "01DV4BAEAGKNT5P3GH10X263K1",
      metadata: {
        description: "Lorem Ipsum",
        original_filename: "foo.tiff",
        location: "s3://bucket/foo/bar",
        label: "foo.tiff",
        sha256: "123481439834-098349-8",
      },
    },
    {
      accessionNumber: "Example-34-4",
      id: "01DV4BAEANHGYQKQ2EPBWJVJSR",
      role: "AM",
      metadata: {
        description: "Lorem Ipsum",
        original_filename: "foo.tiff",
        location: "s3://bucket/foo/bar",
        label: "foo.tiff",
        sha256: "123481439834-098349-8",
      },
    },
  ],
  id: "01DV4BAE9NDQHSMRHKM8KC4FNC",
  insertedAt: "2019-12-02T22:22:30",
  descriptiveMetadata: {
    title: "Ima title",
    description: "Ima description",
    contributor: [
      {
        id: "http://id.gov.loc/someone",
        label: "Some One",
        role: {
          id: "aut",
          label: "Author",
          scheme: "MARC_RELATOR",
        },
      },
    ],
    creator: [
      {
        id: "https://theurioftheresource",
        label: "This is the label",
      },
    ],
    genre: [
      {
        id: "https://theurioftheresource",
        label: "This is the label",
      },
    ],
    language: [
      {
        id: "https://theurioftheresource",
        label: "This is the label",
      },
    ],
    license: {
      id: "https://theurioftheresource",
      label: "This is the label",
    },
    location: [
      {
        id: "https://theurioftheresource",
        label: "This is the label",
      },
    ],
    rightsStatement: {
      id: "https://theurioftheresource",
      label: "This is the label",
    },
    stylePeriod: [
      {
        id: "https://theurioftheresource",
        label: "This is the label",
      },
    ],
    subject: [
      {
        id: "http://id.gov.loc/something",
        label: "Some Thing",
        role: {
          id: "topical",
          label: "Topical",
          scheme: "SUBJECT",
        },
      },
    ],
    technique: [
      {
        id: "https://theurioftheresource",
        label: "This is the label",
      },
    ],
  },
  updatedAt: "2019-12-02T22:22:30",
  published: false,
  project: {
    id: "28b6dd45-ef3e-45df-b380-985c9af8b495",
    name: "Foo",
  },
  sheet: {
    id: "28b6dd45-ef3e-45df-b380-985c9af8b495",
    name: "Bar",
  },
  manifestUrl: "http://foobar",
  representativeImage: "http://foobar",
  visibility: {
    id: "OPEN",
    label: "Public",
  },
  workType: {
    id: "IMAGE",
    label: "Image",
  },
};
