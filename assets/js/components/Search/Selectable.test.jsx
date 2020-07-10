import React from "react";
import { render, fireEvent } from "@testing-library/react";
import Selectable from "./Selectable";

const fn = jest.fn();

describe("SearchSelectable component", () => {
  it("renders", () => {
    expect(render(<Selectable />));
  });

  it("renders a checkbox", () => {
    const { getByTestId } = render(<Selectable />);
    expect(getByTestId("checkbox-search-select")).toBeInTheDocument();
  });

  it("calls onChange function handler when selected/deselected", () => {
    const { getByTestId } = render(<Selectable handleSelectItem={fn} />);
    const el = getByTestId("checkbox-search-select");
    fireEvent.click(el);
    expect(fn).toHaveBeenCalled();
  });
});
