import React from "react";
import CollectionSearch from "./Search";
import { render } from "@testing-library/react";

describe("CollectionSearch component", () => {
  it("renders the root element", () => {
    const { getByTestId } = render(<CollectionSearch />);
    expect(getByTestId("collection-search")).toBeInTheDocument();
  });
});
