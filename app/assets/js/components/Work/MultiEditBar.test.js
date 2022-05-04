import React from "react";
import { render, screen } from "@testing-library/react";
import WorkMultiEditBar from "./MultiEditBar";

describe("MultiEditBar component", () => {
  it("renders the component", () => {
    render(<WorkMultiEditBar currentIndex={3} totalItems={20} />);
    expect(screen.getByTestId("multi-edit-bar"));
  });

  it("renders back and next buttons", () => {
    render(<WorkMultiEditBar currentIndex={3} totalItems={20} />);
    expect(screen.getByTestId("multi-edit-back-button"));
    expect(screen.getByTestId("multi-edit-next-button"));
  });

  it("renders the display message indicating which current item user is editing", () => {
    render(<WorkMultiEditBar currentIndex={3} totalItems={20} />);
    const el = screen.getByTestId("multi-edit-display-message");
    expect(el).toHaveTextContent("4");
    expect(el).toHaveTextContent("20");
  });

  it("has a disabled back button if viewing the first item", () => {
    render(<WorkMultiEditBar currentIndex={0} totalItems={20} />);
    expect(screen.getByTestId("multi-edit-back-button")).toBeDisabled();
  });

  it("has a disabled next button if viewing the last item", () => {
    render(<WorkMultiEditBar currentIndex={19} totalItems={20} />);
    expect(screen.getByTestId("multi-edit-next-button")).toBeDisabled();
  });
});
