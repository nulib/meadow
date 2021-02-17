import React from "react";
import { screen } from "@testing-library/react";
import ScreensDashboardsCsvDetails from "./Details";
import { Route } from "react-router-dom";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import { getCsvMetadataUpdateJobMock } from "@js/components/Dashboards/dashboards.gql.mock";

describe("ScreensDashboardsCsvDetails component", () => {
  it("renders the component", async () => {
    renderWithRouterApollo(
      <Route
        path="/dashboards/csv-metadata-update/:id"
        component={ScreensDashboardsCsvDetails}
      />,
      {
        mocks: [getCsvMetadataUpdateJobMock],
        route:
          "/dashboards/csv-metadata-update/7c171c70-1f1a-4db8-8dcb-07c2c0003e10",
      }
    );
    expect(await screen.findByTestId("dashboard-csv-screen"));
    expect(await screen.findByTestId("page-title"));
  });
});
