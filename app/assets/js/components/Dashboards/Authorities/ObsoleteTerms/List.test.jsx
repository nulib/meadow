import React from "react";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import { screen, within } from "@testing-library/react";
import DashboardsObsoleteTermsList from "./List";
import { getObsoleteTermsMock, getObsoleteTermsSetLimitMock } from "@js/components/Dashboards/dashboards.gql.mock";
import userEvent from "@testing-library/user-event";

describe("DashboardsObsoleteTermsList component", () => {
  beforeEach(() => {
    renderWithRouterApollo(<DashboardsObsoleteTermsList />, {
      mocks: [
        getObsoleteTermsMock,
        getObsoleteTermsSetLimitMock,
      ],
    });
  });

  it("renders", async () => {
    expect(await screen.findByTestId("obsolete-terms-dashboard-table"));
  });

  it("renders the correct number of obsolete terms rows", async () => {
    const rows = await screen.findAllByTestId("obsolete-terms-row");
    expect(rows).toHaveLength(2);
  });

  it("renders correct obsolete terms row details", async () => {
    const td = await screen.findByText(
      "http://id.authority.org/test/12345",
    );
    const row = td.closest("tr");
    const utils = within(row);
    expect(utils.getByText(/Obsolete Term 1/i));
    expect(utils.getByText(/http:\/\/id.authority.org\/test\/67890/i));
    expect(utils.getByText(/Replacement Term 1/i));
  });

  it("renders correct obsolete terms query limit options", async () => {
    const options = await screen.findByTestId(
      "obsolete-terms-dashboard-table-options",
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
});
