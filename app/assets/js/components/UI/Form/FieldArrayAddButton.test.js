import React from "react";
import UIFormFieldArrayAddButton from "@js/components/UI/Form/FieldArrayAddButton";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";

const addFn = jest.fn();

describe("UIFormFieldArrayAddButton component", () => {
  it("renders the button", () => {
    render(<UIFormFieldArrayAddButton />);
    expect(screen.getByTestId("button-add-field-array-row"));
  });

  it("renders the appropriate label", () => {
    render(<UIFormFieldArrayAddButton btnLabel="Add another" />);
    expect(screen.getByTestId("button-add-field-array-row")).toHaveTextContent(
      "Add another"
    );
  });

  it("calls the add callback function", () => {
    render(
      <UIFormFieldArrayAddButton
        btnLabel="Add another"
        handleAddClick={addFn}
      />
    );
    userEvent.click(screen.getByTestId("button-add-field-array-row"));
    expect(addFn).toHaveBeenCalled();
  });
});
