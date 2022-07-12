import React from "react";
import { render, screen } from "@testing-library/react";
import UIFormBatchFieldArray from "@js/components/UI/Form/BatchFieldArray";
import { withReactHookForm } from "@js/services/testing-helpers";
import userEvent from "@testing-library/user-event";

const props = {
  label: "Ima label",
  name: "formElName",
};

describe("UIFormBatchFieldArray component", () => {
  beforeEach(() => {
    const Wrapped = withReactHookForm(UIFormBatchFieldArray, props);
    render(<Wrapped />);
  });

  it("renders", () => {
    expect(screen.getByTestId("batch-field-array"));
  });

  it("renders the legend", () => {
    expect(screen.getByTestId("legend")).toHaveTextContent(props.label);
  });

  it("renders fields list wrapper", () => {
    expect(screen.getByTestId("fields-list"));
  });

  it("renders edit type select element", () => {
    expect(screen.getByTestId("select-edit-type")).toHaveValue("append");
  });

  it("adds fields to the array", async () => {
    const user = userEvent.setup();
    const button = screen.getByTestId("button-add-field-array-row");
    await user.click(button);
    expect(screen.getAllByPlaceholderText("New Ima label")).toHaveLength(1);
    await user.click(button);
    expect(screen.getAllByPlaceholderText("New Ima label")).toHaveLength(2);
  });

  it("hides the fields list and button when Delete is edit type selection", async () => {
    const user = userEvent.setup();
    const button = screen.getByTestId("button-add-field-array-row");
    expect(screen.getByTestId("fields-list"));
    expect(screen.getByTestId("fields-list")).not.toHaveClass("is-hidden");
    expect(button).toBeVisible();

    // Select "delete" from dropdown menu
    await user.selectOptions(screen.getByTestId("select-edit-type"), [
      "delete",
    ]);
    expect(screen.queryByTestId("button-add-field-array-row")).toBeNull();
    expect(screen.getByTestId("fields-list")).toHaveClass("is-hidden");

    // Select "replace" from dropdown menu
    await user.selectOptions(screen.getByTestId("select-edit-type"), [
      "replace",
    ]);
    expect(screen.getByTestId("fields-list")).not.toHaveClass("is-hidden");
    expect(screen.queryByTestId("button-add-field-array-row")).not.toBeNull();
  });
});
