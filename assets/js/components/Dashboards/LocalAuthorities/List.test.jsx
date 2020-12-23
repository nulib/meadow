import React from "react";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import { screen, within } from "@testing-library/react";
import DashboardsLocalAuthoritiesList from "./List";
import {
  deleteNulAuthorityRecordMock,
  getNulAuthorityRecordsMock,
  updateNulAuthorityRecordMock,
} from "@js/components/Dashboards/dashboards.gql.mock";

describe("DashboardsLocalAuthoritiesList component", () => {
  beforeEach(() => {
    renderWithRouterApollo(<DashboardsLocalAuthoritiesList />, {
      mocks: [
        deleteNulAuthorityRecordMock,
        getNulAuthorityRecordsMock,
        updateNulAuthorityRecordMock,
      ],
    });
  });

  it("renders", async () => {
    expect(await screen.findByTestId("local-authorities-dashboard-table"));
  });

  it("renders the correct number of nul authority rows", async () => {
    const rows = await screen.findAllByTestId("nul-authorities-row");
    expect(rows).toHaveLength(2);
  });

  it("renders correct nul authority row details", async () => {
    const td = await screen.findByText(
      "info:nul/675ed59a-ab54-481a-9bd1-d9b7fd2604dc"
    );
    const row = td.closest("tr");
    const utils = within(row);
    expect(utils.getByText(/NUL Auth Record 1/i));
    expect(utils.getByText(/Ima Hint 1/i));
  });

  it("renders an edit and delete buttons", async () => {
    const td = await screen.findByText(
      "info:nul/675ed59a-ab54-481a-9bd1-d9b7fd2604dc"
    );
    const row = td.closest("tr");
    const utils = within(row);
    expect(utils.getByTestId("edit-button"));
    expect(utils.getByTestId("delete-button"));
  });
});
