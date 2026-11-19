import React from "react";
import SearchResults from "./Results";
import { iiifServerUrlMock } from "@js/components/IIIF/iiif.gql.mock";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import { fireEvent, waitFor } from "@testing-library/react";
import { SEARCH_SORT_STORAGE_KEY } from "@js/services/search-sort";

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
  beforeEach(() => {
    localStorage.clear();
  });

  it("renders", async () => {
    const { getByTestId } = renderWithRouterApollo(
      <SearchResults {...defaultProps} />,
      {
        mocks,
      },
    );

    await waitFor(() => {
      expect(getByTestId("search-results-component")).toBeInTheDocument();
    });
  });

  it("renders sort controls in the result stats row, defaulting to relevancy", async () => {
    const { getByTestId, queryByTestId } = renderWithRouterApollo(
      <SearchResults {...defaultProps} />,
      { mocks },
    );

    const select = (await waitFor(() =>
      getByTestId("search-sort-field"),
    )) as HTMLSelectElement;
    expect(getByTestId("search-result-stats")).toBeInTheDocument();
    expect(select.value).toEqual("relevancy");
    expect(select).toHaveDisplayValue("Relevancy");
    expect(queryByTestId("search-sort-direction")).toBeNull();
  });

  it("remembers the chosen field and direction in localStorage", async () => {
    const { getByTestId } = renderWithRouterApollo(
      <SearchResults {...defaultProps} />,
      { mocks },
    );

    const select = (await waitFor(() =>
      getByTestId("search-sort-field"),
    )) as HTMLSelectElement;

    fireEvent.change(select, { target: { value: "date-created" } });
    expect(select.value).toEqual("date-created");
    expect(getByTestId("search-sort-direction")).toHaveAttribute(
      "data-direction",
      "asc",
    );
    expect(JSON.parse(localStorage.getItem(SEARCH_SORT_STORAGE_KEY)!)).toEqual({
      field: "date-created",
      direction: "asc",
    });

    fireEvent.click(getByTestId("search-sort-direction"));
    expect(getByTestId("search-sort-direction")).toHaveAttribute(
      "data-direction",
      "desc",
    );
    expect(JSON.parse(localStorage.getItem(SEARCH_SORT_STORAGE_KEY)!)).toEqual({
      field: "date-created",
      direction: "desc",
    });
  });

  it("restores a previously chosen sort", async () => {
    localStorage.setItem(
      SEARCH_SORT_STORAGE_KEY,
      JSON.stringify({ field: "title", direction: "desc" }),
    );

    const { getByTestId } = renderWithRouterApollo(
      <SearchResults {...defaultProps} />,
      { mocks },
    );

    const select = (await waitFor(() =>
      getByTestId("search-sort-field"),
    )) as HTMLSelectElement;
    expect(select.value).toEqual("title");
    expect(getByTestId("search-sort-direction")).toHaveAttribute(
      "title",
      "Z to A (click for A to Z)",
    );
  });

  // Note currently doesn't seem that ReactiveSearch provides any kind of mocking
  // Provider mechanism.  So it's near impossible to test what ReactiveSearch renders...
});
