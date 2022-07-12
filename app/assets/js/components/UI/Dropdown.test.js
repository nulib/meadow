import { screen, render } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import React from "react";
import UIDropdown from "./Dropdown";

describe("UIDropdown component", () => {
  beforeEach(() => {
    render(
      <UIDropdown data-testid="test-dropdown" id="dropdown1">
        <a href="#">Option 1</a>
        <a href="#">Option 2</a>
      </UIDropdown>
    );
  });

  it("renders the component ", async () => {
    expect(screen.getByTestId("test-dropdown"));
    expect(screen.getByTestId("dropdown-trigger"));
  });

  it("renders the id attribute for accessibility", () => {
    const el = screen.getByTestId("dropdown-menu");
    expect(el.id).toEqual("dropdown1");
  });

  it("renders dropdown content", async () => {
    const user = userEvent.setup();
    const dropdownEl = screen.getByTestId("test-dropdown");
    const el = screen.getByTestId("dropdown-content");

    expect(el.childElementCount).toEqual(2);
    expect(dropdownEl).not.toHaveClass("is-active");

    await user.click(screen.getByTestId("dropdown-trigger-button"));
    expect(dropdownEl).toHaveClass("is-active");
  });
});
