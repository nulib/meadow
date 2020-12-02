import React from "react";
import { render, screen } from "@testing-library/react";
import SearchBatchModal from "./BatchModal";
import userEvent from "@testing-library/user-event";

let props = {
  handleCloseClick: jest.fn(),
  handleCsvExport: jest.fn(),
  handleEditAllItems: jest.fn(),
  isOpen: false,
  numberOfResults: 35,
};

describe("SearchBatchModal component", () => {
  it("renders hidden state", () => {
    render(<SearchBatchModal {...props} />);
    expect(screen.getByTestId("select-all-modal")).not.toHaveClass("is-active");
  });

  it("renders visible state", () => {
    props = { ...props, isOpen: true };
    render(<SearchBatchModal {...props} />);
    expect(screen.getByTestId("select-all-modal")).toHaveClass("is-active");
  });

  it("calls the appropriate callback functions on button clicks", () => {
    props = { ...props, isOpen: true };
    render(<SearchBatchModal {...props} />);
    userEvent.click(screen.getByTestId("button-batch-edit"));
    userEvent.click(screen.getByTestId("button-csv-export"));

    expect(props.handleCsvExport).toHaveBeenCalled();
    expect(props.handleEditAllItems).toHaveBeenCalled();
  });
});
