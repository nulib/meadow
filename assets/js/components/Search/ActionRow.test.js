import React from "react";
import { render, screen } from "@testing-library/react";
import SearchActionRow from "./ActionRow";
import userEvent from "@testing-library/user-event";

const mockHandleEditAllItems = jest.fn();
const mockHandleDeselectAll = jest.fn();
const mockHandleViewAndEdit = jest.fn();

let props = {
  handleEditAllItems: mockHandleEditAllItems,
  handleDeselectAll: mockHandleDeselectAll,
  handleViewAndEdit: mockHandleViewAndEdit,
};

describe("SearchActionRow component", () => {
  it("renders the search action row", () => {
    render(<SearchActionRow {...props} />);
    expect(screen.getByTestId("search-action-row"));
  });

  it("renders 'edit all' enabled by default, and 'view and edit' disabled by default  when search items are selected", () => {
    render(<SearchActionRow {...props} selectedItems={[]} />);

    const editAllButton = screen.getByTestId("edit-all-button");

    expect(editAllButton).not.toBeDisabled();
    expect(screen.getByTestId("view-and-edit-button")).toBeDisabled();

    userEvent.click(editAllButton);
    expect(mockHandleEditAllItems).toHaveBeenCalled();
  });

  it("renders 'view and edit' disabled, 'view and edit' enabled, and 'deselect all' button enabled when search items are selected", () => {
    render(<SearchActionRow {...props} selectedItems={["abc", "dfg"]} />);

    const viewAndEditButton = screen.getByTestId("view-and-edit-button");
    const deselectAll = screen.getByTestId("deselect-all-button");

    expect(screen.getByTestId("edit-all-button")).toBeDisabled();
    expect(viewAndEditButton).not.toBeDisabled();
    expect(deselectAll).not.toBeDisabled();

    userEvent.click(viewAndEditButton);
    expect(mockHandleViewAndEdit).toHaveBeenCalled();

    userEvent.click(deselectAll);
    expect(mockHandleDeselectAll).toHaveBeenCalled();
  });
});
