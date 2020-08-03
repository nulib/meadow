import React from "react";
import ScreensCollection from "./Collection";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import { Route } from "react-router-dom";
import { waitFor, fireEvent } from "@testing-library/react";
import {
  GET_COLLECTION,
  UPDATE_COLLECTION,
} from "../../components/Collection/collection.gql";
import {
  collectionMock,
  getCollectionMock,
  MOCK_COLLECTION_ID,
} from "../../components/Collection/collection.gql.mock";

/**
 * Helper function to render the component for testing
 * @param {Array} mocks All the mocks needed to run each spec
 */
function setupTests(mocks) {
  return renderWithRouterApollo(
    <Route path="/collection/:id" component={ScreensCollection} />,
    {
      mocks,
      route: `/collection/${MOCK_COLLECTION_ID}`,
    }
  );
}

it("renders without crashing", async () => {
  const { container, queryByTestId } = setupTests([getCollectionMock]);
  await waitFor(() => {
    expect(queryByTestId("loading")).not.toBeInTheDocument();
    expect(container).toBeTruthy();
  });
});

it("renders hero section", async () => {
  const { findByTestId } = setupTests([getCollectionMock]);
  const el = await findByTestId("collection-screen-hero");
  expect(el).toBeInTheDocument();
});

it("renders breadcrumbs", async () => {
  const { findByTestId } = setupTests([getCollectionMock]);
  const breadcrumbs = await findByTestId("breadcrumbs");
  expect(breadcrumbs).toBeInTheDocument();
});

it("opens up Delete dialog", async () => {
  const { findByTestId } = setupTests([getCollectionMock]);
  const deleteButtonEl = await findByTestId("delete-button");
  fireEvent.click(deleteButtonEl);
  const deleteModalEl = await findByTestId("delete-modal");
  expect(deleteModalEl).toBeInTheDocument();
});

it("renders Edit button", async () => {
  const { findByTestId } = setupTests([getCollectionMock]);
  const button = await findByTestId("edit-button");
  expect(button).toBeInTheDocument();
});

it("renders Publish button", async () => {
  const { findByTestId } = setupTests([getCollectionMock]);
  const button = await findByTestId("publish-button");
  expect(button).toBeInTheDocument();
});

it("changes tags upon publish", async () => {
  // What the collection looks like after an update
  const collectionAfterUpdate = {
    ...collectionMock,
    published: true,
  };

  // We can write our own custom update mutation mocks, since they'll all be different
  const updateCollectionMock = {
    request: {
      query: UPDATE_COLLECTION,
      variables: {
        collectionId: MOCK_COLLECTION_ID,
        published: true,
      },
    },
    result: {
      data: {
        updateCollection: collectionAfterUpdate,
      },
    },
  };

  // A query mock which returns data post update mutation
  const getCollectionAfterUpdate = {
    request: {
      query: GET_COLLECTION,
      variables: {
        id: MOCK_COLLECTION_ID,
      },
    },
    result: {
      data: {
        collection: collectionAfterUpdate,
      },
    },
  };

  const { findByTestId, debug } = setupTests([
    getCollectionMock,
    updateCollectionMock,
    getCollectionAfterUpdate,
  ]);
  const button = await findByTestId("publish-button");
  expect(button).toBeInTheDocument();

  const publishedTag = await findByTestId("published-tag");
  expect(publishedTag).toHaveClass("is-warning");

  fireEvent.click(button);

  const publishedTag2 = await findByTestId("published-tag");
  expect(publishedTag2).toHaveClass("is-info");
});
