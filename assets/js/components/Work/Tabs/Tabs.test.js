import React from "react";
import WorkTabs from "./Tabs";
import { fireEvent } from "@testing-library/react";
import {
  renderWithRouter,
  renderWithRouterApollo,
  mockWork
} from "../../../services/testing-helpers";
import { IIIF_SERVER_URL } from "../../Iiif/iiif.query";

const mocks = [
  {
    request: {
      query: IIIF_SERVER_URL
    },
    result: {
      data: {
        iiifServerUrl: {
          url: "http://localhost:8184/iiif/2/"
        }
      }
    }
  }
];

describe("Tabs component", () => {
  function setupTests() {
    return renderWithRouterApollo(<WorkTabs work={mockWork} />, { mocks });
  }

  it("renders without crashing", () => {
    expect(setupTests()).toBeTruthy();
  });

  it("renders tab section and all four tabs: About, Administrative, Structure, and Preservation", () => {
    const { getByText, getByTestId } = setupTests();

    expect(getByTestId("tabs")).toBeInTheDocument();

    expect(getByTestId("tab-about")).toBeInTheDocument();
    expect(getByTestId("tab-administrative")).toBeInTheDocument();
    expect(getByTestId("tab-structure")).toBeInTheDocument();
    expect(getByTestId("tab-preservation")).toBeInTheDocument();
  });

  it("renders About tab content by default", () => {
    const { queryByTestId } = setupTests();

    expect(queryByTestId("tab-about-content")).toBeVisible();
    expect(queryByTestId("structure-content")).toBeNull();
  });

  it("renders a tab active when clicking on a tab nav item", () => {
    const { queryByTestId, debug } = setupTests();

    expect(queryByTestId("tab-about-content")).not.toHaveClass("is-hidden");

    fireEvent.click(queryByTestId("tab-administrative"));

    expect(queryByTestId("tab-administrative-content")).not.toHaveClass(
      "is-hidden"
    );
    expect(queryByTestId("tab-about-content")).toHaveClass("is-hidden");

    fireEvent.click(queryByTestId("tab-preservation"));

    expect(queryByTestId("tab-about-content")).toHaveClass("is-hidden");
    expect(queryByTestId("tab-administrative-content")).toHaveClass(
      "is-hidden"
    );
    expect(queryByTestId("tab-structure-content")).toHaveClass("is-hidden");
    expect(queryByTestId("tab-preservation-content")).not.toHaveClass(
      "is-hidden"
    );
  });
});
