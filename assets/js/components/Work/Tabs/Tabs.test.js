import React from "react";
import WorkTabs from "./Tabs";
import { fireEvent } from "@testing-library/react";
import { renderWithRouter, mockWork } from "../../../services/testing-helpers";

describe("Tabs component", () => {
  function setupTests() {
    return renderWithRouter(<WorkTabs work={mockWork} />);
  }

  it("renders without crashing", () => {
    expect(setupTests()).toBeTruthy();
  });

  it("renders tab section and all four tabs: About, Administrative, Structure, and Preservation", () => {
    const { getByText, getByTestId } = setupTests();

    expect(getByTestId("tabs")).toBeInTheDocument();

    expect(getByText(/About this item/i)).toBeInTheDocument();
    expect(getByText(/Administrative/i)).toBeInTheDocument();
    expect(getByText(/Structure/i)).toBeInTheDocument();
    expect(getByText(/Preservation/i)).toBeInTheDocument();
  });

  it("renders About tab content by default", () => {
    const { queryByTestId } = setupTests();

    expect(queryByTestId("tab-about-content")).toBeVisible();
    expect(queryByTestId("structure-content")).toBeNull();
  });

  it("renders a tab active when clicking on a tab nav item", () => {
    const { queryByTestId, debug } = setupTests();

    expect(queryByTestId("tab-about-content")).not.toBeNull();

    fireEvent.click(queryByTestId("tab-administrative"));

    expect(queryByTestId("tab-administrative-content")).toBeVisible();
    expect(queryByTestId("tab-about-content")).toBeNull();

    fireEvent.click(queryByTestId("tab-preservation"));

    expect(queryByTestId("tab-about-content")).toBeNull();
    expect(queryByTestId("tab-administrative-content")).toBeNull();
    expect(queryByTestId("tab-structure-content")).toBeNull();
    expect(queryByTestId("tab-preservation-content")).toBeVisible();
  });
});
