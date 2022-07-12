import React from "react";
import ProjectForm from "./Form";
import { fireEvent, act, screen } from "@testing-library/react";
import { renderWithRouterApollo } from "../../services/testing-helpers";
import userEvent from "@testing-library/user-event";

describe("ProjectForm component", () => {
  beforeEach(() => {
    renderWithRouterApollo(<ProjectForm />);
  });

  it("renders without crashing", () => {
    expect(screen.getAllByTestId("project-form"));
  });

  it("renders form input and buttons", () => {
    expect(screen.getByTestId("project-title-input"));
    expect(screen.getByTestId("submit-button"));
    expect(screen.getByTestId("cancel-button"));
  });

  it("displays input error when project title text input has no value", async () => {
    const user = userEvent.setup();
    const el = await screen.findByTestId("project-title-input");
    expect(el);

    await user.clear(el);
    await user.click(screen.getByTestId("submit-button"));
    expect(await screen.findByTestId("input-errors"));
  });
});
