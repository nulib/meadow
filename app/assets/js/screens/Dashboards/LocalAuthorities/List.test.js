import React from "react";
import { screen, within } from "@testing-library/react";
import ScreensDashboardsLocalAuthoritiesList from "./List";
import { renderWithRouterApollo } from "@js/services/testing-helpers";

describe("ScreensDashboardsLocalAuthoritiesList component", () => {
  beforeEach(() => {
    renderWithRouterApollo(<ScreensDashboardsLocalAuthoritiesList />);
  });

  it("renders the component and title", () => {
    expect(screen.getByTestId("dashboard-local-authorities-screen"));
  });

  it("renders breadcrumbs", () => {
    const breadcrumbs = screen.getByTestId("breadcrumbs");
    const utils = within(breadcrumbs);
    expect(utils.getByText("Dashboards"));
    expect(utils.getByText("Local Authorities"));
  });
});
