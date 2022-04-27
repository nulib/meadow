import { screen, render } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import React from "react";
import UIDropdownItem from "./DropdownItem";

const mockHandleClick = jest.fn();

describe("UIDropdownItem component", () => {
  describe("default implementation", () => {
    beforeEach(() => {
      render(
        <UIDropdownItem
          data-testid="test-dropdown-item"
          onClick={mockHandleClick}
        >
          Option 1
        </UIDropdownItem>
      );
    });

    it("renders the component", async () => {
      expect(screen.getByTestId("test-dropdown-item"));
      expect(screen.getByText("Option 1"));
    });

    it("handles click event", () => {
      userEvent.click(screen.getByTestId("test-dropdown-item"));
      expect(mockHandleClick).toHaveBeenCalled();
    });
  });

  describe("custom implementation", () => {
    it("renders as dynamic HTML element", async () => {
      render(
        <UIDropdownItem
          as="div"
          data-testid="test-dropdown-item"
          onClick={mockHandleClick}
        >
          Option 1
        </UIDropdownItem>
      );
      const el = screen.getByTestId("test-dropdown-item");
      expect(el.tagName).toEqual("DIV");
    });
  });
});
