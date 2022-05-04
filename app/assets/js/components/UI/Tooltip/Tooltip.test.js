import React from "react";
import { screen, render } from "@testing-library/react";
import UITooltip from "./Tooltip";

describe("UITooltip component", () => {
  it("renders tooltip", () => {
    render(
      <UITooltip>
        <div className="tooltip-header">Test Header</div>
        <div className="tooltip-content">Test Content</div>
      </UITooltip>
    );
    expect(screen.getByTestId("tooltip-wrapper"));
    expect(screen.getByTestId("tooltip-body"));
  });

  it("renders empty when content is missing", () => {
    render(
      <UITooltip>
        <div className="tooltip-header">Test Header</div>
      </UITooltip>
    );
    expect(screen.queryByTestId("tooltip-wrapper")).not.toBeInTheDocument();
    expect(screen.queryByTestId("tooltip-content")).not.toBeInTheDocument();
  });

  it("renders empty when header is missing", () => {
    render(
      <UITooltip>
        <div className="tooltip-content">Test Content</div>
      </UITooltip>
    );
    expect(screen.queryByTestId("tooltip-wrapper")).not.toBeInTheDocument();
    expect(screen.queryByTestId("tooltip-content")).not.toBeInTheDocument();
  });

  it("renders empty wrapper when classnames are missing", () => {
    render(
      <UITooltip>
        <div>Test Header</div>
        <div>Test Content</div>
      </UITooltip>
    );
    expect(screen.queryByTestId("tooltip-wrapper")).toBeEmpty;
    expect(screen.queryByTestId("tooltip-content")).not.toBeInTheDocument();
  });
});
