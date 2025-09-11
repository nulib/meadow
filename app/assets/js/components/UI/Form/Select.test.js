import React from "react";
import { render, fireEvent, waitFor } from "@testing-library/react";
import UIFormSelect from "./Select";
import { renderWithReactHookForm } from "../../../services/testing-helpers";

describe("Select component", () => {
  const options = [
    { label: "Level 1", id: "1", value: "1" },
    { label: "Level 2", id: "2", value: "2" },
    { label: "Level 3", id: "3", value: "3" },
  ];

  const props = {
    name: "level",
    label: "Level",
    "data-testid": "select-level",
    options,
  };

  it("renders without crashing", () => {
    expect(renderWithReactHookForm(<UIFormSelect {...props} />));
  });

  it("renders passed through attributes to the select element", () => {
    const { getByTestId } = renderWithReactHookForm(
      <UIFormSelect {...props} defaultValue={2} data-foo="bar" />,
    );
    const select = getByTestId("select-level");

    expect(select.name).toEqual(props.name);
    expect(select.getAttribute("data-foo")).toEqual("bar");
  });

  it("renders isReadOnly attribute to the select element", () => {
    const { getByTestId } = renderWithReactHookForm(
      <UIFormSelect {...props} defaultValue={2} isReadOnly={true} />,
    );
    const select = getByTestId("select-level");

    expect(select.name).toEqual(props.name);
    expect(select.getAttribute("aria-readonly")).toBeTruthy();
  });

  it("renders supplied options and a default value", () => {
    const { getByTestId, getByText } = renderWithReactHookForm(
      <UIFormSelect {...props} defaultValue={2} />,
    );

    expect(getByText("Level 1")).toBeInTheDocument();
    expect(getByText("Level 2")).toBeInTheDocument();
    expect(getByText("Level 3")).toBeInTheDocument();

    const select = getByTestId("select-level");
    expect(select.value).toEqual("2");
  });

  it("selects different option values correctly", () => {
    const { getByTestId } = renderWithReactHookForm(
      <UIFormSelect {...props} />,
    );
    const select = getByTestId("select-level");
    fireEvent.change(select, { target: { value: "3" } });
    expect(select.value).toEqual("3");
  });

  // TODO: Figure out why setError is not working
  xit("displays error message when errors", async () => {
    const { getByTestId, getByText, reactHookFormMethods } =
      renderWithReactHookForm(<UIFormSelect isReactHookForm {...props} />, {
        toPassBack: ["setError"],
      });

    await waitFor(() => {
      reactHookFormMethods.setError(props.name, {
        type: "manual",
        message: "Level field is required",
      });
    });

    expect(getByTestId("select-errors")).toBeInTheDocument();
    expect(getByText("Level field is required"));
  });
});
