import React from "react";
import ScreensProjectList from "./List";
import { GET_PROJECTS } from "../../components/Project/project.query";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import { waitForElement } from "@testing-library/react";
import "@testing-library/jest-dom/extend-expect";

const mocks = [
  {
    request: {
      query: GET_PROJECTS
    },
    result: {
      data: {
        projects: [
          {
            folder: "asdfasdf-1569333444",
            id: "01DNHRZZF8M2GF7RXD7K0MJV2V",
            ingestSheets: [
              {
                id: "01DNJ161YWWVSMHMWZM4V2J7S1"
              }
            ],
            title: "Mock project title",
            updatedAt: "2019-09-24T13:57:24"
          }
        ]
      }
    }
  }
];

it("renders a create new project button", async () => {
  const { getByTestId } = renderWithRouterApollo(<ScreensProjectList />);
  const buttonElement = await waitForElement(() =>
    getByTestId("button-new-project")
  );
  expect(buttonElement).toBeInTheDocument();
});

it("renders header page section and main page content section", async () => {
  const { getByTestId } = renderWithRouterApollo(<ScreensProjectList />);
  const [
    screenHeaderElement,
    screenContentElement
  ] = await waitForElement(() => [
    getByTestId("screen-header"),
    getByTestId("screen-content")
  ]);
  expect(screenHeaderElement).toBeInTheDocument();
  expect(screenContentElement).toBeInTheDocument();
});

it("renders the project list component", async () => {
  const { getByTestId } = renderWithRouterApollo(<ScreensProjectList />, {
    mocks
  });
  const listElement = await waitForElement(() => getByTestId("project-list"));
  expect(listElement).toBeInTheDocument();
});
