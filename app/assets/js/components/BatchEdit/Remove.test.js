import React from "react";
import { render, fireEvent } from "@testing-library/react";
import BatchEditRemove from "./Remove";
import { BatchProvider } from "../../context/batch-edit-context";

const mockHandleRemoveClick = jest.fn();

describe("BatchEditRemove component", () => {
  function setupTests() {
    return render(
      <BatchProvider value={null}>
        <BatchEditRemove
          label="Item title"
          handleRemoveClick={mockHandleRemoveClick}
          removeItems={["ABC123", "EFG888"]}
        />
      </BatchProvider>
    );
  }
  it("renders without crashing", () => {
    const { getByTestId } = setupTests();
    expect(getByTestId("batch-edit-remove")).toBeInTheDocument();
  });

  it("renders the remove button", () => {
    const { getByTestId } = setupTests();
    const el = getByTestId("button-remove");
    expect(el).toBeInTheDocument();
    expect(el).toHaveTextContent(/^View and remove Item title$/);

    fireEvent.click(el);
    expect(mockHandleRemoveClick).toHaveBeenCalled();
  });

  it("renders clear entries button", () => {
    const { getAllByTestId } = setupTests();
    expect(getAllByTestId("remove-delete-entries")).toHaveLength(2);
  });
});
