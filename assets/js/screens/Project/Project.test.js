import React from "react";
import ScreensProject from "./Project";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import { Route } from "react-router-dom";
import {
  getProjectMock,
  ingestSheetUpdatesMock,
} from "../../components/Project/project.gql.mock";

const MOCK_PROJECT_TITLE = "Mock project title";
const mocks = [getProjectMock, ingestSheetUpdatesMock];

function setupMatchTests() {
  return renderWithRouterApollo(
    <Route path="/project/:id" component={ScreensProject} />,
    {
      mocks,
      route: "/project/01DNFK4B8XASXNKBSAKQ6YVNF3",
    }
  );
}

it("displays the project title", async () => {
  const { findAllByText } = setupMatchTests();
  const projectTitleArray = await findAllByText(MOCK_PROJECT_TITLE);
  expect(projectTitleArray.length).toEqual(2);
});

it("renders a button to create a new ingest sheet", async () => {
  const { findByTestId } = setupMatchTests();
  const button = await findByTestId("button-new-ingest-sheet");
  expect(button).toBeInTheDocument();
});

it("renders both screen header and screen content components", async () => {
  const { findByTestId } = setupMatchTests();
  const screenHeaderElement = await findByTestId("screen-header");
  const screenContentElement = await findByTestId("screen-content");

  expect(screenHeaderElement).toBeInTheDocument();
  expect(screenContentElement).toBeInTheDocument();
});
