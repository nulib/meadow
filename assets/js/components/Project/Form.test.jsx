import React from "react";
import ProjectForm from "./Form";
import { fireEvent, act } from "@testing-library/react";
import { renderWithRouterApollo } from "../../services/testing-helpers";

describe("ProjectForm component", () => {
  function setUpTests() {
    return renderWithRouterApollo(<ProjectForm />);
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

  it("displays input error when project title text input has no value", async () => {
    const { getByTestId } = setUpTests();
    const el = getByTestId("project-title-input");
    expect(el).toBeInTheDocument();

    await act(async () => {
      fireEvent.change(el, { target: { value: "" } });
    });
    await act(async () => {
      fireEvent.submit(getByTestId("project-form"));
    });

    expect(getByTestId("input-errors")).toBeInTheDocument();
  });
});
