import React from "react";
import UIInput from "./Input";
import { render, fireEvent } from "@testing-library/react";

const props = {
  id: "my-input",
  label: "First name",
  name: "my-input",
  type: "text",
  onChange: () => {}
};

it("renders without error", () => {
  render(<UIInput {...props} />);
});

it("renders a label for the input element", () => {
  const { getByLabelText } = render(<UIInput {...props} />);
  expect(getByLabelText(props.label)).toBeInTheDocument();
});

it("renders id and name attributes on the input element", () => {
  const { getByLabelText } = render(<UIInput {...props} />);
  const inputElement = getByLabelText(props.label);
  expect(inputElement.id).toEqual(props.id);
  expect(inputElement.name).toEqual(props.name);
});

it("fires the onChange function", () => {
  const mockFn = jest.fn();
  const newProps = { ...props, ...{ onChange: mockFn } };

  const { getByLabelText } = render(<UIInput {...newProps} />);
  const inputEl = getByLabelText(props.label);

  fireEvent.change(inputEl, { target: { value: "foo" } });
  expect(inputEl.value).toBe("foo");
  expect(mockFn).toHaveBeenCalledTimes(1);
});
