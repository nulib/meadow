import React from "react";
import { screen, within } from "@testing-library/react";
import DashboardsBatchEditList from "./List";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import { getBatchesMock } from "@js/components/Dashboards/dashboards.gql.mock";

describe("DashboardsBatchEditList component", () => {
  beforeEach(() => {
    renderWithRouterApollo(<DashboardsBatchEditList />, {
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
    const td = await screen.findByText("7b9fa4c5-fa97-46e8-8fd7-db0001dc76c3");
    const row = td.closest("tr");
    const utils = within(row);
    expect(utils.getByText(/My Batch Job/i));
    expect(utils.getByText(/aja0137/i));
    expect(utils.getByText("43"));
    expect(utils.getByText(/complete/i));
    expect(utils.getByTestId("button-to-search"));
  });

  it("renders a view button", async () => {
    const td = await screen.findByText("7b9fa4c5-fa97-46e8-8fd7-db0001dc76c3");
    const row = td.closest("tr");
    const utils = within(row);
    expect(utils.getByTestId("view-button"));
  });
});
