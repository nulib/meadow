import React from "react";
import CollectionImageModal from "./CollectionImageModal";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import { fireEvent, waitFor } from "@testing-library/react";
import { collectionMock, setCollectionImageMock } from "./collection.gql.mock";

const mocks = [setCollectionImageMock];

let isModalOpen = true;

const handleClose = () => {
  isModalOpen = false;
};

function setupMatchTests() {
  return renderWithRouterApollo(
    <CollectionImageModal
      collection={collectionMock}
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
    expect(getByText("Title 1")).toBeInTheDocument();
    fireEvent.click(getByText("Title 1"));
    expect(getByTestId("button-set-image")).toBeInTheDocument();

    //TO-DO use MockedProvider to render mocks and set collection thumbnail
    // fireEvent.click(getByTestId("button-set-image"));
    // expect(getByTestId("modal-collection-thumbnail")).not.toHaveClass(
    //   "is-active "
    // );
  });
});
