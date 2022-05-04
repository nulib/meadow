import React from "react";
import { screen, fireEvent, waitFor } from "@testing-library/react";
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
      const {
        findByText,
        getByTestId,
        reactHookFormMethods,
      } = renderWithReactHookForm(<UIFormRelatedURL {...props} />, {
        toPassBack: ["setError"],
      });

      userEvent.click(getByTestId("button-add-field-array-row"));

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
        1
      );
      expect(
        screen.getByText(
          "http://www.northwestern.edu, Hathi Trust Digital Library"
        )
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
});
