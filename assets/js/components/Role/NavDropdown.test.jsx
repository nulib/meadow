import React from "react";
import RoleNavDropdown from "./NavDropdown";
import { screen } from "@testing-library/react";
import { renderWithRouterApollo } from "@js/services/testing-helpers";

describe("RoleNavDropdown component", () => {
  beforeEach(() => {
    renderWithRouterApollo(<RoleNavDropdown />);
  });

  it("renders the dropdown", () => {
    expect(screen.getAllByRole("menuitem")).toHaveLength(6);
  });
});
