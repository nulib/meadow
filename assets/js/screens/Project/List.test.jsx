import React from "react";
import ScreensProjectList from "./List";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import { getProjectsMock } from "../../components/Project/project.gql.mock";
import { AuthProvider } from "@js/components/Auth/Auth";
import { getCurrentUserMock } from "@js/components/Auth/auth.gql.mock";
import { waitFor, screen } from "@testing-library/dom";

const mocks = [getProjectsMock, getCurrentUserMock];

jest.mock("../../services/elasticsearch");
describe("Project List component", () => {
  beforeEach(() => {
    return renderWithRouterApollo(
      <AuthProvider>
        <ScreensProjectList />
      </AuthProvider>,
      {
        mocks,
      }
    );
  });
});
it("renders a create new project button", async () => {
  await waitFor(() => {
    expect(screen.findByTestId("button-new-project"));
  });
});

it("renders header page section and main page content section", async () => {
  await waitFor(() => {
    expect(screen.findByTestId("screen-header"));
    expect(screen.findByTestId("screen-content"));
  });
});

it("renders the project list component", async () => {
  await waitFor(() => {
    expect(screen.findByTestId("project-list"));
  });
});
