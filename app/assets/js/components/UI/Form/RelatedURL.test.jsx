import React from "react";
import { render, screen, fireEvent, waitFor } from "@testing-library/react";
import { FormProvider, useForm } from "react-hook-form";
import UIFormRelatedURL from "./RelatedURL";
import { relatedUrlSchemeMock } from "../../Work/controlledVocabulary.gql.mock";
import { renderWithReactHookForm } from "../../../services/testing-helpers";
import userEvent from "@testing-library/user-event";

const props = {
  codeLists: relatedUrlSchemeMock,
  name: "relatedUrl",
  label: "Related URL",
};

describe("Related Url controlled metadata form component", () => {
  describe("error handling", () => {
    // Here's an example of how to test that a React Hook Form element
    // displays error messages, without submitting the form.

    // The use case is, if you'd want to test a component independently which contains
    // a React Hook Form element you'd like to test
    it("renders appropriate error messages with invalid url or select values", async () => {
      const user = userEvent.setup();
      const { findByText, getByTestId, reactHookFormMethods } =
        renderWithReactHookForm(<UIFormRelatedURL {...props} />, {
          toPassBack: ["setError"],
        });

      await user.click(getByTestId("button-add-field-array-row"));

      await waitFor(() => {
        reactHookFormMethods.setError("relatedUrl[0].url", {
          type: "validate",
          message: "Please enter a valid url",
        });
      });
      expect(await findByText("Please enter a valid url"));
    });
  });

  describe("standard component behavior", () => {
    beforeEach(() => {
      renderWithReactHookForm(<UIFormRelatedURL {...props} />, {
        defaultValues: {
          relatedUrl: [
            {
              url: "http://www.northwestern.edu",
              label: {
                id: "HATHI_TRUST_DIGITAL_LIBRARY",
                label: "Hathi Trust Digital Library",
                scheme: "RELATED_URL",
              },
            },
          ],
        },
      });
    });

    it("renders component and an add button", () => {
      expect(screen.getByTestId("related-url-wrapper"));
      expect(screen.getByTestId("button-add-field-array-row"));
    });

    it("renders existing related url values", () => {
      expect(screen.getAllByTestId("related-url-existing-value")).toHaveLength(
        1,
      );
      expect(
        screen.getByText(
          "http://www.northwestern.edu, Hathi Trust Digital Library",
        ),
      );
    });

    it("renders form elements when adding a new related url value", () => {
      const addButton = screen.getByTestId("button-add-field-array-row");
      fireEvent.click(addButton);
      fireEvent.click(addButton);
      expect(screen.getAllByTestId("related-url-form-item")).toHaveLength(2);
      expect(screen.getAllByTestId("related-url-url-input")).toHaveLength(2);
      expect(screen.getAllByTestId("related-url-select")).toHaveLength(2);
    });

    it("renders delete button, removes related URL on click", () => {
      const addButton = screen.getByTestId("button-add-field-array-row");
      fireEvent.click(addButton);
      fireEvent.click(addButton);
      fireEvent.click(addButton);
      fireEvent.click(addButton);

      expect(screen.getAllByTestId("related-url-form-item")).toHaveLength(4);

      const removeButtons = screen.getAllByTestId("button-related-url-remove");
      fireEvent.click(removeButtons[3]);
      expect(screen.getAllByTestId("related-url-form-item")).toHaveLength(3);
    });
  });

  /**
   * Regression test for bug #5825: saving 3+ Related URL entries caused the error banner
   * "An issue has occured within Related URL."
   *
   * Root cause: `useFieldArray` rebuilds the `fields` snapshot from current form values
   * on every `append()`. A previously-filled row has `item.labelId` populated in the
   * new snapshot, which switches it from the editable path to the hidden-input path.
   * The hidden `labelId` input was written as `value={item.label ? item.label.id : ""}`.
   * Because form-entered rows have only a `labelId` string (no `label` object), the
   * value collapsed to `""`, erasing the selection and causing required validation to
   * fail on submit.
   *
   * Fix: `value={item.label ? item.label.id : item.labelId}` — falls back to the string.
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
              <UIFormRelatedURL {...props} />
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
      // After append, fields snapshot is rebuilt; row 1 is new (labelId=""), so it
      // renders the editable form path.
      fireEvent.change(screen.getAllByTestId("related-url-url-input")[0], {
        target: { value: "http://example1.com" },
      });
      fireEvent.change(screen.getAllByTestId("related-url-select")[0], {
        target: { value: "FINDING_AID" },
      });

      // --- Row 2 ---
      // append() rebuilds fields; row 1 now has labelId="FINDING_AID" in the snapshot
      // → switches to the hidden-input path. Row 2 is new → editable path.
      await user.click(screen.getByTestId("button-add-field-array-row"));
      // Only row 2's inputs are visible now (row 1 is in hidden-input path).
      fireEvent.change(screen.getAllByTestId("related-url-url-input")[0], {
        target: { value: "http://example2.com" },
      });
      fireEvent.change(screen.getAllByTestId("related-url-select")[0], {
        target: { value: "HATHI_TRUST_DIGITAL_LIBRARY" },
      });

      // --- Row 3 ---
      // append() rebuilds again; rows 1 & 2 switch to hidden-input path.
      // Before the fix, these hidden inputs wrote value="" for form-entered rows,
      // silently erasing the selections and causing required validation to fail.
      await user.click(screen.getByTestId("button-add-field-array-row"));
      // Only row 3's inputs are visible now.
      fireEvent.change(screen.getAllByTestId("related-url-url-input")[0], {
        target: { value: "http://example3.com" },
      });
      fireEvent.change(screen.getAllByTestId("related-url-select")[0], {
        target: { value: "RELATED_INFORMATION" },
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
