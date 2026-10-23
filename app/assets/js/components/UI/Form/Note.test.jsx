import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { FormProvider, useForm } from "react-hook-form";
import UIFormNote from "./Note";
import { notesSchemeMock } from "../../Work/controlledVocabulary.gql.mock";
import { renderWithReactHookForm } from "../../../services/testing-helpers";
import { prepNotes } from "../../../services/metadata";
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
    let reactHookFormMethods;

    beforeEach(() => {
      ({ reactHookFormMethods } = renderWithReactHookForm(
        <UIFormNote {...props} />,
        {
          defaultValues: {
            notes: [
              {
                id: "existing-note-id",
                note: "A sample general note",
                type: {
                  id: "GENERAL_NOTE",
                  label: "General note",
                  scheme: "NOTE_TYPE",
                },
              },
            ],
          },
          toPassBack: ["getValues"],
        },
      ));
    });

    it("renders component and an add button", () => {
      expect(screen.getByTestId("note-wrapper"));
      expect(screen.getByTestId("button-add-field-array-row"));
    });

    it("renders existing note values as editable form elements", () => {
      expect(screen.getAllByTestId("note-form-item")).toHaveLength(1);
      expect(screen.getByTestId("note-input")).toHaveValue(
        "A sample general note",
      );
      expect(screen.getByTestId("note-select")).toHaveValue("GENERAL_NOTE");
    });

    it("keeps an existing note's id when its text and type are edited", () => {
      fireEvent.change(screen.getByTestId("note-input"), {
        target: { value: "An edited note" },
      });
      fireEvent.change(screen.getByTestId("note-select"), {
        target: { value: "BIOGRAPHICAL_HISTORICAL_NOTE" },
      });

      expect(prepNotes(reactHookFormMethods.getValues().notes)).toEqual([
        {
          id: "existing-note-id",
          note: "An edited note",
          type: { scheme: "NOTE_TYPE", id: "BIOGRAPHICAL_HISTORICAL_NOTE" },
        },
      ]);
    });

    it("renders form elements when adding a new note value", () => {
      const addButton = screen.getByTestId("button-add-field-array-row");
      fireEvent.click(addButton);
      fireEvent.click(addButton);
      expect(screen.getAllByTestId("note-form-item")).toHaveLength(3);
      expect(screen.getAllByTestId("note-input")).toHaveLength(3);
      expect(screen.getAllByTestId("note-select")).toHaveLength(3);
    });

    it("renders delete button, removes note on click", () => {
      const addButton = screen.getByTestId("button-add-field-array-row");
      fireEvent.click(addButton);
      fireEvent.click(addButton);
      fireEvent.click(addButton);
      fireEvent.click(addButton);

      expect(screen.getAllByTestId("note-form-item")).toHaveLength(5);

      const removeButtons = screen.getAllByTestId("button-note-remove");
      fireEvent.click(removeButtons[4]);
      expect(screen.getAllByTestId("note-form-item")).toHaveLength(4);
    });
  });

  /**
   * Regression test for bug #5825: saving 3+ Note entries caused the error banner
   * "An issue has occured within Note."
   *
   * Root cause: `useFieldArray` rebuilds the `fields` snapshot from current form values
   * on every `append()`. A previously-filled row has `item.typeId` populated in the
   * new snapshot, which used to switch it from the editable path to a hidden-input
   * path whose `typeId` value collapsed to `""`, erasing the selection and causing
   * required validation to fail on submit.
   *
   * Every row is now editable (#5842), so each row keeps its own inputs and values
   * no matter how many rows are added after it.
   */
  describe("regression: 3+ entries caused save failure (#5825)", () => {
    it("saves without an error banner when 3 rows are added and filled sequentially", async () => {
      const user = userEvent.setup();
      let submittedNotes;

      // Use a real form so handleSubmit/validation runs end-to-end.
      const TestForm = () => {
        const methods = useForm();
        return (
          <FormProvider {...methods}>
            <form
              data-testid="test-form"
              onSubmit={methods.handleSubmit((data) => {
                submittedNotes = data.notes;
              })}
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
      fireEvent.change(screen.getAllByTestId("note-input")[0], {
        target: { value: "First note text" },
      });
      fireEvent.change(screen.getAllByTestId("note-select")[0], {
        target: { value: "GENERAL_NOTE" },
      });

      // --- Row 2 ---
      // append() rebuilds fields; row 1 stays editable alongside the new row 2.
      await user.click(screen.getByTestId("button-add-field-array-row"));
      fireEvent.change(screen.getAllByTestId("note-input")[1], {
        target: { value: "Second note text" },
      });
      fireEvent.change(screen.getAllByTestId("note-select")[1], {
        target: { value: "BIOGRAPHICAL_HISTORICAL_NOTE" },
      });

      // --- Row 3 ---
      await user.click(screen.getByTestId("button-add-field-array-row"));
      fireEvent.change(screen.getAllByTestId("note-input")[2], {
        target: { value: "Third note text" },
      });
      fireEvent.change(screen.getAllByTestId("note-select")[2], {
        target: { value: "GENERAL_NOTE" },
      });

      // Earlier rows keep their selections after later rows are added.
      expect(screen.getAllByTestId("note-select")[0]).toHaveValue(
        "GENERAL_NOTE",
      );
      expect(screen.getAllByTestId("note-select")[1]).toHaveValue(
        "BIOGRAPHICAL_HISTORICAL_NOTE",
      );

      // Submit and confirm no error banner appears and every row is submitted.
      await user.click(screen.getByTestId("submit-btn"));

      await waitFor(() => {
        expect(
          screen.queryByText(/An issue has occured within/),
        ).not.toBeInTheDocument();
        expect(prepNotes(submittedNotes)).toEqual([
          {
            note: "First note text",
            type: { scheme: "NOTE_TYPE", id: "GENERAL_NOTE" },
          },
          {
            note: "Second note text",
            type: { scheme: "NOTE_TYPE", id: "BIOGRAPHICAL_HISTORICAL_NOTE" },
          },
          {
            note: "Third note text",
            type: { scheme: "NOTE_TYPE", id: "GENERAL_NOTE" },
          },
        ]);
      });
    });
  });
});
