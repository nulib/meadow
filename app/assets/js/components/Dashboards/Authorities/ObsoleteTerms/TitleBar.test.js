import React from "react";
import { screen } from "@testing-library/react";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import DashboardsObsoleteTermsTitleBar from "./TitleBar";

describe("DashboardsObsoleteTermsTitleBar component", () => {
  beforeEach(() => {
    renderWithRouterApollo(<DashboardsObsoleteTermsTitleBar />);
  });

  it("renders component, title and add new button", () => {
    expect(screen.getByTestId("obsolete-terms-title-bar"));
    expect(screen.getByTestId("obsolete-terms-dashboard-title"));
  });
});
