import React from "react";
import { render, fireEvent, screen } from "@testing-library/react";
import UIFormFieldArray from "./FieldArray";
import { useForm } from "react-hook-form";

const name = "imaMulti";
const defaultValue = "New Ima Multi";
const props = {
  "data-testid": "fieldset-ima-multi",
  name,
  label: "Ima Multi",
  errors: {},
};

const withReactHookFormControl = (WrappedComponent) => {
  const HOC = () => {
    const { control, register } = useForm({
      defaultValues: {
        imaMulti: [{ value: defaultValue }],
      },
    });
    return (
      <WrappedComponent {...props} control={control} register={register} />
    );
  };

  return HOC;
};

describe("InputMultiple component", () => {
  function setUpTests() {
    const Wrapped = withReactHookFormControl(UIFormFieldArray);
    return render(<Wrapped {...props} />);
  }

  it("renders without crashing", () => {
    expect(setUpTests());
  });

  it("renders the wrapper fieldset element with the proper display label", () => {
    const { getByTestId, getByLabelText } = setUpTests();
    expect(getByTestId("fieldset-ima-multi"));
    const legend = getByTestId("legend");
    expect(legend.innerHTML.trim()).toEqual(props.label);
  });

  it("renders a field group with a form input, default value, and delete button", () => {
    const { getByTestId, getAllByTestId } = setUpTests();
    expect(getAllByTestId("input-field-array")).toHaveLength(1);
    expect(getByTestId("button-delete-field-array-row"));
  });

  it("renders an Add field button, which when clicked adds a new field array input row", () => {
    const { getByTestId, getAllByTestId } = setUpTests();
    const addButton = getByTestId("button-add-field-array-row");
    expect(addButton);

    // Change the input value
    const firstInput = getByTestId("input-field-array");
    fireEvent.input(firstInput, { target: { value: "foobar " } });

    // Add a new input row
    fireEvent.click(addButton);
    expect(getAllByTestId("input-field-array")).toHaveLength(2);
    expect(screen.getByDisplayValue(defaultValue));
  });

  it("deletes the proper field array row successfully", () => {
    const { getByTestId, getAllByTestId, queryByDisplayValue } = setUpTests();
    const addButton = getByTestId("button-add-field-array-row");

    // Add new input rows
    fireEvent.click(addButton);
    fireEvent.click(addButton);
    fireEvent.click(addButton);

    const inputs = getAllByTestId("input-field-array");

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

    const buttons = getAllByTestId("button-delete-field-array-row");
    fireEvent.click(buttons[1]);
    expect(queryByDisplayValue("aaa"));
    expect(queryByDisplayValue("ccc"));
    expect(queryByDisplayValue("bbb")).toBeNull();
  });
});
