import React, { useState } from "react";
import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import Selectable from "./Selectable";
import { mockUser } from "@js/components/Auth/auth.gql.mock";
import useIsAuthorized from "@js/hooks/useIsAuthorized";

jest.mock("@js/hooks/useIsAuthorized");
useIsAuthorized.mockReturnValue({
  user: mockUser,
  isAuthorized: () => true,
});

const fn = jest.fn();

describe("SearchSelectable component", () => {
  let isSelected = false;

  const TestWrapper = () => {
    const [selected, setSelected] = useState(isSelected);

    return (
      <Selectable
        id="foo"
        handleSelectItem={(id) => {
          setSelected(!selected);
          fn(id);
        }}
        isSelected={selected}
      />
    );
  };

  beforeEach(() => {
    render(<TestWrapper />);
  });

  it("renders a checkbox", async () => {
    const checkbox = await screen.findByTestId("checkbox-search-select");
    expect(checkbox).toBeInTheDocument();
    expect(checkbox).toHaveAttribute("id", "search-select-foo");
    expect(checkbox).toHaveAttribute("name", "search-select-foo");
    expect(checkbox).toHaveAttribute("role", "checkbox");
    expect(checkbox).toHaveAttribute("aria-label", "Select work");
    expect(checkbox).toHaveAttribute("aria-checked", "false");
  });

  it("calls onChange function handler when selected/deselected", async () => {
    const checkbox = screen.getByTestId("checkbox-search-select");

    fireEvent.click(checkbox);
    expect(fn).toHaveBeenCalledTimes(1);
    expect(fn).toHaveBeenCalledWith("foo");

    // Wait for state change and re-render
    await waitFor(() => {
      expect(checkbox).toHaveAttribute("aria-checked", "true");
      expect(checkbox).toHaveAttribute("aria-label", "Deselect work");
    });

    fireEvent.click(checkbox);
    expect(fn).toHaveBeenCalledTimes(2);
    expect(fn).toHaveBeenCalledWith("foo");

    await waitFor(() => {
      expect(checkbox).toHaveAttribute("aria-checked", "false");
      expect(checkbox).toHaveAttribute("aria-label", "Select work");
    });
  });
});
