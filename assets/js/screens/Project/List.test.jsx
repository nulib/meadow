import React from "react";
import ScreensProjectList from "./List";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import { getProjectsMock } from "../../components/Project/project.gql.mock";
const mocks = [getProjectsMock];

it("renders a create new project button", async () => {
  const { findByTestId } = renderWithRouterApollo(<ScreensProjectList />);
  const buttonElement = await findByTestId("button-new-project");
  expect(buttonElement).toBeInTheDocument();
});

it("renders header page section and main page content section", async () => {
  const { findByTestId } = renderWithRouterApollo(<ScreensProjectList />);
  const screenHeaderElement = await findByTestId("screen-header");
  const screenContentElement = await findByTestId("screen-content");

  expect(screenHeaderElement).toBeInTheDocument();
  expect(screenContentElement).toBeInTheDocument();
});

it("renders the project list component", async () => {
  const { findByTestId } = renderWithRouterApollo(<ScreensProjectList />, {
    mocks,
  });
  const listElement = await findByTestId("project-list");
  expect(listElement).toBeInTheDocument();
});
