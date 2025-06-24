import React from "react";
import { screen, within } from "@testing-library/react";
import DashboardsUsersList from "./List";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import { listRolesMock, listUsersMock, setUserRoleMock } from "@js/components/Auth/auth.gql.mock";

describe("DashboardsUsersList component", () => {
  beforeEach(() => {
    renderWithRouterApollo(<DashboardsUsersList />, {
      mocks: [listRolesMock, listUsersMock, setUserRoleMock],
    });
  });

  it("renders the component", async () => {
    expect(await screen.findByTestId("users-dashboard-table"));
  });

  it("renders an add user input", async () => {
    expect(await screen.findByTestId("dashboard-user-add-username"));
    expect(await screen.findByTestId("dashboard-user-add-submit"));
  });

  it("renders user table column headers", async () => {
    const cols = ["Username", "Display Name", "Email", "Role"];
    for (let col of cols) {
      expect(await screen.findByText(col));
    }
  });

  it("renders the correct number of user rows", async () => {
    const rows = await screen.findAllByTestId("user-row");
    expect(rows).toHaveLength(2);
  });

  it("renders correct user row details", async () => {
    const td = await screen.findByText("rdctech@northwestern.edu");
    const row = td.closest("tr");
    const utils = within(row);
    expect(utils.getByText(/nutest/i));
  });

  it("renders a delete button", async () => {
    const td = await screen.findByText("rdctech@northwestern.edu");
    const row = td.closest("tr");
    const utils = within(row);
    expect(utils.getByTestId("remove-user-nutest"));
  });

  it("renders a role select dropdown", async () => {
    const td = await screen.findByText("rdctech@northwestern.edu");
    const row = td.closest("tr");
    const utils = within(row);
    expect(utils.getByTestId("user-role-select-nutest"));
  });
});
