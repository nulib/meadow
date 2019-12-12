import React from "react";
import Collection from "./Collection";
import { render } from "@testing-library/react";

describe("Collection component", () => {
  it("renders the root element", () => {
    const { getByTestId } = render(<Collection />);
    expect(getByTestId("collection")).toBeInTheDocument();
  });
});
