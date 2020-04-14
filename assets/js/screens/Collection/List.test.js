import React from "react";
import ScreensCollectionList from "./List";
import { GET_COLLECTIONS } from "../../components/Collection/collection.query";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import { Route } from "react-router-dom";
import { wait } from "@testing-library/react";

const mocks = [
  {
    request: {
      query: GET_COLLECTIONS
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
            name: "1",
            published: false,
            works: []
          }
        ]
      }
    }
  }
];

describe("ScreensCollectionList component", () => {
  it("renders collection hero and list", async () => {
    const { getByTestId } = renderWithRouterApollo(
      <Route path="/collection/list/" component={ScreensCollectionList} />,
      {
        mocks,
        route: "/collection/list/"
      }
    );

    await wait();
    expect(getByTestId("collection-list-hero")).toBeInTheDocument();
    expect(getByTestId("collection-list")).toBeInTheDocument();
  });
});
