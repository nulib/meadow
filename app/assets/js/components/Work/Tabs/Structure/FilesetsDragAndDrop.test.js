import React from "react";
import WorkTabsStructureFilesetsDragAndDrop from "./FilesetsDragAndDrop";
import { render, screen } from "@testing-library/react";
import { mockFileSets } from "@js/mock-data/filesets";
import userEvent from "@testing-library/user-event";
import { WorkProvider } from "@js/context/work-context";

const mockHandleCancelFn = jest.fn();
const mockHandleSaveFn = jest.fn();

describe("WorkTabsStructureFilesetsDragAndDrop component", () => {
  beforeEach(() => {
    render(
      <WorkProvider>
        <WorkTabsStructureFilesetsDragAndDrop
          fileSets={mockFileSets}
          handleCancelReorder={mockHandleCancelFn}
          handleSaveReorder={mockHandleSaveFn}
        />
      </WorkProvider>
    );
  });

  it("renders the Drag and Drop wrapper", async () => {
    expect(await screen.findByTestId("fileset-dnd-wrapper"));
  });

  it("renders save and cancel buttons", async () => {
    const user = userEvent.setup();
    const saveBtn = screen.getByTestId("button-reorder-save");
    const cancelBtn = screen.getByTestId("button-reorder-cancel");

    await user.click(saveBtn);
    expect(mockHandleSaveFn).toHaveBeenCalled();

    await user.click(cancelBtn);
    expect(mockHandleCancelFn).toHaveBeenCalled();
  });

  it("renders file sets", () => {});
});
