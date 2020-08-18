import React from "react";
import ScreensCollectionList from "./List";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import { Route } from "react-router-dom";
import { waitFor } from "@testing-library/react";
import { getCollectionsMock } from "../../components/Collection/collection.gql.mock";
const mocks = [getCollectionsMock];

jest.mock("../../services/elasticsearch");

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
      expect(getByText("Great collection")).toBeInTheDocument();
    });
  });
});
