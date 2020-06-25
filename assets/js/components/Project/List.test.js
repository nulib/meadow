import React from "react";
import ProjectList from "./List";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import { fireEvent } from "@testing-library/react";
import { Route } from "react-router-dom";
import { getProjectsMock } from "./project.gql.mock";

const mocks = [getProjectsMock];

function setupMatchTests() {
  return renderWithRouterApollo(
    <Route path="/project/list" component={ProjectList} />,
    {
      mocks,
      route: "/project/list",
    }
  );
}

it("render without crashing", () => {
  setupMatchTests();
});

it("renders the ProjectsList component", async () => {
  const { findByTestId, debug } = setupMatchTests();
  const projectListEl = await findByTestId("project-list");
  expect(projectListEl).toBeInTheDocument();
});

it("opens delete modal", async () => {
  const { findByTestId, debug } = setupMatchTests();
  const deleteButtonEl = await findByTestId("delete-button");
  fireEvent.click(deleteButtonEl);
  const deleteModalEl = await findByTestId("delete-modal");
  expect(deleteModalEl).toBeInTheDocument();
});
