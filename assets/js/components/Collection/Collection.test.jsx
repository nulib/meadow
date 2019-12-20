import React from "react";
import Collection from "./Collection";
import { render } from "@testing-library/react";

xdescribe("Collection component", () => {
  xit("renders the root element", () => {
    const { getByTestId } = render(<Collection />);
    expect(getByTestId("collection")).toBeInTheDocument();
  });
});
