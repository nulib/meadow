import React from "react";
import CollectionSearch from "./Search";
import { renderWithRouter } from "../../services/testing-helpers";

const mockCollection = {
  adminEmail: "admin@nu.com",
  description: "asdf asdfasdf",
  representativeImage: "https://thisIsTest.com",
  featured: true,
  findingAidUrl: "http://something.com",
  id: "01DWHQQYTVKC2THHW8SHRBH2XP",
  keywords: ["any", " work", "foo", "bar"],
  name: "Great collection",
  published: false,
  works: [
    {
      id: "1id-23343432",
      accessionNumber: "accessNumber1",
      representativeImage: "repImage1url.com",
      descriptiveMetadata: {
        title: "Title 1",
      },
    },
    {
      id: "2is-234o24332-id",
      accessionNumber: "accessNumber2",
      representativeImage: "repImage2url.com",
      descriptiveMetadata: {
        title: null,
      },
    },
    {
      id: "3id-23sd7343432",
      accessionNumber: "accessNumber3",
      representativeImage: null,
      descriptiveMetadata: {
        title: "Test title goes here",
      },
    },
  ],
};
function setupTests() {
  return renderWithRouter(<CollectionSearch collection={mockCollection} />);
}
describe("CollectionSearch component", () => {
  it("renders the root element", () => {
    const { getByTestId } = setupTests();
    expect(getByTestId("collection-search")).toBeInTheDocument();
  });

  it("displays number of works", () => {
    const { getByTestId, debug } = setupTests();
    expect(getByTestId("number-of-works").innerHTML).toBe("3 results...");
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
      "repImage1url.com/square/500,500/0/default.jpg"
    );
  });

  it("displays default work image", () => {
    const { getByTestId } = setupTests();
    const el = getByTestId("work-image-3id-23sd7343432");
    expect(el.getAttribute("src")).toEqual("/images/480x480.png");
  });
});
