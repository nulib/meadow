import React from "react";
import UIInput from "./Input";
import { waitFor } from "@testing-library/react";
import { renderWithReactHookForm } from "../../../services/testing-helpers";

const attrs = {
  label: "First name",
  name: "tester",
  type: "text",
  "data-testid": "input-element",
  required: true,
  defaultValue: "Bob Smith",
};

it("renders without error", () => {
  renderWithReactHookForm(<UIInput {...attrs} />);
});

it("renders passed through attributes to the input element", () => {
  const { getByTestId } = renderWithReactHookForm(<UIInput {...attrs} />);
  const input = getByTestId("input-element");

  expect(input.name).toEqual(attrs.name);
  expect(input.type).toEqual("text");
  expect(input.value).toEqual("Bob Smith");
});

// TODO: Figure out why setError is not working.  Related to other tests after upgrade.
xit("renders error message when errors", async () => {
  const { getByTestId, getByText, reactHookFormMethods } =
    renderWithReactHookForm(<UIInput isReactHookForm {...attrs} />, {
      toPassBack: ["setError"],
    });

  await waitFor(() => {
    reactHookFormMethods.setError(attrs.name, {
      type: "manual",
      message: "required",
    });
  });

  expect(getByTestId("input-element")).toHaveClass("is-danger");
  expect(getByTestId("input-errors")).toBeInTheDocument();
  expect(getByText("First name field is required"));
});


it("does not show clear button when showClearButton is false", () => {
  const { queryByLabelText } = renderWithReactHookForm(
    <UIInput {...attrs} showClearButton={false} />
  );

  expect(queryByLabelText("Clear input")).not.toBeInTheDocument();
});

it("does not show clear button when input is empty", () => {
  const attrsWithoutValue = { ...attrs, defaultValue: "" };
  const { queryByLabelText } = renderWithReactHookForm(
    <UIInput {...attrsWithoutValue} showClearButton={true} />
  );

  expect(queryByLabelText("Clear input")).not.toBeInTheDocument();
});

it("shows clear button when showClearButton is true and input has value", () => {
  const { getByLabelText } = renderWithReactHookForm(
    <UIInput {...attrs} isReactHookForm={true} showClearButton={true} />,
    {
      defaultValues: { tester: "Bob Smith" }  
    }
  );
  
  expect(getByLabelText("Clear input")).toBeInTheDocument();
});

it("clears input value when clear button is clicked (React Hook Form)", async () => {
  const { getByLabelText, getByTestId } = renderWithReactHookForm(
    <UIInput {...attrs} isReactHookForm={true} showClearButton={true} />,
    {
      defaultValues: { tester: "Bob Smith" }
    }
  );

  const input = getByTestId("input-element");
  const clearButton = getByLabelText("Clear input");

  expect(input.value).toEqual("Bob Smith");

  clearButton.click();

  await waitFor(() => {
    expect(input.value).toEqual("");
  });
});

it("clears input value when clear button is clicked (non-React Hook Form)", () => {
  const mockOnChange = jest.fn();
  const nonHookFormAttrs = {
    ...attrs,
    isReactHookForm: false,
    onChange: mockOnChange,
    value: "Bob Smith"
  };

  const { getByLabelText } = renderWithReactHookForm(
    <UIInput {...nonHookFormAttrs} showClearButton={true} />
  );

  const clearButton = getByLabelText("Clear input");
  clearButton.click();

  expect(mockOnChange).toHaveBeenCalledWith({
    target: { name: "tester", value: "" }
  });
});

it("hides clear button after clearing input", async () => {
  const { getByLabelText, queryByLabelText, getByTestId } = renderWithReactHookForm(
    <UIInput {...attrs} isReactHookForm={true} showClearButton={true} />,
    {
      defaultValues: { tester: "Bob Smith" }
    }
  );

  expect(getByLabelText("Clear input")).toBeInTheDocument();

  getByLabelText("Clear input").click();

  await waitFor(() => {
    expect(getByTestId("input-element").value).toEqual("");
  });

  await waitFor(() => {
    expect(queryByLabelText("Clear input")).not.toBeInTheDocument();
  });
});
