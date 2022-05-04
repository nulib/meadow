import React from "react";
import { render, fireEvent } from "@testing-library/react";
import UICodeListCacheRefresh from "./CodeListCacheRefresh";

const mockHandleClick = jest.fn();

describe("UICodeListCacheRefresh component", () => {
  it("renders the component", () => {
    const { getByTestId } = render(<UICodeListCacheRefresh />);
    expect(getByTestId("cache-refresh")).toBeInTheDocument();
  });

  it("renders the cache refresh button and fires the callback function successfully when clicked", () => {
    const { getByTestId } = render(
      <UICodeListCacheRefresh handleClick={mockHandleClick} />
    );
    const el = getByTestId("button-cache-refresh");
    fireEvent.click(el);
    expect(mockHandleClick).toHaveBeenCalled();
  });
});
