import React from "react";
import { renderWithRouter } from "../../services/testing-helpers";
import ScreensBatchEdit from "./BatchEdit";

describe("BatchEdit component", () => {
  function setupComponent() {
    return renderWithRouter(<ScreensBatchEdit />, {
      // Mocks sending in 2 items to Batch Edit component via react-router-dom "state"
      state: { items: ["abc123", "bez444"] },
    });
  }

  it("renders without crashing", () => {
    expect(setupComponent());
  });

  it("renders breadcrumbs", () => {
    const { getByTestId } = setupComponent();
    expect(getByTestId("breadcrumbs")).toBeInTheDocument();
  });

  it("renders screen title and number of records editing", () => {
    const { getByTestId, queryByText, debug } = setupComponent();

    expect(getByTestId("title")).toBeInTheDocument();
    expect(getByTestId("num-results")).toBeInTheDocument();
    expect(queryByText("Editing 2 rows")).toBeInTheDocument();
  });

  it("renders the item preview window", () => {
    const { getByTestId } = setupComponent();
    expect(getByTestId("preview-wrapper")).toBeInTheDocument();
  });

  it("renders Tabs section", () => {
    const { getByTestId } = setupComponent();
    expect(getByTestId("tabs-wrapper")).toBeInTheDocument();
  });
});
