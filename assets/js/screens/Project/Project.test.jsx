import React from "react";
import ScreensProject from "./Project";
import { GET_PROJECT } from "../../components/Project/project.query";
import { renderWithRouterApollo } from "../../testing-helpers";
import "@testing-library/jest-dom/extend-expect";
import { Route } from "react-router-dom";
import { waitForElement } from "@testing-library/react";

const MOCK_PROJECT_TITLE = "Mock project title";
const mocks = [
  {
    request: {
      query: GET_PROJECT,
      variables: {
        projectId: "01DNFK4B8XASXNKBSAKQ6YVNF3"
      }
    },
    result: {
      data: {
        project: {
          id: "01DNFK4B8XASXNKBSAKQ6YVNF3",
          ingestSheets: [
            {
              id: "01DNFK56MEN9H0C4CDBE7TECJT",
              name: "fffff"
            },
            {
              id: "01DNFK9XNJ1FWE8GQGSTR3D1NE",
              name: "not a csv"
            }
          ],
          title: MOCK_PROJECT_TITLE
        }
      }
    }
  }
];

function setupMatchTests() {
  return renderWithRouterApollo(
    <Route path="/project/:id" component={ScreensProject} />,
    {
      mocks,
      route: "/project/01DNFK4B8XASXNKBSAKQ6YVNF3"
    }
  );
}

// This throws an "act()" warning... not sure of the fix for now
it("renders a loading spinner initially", () => {
  const { getByTestId } = renderWithRouterApollo(<ScreensProject />);
  const loading = getByTestId("loading");
  expect(loading).toBeInTheDocument();
});

it("displays the project title", async () => {
  const { findAllByText } = setupMatchTests();
  const projectTitleArray = await findAllByText(MOCK_PROJECT_TITLE);
  expect(projectTitleArray.length).toBeGreaterThan(1);
});

it("renders a button to create a new ingest sheet", async () => {
  const { getByTestId, debug } = setupMatchTests();
  const button = await waitForElement(() =>
    getByTestId("button-new-ingest-sheet")
  );
  expect(button).toBeInTheDocument();
});

it("renders both screen header and screen content components", async () => {
  const { getByTestId } = setupMatchTests();
  const [screenHeaderElement, screenContentElement] = await waitForElement(
    () => [getByTestId("screen-header"), getByTestId("screen-content")]
  );
  expect(screenHeaderElement).toBeInTheDocument();
  expect(screenContentElement).toBeInTheDocument();
});
