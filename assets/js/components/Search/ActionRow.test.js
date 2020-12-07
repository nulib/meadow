import React from "react";
import { render, screen } from "@testing-library/react";
import SearchActionRow from "./ActionRow";
import userEvent from "@testing-library/user-event";

let props = {
  handleCsvExportAllItems: jest.fn(),
  handleCsvExportItems: jest.fn(),
  handleDeselectAll: jest.fn(),
  handleEditAllItems: jest.fn(),
  handleEditItems: jest.fn(),
  handleViewAndEdit: jest.fn(),
  numberOfResults: 33,
  selectedItems: [],
};

describe("SearchActionRow component", () => {
  it("renders the search action row", () => {
    render(<SearchActionRow {...props} />);
    expect(screen.getByTestId("search-action-row"));
  });

  describe("with no selected items", () => {
    beforeEach(() => {
      render(<SearchActionRow {...props} selectedItems={[]} />);
    });

    it("renders the select all and edit buttons", () => {
      expect(screen.getByTestId("button-select-all")).not.toBeDisabled();
      expect(screen.getByTestId("button-edit-items")).toBeDisabled();
    });

    it("renders 'batch edit' and 'csv export' buttons when select all button is clicked", () => {
      userEvent.click(screen.getByTestId("button-select-all"));
      userEvent.click(screen.getByTestId("button-batch-all-edit"));
      expect(props.handleEditAllItems).toHaveBeenCalled();
      userEvent.click(screen.getByTestId("button-csv-all-export"));
      expect(props.handleCsvExportAllItems).toHaveBeenCalled();
    });
  });

  describe("with selected items", () => {
    beforeEach(() => {
      render(<SearchActionRow {...props} selectedItems={["abc", "def"]} />);
    });

    it("renders the disabled select all and enabled edit and deselect all buttons", () => {
      expect(screen.getByTestId("button-select-all")).toBeDisabled();
      expect(screen.getByTestId("button-edit-items")).not.toBeDisabled();
      expect(screen.getByTestId("button-deselect-all")).not.toBeDisabled();
    });

    it("calls the deselect all callback function when button clicked", () => {
      userEvent.click(screen.getByTestId("button-deselect-all"));
      expect(props.handleDeselectAll).toHaveBeenCalled();
    });

    it("renders 'batch edit' and 'csv export' buttons when select all button is clicked", () => {
      userEvent.click(screen.getByTestId("button-edit-items"));
      userEvent.click(screen.getByTestId("button-batch-items-edit"));
      expect(props.handleEditItems).toHaveBeenCalled();
      userEvent.click(screen.getByTestId("button-view-and-edit"));
      expect(props.handleViewAndEdit).toHaveBeenCalled();
      userEvent.click(screen.getByTestId("button-csv-items-export"));
      expect(props.handleCsvExportItems).toHaveBeenCalled();
    });
  });
});
