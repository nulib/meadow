import React from "react";
import ScreensCollection from "./Collection";
import { GET_COLLECTION } from "../../components/Collection/collection.gql";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import { Route } from "react-router-dom";
import { waitFor, fireEvent } from "@testing-library/react";

const mocks = [
  {
    request: {
      query: GET_COLLECTION,
      variables: {
        id: "form",
      },
    },
    result: {
      data: {
        collection: {
          adminEmail: "test@test.com",
          description: "Test arrays keyword arrays arrays arrays arrays",
          featured: false,
          representativeImage: "",
          findingAidUrl: "http://go.com",
          id: "form",
          keywords: ["yo", "foo", "bar", "dude", "hey"],
          name: "Ima collection",
          published: false,
          works: [],
        },
      },
    },
  },
  {
    request: {
      query: GET_COLLECTION,
      variables: {
        id: "7a6c7b35-41a6-465a-9be2-0587c6b39ae0",
      },
    },
    result: {
      data: {
        collection: {
          adminEmail: "test@test.com",
          description: "Test arrays keyword arrays arrays arrays arrays",
          featured: false,
          findingAidUrl: "http://go.com",
          representativeImage: "",
          id: "7a6c7b35-41a6-465a-9be2-0587c6b39ae0",
          keywords: ["yo", "foo", "bar", "dude", "hey"],
          name: "Ima collection",
          published: false,
          works: [],
        },
      },
    },
  },
];

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
