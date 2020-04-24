import React from "react";
import ScreensCollectionList from "./List";
import { GET_COLLECTIONS } from "../../components/Collection/collection.query";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import { Route } from "react-router-dom";
import { waitFor } from "@testing-library/react";

const mocks = [
  {
    request: {
      query: GET_COLLECTIONS,
    },
    result: {
      data: {
        collections: [
          {
            adminEmail: null,
            description: null,
            featured: false,
            findingAidUrl: null,
            id: "34275ed5-7123-4104-87ad-c0d9b7927b72",
            keywords: [""],
            name: "First List item",
            published: false,
            works: [],
          },
        ],
      },
    },
  },
];

function setupTests() {
  return renderWithRouterApollo(
    <Route path="/collection/list/" component={ScreensCollectionList} />,
    {
      mocks,
      route: "/collection/list/",
    }
  );
}

describe("ScreensCollectionList component", () => {
  it("renders list wrapping element", async () => {
    const { getByTestId, debug } = setupTests();

    await waitFor(() => {
      expect(getByTestId("collection-list-wrapper")).toBeInTheDocument();
    });
  });

  it("renders collection list", async () => {
    const { getByTestId, getByText } = setupTests();
    await waitFor(() => {
      expect(getByText("Add new collection")).toBeInTheDocument();
      expect(getByTestId("collection-list")).toBeInTheDocument();
    });
  });

  it("renders collection list row item from mock", async () => {
    const { getByText } = setupTests();
    await waitFor(() => {
      expect(getByText("First List item")).toBeInTheDocument();
    });
  });
});
