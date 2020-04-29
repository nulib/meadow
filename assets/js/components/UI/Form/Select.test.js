import React from "react";
import { render, fireEvent } from "@testing-library/react";
import UIFormSelect from "./Select";

describe("Select component", () => {
  const registerFn = jest.fn();

  const options = [
    { label: "Level 1", id: "1", value: "1" },
    { label: "Level 2", id: "2", value: "2" },
    { label: "Level 3", id: "3", value: "3" },
  ];

  const props = {
    name: "level",
    label: "Level",
    errors: {},
    "data-testid": "select-level",
    register: registerFn,
    options,
  };

  it("renders without crashing", () => {
    expect(render(<UIFormSelect {...props} />));
  });

  it("renders passed through attributes to the input element", () => {
    const { getByTestId } = render(
      <UIFormSelect {...props} defaultValue={2} disabled />
    );
    const select = getByTestId("select-level");

    expect(select.name).toEqual(props.name);
    expect(registerFn).toHaveBeenCalled();
    expect(select.disabled).toBeTruthy();
  });

  it("renders supplied options and a default value", () => {
    const { getByTestId, getByText } = render(
      <UIFormSelect {...props} defaultValue={2} />
    );

    expect(getByText("Level 1")).toBeInTheDocument();
    expect(getByText("Level 2")).toBeInTheDocument();
    expect(getByText("Level 3")).toBeInTheDocument();

    const select = getByTestId("select-level");
    expect(select.value).toEqual("2");
  });

  it("selects different option values correctly", () => {
    const { getByTestId } = render(<UIFormSelect {...props} />);
    const select = getByTestId("select-level");
    fireEvent.change(select, { target: { value: "3" } });
    expect(select.value).toEqual("3");
  });

  it("displays error message when error object present", () => {
    const { getByTestId, getByText } = render(
      <UIFormSelect {...props} errors={{ level: { message: "required" } }} />
    );

    expect(getByTestId("select-errors")).toBeInTheDocument();
    expect(getByText("Level field is required"));
  });
});
