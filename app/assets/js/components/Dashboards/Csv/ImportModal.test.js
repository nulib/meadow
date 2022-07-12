import React from "react";
import DashboardsCsvImportModal from "./ImportModal";
import { screen } from "@testing-library/react";
import { renderWithRouterApollo } from "@js/services/testing-helpers";
import userEvent from "@testing-library/user-event";

const props = {
  currentFile: null,
  handleClose: jest.fn(),
  handleImportCsv: jest.fn(),
  isOpen: true,
  setCurrentFile: jest.fn(),
};

describe("DashboardsCsvImportModal component", () => {
  beforeEach(() => {
    renderWithRouterApollo(<DashboardsCsvImportModal {...props} />);
  });

  it("renders", () => {
    expect(screen.getByTestId("import-csv-modal"));
  });

  it("renders title and all buttons", () => {
    expect(screen.getByTestId("modal-title"));
    expect(screen.getByLabelText("close"));
    expect(screen.getByTestId("cancel-button"));
    expect(screen.getByTestId("submit-button"));
  });

  it("calls callback functions on cancel and submit", async () => {
    const user = userEvent.setup();

    const submitButton = screen.getByTestId("submit-button");
    expect(submitButton).toBeDisabled();
    await user.click(screen.getByTestId("cancel-button"));
    expect(props.handleClose).toHaveBeenCalled();
  });
});
