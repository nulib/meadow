import React from "react";
import ScreensCollection from "./Collection";
import { GET_COLLECTION } from "../../components/Collection/collection.query";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import { Route } from "react-router-dom";
import {
  wait,
  fireEvent,
  waitForElement,
  getByText
} from "@testing-library/react";

const mocks = [
  {
    request: {
      query: GET_COLLECTION,
      variables: {
        id: "form"
      }
    },
    result: {
      data: {
        collection: {
          adminEmail: "test@test.com",
          description: "Test arrays keyword arrays arrays arrays arrays",
          featured: false,
          findingAidUrl: "http://go.com",
          id: "form",
          keywords: ["yo", "foo", "bar", "dude", "hey"],
          name: "Ima collection",
          published: false,
          works: []
        }
      }
    }
  },
  {
    request: {
      query: GET_COLLECTION,
      variables: {
        id: "7a6c7b35-41a6-465a-9be2-0587c6b39ae0"
      }
    },
    result: {
      data: {
        collection: {
          adminEmail: "test@test.com",
          description: "Test arrays keyword arrays arrays arrays arrays",
          featured: false,
          findingAidUrl: "http://go.com",
          id: "7a6c7b35-41a6-465a-9be2-0587c6b39ae0",
          keywords: ["yo", "foo", "bar", "dude", "hey"],
          name: "Ima collection",
          published: false,
          works: []
        }
      }
    }
  }
];

function setupTests() {
  return renderWithRouterApollo(
    <Route path="/collection/:id" component={ScreensCollection} />,
    {
      mocks,
      route: "/collection/7a6c7b35-41a6-465a-9be2-0587c6b39ae0"
    }
  );
}

it("renders without crashing", async () => {
  const { container, queryByTestId } = setupTests();

  expect(queryByTestId("loading")).toBeInTheDocument();

  // This "wait()" magically makes Apollo MockProvider warning messages go away
  await wait();
  expect(queryByTestId("loading")).not.toBeInTheDocument();
  expect(container).toBeTruthy();
});

it("renders hero section", async () => {
  const { getByTestId } = setupTests();
  await wait();
  expect(getByTestId("collection-screen-hero")).toBeInTheDocument();
});

it("renders breadcrumbs", async () => {
  const { getByTestId } = setupTests();
  await wait();
  expect(getByTestId("breadcrumbs")).toBeInTheDocument();
});

it("opens up Delete dialog", async () => {
  const { getByTestId } = setupTests();
  const deleteButtonEl = await waitForElement(() =>
    getByTestId("delete-button")
  );
  fireEvent.click(deleteButtonEl);
  const deleteModalEl = await waitForElement(() => getByTestId("delete-modal"));
  expect(deleteModalEl).toBeInTheDocument();
});

it("renders Edit button", async () => {
  const { getByTestId } = setupTests();
  await wait();
  expect(getByTestId("edit-button")).toBeInTheDocument();
});
