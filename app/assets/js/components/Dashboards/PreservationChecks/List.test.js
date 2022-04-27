import React from "react";
import { screen, within } from "@testing-library/react";
import DashboardsPreservationChecksList from "./List";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import { getPreservationChecksMocks } from "@js/components/Dashboards/dashboards.gql.mock";

describe("DashboardsPreservationChecksList component", () => {
  beforeEach(() => {
    renderWithRouterApollo(<DashboardsPreservationChecksList />, {
      mocks: [getPreservationChecksMocks],
    });
  });

  it("renders the component", async () => {
    expect(await screen.findByTestId("preservation-checks-dashboard-table"));
  });

  it("renders batch job column headers", async () => {
    const cols = ["Started", "Completed", "Job Status", "Errors", "Filename"];
    for (let col of cols) {
      expect(await screen.findByText(col));
    }
  });

  it("renders the correct number of batch job rows", async () => {
    const rows = await screen.findAllByTestId("preservation-check-row");
    expect(rows).toHaveLength(2);
  });

  it("renders correct batch job row details", async () => {
    const td = await screen.findByText("7c171c70-1f1a-4db8-8dcb-07c2c0003e10");
    const row = td.closest("tr");
    const utils = within(row);
    expect(utils.getByText(/preservation_check.csv/i));
  });

  it("renders a download button", async () => {
    const td = await screen.findByText("7c171c70-1f1a-4db8-8dcb-07c2c0003e10");
    const row = td.closest("tr");
    const utils = within(row);
    expect(utils.getByTestId("download-button"));
  });
});
