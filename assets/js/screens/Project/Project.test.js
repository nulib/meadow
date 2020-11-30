import React from "react";
import ScreensProject from "./Project";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import { Route } from "react-router-dom";
import {
  getProjectMock,
  ingestSheetUpdatesMock,
} from "../../components/Project/project.gql.mock";
import { screen } from "@testing-library/react";
import { AuthProvider } from "@js/components/Auth/Auth";
import { getCurrentUserMock } from "@js/components/Auth/auth.gql.mock";

jest.mock("../../services/elasticsearch");

const MOCK_PROJECT_TITLE = "Mock project title";
const mocks = [getProjectMock, ingestSheetUpdatesMock, getCurrentUserMock];

describe("BatchEditAboutCoreMetadata component", () => {
  beforeEach(() => {
    return renderWithRouterApollo(
      <AuthProvider>
        <Route path="/project/:id" component={ScreensProject} />
      </AuthProvider>,
      {
        mocks,
        route: "/project/01DNFK4B8XASXNKBSAKQ6YVNF3",
      }
    );
  });
  it("displays the project title", async () => {
    const projectTitleArray = await screen.findAllByText(MOCK_PROJECT_TITLE);
    expect(projectTitleArray.length).toEqual(2);
  });
  it("renders a button to create a new ingest sheet", async () => {
    expect(
      await screen.findByTestId("button-new-ingest-sheet")
    ).toBeInTheDocument();
  });
  it("renders a button to view all works", async () => {
    expect(
      await screen.findByTestId("button-view-all-works")
    ).toBeInTheDocument();
  });
  it("renders both screen header and screen content components", async () => {
    expect(await screen.findByTestId("screen-header")).toBeInTheDocument();
    expect(await screen.findByTestId("screen-content")).toBeInTheDocument();
  });
});
