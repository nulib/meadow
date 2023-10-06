import React from "react";
import SearchResults from "./Results";
import { iiifServerUrlMock } from "@js/components/IIIF/iiif.gql.mock";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import { waitFor } from "@testing-library/react";

// Mock GraphQL queries
const mocks = [iiifServerUrlMock];

const defaultProps = {
  handleOnDataChange: jest.fn(),
  handleQueryChange: jest.fn(),
  handleSelectItem: jest.fn(),
  isListView: false,
  selectedItems: [],
};

describe("SearchResults component", () => {
  it("renders", async () => {
    const { getByTestId } = renderWithRouterApollo(
      <SearchResults {...defaultProps} />,
      {
        mocks,
      }
    );

    await waitFor(() => {
      expect(getByTestId("search-results-component")).toBeInTheDocument();
    });
  });

  // Note currently doesn't seem that ReactiveSearch provides any kind of mocking
  // Provider mechanism.  So it's near impossible to test what ReactiveSearch renders...
});
