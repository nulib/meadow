import React from "react";
import { fireEvent, screen } from "@testing-library/react";
import UIFormFieldArray from "./FieldArray";
import { renderWithReactHookForm } from "../../../services/testing-helpers";

const name = "imaMulti";
const defaultValue = "New Ima Multi";
const props = {
  "data-testid": "fieldset-ima-multi",
  name,
  label: "Ima Multi",
};

describe("InputMultiple component", () => {
  beforeEach(() => {
    renderWithReactHookForm(<UIFormFieldArray {...props} />, {
      // Prep the form with some default values if we wish
      defaultValues: {
        imaMulti: [{ value: defaultValue }],
      },
    });
  });

  it("renders without crashing", () => {
    expect(screen.getByTestId("fieldset-ima-multi"));
  });

  it("renders the wrapper fieldset element with the proper display label", () => {
    expect(screen.getByTestId("fieldset-ima-multi"));
    const legend = screen.getByTestId("legend");
    expect(legend.innerHTML.trim()).toEqual(props.label);
  });

  it("renders a field group with a form input, default value, and delete button", () => {
    expect(screen.getByTestId("input-field-array"));
    expect(screen.getByTestId("button-delete-field-array-row"));
  });

  it("renders an Add field button, which when clicked adds a new field array input row", () => {
    const addButton = screen.getByTestId("button-add-field-array-row");
    expect(addButton);

    // Change the input value
    const firstInput = screen.getByTestId("input-field-array");
    fireEvent.input(firstInput, { target: { value: "foobar " } });

    // Add a new input row
    fireEvent.click(addButton);
    const fieldArrayItems = screen.getAllByTestId("input-field-array");
    expect(fieldArrayItems).toHaveLength(2);
    expect(screen.getAllByPlaceholderText(defaultValue)).toHaveLength(2);
  });

  it("deletes the proper field array row successfully", () => {
    const addButton = screen.getByTestId("button-add-field-array-row");

    // Add new input rows
    fireEvent.click(addButton);
    fireEvent.click(addButton);
    fireEvent.click(addButton);

    const inputs = screen.getAllByTestId("input-field-array");

    // Change the input values
    fireEvent.input(inputs[0], {
      target: { value: "aaa" },
    });
    fireEvent.input(inputs[1], {
      target: { value: "bbb" },
    });
    fireEvent.input(inputs[2], {
      target: { value: "ccc" },
    });

    const buttons = screen.getAllByTestId("button-delete-field-array-row");
    fireEvent.click(buttons[1]);
    expect(screen.queryByDisplayValue("aaa"));
    expect(screen.queryByDisplayValue("ccc"));
    expect(screen.queryByDisplayValue("bbb")).toBeNull();
  });
});
