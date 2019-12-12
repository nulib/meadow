import React from "react";
import CollectionListRow from "./ListRow";
import { renderWithRouter } from "../../testing-helpers";

const collection = {
  description: "collection description",
  id: "01DVRVWZD0FJ3CJMQZC9S9HSTF",
  keywords: ["test, testing, tested"],
  name: "Ima Collection"
};

describe("CollectionListRow component", () => {
  it("renders the root element", () => {
    const { getByTestId } = renderWithRouter(
      <CollectionListRow collection={collection} />
    );
    expect(getByTestId("collection-list-row")).toBeInTheDocument();
  });
});
