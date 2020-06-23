import React from "react";
import CollectionListRow from "./ListRow";
import { renderWithRouter } from "../../services/testing-helpers";
import { collectionMock } from "./collection.gql.mock";

describe("CollectionListRow component", () => {
  it("renders the root element", () => {
    const { getByTestId } = renderWithRouter(
      <CollectionListRow collection={collectionMock} />
    );
    expect(getByTestId("collection-list-row")).toBeInTheDocument();
  });
});
