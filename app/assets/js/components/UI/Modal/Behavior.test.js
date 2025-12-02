import { screen, render } from "@testing-library/react";
import React from "react";
import UIBehaviorModal from "@js/components/UI/Modal/Behavior";
import userEvent from "@testing-library/user-event";

const mockBehaviors = [
  { id: "individuals", label: "Individuals" },
  { id: "continuous", label: "Continuous" },
  { id: "paged", label: "Paged" },
];

describe("UIBehaviorModal component", () => {
  const mockOnClose = jest.fn();
  const mockOnSave = jest.fn();

  beforeEach(() => {
    jest.clearAllMocks();
    render(
      <UIBehaviorModal
        isVisible={true}
        behaviors={mockBehaviors}
        currentBehavior="continuous"
        onClose={mockOnClose}
        onSave={mockOnSave}
      />
    );
  });

  it("renders the modal when visible", () => {
    const modalWrapper = screen.getByTestId("behavior-modal");
    expect(modalWrapper).toHaveClass("is-active");
  });

  it("renders radio buttons for all behaviors", () => {
    const radioWrapper = screen.getByTestId("radio-behavior");
    const radioButtons = radioWrapper.querySelectorAll('input[type="radio"]');
    expect(radioButtons).toHaveLength(3);
  });

  it("calls onClose when cancel button is clicked", async () => {
    const user = userEvent.setup();
    const cancelButton = screen.getByTestId("cancel-button");
    await user.click(cancelButton);
    expect(mockOnClose).toHaveBeenCalledTimes(1);
  });

  it("calls onSave with selected behavior when save button is clicked", async () => {
    const user = userEvent.setup();
    const saveButton = screen.getByTestId("submit-button");
    await user.click(saveButton);
    expect(mockOnSave).toHaveBeenCalledWith("continuous");
  });
});
