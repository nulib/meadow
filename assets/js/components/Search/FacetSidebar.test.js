import React from "react";
import SearchFacetSidebar from "./FacetSidebar";
import { render } from "@testing-library/react";

describe("SearchFacetSidebar component", () => {
  it("renders without crashing", () => {
    const { getByTestId } = render(<SearchFacetSidebar />);
    expect(getByTestId("search-facet-sidebar-wrapper")).toBeInTheDocument();
  });
});
