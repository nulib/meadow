import React from "react";
import CollectionImageModal from "./CollectionImageModal";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import { fireEvent, waitFor } from "@testing-library/react";
import { SET_COLLECTION_IMAGE } from "../../components/Collection/collection.query";

const mocks = [
  {
    request: {
      query: SET_COLLECTION_IMAGE,
      variables: {
        collectionId: "01DWHQQYTVKC2THHW8SHRBH2XP",
        workId: "1id-23343432",
      },
    },
    result: {
      data: {
        setCollectionImage: {
          id: "01DWHQQYTVKC2THHW8SHRBH2XP",
          representativeImage: "repImage1url.com",
        },
      },
    },
  },
];

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
    },
    {
      id: "2is-234o24332-id",
      accessionNumber: "accessNumber2",
      representativeImage: "repImage2url.com",
    },
  ],
};

let isModalOpen = true;

const handleClose = () => {
  isModalOpen = false;
};

function setupMatchTests() {
  return renderWithRouterApollo(
    <CollectionImageModal
      collection={mockCollection}
      isModalOpen={isModalOpen}
      handleClose={handleClose}
    />,
    { mocks }
  );
}

it("renders collection image modal", async () => {
  const { getByTestId, debug } = setupMatchTests();
  await waitFor(() => {
    expect(getByTestId("modal-collection-thumbnail")).toHaveClass("is-active");
  });
});

it("saves collection image", async () => {
  const { getByTestId, getByText, debug } = setupMatchTests();
  await waitFor(() => {
    expect(getByTestId("modal-collection-thumbnail")).toHaveClass(" is-active");
    expect(getByText("accessNumber1")).toBeInTheDocument();
    fireEvent.click(getByText("accessNumber1"));
    expect(getByTestId("button-set-image")).toBeInTheDocument();
    fireEvent.click(getByTestId("button-set-image"));

    // expect(getByTestId("modal-collection-thumbnail")).not.toHaveClass(
    //   "is-active "
    // );
  });
});
