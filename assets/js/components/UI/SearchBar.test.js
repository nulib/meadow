import React from "react";
import { render } from "@testing-library/react";
import UISearchBar from "./SearchBar";

describe("UISearchBar component", () => {
  it("renders without crashing", () => {
    expect(render(<UISearchBar />));
  });

  it("renders the search bar component", () => {
    const { getByTestId } = render(<UISearchBar />);
    expect(getByTestId("reactive-search-bar")).toBeInTheDocument();
  });
});
