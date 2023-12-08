import React from "react";
import { render, screen, waitFor } from "@testing-library/react";
import DashboardsLocalAuthoritiesModalBulkAdd from "./ModalBulkAdd";
import userEvent from "@testing-library/user-event";

const cancelCallback = jest.fn();

const props = {
  isOpen: true,
  handleClose: cancelCallback,
};

describe("DashboardsLocalAuthoritiesModalBulkAdd component", () => {
  beforeEach(() => {
    render(<DashboardsLocalAuthoritiesModalBulkAdd {...props} />);
  });

  it("renders", () => {
    expect(screen.getByTestId("modal-nul-authority-bulk-add"));
  });

  it("renders all add form elements ", () => {
    expect(screen.getByRole("form"));
    expect(screen.getByTestId("dropzone-input"));
    expect(screen.getByTestId("submit-button"));
    expect(screen.getByTestId("cancel-button"));
  });

  it("calls the Cancel callback function", async () => {
    const user = userEvent.setup();
    await user.click(screen.getByTestId("cancel-button"));
    expect(cancelCallback).toHaveBeenCalled();
  });
});
