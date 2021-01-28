import React from "react";
import { screen } from "@testing-library/react";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import ScreensDashboardsCsvList from "./List";
import { getCsvMetadataUpdateJobsMock } from "@js/components/Dashboards/dashboards.gql.mock";

jest.mock("@js/services/elasticsearch");

describe("ScreensDashboardsCsvList component", () => {
  beforeEach(() => {
    renderWithRouterApollo(<ScreensDashboardsCsvList />, {
      mocks: [getCsvMetadataUpdateJobsMock],
    });
  });

  it("renders the component and screen title", async () => {
    expect(await screen.findByTestId("dashboard-csv-screen"));
  });

  it("renders child content", async () => {
    expect(await screen.findByTestId("csv-dashboard-title"));
    expect(await screen.findByTestId("csv-list"));
  });
});
