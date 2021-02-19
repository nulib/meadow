import React from "react";
import ProjectList from "./List";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import { getProjectsMock, mockProjects } from "./project.gql.mock";
import { screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { AuthProvider } from "@js/components/Auth/Auth";
import { getCurrentUserMock } from "@js/components/Auth/auth.gql.mock";

describe("BatchEditAboutDescriptiveMetadata component", () => {
  beforeEach(() => {
    return renderWithRouterApollo(
      <AuthProvider>
        <ProjectList projects={mockProjects} />
      </AuthProvider>,
      {
        mocks: [getProjectsMock, getCurrentUserMock],
        route: "/project/list",
      }
    );
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
