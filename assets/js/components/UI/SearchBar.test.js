import React from "react";
import UISearchBar from "./SearchBar";
import { renderWithRouter } from "@js/services/testing-helpers";

jest.mock("../../services/elasticsearch");

describe("UISearchBar component", () => {
  it("renders the search bar component", () => {
    const { getByTestId } = renderWithRouter(<UISearchBar />);
    expect(getByTestId("reactive-search-wrapper")).toBeInTheDocument();
  });
});
