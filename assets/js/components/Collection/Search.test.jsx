import React from "react";
import CollectionSearch from "./Search";
import { renderWithRouter } from "../../services/testing-helpers";
import { collectionMock } from "./collection.gql.mock";

function setupTests() {
  return renderWithRouter(<CollectionSearch collection={collectionMock} />);
}
describe("CollectionSearch component", () => {
  it("renders the root element", () => {
    const { getByTestId } = setupTests();
    expect(getByTestId("collection-search")).toBeInTheDocument();
  });

  // TODO: All these tests seem to be testing elements not directly rendered in the CollectionSearch component.  They should be moved to their appropriate component.
  it("displays number of works", () => {
    const { getByTestId, debug } = setupTests();
    expect(getByTestId("number-of-works").innerHTML).toBe("2 results...");
  });

  it("displays work title", () => {
    const { getByTestId } = setupTests();
    expect(getByTestId("work-title-1id-23343432").innerHTML).toBe("Title 1");
  });

  xit("displays default work title", () => {
    const { getByTestId, debug } = setupTests();
    expect(getByTestId("work-title-2is-234o24332-id").innerHTML).toBe(
      "Untitled"
    );
  });
});
