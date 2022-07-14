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
