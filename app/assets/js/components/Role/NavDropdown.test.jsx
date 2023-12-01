import React from "react";
import RoleNavDropdown from "./NavDropdown";
import { screen } from "@testing-library/react";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import { mockUser } from "@js/components/Auth/auth.gql.mock";
import useIsAuthorized from "@js/hooks/useIsAuthorized";

jest.mock("@js/hooks/useIsAuthorized");
useIsAuthorized.mockReturnValue({
  user: mockUser,
  isAuthorized: () => true,
});

describe("RoleNavDropdown component", () => {
  beforeEach(() => {
    renderWithRouterApollo(<RoleNavDropdown />);
  });

  it("renders the dropdown", () => {
    expect(screen.getAllByRole("menu")).toHaveLength(1);
    expect(screen.getByText("Administrator", { exact: true })).toBeInTheDocument();
    expect(screen.getByText("Manager", { exact: true })).toBeInTheDocument();
    expect(screen.getByText("Editor", { exact: true })).toBeInTheDocument();
    expect(screen.getByText("User", { exact: true })).toBeInTheDocument();
    expect(
      screen.getByText("Assume Role", { exact: true })
    ).toBeInTheDocument();
  });
});
