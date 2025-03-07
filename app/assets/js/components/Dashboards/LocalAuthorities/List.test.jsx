import React from "react";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import { screen, within } from "@testing-library/react";
import DashboardsLocalAuthoritiesList from "./List";
import {
  deleteNulAuthorityRecordMock,
  getNulAuthorityRecordsMock,
  getNulAuthorityRecordsSetLimitMock,
  updateNulAuthorityRecordMock,
} from "@js/components/Dashboards/dashboards.gql.mock";
import { authoritiesSearchMock } from "@js/components/Work/controlledVocabulary.gql.mock";
import userEvent from "@testing-library/user-event";

describe("DashboardsLocalAuthoritiesList component", () => {
  beforeEach(() => {
    renderWithRouterApollo(<DashboardsLocalAuthoritiesList />, {
      mocks: [
        deleteNulAuthorityRecordMock,
        getNulAuthorityRecordsMock,
        getNulAuthorityRecordsSetLimitMock,
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
      "info:nul/675ed59a-ab54-481a-9bd1-d9b7fd2604dc",
    );
    const row = td.closest("tr");
    const utils = within(row);
    expect(utils.getByText(/NUL Auth Record 1/i));
    expect(utils.getByText(/Ima Hint 1/i));
  });

  it("renders correct nul authority query limit options", async () => {
    const options = await screen.findByTestId(
      "local-authorities-dashboard-table-options",
    );

    const buttons = within(options).getAllByRole("button");

    // expect 4 buttons
    expect(buttons).toHaveLength(4);

    // expect button text content
    expect(buttons[0]).toHaveTextContent("25");
    expect(buttons[1]).toHaveTextContent("50");
    expect(buttons[2]).toHaveTextContent("100");
    expect(buttons[3]).toHaveTextContent("500");

    // expect default active button
    expect(buttons[2]).toHaveClass("active", "is-primary");

    // expect button click and active class change
    await userEvent.click(buttons[0]);
    expect(await screen.findByText("25")).toHaveClass("active", "is-primary");
  });

  it("renders an edit, search, and delete buttons", async () => {
    const td = await screen.findByText(
      "info:nul/675ed59a-ab54-481a-9bd1-d9b7fd2604dc",
    );
    const row = td.closest("tr");
    const utils = within(row);
    expect(utils.getByTestId("edit-button"));
    expect(utils.getByTestId("button-to-search"));
    expect(utils.getByTestId("delete-button"));
  });
});

describe("DashboardsLocalAuthoritiesList component searching", () => {
  // TODO: Fix this.  Why is is breaking out of nowhere?
  xit("calls the GraphQL query successfully and renders results", async () => {
    // To mock this query, the passed in value must match the return value,
    // otherwise Apollo complains its missing a mocked instance of the query
    const dynamicMock = authoritiesSearchMock("f");
    const user = userEvent.setup();

    renderWithRouterApollo(<DashboardsLocalAuthoritiesList />, {
      mocks: [getNulAuthorityRecordsMock, dynamicMock],
    });

    const el = await screen.findByPlaceholderText("Search");
    expect(await screen.findAllByTestId("nul-authorities-row")).toHaveLength(2);
    await user.type(el, "f");
    expect(await screen.findAllByText("Fast food restaurants"));
  });
});
