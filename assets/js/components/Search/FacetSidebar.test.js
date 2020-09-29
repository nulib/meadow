import React from "react";
import SearchFacetSidebar from "./FacetSidebar";
import { renderWithRouter } from "../../services/testing-helpers";

jest.mock("../../services/elasticsearch");

describe("SearchFacetSidebar component", () => {
  it("renders without crashing", () => {
    const { getByTestId } = renderWithRouter(<SearchFacetSidebar />);
    expect(getByTestId("search-facet-sidebar-wrapper")).toBeInTheDocument();
  });
});
