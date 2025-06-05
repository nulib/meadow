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

  it("renders all form elements", () => {
    expect(screen.getByRole("form"));
    expect(screen.getByTestId("dropzone-input"));
    expect(screen.getByTestId("submit-button"));
    expect(screen.getByTestId("cancel-button"));
    expect(screen.getByTestId("bulk-add-radio"));
    // expect(screen.getByTestId("bulk-update-radio"));
  });

  it("calls the Cancel callback function", async () => {
    const user = userEvent.setup();
    await user.click(screen.getByTestId("cancel-button"));
    expect(cancelCallback).toHaveBeenCalled();
  });

  it("has 'Bulk Add' selected by default", () => {
    const bulkAddRadio = screen.getByTestId("bulk-add-radio");
    // const bulkUpdateRadio = screen.getByTestId("bulk-update-radio");
    
    expect(bulkAddRadio).toBeChecked();
    // expect(bulkUpdateRadio).not.toBeChecked();
  });

  // it("changes form action when 'Bulk Update' is selected", async () => {
  //   const user = userEvent.setup();
  //   const bulkUpdateRadio = screen.getByTestId("bulk-update-radio");
    
  //   const form = screen.getByRole("form");
  //   expect(form.getAttribute("action")).toBe("/api/authority_records/bulk_create");
    
  //   await user.click(bulkUpdateRadio);
    
  //   expect(form.getAttribute("action")).toBe("/api/authority_records/bulk_update");
  // });

  // it("changes form action when switching between options", async () => {
  //   const user = userEvent.setup();
  //   const bulkAddRadio = screen.getByTestId("bulk-add-radio");
  //   const bulkUpdateRadio = screen.getByTestId("bulk-update-radio");
  //   const form = screen.getByRole("form");
    
  //   // Initial state
  //   expect(form.getAttribute("action")).toBe("/api/authority_records/bulk_create");
    
  //   // Switch to update
  //   await user.click(bulkUpdateRadio);
  //   expect(form.getAttribute("action")).toBe("/api/authority_records/bulk_update");
    
  //   // Switch back to add
  //   await user.click(bulkAddRadio);
  //   expect(form.getAttribute("action")).toBe("/api/authority_records/bulk_create");
  // });
});