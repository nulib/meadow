import React from "react";
import { screen } from "@testing-library/react";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import DashboardsLocalAuthoritiesTitleBar from "./TitleBar";
import userEvent from "@testing-library/user-event";

describe("DashboardsLocalAuthoritiesTitleBar component", () => {
  beforeEach(() => {
    renderWithRouterApollo(<DashboardsLocalAuthoritiesTitleBar />);
  });

  it("renders component, title and add new button", () => {
    expect(screen.getByTestId("nul-authorities-title-bar"));
    expect(screen.getByTestId("local-authorities-dashboard-title"));
    expect(screen.getByTestId("add-button"));
    expect(screen.getByTestId("bulk-add-button"));
    expect(screen.getByTestId("button-csv-authority-export"));
  });

  it("renders the Add modal and displays the modal successfully when clicking the Add button", async () => {
    const user = userEvent.setup();
    const modalEl = screen.getByTestId("modal-nul-authority-add");
    expect(modalEl).not.toHaveClass("is-active");
    await user.click(screen.getByTestId("add-button"));
    expect(modalEl).toHaveClass("is-active");
  });

  it("renders the Bulk Add modal and displays the modal successfully when clicking the Bulk Add button", async () => {
    const user = userEvent.setup();
    const modalEl = screen.getByTestId("modal-nul-authority-bulk-add");
    expect(modalEl).not.toHaveClass("is-active");
    await user.click(screen.getByTestId("bulk-add-button"));
    expect(modalEl).toHaveClass("is-active");
  });
});
