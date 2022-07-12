import React from "react";
import { render, screen } from "@testing-library/react";
import SearchBatchModal from "./BatchModal";
import userEvent from "@testing-library/user-event";

let props = {
  handleCloseClick: jest.fn(),
  isOpen: false,
  children: (
    <div>
      <p>Im child content</p>
    </div>
  ),
};

describe("SearchBatchModal component", () => {
  it("renders modal hidden state", () => {
    render(<SearchBatchModal {...props} />);
    expect(screen.getByTestId("select-all-modal")).not.toHaveClass("is-active");
  });

  it("renders modal visible state", () => {
    props = { ...props, isOpen: true };
    render(<SearchBatchModal {...props} />);
    expect(screen.getByTestId("select-all-modal")).toHaveClass("is-active");
  });

  it("calls the close modal callback function", async () => {
    const user = userEvent.setup();
    props = { ...props, isOpen: true };
    render(<SearchBatchModal {...props} />);
    await user.click(screen.getByTestId("header-close-button"));
    await user.click(screen.getByText("Cancel"));
    expect(props.handleCloseClick).toHaveBeenCalledTimes(2);
  });

  it("renders child content", () => {
    props = { ...props, isOpen: true };
    render(<SearchBatchModal {...props} />);
    expect(screen.getByText("Im child content"));
  });
});
