import React from "react";
import Work from "./Work";
import { fireEvent } from "@testing-library/react";
import {
  renderWithRouterApollo,
  mockWork
} from "../../services/testing-helpers";

describe("Work component", () => {
  function setupTests() {
    return renderWithRouterApollo(<Work work={mockWork} />);
  }

  it("renders without crashing", () => {
    expect(setupTests()).toBeTruthy();
  });

  it("renders the viewer and tabs", () => {
    const { getByTestId } = setupTests();
    expect(getByTestId("viewer")).toBeInTheDocument();
    expect(getByTestId("tabs")).toBeInTheDocument();
  });
});
