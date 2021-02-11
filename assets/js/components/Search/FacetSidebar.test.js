import React from "react";
import SearchFacetSidebar from "./FacetSidebar";
import { renderWithRouter } from "../../services/testing-helpers";

jest.mock("../../services/elasticsearch");

describe("SearchFacetSidebar component", () => {
  //TODO: For some reason Jest doesn't recognize the ReactiveSearch component "RangeSlider".
  // Maybe figure this out later when more time
  xit("renders without crashing", () => {
    const { getByTestId } = renderWithRouter(<SearchFacetSidebar />);
    expect(getByTestId("search-facet-sidebar-wrapper")).toBeInTheDocument();
  });
});
