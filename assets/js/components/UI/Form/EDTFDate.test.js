import React from "react";
import { screen, fireEvent, waitFor } from "@testing-library/react";
import UIFormEDTFDate from "./EDTFDate";
import { renderWithReactHookForm } from "../../../services/testing-helpers";
import userEvent from "@testing-library/user-event";

const props = {
  name: "dateCreated",
  label: "Date created",
};

describe("EDTF Date test", () => {
  describe("error handling", () => {
    it("renders appropriate error messages with invalid date values", async () => {
      const {
        findByText,
        getByTestId,
        reactHookFormMethods,
      } = renderWithReactHookForm(<UIFormEDTFDate {...props} />, {
        toPassBack: ["setError"],
      });

      userEvent.click(getByTestId("button-add-field-array-row"));

      await waitFor(() => {
        reactHookFormMethods.setError("dateCreated[0].edtf", {
          type: "validate",
          message: "Please enter a valid date",
        });
      });
      expect(await findByText("Please enter a valid date"));
    });
  });

  describe("standard component behavior", () => {
    beforeEach(() => {
      renderWithReactHookForm(<UIFormEDTFDate {...props} />, {
        defaultValues: {
          dateCreated: [
            {
              edtf: "2010-01-01",
              humanized: "2010-01-01",
            },
          ],
        },
      });
    });

    it("renders component and an add button", () => {
      expect(screen.getByTestId("dateCreated-wrapper"));
      expect(screen.getByTestId("button-add-field-array-row"));
    });

    it("renders existing dateCreated values", () => {
      expect(screen.getAllByTestId("dateCreated-form-item")).toHaveLength(1);
    });

    it("renders form elements when adding a new dateCreated value", () => {
      const addButton = screen.getByTestId("button-add-field-array-row");
      fireEvent.click(addButton);
      fireEvent.click(addButton);
      expect(screen.getAllByTestId("dateCreated-form-item")).toHaveLength(3);
    });

    it("renders delete button, removes dateCreated on click", () => {
      const addButton = screen.getByTestId("button-add-field-array-row");
      fireEvent.click(addButton);
      fireEvent.click(addButton);
      fireEvent.click(addButton);
      fireEvent.click(addButton);

      expect(screen.getAllByTestId("dateCreated-form-item")).toHaveLength(5);

      const removeButtons = screen.getAllByTestId("button-dateCreated-remove");
      fireEvent.click(removeButtons[3]);
      expect(screen.getAllByTestId("dateCreated-form-item")).toHaveLength(4);
    });
  });
});
