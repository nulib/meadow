import React from "react";
import ProjectList from "./List";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import { fireEvent, act } from "@testing-library/react";
import { Route } from "react-router-dom";
import {
  getProjectsMock,
  MOCK_PROJECT_ID,
  MOCK_PROJECT_ID_2,
} from "./project.gql.mock";

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

it("renders list of projects", async () => {
  const { findByTestId, debug } = setupMatchTests();
  const projectEl1 = await findByTestId(`project-title-${MOCK_PROJECT_ID}`);
  const projectEl2 = await findByTestId(`project-title-${MOCK_PROJECT_ID_2}`);
  expect(projectEl1).toBeInTheDocument();
  expect(projectEl2).toBeInTheDocument();
});

it("filters for a project by title", async () => {
  const { findByTestId, debug } = setupMatchTests();
  const el = await findByTestId("input-project-filter");
  expect(el).toBeInTheDocument();

  const projectEl1 = await findByTestId(`project-title-${MOCK_PROJECT_ID}`);
  const projectEl2 = await findByTestId(`project-title-${MOCK_PROJECT_ID_2}`);
  expect(projectEl1).toBeInTheDocument();
  expect(projectEl2).toBeInTheDocument();

  await act(async () => {
    fireEvent.change(el, { target: { value: "Second" } });
  });
  expect(el.value).toEqual("Second");

  expect(projectEl1).not.toBeInTheDocument();
  expect(projectEl2).toBeInTheDocument();
});

it("opens delete modal", async () => {
  const { findByTestId, debug } = setupMatchTests();
  const deleteButtonEl = await findByTestId(
    "delete-button-01DNFK4B8XASXNKBSAKQ6YVNF3"
  );
  expect(deleteButtonEl).toBeInTheDocument();
  fireEvent.click(deleteButtonEl);
  const deleteModalEl = await findByTestId("delete-modal");
  expect(deleteModalEl).toBeInTheDocument();
});
