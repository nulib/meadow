import React from "react";
import { render, fireEvent } from "@testing-library/react";
import BatchEditRemove from "./Remove";

const mockHandleRemoveClick = jest.fn();

describe("BatchEditRemove component", () => {
  function setupTests() {
    return render(
      <BatchEditRemove
        label="Item title"
        handleRemoveClick={mockHandleRemoveClick}
      />
    );
  }
  it("renders without crashing", () => {
    const { getByTestId } = setupTests();
    expect(getByTestId("batch-edit-remove")).toBeInTheDocument();
  });

  it("renders the correct legend label", () => {
    const { getByTestId } = setupTests();
    const el = getByTestId("legend-label");
    expect(el).toHaveTextContent("Item title (Remove)");
  });

  it("renders the remove button", () => {
    const { getByTestId } = setupTests();
    const el = getByTestId("button-remove");
    expect(el).toBeInTheDocument();

    fireEvent.click(el);
    expect(mockHandleRemoveClick).toHaveBeenCalled();
  });
});
