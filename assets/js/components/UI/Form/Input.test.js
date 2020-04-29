import React from "react";
import UIInput from "./Input";
import { render, fireEvent } from "@testing-library/react";

const registerFn = jest.fn();
const props = {
  errors: {},
  register: registerFn,
};
const attrs = {
  label: "First name",
  name: "tester",
  type: "text",
  "data-testid": "input-element",
  required: true,
  defaultValue: "Bob Smith",
};

it("renders without error", () => {
  render(<UIInput {...props} {...attrs} />);
});

it("renders passed through attributes to the input element", () => {
  const { getByTestId } = render(<UIInput {...props} {...attrs} />);
  const input = getByTestId("input-element");

  expect(input.name).toEqual(attrs.name);
  expect(input.type).toEqual("text");
  expect(input.value).toEqual("Bob Smith");
  expect(registerFn).toHaveBeenCalled();
});

it("renders error message when errors object passed in", () => {
  const { getByTestId, getByText } = render(
    <UIInput
      {...props}
      {...attrs}
      errors={{ tester: { message: "required" } }}
    />
  );
  const input = getByTestId("input-element");
  const p = getByTestId("input-errors");

  expect(input).toHaveClass("is-danger");
  expect(p).toBeInTheDocument();
  expect(getByText("First name field is required"));
});
