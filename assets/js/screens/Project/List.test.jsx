import React from "react";
import ScreensProjectList from "./List";
import { GET_PROJECTS } from "../../components/Project/project.query";
import { renderWithRouterApollo } from "../../services/testing-helpers";

const mocks = [
  {
    request: {
      query: GET_PROJECTS,
    },
    result: {
      data: {
        projects: [
          {
            folder: "asdfasdf-1569333444",
            id: "01DNHRZZF8M2GF7RXD7K0MJV2V",
            ingestSheets: [
              {
                id: "01DNJ161YWWVSMHMWZM4V2J7S1",
              },
            ],
            title: "Mock project title",
            updatedAt: "2019-09-24T13:57:24",
          },
        ],
      },
    },
  },
];

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
