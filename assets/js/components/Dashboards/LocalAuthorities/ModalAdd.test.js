import React from "react";
import { render, screen, waitFor } from "@testing-library/react";
import DashboardsLocalAuthoritiesModalAdd from "./ModalAdd";
import userEvent from "@testing-library/user-event";

const submitCallback = jest.fn();
const cancelCallback = jest.fn();

const props = {
  isOpen: true,
  handleAddLocalAuthority: submitCallback,
  handleClose: cancelCallback,
};

describe("DashboardsLocalAuthoritiesModalAdd component", () => {
  beforeEach(() => {
    render(<DashboardsLocalAuthoritiesModalAdd {...props} />);
  });

  it("renders", () => {
    expect(screen.getByTestId("modal-nul-authority-add"));
  });

  it("renders all add form elements ", () => {
    expect(screen.getByRole("form"));
    expect(screen.getByLabelText("Hint"));
    expect(screen.getByLabelText("Label", { exact: false }));
    expect(screen.getByTestId("submit-button"));
    expect(screen.getByTestId("cancel-button"));
  });

  it("calls the Cancel and Submit callback functions", async () => {
    const expectedFormPostData = {
      label: "foo bar",
      hint: "ima hint",
    };

    userEvent.type(screen.getByLabelText(/label/i), "foo bar");
    userEvent.type(screen.getByLabelText(/hint/i), "ima hint");
    userEvent.click(screen.getByTestId("submit-button"));
    await waitFor(() => {
      expect(submitCallback).toHaveBeenCalledWith(expectedFormPostData);
    });

    userEvent.click(screen.getByTestId("cancel-button"));
    expect(cancelCallback).toHaveBeenCalled();
  });
});
