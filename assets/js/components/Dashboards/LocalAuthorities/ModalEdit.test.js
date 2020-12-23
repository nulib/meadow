import React from "react";
import { render, screen, waitFor } from "@testing-library/react";
import DashboardsLocalAuthoritiesModalEdit from "./ModalEdit";
import userEvent from "@testing-library/user-event";
import { mockNulAuthorityRecords } from "@js/components/Dashboards/dashboards.gql.mock";

const submitCallback = jest.fn();
const cancelCallback = jest.fn();

const props = {
  currentAuthority: mockNulAuthorityRecords[0],
  isOpen: true,
  handleUpdate: submitCallback,
  handleClose: cancelCallback,
};

describe("DashboardsLocalAuthoritiesModalEdit component", () => {
  beforeEach(() => {
    render(<DashboardsLocalAuthoritiesModalEdit {...props} />);
  });

  it("renders the component", () => {
    expect(screen.getByTestId("modal-nul-authority-update"));
  });

  it("renders all add form elements with default values", () => {
    expect(screen.getByRole("form"));
    expect(screen.getByLabelText("Hint")).toHaveValue("Ima hint 1");
    expect(screen.getByLabelText("Label", { exact: false })).toHaveValue(
      "NUL Auth Record 1"
    );
    expect(screen.getByTestId("submit-button"));
    expect(screen.getByTestId("cancel-button"));
  });

  it("renders a disabled Submit button if no elements have been interacted with", () => {
    const submitButtonEl = screen.getByTestId("submit-button");
    expect(submitButtonEl).toBeDisabled();
    userEvent.type(screen.getByLabelText(/label/i), "something");
    expect(submitButtonEl).not.toBeDisabled();
  });

  it("calls the Cancel and Submit callback functions", async () => {
    const expectedFormPostData = {
      label: "foo bar",
      hint: "ima hint",
    };
    const labelEl = screen.getByLabelText(/label/i);
    const hintEl = screen.getByLabelText(/hint/i);

    userEvent.clear(labelEl);
    userEvent.clear(hintEl);

    userEvent.type(labelEl, "foo bar");
    userEvent.type(hintEl, "ima hint");
    userEvent.click(screen.getByTestId("submit-button"));
    await waitFor(() => {
      expect(submitCallback).toHaveBeenCalledWith(expectedFormPostData);
    });

    userEvent.click(screen.getByTestId("cancel-button"));
    expect(cancelCallback).toHaveBeenCalled();
  });
});
