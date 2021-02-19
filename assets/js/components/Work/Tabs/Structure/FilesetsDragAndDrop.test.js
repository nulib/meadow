import React from "react";
import WorkTabsStructureFilesetsDragAndDrop from "./FilesetsDragAndDrop";
import { render, screen } from "@testing-library/react";
import { mockFileSets } from "@js/mock-data/filesets";
import userEvent from "@testing-library/user-event";

const mockHandleCancelFn = jest.fn();
const mockHandleSaveFn = jest.fn();

describe("WorkTabsStructureFilesetsDragAndDrop component", () => {
  beforeEach(() => {
    render(
      <WorkTabsStructureFilesetsDragAndDrop
        fileSets={mockFileSets}
        handleCancelReorder={mockHandleCancelFn}
        handleSaveReorder={mockHandleSaveFn}
      />
    );
  });

  it("renders the Drag and Drop wrapper", () => {
    expect(screen.getByTestId("fileset-dnd-wrapper"));
  });

  it("renders save and cancel buttons", () => {
    const saveBtn = screen.getByTestId("button-reorder-save");
    const cancelBtn = screen.getByTestId("button-reorder-cancel");

    userEvent.click(saveBtn);
    expect(mockHandleSaveFn).toHaveBeenCalled();

    userEvent.click(cancelBtn);
    expect(mockHandleCancelFn).toHaveBeenCalled();
  });

  it("renders file sets", () => {});
});
