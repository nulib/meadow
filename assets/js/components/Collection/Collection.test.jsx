import React from "react";
import Collection from "./Collection";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import { collectionMock } from "./collection.gql.mock";

function setUpTests() {
  return renderWithRouterApollo(<Collection collection={collectionMock} />, {});
}

it("renders Collection component", async () => {
  const { getByTestId } = setUpTests();
  const collectionSection = getByTestId("collection");
  expect(collectionSection).toBeInTheDocument();
});

it("renders collection properties", async () => {
  const { getByText } = setUpTests();
  expect(getByText("admin@nu.com")).toBeInTheDocument();
  expect(getByText("Collection description lorem ipsum")).toBeInTheDocument();
});
