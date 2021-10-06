import React from "react";
import BatchDeleteConrimationModal from "./BatchDeleteConfirmationModal";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import { fireEvent, waitFor, screen } from "@testing-library/react";
import { batchDeleteMock } from "@js/components/BatchEdit/batch-edit.gql.mock";

const mocks = [batchDeleteMock];

let isModalOpen = true;

const handleClose = () => {
  isModalOpen = false;
};

function setupMatchTests() {
  return renderWithRouterApollo(
    <BatchDeleteConrimationModal
      filteredQuery={{
        bool: {
          must: [
            {
              bool: {
                must: [
                  { bool: { must: [{ match: { "model.name": "Work" } }] } },
                ],
              },
            },
          ],
        },
      }}
      numberOfResults={4}
      handleCloseClick={handleClose}
      isOpen={isModalOpen}
      selectedItems={[]}
      isModalOpen={isModalOpen}
      handleClose={handleClose}
    />,
    { mocks }
  );
}

it("renders the BatchDeleteConfirmationModal", async () => {
  const { getByTestId, debug } = setupMatchTests();
  await waitFor(() => {
    expect(screen.getByTestId("input-confirmation-text"));
    expect(
      screen.getByText(
        "NOTE: This batch operation will permanently delete 4 works.",
        { exact: false }
      )
    ).toBeInTheDocument();
  });
});
