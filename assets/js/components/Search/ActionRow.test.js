import React from "react";
import { render, screen } from "@testing-library/react";
import SearchActionRow from "./ActionRow";
import userEvent from "@testing-library/user-event";

let props = {
  handleCsvExport: jest.fn(),
  handleDeselectAll: jest.fn(),
  handleEditAllItems: jest.fn(),
  handleViewAndEdit: jest.fn(),
  numberOfResults: 33,
  selectedItems: [],
};

describe("SearchActionRow component", () => {
  it("renders the search action row", () => {
    render(<SearchActionRow {...props} />);
    expect(screen.getByTestId("search-action-row"));
  });

  it("renders 'select all' button enabled by default, and 'edit X items' button disabled by default ", () => {
    render(<SearchActionRow {...props} selectedItems={[]} />);

    const selectAllButton = screen.getByTestId("select-all-button");

    expect(selectAllButton).not.toBeDisabled();
    expect(screen.getByTestId("view-and-edit-button")).toBeDisabled();
  });

  it("renders a disabled 'select all' button, and enabled 'view and edit' and 'deselect all' buttons when search items are selected", () => {
    render(<SearchActionRow {...props} selectedItems={["abc", "dfg"]} />);

    const viewAndEditButton = screen.getByTestId("view-and-edit-button");
    const deselectAll = screen.getByTestId("deselect-all-button");

    expect(screen.getByTestId("select-all-button")).toBeDisabled();
    expect(viewAndEditButton).not.toBeDisabled();
    expect(deselectAll).not.toBeDisabled();

    userEvent.click(viewAndEditButton);
    expect(props.handleViewAndEdit).toHaveBeenCalled();

    userEvent.click(deselectAll);
    expect(props.handleDeselectAll).toHaveBeenCalled();
  });
});
