import React from "react";
import ProjectList from "./List";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import { getProjectsMock, mockProjects } from "./project.gql.mock";
import { screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { mockUser } from "@js/components/Auth/auth.gql.mock";
import useIsAuthorized from "@js/hooks/useIsAuthorized";

jest.mock("@js/hooks/useIsAuthorized");
useIsAuthorized.mockReturnValue({
  user: mockUser,
  isAuthorized: () => true,
});

describe("BatchEditAboutDescriptiveMetadata component", () => {
  beforeEach(() => {
    return renderWithRouterApollo(<ProjectList projects={mockProjects} />, {
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

  it("filters for a project by title", async () => {
    const el = await screen.findByTestId("input-project-filter");
    expect(el);
    expect(screen.getAllByTestId("project-title-row")).toHaveLength(2);
    //filter for project title
    userEvent.type(el, "Second");
    expect(screen.getAllByTestId("project-title-row")).toHaveLength(1);
  });

  it("opens delete modal", async () => {
    expect(await screen.findAllByTestId("delete-button-row")).toHaveLength(2);
    userEvent.click(screen.getAllByTestId("delete-button-row")[0]);
    expect(screen.getAllByTestId("delete-modal")).toHaveLength(1);
  });
});
