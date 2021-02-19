import React from "react";
import { screen } from "@testing-library/react";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import ScreensDashboardsBatchEditList from "./List";
import { getBatchesMock } from "@js/components/Dashboards/dashboards.gql.mock";

describe("ScreensDashboardsBatchEditList component", () => {
  beforeEach(() => {
    renderWithRouterApollo(<ScreensDashboardsBatchEditList />, {
      mocks: [getBatchesMock],
    });
  });

  it("renders the component and screen title", async () => {
    expect(await screen.findByTestId("dashboard-batch-edit-screen"));
    expect(await screen.findByTestId("batch-edit-dashboard-title"));
  });
});
