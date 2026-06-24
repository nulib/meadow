import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { FormProvider, useForm } from "react-hook-form";
import UIFormNote from "./Note";
import { notesSchemeMock } from "../../Work/controlledVocabulary.gql.mock";
import { renderWithReactHookForm } from "../../../services/testing-helpers";
import userEvent from "@testing-library/user-event";

const props = {
  codeLists: notesSchemeMock,
  name: "notes",
  label: "Note",
};

describe("Note controlled metadata form component", () => {
  describe("error handling", () => {
    it("renders appropriate error message when url errors are set manually", async () => {
      const user = userEvent.setup();
      const { findByText, getByTestId, reactHookFormMethods } =
        renderWithReactHookForm(<UIFormNote {...props} />, {
          toPassBack: ["setError"],
        });

      await user.click(getByTestId("button-add-field-array-row"));

      await waitFor(() => {
        reactHookFormMethods.setError("notes[0].note", {
          type: "required",
          message: "Note is required",
        });
      });
      expect(await findByText("Note is required"));
    });
  });

  describe("standard component behavior", () => {
    beforeEach(() => {
      renderWithReactHookForm(<UIFormNote {...props} />, {
        defaultValues: {
          notes: [
            {
              note: "A sample general note",
              type: {
                id: "GENERAL_NOTE",
                label: "General note",
                scheme: "NOTE_TYPE",
              },
            },
          ],
        },
      });
    });

    it("renders component and an add button", () => {
      expect(screen.getByTestId("note-wrapper"));
      expect(screen.getByTestId("button-add-field-array-row"));
    });

    it("renders existing note values", () => {
      expect(screen.getAllByTestId("note-existing-value")).toHaveLength(1);
      expect(screen.getByText("A sample general note, General note"));
    });

    it("renders form elements when adding a new note value", () => {
      const addButton = screen.getByTestId("button-add-field-array-row");
      fireEvent.click(addButton);
      fireEvent.click(addButton);
      expect(screen.getAllByTestId("note-form-item")).toHaveLength(2);
      expect(screen.getAllByTestId("note-input")).toHaveLength(2);
      expect(screen.getAllByTestId("note-select")).toHaveLength(2);
    });

    it("renders delete button, removes note on click", () => {
      const addButton = screen.getByTestId("button-add-field-array-row");
      fireEvent.click(addButton);
      fireEvent.click(addButton);
      fireEvent.click(addButton);
      fireEvent.click(addButton);

      expect(screen.getAllByTestId("note-form-item")).toHaveLength(4);

      const removeButtons = screen.getAllByTestId("button-note-remove");
      fireEvent.click(removeButtons[3]);
      expect(screen.getAllByTestId("note-form-item")).toHaveLength(3);
    });
  });

  /**
   * Regression test for bug #5825: saving 3+ Note entries caused the error banner
   * "An issue has occured within Note."
   *
   * Root cause: `useFieldArray` rebuilds the `fields` snapshot from current form values
   * on every `append()`. A previously-filled row has `item.typeId` populated in the
   * new snapshot, which switches it from the editable path to the hidden-input path.
   * The hidden `typeId` input was written as `value={item.type ? item.type.id : ""}`.
   * Because form-entered rows have only a `typeId` string (no `type` object), the
   * value collapsed to `""`, erasing the selection and causing required validation to
   * fail on submit.
   *
   * Fix: `value={item.type ? item.type.id : item.typeId}` — falls back to the string.
   */
  describe("regression: 3+ entries caused save failure (#5825)", () => {
    it("saves without an error banner when 3 rows are added and filled sequentially", async () => {
      const user = userEvent.setup();

      // Use a real form so handleSubmit/validation runs end-to-end.
      const TestForm = () => {
        const methods = useForm();
        return (
          <FormProvider {...methods}>
            <form
              data-testid="test-form"
              onSubmit={methods.handleSubmit(() => {})}
            >
              <UIFormNote {...props} />
              <button type="submit" data-testid="submit-btn">
                Save
              </button>
            </form>
          </FormProvider>
        );
      };
      render(<TestForm />);

      // --- Row 1 ---
      await user.click(screen.getByTestId("button-add-field-array-row"));
      // Row 1 is new (typeId="") → editable path.
      fireEvent.change(screen.getAllByTestId("note-input")[0], {
        target: { value: "First note text" },
      });
      fireEvent.change(screen.getAllByTestId("note-select")[0], {
        target: { value: "GENERAL_NOTE" },
      });

      // --- Row 2 ---
      // append() rebuilds fields; row 1 now has typeId="GENERAL_NOTE" in the snapshot
      // → switches to the hidden-input path. Row 2 is new → editable path.
      await user.click(screen.getByTestId("button-add-field-array-row"));
      // Only row 2's inputs are visible now (row 1 is in hidden-input path).
      fireEvent.change(screen.getAllByTestId("note-input")[0], {
        target: { value: "Second note text" },
      });
      fireEvent.change(screen.getAllByTestId("note-select")[0], {
        target: { value: "BIOGRAPHICAL_HISTORICAL_NOTE" },
      });

      // --- Row 3 ---
      // append() rebuilds again; rows 1 & 2 switch to hidden-input path.
      // Before the fix, these hidden inputs wrote value="" for form-entered rows,
      // silently erasing the selections and causing required validation to fail.
      await user.click(screen.getByTestId("button-add-field-array-row"));
      // Only row 3's inputs are visible now.
      fireEvent.change(screen.getAllByTestId("note-input")[0], {
        target: { value: "Third note text" },
      });
      fireEvent.change(screen.getAllByTestId("note-select")[0], {
        target: { value: "GENERAL_NOTE" },
      });

      // Submit and confirm no error banner appears.
      await user.click(screen.getByTestId("submit-btn"));

      await waitFor(() => {
        expect(
          screen.queryByText(/An issue has occured within/),
        ).not.toBeInTheDocument();
      });
    });
  });
});
