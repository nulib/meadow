import React from "react";
import { fireEvent, screen } from "@testing-library/react";
import UIFormBatchEDTFDate from "./BatchEDTFDate";
import { renderWithReactHookForm } from "../../../services/testing-helpers";

const name = "imaMulti";
const defaultValue = "";
const props = {
  "data-testid": "fieldset-ima-multi",
  name,
  label: "Ima Multi",
};

describe("InputMultiple component", () => {
  beforeEach(() => {
    renderWithReactHookForm(<UIFormBatchEDTFDate {...props} />, {
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
    expect(screen.getByTestId("dateCreated-edtf-input"));
    expect(screen.getByTestId("button-delete-field-array-row"));
  });

  it("renders an Add field button, which when clicked adds a new field array input row", () => {
    const addButton = screen.getByTestId("button-add-field-array-row");
    expect(addButton);

    // Change the input value
    const firstInput = screen.getByTestId("dateCreated-edtf-input");
    fireEvent.input(firstInput, { target: { value: "2020-01-01" } });

    // Add a new input row
    fireEvent.click(addButton);
    const fieldArrayItems = screen.getAllByTestId("dateCreated-edtf-input");
    expect(fieldArrayItems).toHaveLength(2);
  });
});
