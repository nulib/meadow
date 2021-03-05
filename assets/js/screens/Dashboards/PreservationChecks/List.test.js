import React from "react";
import { screen, within } from "@testing-library/react";
import ScreensDashboardsPreservationChecksList from "./List";
import { renderWithRouterApollo } from "@js/services/testing-helpers";

describe("ScreensDashboardsPreservationChecksList component", () => {
  beforeEach(() => {
    renderWithRouterApollo(<ScreensDashboardsPreservationChecksList />);
  });

  it("renders the component and title", () => {
    expect(screen.getByTestId("dashboard-preservation-checks-screen"));
  });

  it("renders breadcrumbs", () => {
    const breadcrumbs = screen.getByTestId("breadcrumbs");
    const utils = within(breadcrumbs);
    expect(utils.getByText("Dashboards"));
    expect(utils.getByText("Preservation Checks"));
  });
});
