import React from "react";
import ScreensProject from "./Project";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import { Route } from "react-router-dom";
import {
  getProjectMock,
  ingestSheetUpdatesMock,
} from "../../components/Project/project.gql.mock";
import { getPresignedUrlMock } from "@js/components/IngestSheet/ingestSheet.gql.mock";
import { screen } from "@testing-library/react";

jest.mock("../../services/elasticsearch");

const MOCK_PROJECT_TITLE = "Mock project title";
const mocks = [getPresignedUrlMock, getProjectMock, ingestSheetUpdatesMock];

describe("BatchEditAboutCoreMetadata component", () => {
  beforeEach(() => {
    return renderWithRouterApollo(
      <Route path="/project/:id" component={ScreensProject} />,
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
