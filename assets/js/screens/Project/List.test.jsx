import React from "react";
import ScreensProjectList from "./List";
import GetProjectsQuery from "../../gql/GetProjects.gql";
import { renderWithRouterApollo, wrapWithToast } from "../../testing-helpers";
import { waitForElement } from "@testing-library/react";

const mocks = [
  {
    request: {
      query: GetProjectsQuery
    },
    result: {
      data: {
        projects: [
          {
            id: "01DNHRZZF8M2GF7RXD7K0MJV2V",
            title: "Mock project title",
            folder: "asdfasdf-1569333444",
            updatedAt: "2019-09-24T13:57:24",
            ingestSheets: [
              {
                id: "01DNJ161YWWVSMHMWZM4V2J7S1",
                __typename: "IngestSheet"
              }
            ],
            __typename: "IngestSheet"
          }
        ]
      }
    }
  }
];

it("renders a create new project button", async () => {
  const { getByTestId } = renderWithRouterApollo(
    wrapWithToast(<ScreensProjectList />)
  );
  const buttonElement = await waitForElement(() =>
    getByTestId("button-new-project")
  );
  expect(buttonElement).toBeInTheDocument();
});

it("renders screen header and screen content components", async () => {
  const { getByTestId } = renderWithRouterApollo(
    wrapWithToast(<ScreensProjectList />)
  );
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
  const { getByTestId } = renderWithRouterApollo(
    wrapWithToast(<ScreensProjectList />),
    {
      mocks
    }
  );

  const listElement = await waitForElement(() => getByTestId("project-list"));
  expect(listElement).toBeInTheDocument();
});
