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

  it("renders a disabled Submit button if no elements have been interacted with", async () => {
    const user = userEvent.setup();

    const submitButtonEl = screen.getByTestId("submit-button");
    expect(submitButtonEl).toBeDisabled();
    await user.type(screen.getByLabelText(/label/i), "something");
    expect(submitButtonEl).not.toBeDisabled();
  });

  it("calls the Cancel and Submit callback functions", async () => {
    const user = userEvent.setup();
    const expectedFormPostData = {
      label: "foo bar",
      hint: "ima hint",
    };
    const labelEl = screen.getByLabelText(/label/i);
    const hintEl = screen.getByLabelText(/hint/i);

    await user.clear(labelEl);
    await user.clear(hintEl);

    await user.type(labelEl, "foo bar");
    await user.type(hintEl, "ima hint");
    await user.click(screen.getByTestId("submit-button"));
    await waitFor(() => {
      expect(submitCallback).toHaveBeenCalledWith(expectedFormPostData);
    });

    await user.click(screen.getByTestId("cancel-button"));
    expect(cancelCallback).toHaveBeenCalled();
  });
});
