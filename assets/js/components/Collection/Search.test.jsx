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

  it("displays number of works", () => {
    const { getByTestId, debug } = setupTests();
    expect(getByTestId("number-of-works").innerHTML).toBe("2 results...");
  });

  it("displays work title", () => {
    const { getByTestId } = setupTests();
    expect(getByTestId("work-title-1id-23343432").innerHTML).toBe("Title 1");
  });

  it("displays default work title", () => {
    const { getByTestId } = setupTests();
    expect(getByTestId("work-title-2is-234o24332-id").innerHTML).toBe(
      "Untitled"
    );
  });

  it("displays work image", () => {
    const { getByTestId } = setupTests();
    const el = getByTestId("work-image-1id-23343432");
    expect(el.getAttribute("src")).toEqual(
      "repImage1url.com/full/1280,960/0/default.jpg"
    );
  });

  it("displays default work image", () => {
    const { getByTestId } = setupTests();
    const el = getByTestId("work-image-2is-234o24332-id");
    expect(el.getAttribute("src")).toEqual("/images/480x480.png");
  });
});
