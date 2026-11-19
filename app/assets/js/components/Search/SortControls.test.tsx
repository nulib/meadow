import { fireEvent, render, screen } from "@testing-library/react";

import React from "react";
import SearchSortControls from "./SortControls";

describe("SearchSortControls component", () => {
  it("hides the direction toggle for relevancy", () => {
    render(
      <SearchSortControls
        sort={{ field: "relevancy", direction: "desc" }}
        onChange={jest.fn()}
      />,
    );
    const select = screen.getByTestId("search-sort-field") as HTMLSelectElement;
    expect(select.value).toEqual("relevancy");
    expect(screen.queryByTestId("search-sort-direction")).toBeNull();
  });

  it("switches field using that field's natural direction", () => {
    const onChange = jest.fn();
    render(
      <SearchSortControls
        sort={{ field: "relevancy", direction: "desc" }}
        onChange={onChange}
      />,
    );
    fireEvent.change(screen.getByTestId("search-sort-field"), {
      target: { value: "modified" },
    });
    expect(onChange).toHaveBeenCalledWith({
      field: "modified",
      direction: "desc",
    });
  });

  it("labels and toggles the direction per field", () => {
    const onChange = jest.fn();
    render(
      <SearchSortControls
        sort={{ field: "date-created", direction: "asc" }}
        onChange={onChange}
      />,
    );
    const button = screen.getByTestId("search-sort-direction");
    expect(button).toHaveAttribute(
      "title",
      "Oldest first (click for newest first)",
    );
    expect(button).toHaveAttribute("data-direction", "asc");
    fireEvent.click(button);
    expect(onChange).toHaveBeenCalledWith({
      field: "date-created",
      direction: "desc",
    });
  });
});
