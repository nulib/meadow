import React from "react";
import { render, screen } from "@testing-library/react";
import { mockFileSets } from "@js/mock-data/filesets";
import userEvent from "@testing-library/user-event";
import { WorkProvider } from "@js/context/work-context";
import WorkFilesetActionButtonsGroupRemove from "./GroupRemove";

const mockUpdateFileSetFn = jest.fn();

const fileSet = mockFileSets[1];

describe("WorkFilesetActionButtonsGroupAdd component", () => {
  beforeEach(() => {
    render(
      <WorkProvider>
        <WorkFilesetActionButtonsGroupRemove
          fileSetId={fileSet.id}
          handleUpdateFileSet={mockUpdateFileSetFn}
        />
      </WorkProvider>,
    );
  });

  it("renders the FileSet GroupRemove component", async () => {
    const groupRemove = await screen.findByTestId("fileset-group-remove");
    expect(groupRemove).toBeInTheDocument();

    // renders the remove button
    expect(groupRemove.textContent).toBe("Detach");

    // triggers the remove function
    const user = userEvent.setup();
    await user.click(groupRemove);
    expect(mockUpdateFileSetFn).toHaveBeenCalledWith(fileSet.id, null);
  });
});
