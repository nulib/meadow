import React from "react";
import ScreensWork from "./Work";
import { Route } from "react-router-dom";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import { getWorkMock } from "../../components/Work/work.gql.mock";
const mocks = [getWorkMock];

// This function helps mock out a component's dependency on
// react-router's param object
function setupMatchTests() {
  return renderWithRouterApollo(
    <Route path="/work/:id" component={ScreensWork} />,
    {
      mocks,
      route: "/work/ABC123",
    }
  );
}

it("renders without crashing", () => {
  setupMatchTests();
});

it("renders Publish, and Delete buttons", async () => {
  const { findByTestId, getByTestId } = setupMatchTests();
  const buttonEl = await findByTestId("publish-button");
  expect(buttonEl).toBeInTheDocument();
  expect(getByTestId("delete-button")).toBeInTheDocument();
});

it("renders breadcrumbs", async () => {
  const { findByTestId, debug } = setupMatchTests();
  const crumbsEl = await findByTestId("work-breadcrumbs");
  expect(crumbsEl).toBeInTheDocument();
});

it("renders the Work component", () => {});

// it("displays the project title", async () => {
//   const { findAllByText, debug } = setupMatchTests();
//   const projectTitleArray = await findAllByText(MOCK_PROJECT_TITLE);

//   expect(projectTitleArray.length).toEqual(1);
// });
