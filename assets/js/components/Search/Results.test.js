import React from "react";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import SearchResults from "./Results";
import { iiifServerUrlMock } from "../IIIF/iiif.gql.mock";
import { waitFor } from "@testing-library/react";

// Mock GraphQL queries
const mocks = [iiifServerUrlMock];

describe("SearchResults component", () => {
  it("renders", async () => {
    const { getByTestId } = renderWithRouterApollo(<SearchResults />, {
      mocks: [iiifServerUrlMock],
    });

    await waitFor(() => {
      expect(getByTestId("search-results-component")).toBeInTheDocument();
    });
  });

  // Note currently doesn't seem that ReactiveSearch provides any kind of mocking
  // Provider mechanism.  So it's near impossible to test what ReactiveSearch renders...
});
