import React from "react";
import { screen } from "@testing-library/react";
import SearchActionRow from "./ActionRow";
import userEvent from "@testing-library/user-event";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import { mockUser } from "@js/components/Auth/auth.gql.mock";
import useIsAuthorized from "@js/hooks/useIsAuthorized";

jest.mock("@js/hooks/useIsAuthorized");
useIsAuthorized.mockReturnValue({
  user: mockUser,
  isAuthorized: () => true,
});

let props = {
  handleCsvExportAllItems: jest.fn(),
  handleCsvExportItems: jest.fn(),
  handleDeselectAll: jest.fn(),
  handleEditAllItems: jest.fn(),
  handleEditItems: jest.fn(),
  handleViewAndEdit: jest.fn(),
  numberOfResults: 33,
  selectedItems: [],
  filteredQuery: {
    bool: {
      must: [
        {
          bool: {
            must: [{ bool: { must: [{ match: { "model.name": "Work" } }] } }],
          },
        },
      ],
    },
  },
};

describe("SearchActionRow component", () => {
  it("renders the search action row", () => {
    renderWithRouterApollo(<SearchActionRow {...props} />);
    expect(screen.getByTestId("search-action-row"));
  });

  describe("with no selected items", () => {
    beforeEach(() => {
      renderWithRouterApollo(<SearchActionRow {...props} selectedItems={[]} />);
    });

    it("renders the select all and edit buttons", () => {
      expect(screen.getByTestId("button-select-all")).not.toBeDisabled();
      expect(screen.getByTestId("button-edit-items")).toBeDisabled();
    });

    it("renders all buttons when select all button is clicked", async () => {
      const user = userEvent.setup();

      // Open the modal
      await user.click(screen.getByTestId("button-select-all"));

      await user.click(screen.getByTestId("button-batch-all-edit"));
      expect(props.handleEditAllItems).toHaveBeenCalled();

      expect(screen.getByTestId("button-csv-all-export"));
      expect(screen.getByTestId("button-csv-all-shared-links"));
      expect(screen.getByTestId("button-batch-all-delete"));
    });
  });

  describe("with selected items", () => {
    beforeEach(() => {
      renderWithRouterApollo(
        <SearchActionRow {...props} selectedItems={["abc", "def"]} />
      );
    });

    it("renders the disabled select all and enabled edit and deselect all buttons", () => {
      expect(screen.getByTestId("button-select-all")).toBeDisabled();
      expect(screen.getByTestId("button-edit-items")).not.toBeDisabled();
      expect(screen.getByTestId("button-deselect-all")).not.toBeDisabled();
    });

    it("calls the deselect all callback function when button clicked", async () => {
      const user = userEvent.setup();
      await user.click(screen.getByTestId("button-deselect-all"));
      expect(props.handleDeselectAll).toHaveBeenCalled();
    });

    it("renders 'batch edit', 'csv export' and 'batch_delete' buttons when select all button is clicked", async () => {
      const user = userEvent.setup();
      // Open the modal
      await user.click(screen.getByTestId("button-edit-items"));

      await user.click(screen.getByTestId("button-batch-items-edit"));
      expect(props.handleEditItems).toHaveBeenCalled();

      await user.click(screen.getByTestId("button-view-and-edit"));
      expect(props.handleViewAndEdit).toHaveBeenCalled();

      expect(screen.getByTestId("button-csv-items-export"));
      expect(screen.getByTestId("button-csv-items-shared-links"));
      expect(screen.getByTestId("button-delete-items"));
    });
  });
});
