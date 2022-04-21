import React from "react";
import UISearchBar from "./SearchBar";
import { renderWithRouter } from "@js/services/testing-helpers";

describe("UISearchBar component", () => {
  it("renders the search bar component", () => {
    const { getByTestId } = renderWithRouter(<UISearchBar />);
    expect(getByTestId("reactive-search-wrapper")).toBeInTheDocument();
  });
});
