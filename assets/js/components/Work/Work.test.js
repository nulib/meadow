import React from "react";
import Work from "./Work";
import { renderWithRouter, mockWork } from "../../testing-helpers";

describe("Work component", () => {
  function setupTests() {
    return renderWithRouter(<Work work={mockWork} />);
  }

  it("renders without crashing", () => {
    expect(setupTests()).toBeTruthy();
  });

  it("renders the work element", () => {
    // TODO: Flesh this out more as the Work component becomes more real
    const { getByTestId, getByText } = setupTests();
    expect(getByTestId("work")).toBeInTheDocument();
    expect(getByTestId("tabs")).toBeInTheDocument();
  });
});
