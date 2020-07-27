import React from "react";
import ScreensCollection from "./Collection";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import { Route } from "react-router-dom";
import { waitFor, fireEvent } from "@testing-library/react";
import {
  getCollectionMock,
  updateCollectionMock,
} from "../../components/Collection/collection.gql.mock";
import { UPDATE_COLLECTION } from "../../components/Collection/collection.gql";
const mocks = [getCollectionMock, getCollectionMock, updateCollectionMock];

function setupTests() {
  return renderWithRouterApollo(
    <Route path="/collection/:id" component={ScreensCollection} />,
    {
      mocks,
      route: "/collection/7a6c7b35-41a6-465a-9be2-0587c6b39ae0",
    }
  );
}

it("renders without crashing", async () => {
  const { container, queryByTestId } = setupTests();

  //expect(queryByTestId("loading")).toBeInTheDocument();

  await waitFor(() => {
    expect(queryByTestId("loading")).not.toBeInTheDocument();
    expect(container).toBeTruthy();
  });
});

it("renders hero section", async () => {
  const { findByTestId } = setupTests();
  const el = await findByTestId("collection-screen-hero");
  expect(el).toBeInTheDocument();
});

it("renders breadcrumbs", async () => {
  const { findByTestId } = setupTests();
  const breadcrumbs = await findByTestId("breadcrumbs");
  expect(breadcrumbs).toBeInTheDocument();
});

it("opens up Delete dialog", async () => {
  const { findByTestId } = setupTests();
  const deleteButtonEl = await findByTestId("delete-button");
  fireEvent.click(deleteButtonEl);
  const deleteModalEl = await findByTestId("delete-modal");
  expect(deleteModalEl).toBeInTheDocument();
});

it("renders Edit button", async () => {
  const { findByTestId } = setupTests();
  const button = await findByTestId("edit-button");
  expect(button).toBeInTheDocument();
});

it("renders Publish button", async () => {
  const { findByTestId } = setupTests();
  const button = await findByTestId("publish-button");
  expect(button).toBeInTheDocument();
});

xit("changes tags upon publish", async () => {
  const { findByTestId } = setupTests();
  const button = await findByTestId("publish-button");
  expect(button).toBeInTheDocument();

  const publishedTag = await findByTestId("published-tag");
  expect(publishedTag).toHaveClass("is-warning");
  fireEvent.click(button);
  const publishedTag2 = await findByTestId("published-tag");
  expect(publishedTag2).toHaveClass("is-info");
});
