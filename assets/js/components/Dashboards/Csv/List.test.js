import React from "react";
import { screen, within } from "@testing-library/react";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import DashboardsCsvList from "@js/components/Dashboards/Csv/List";
import { getCsvMetadataUpdateJobsMock } from "@js/components/Dashboards/dashboards.gql.mock";

describe("DashboardsCsvList component", () => {
  beforeEach(() => {
    renderWithRouterApollo(<DashboardsCsvList />, {
      mocks: [getCsvMetadataUpdateJobsMock],
    });
  });

  it("renders", () => {
    expect(screen.getByTestId("csv-list"));
  });

  it("renders the search bar row", () => {
    expect(screen.getByTestId("search-bar-row"));
  });

  it("renders the correct number of csv import job rows", async () => {
    const rows = await screen.findAllByTestId("csv-row");
    expect(rows).toHaveLength(2);
  });

  it("renders correct csv import job row details", async () => {
    const td = await screen.findByText("csv-contributor-faceted-mandela.csv");
    const row = td.closest("tr");
    const utils = within(row);
    expect(utils.getByText(/complete/i));
    expect(utils.getByText(/aja0137/i));
  });

  it("renders a view button", async () => {
    const td = await screen.findByText("csv-contributor-faceted-mandela.csv");
    const row = td.closest("tr");
    const utils = within(row);
    const buttonLink = utils.getByTestId("view-button");
    expect(buttonLink.href).toContain(
      "dashboards/csv-metadata-update/7c171c70-1f1a-4db8-8dcb-07c2c0003e10"
    );
  });
});
