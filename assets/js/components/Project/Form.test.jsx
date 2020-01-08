import React from "react";
import ProjectForm from "./Form";
import { fireEvent } from "@testing-library/react";
import { renderWithRouterApollo, wrapWithToast } from "../../testing-helpers";

describe("ProjectForm component", () => {
  function setUpTests() {
    return renderWithRouterApollo(wrapWithToast(<ProjectForm />));
  }

  it("renders without crashing", () => {
    expect(setUpTests());
  });

  it("renders form input and buttons", () => {
    const { getByTestId, debug } = setUpTests();
    expect(getByTestId("project-title-input")).toBeInTheDocument();
    expect(getByTestId("submit-button")).toBeInTheDocument();
    expect(getByTestId("cancel-button")).toBeInTheDocument();
  });

  it("disables the submit button when project title text input has no value", () => {
    const { getByLabelText, getByTestId, debug } = setUpTests();
    const el = getByLabelText(/project title/i);
    const button = getByTestId("submit-button");

    expect(el).toBeInTheDocument();
    expect(button).toHaveAttribute("disabled");

    // Add some text
    fireEvent.change(el, { target: { value: "abc" } });
    expect(el.value).toBe("abc");
    expect(button).not.toHaveAttribute("disabled");

    // Remove all input text
    fireEvent.change(el, { target: { value: "" } });
    expect(button).toHaveAttribute("disabled");
  });
});
