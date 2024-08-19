import React from "react";
import ScreensProjectList from "./List";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import { getProjectsMock } from "@js/components/Project/project.gql.mock";
import { mockUser } from "@js/components/Auth/auth.gql.mock";
import { screen } from "@testing-library/react";
import useIsAuthorized from "@js/hooks/useIsAuthorized";

jest.mock("@js/hooks/useIsAuthorized");
useIsAuthorized.mockReturnValue({
  user: mockUser,
  isAuthorized: () => true,
});

const mocks = [getProjectsMock];

describe("Project List component", () => {
  beforeEach(() => {
    renderWithRouterApollo(<ScreensProjectList />, {
      mocks,
    });
  });

  it("renders a create new project button", async () => {
    expect(await screen.findByTestId("button-new-project"));
  });

  it("renders header page section and main page content section", async () => {
    expect(await screen.findByTestId("screen-header"));
    expect(await screen.findByTestId("screen-content"));
  });
});
