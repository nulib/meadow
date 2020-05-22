import React from "react";
import ProjectList from "./List";
import { GET_PROJECTS } from "../../components/Project/project.gql.js";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import { fireEvent } from "@testing-library/react";
import { Route } from "react-router-dom";

const MOCK_PROJECT_TITLE = "Mock project title";

const mocks = [
  {
    request: {
      query: GET_PROJECTS,
    },
    result: {
      data: {
        projects: [
          {
            id: "1010SDSDFS-02380283",
            title: MOCK_PROJECT_TITLE,
            ingestSheets: [
              {
                id: "01DTYTYNJ161YWWVSMHMWZM4V2J7S1",
              },
              {
                id: "02DTYTYNJ161YWWVSMHMWZM4V2J7S12",
              },
            ],
            folder: "asdf-folder-name-123",
            updatedAt: "2020-02-29T02:02:02",
          },
        ],
      },
    },
  },
];

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
