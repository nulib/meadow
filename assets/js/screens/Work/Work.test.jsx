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

jest.mock("../../services/elasticsearch");

// TODO: Figure out why the getWorkMock is not working.

xit("renders without crashing", () => {
  setupMatchTests();
});

xit("renders Publish, and Delete buttons", async () => {
  const { findByTestId, getByTestId, debug } = setupMatchTests();
  const buttonEl = await findByTestId("publish-button");
  debug();
  expect(buttonEl).toBeInTheDocument();
  expect(getByTestId("delete-button")).toBeInTheDocument();
});

xit("renders breadcrumbs", async () => {
  const { findByTestId, debug } = setupMatchTests();
  const crumbsEl = await findByTestId("work-breadcrumbs");
  expect(crumbsEl).toBeInTheDocument();
});
