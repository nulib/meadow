import {
  renderWithRouterApollo,
} from "@js/services/testing-helpers";
import React from "react";
import WorkTabsStructureFilesetsDragAndDrop from "./FilesetsDragAndDrop";
import { screen } from "@testing-library/react";
import { mockFileSets } from "@js/mock-data/filesets";
import { CodeListProvider } from "@js/context/code-list-context";
import userEvent from "@testing-library/user-event";
import { WorkProvider } from "@js/context/work-context";
import { allCodeListMocks } from "@js/components/Work/controlledVocabulary.gql.mock";

const mockHandleCancelFn = jest.fn();
const mockHandleSaveFn = jest.fn();
const mockGroupWithFn = jest.fn();

describe("WorkTabsStructureFilesetsDragAndDrop component", () => {
  beforeEach(() => {
    renderWithRouterApollo(
      <CodeListProvider>
        <WorkProvider>
          <WorkTabsStructureFilesetsDragAndDrop
            fileSets={mockFileSets}
            handleCancelReorder={mockHandleCancelFn}
            handleSaveReorder={mockHandleSaveFn}
            handleGroupWithUpdate={mockGroupWithFn}
          />
        </WorkProvider>
      </CodeListProvider>,
      {
        mocks: allCodeListMocks,
      }
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
    expect(mockGroupWithFn).toHaveBeenCalled();

    await user.click(cancelBtn);
    expect(mockHandleCancelFn).toHaveBeenCalled();
  });
});
