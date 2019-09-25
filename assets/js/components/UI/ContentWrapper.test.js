import React from "react";
import ContentWrapper from "./ContentWrapper";
import { render } from "@testing-library/react";

it("renders without errors", () => {
  const { container } = render(<ContentWrapper />);
  expect(container);
});
