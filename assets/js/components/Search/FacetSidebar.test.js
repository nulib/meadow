import React from "react";
import SearchFacetSidebar from "./FacetSidebar";
import { renderWithRouter } from "../../services/testing-helpers";
import { screen } from "@testing-library/react";

// NOTE: We can't test the actual ReactiveSearch facets, so have to mock them just to avoid tests crashing

describe("SearchFacetSidebar component", () => {
  beforeEach(() => {
    renderWithRouter(<SearchFacetSidebar />);
  });

  it("renders without crashing", () => {
    expect(
      screen.getByTestId("search-facet-sidebar-wrapper")
    ).toBeInTheDocument();
  });

  it("renders all general facet category boxes", () => {
    expect(screen.getByTestId("general-facets"));
    expect(screen.getByTestId("technical-facets"));
    expect(screen.getByTestId("project-facets"));
  });
});
