import React from "react";
import { screen, within } from "@testing-library/react";
import DashboardsBatchEditTable from "./BatchEditTable";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import { getBatchesMock } from "@js/components/Dashboards/dashboards.gql.mock";

describe("DashboardsBatchEditTable component", () => {
  beforeEach(() => {
    renderWithRouterApollo(<DashboardsBatchEditTable />, {
      mocks: [getBatchesMock],
    });
  });

  it("renders the component", async () => {
    expect(await screen.findByTestId("batch-dashboard-table"));
  });

  it("renders batch job column headers", async () => {
    const cols = [
      "Nickname",
      "Type",
      "Started",
      "User",
      "Works Updated",
      "Status",
    ];
    for (let col of cols) {
      expect(await screen.findByText(col));
    }
  });

  it("renders the correct number of batch job rows", async () => {
    const rows = await screen.findAllByTestId("batches-row");
    expect(rows).toHaveLength(4);
  });

  it("renders correct batch job row details", async () => {
    const td = await screen.findByText("Dec 08, 2020 11:24 AM");
    const row = td.closest("tr");
    const utils = within(row);
    expect(utils.getByText(/My Batch Job/i));
    expect(utils.getByText(/aja0137/i));
    expect(utils.getByText("43"));
    expect(utils.getByText(/complete/i));
  });

  it("renders a view button", async () => {
    const td = await screen.findByText("Dec 08, 2020 11:24 AM");
    const row = td.closest("tr");
    const utils = within(row);
    expect(utils.getByTestId("view-button"));
  });
});
