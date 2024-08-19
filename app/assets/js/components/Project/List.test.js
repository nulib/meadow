import React from "react";
import ProjectList from "./List";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import { getProjectsMock, mockProjects, projectsSearchMock } from "./project.gql.mock";
import { screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { mockUser } from "@js/components/Auth/auth.gql.mock";
import useIsAuthorized from "@js/hooks/useIsAuthorized";

jest.mock("@js/hooks/useIsAuthorized");
useIsAuthorized.mockReturnValue({
  user: mockUser,
  isAuthorized: () => true,
});

describe("Project list component", () => {
  beforeEach(() => {
    return renderWithRouterApollo(<ProjectList />, {
      mocks: [getProjectsMock],
      route: "/project/list",
    });
  });

  it("renders the ProjectsList component", () => {
    expect(screen.queryByTestId("project-list"));
  });

  it("renders list of projects", async () => {
    expect(await screen.findAllByTestId("project-title-row")).toHaveLength(2);
  });

  it("opens delete modal", async () => {
    const user = userEvent.setup();
    expect(await screen.findAllByTestId("delete-button")).toHaveLength(2);
    await user.click(screen.getAllByTestId("delete-button")[0]);
    expect(screen.getAllByTestId("delete-modal")).toHaveLength(1);
  });
});

describe("ProjectList component searching", () => {
  // TODO: Fix this.  Why is is breaking out of nowhere?
  xit("calls the GraphQL query successfully and renders results", async () => {
    const dynamicMock = projectsSearchMock("f");
    const user = userEvent.setup();

    renderWithRouterApollo(<ProjectList />, {
      mocks: [getProjectsMock, dynamicMock],
    });

    const el = await screen.findByPlaceholderText("Search");
    expect(await screen.findAllByTestId("projects-row")).toHaveLength(2);
    await user.type(el, "f");
    expect(await screen.findAllByText("fffff"));
  });
});
