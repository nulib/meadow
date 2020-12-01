import React from "react";
import { render, screen, waitFor } from "@testing-library/react";
import WorkTabsStructureFileset from "./Fileset";
import { mockFileSets } from "@js/mock-data/filesets";
import {
  renderWithReactHookForm,
  withReactBeautifulDND,
  renderWithRouterApollo,
} from "@js/services/testing-helpers";
import { AuthProvider } from "@js/components/Auth/Auth";
import { getCurrentUserMock } from "@js/components/Auth/auth.gql.mock";

describe("Fileset component", () => {
  describe("when not editing", () => {
    function setUpTests(workImageFilesetId) {
      return renderWithRouterApollo(
        <AuthProvider>
          <WorkTabsStructureFileset
            fileSet={mockFileSets[0]}
            workImageFilesetId={workImageFilesetId}
          />
        </AuthProvider>,
        {
          mocks: [getCurrentUserMock],
        }
      );
    }
    it("renders the image preview, label and description", async () => {
      setUpTests();
      await waitFor(() => {
        expect(screen.getByTestId("fileset-item"));
        expect(screen.getByTestId("fileset-image"));
        expect(screen.getByText(mockFileSets[0].metadata.label));
        expect(screen.getByText(mockFileSets[0].metadata.description));
      });
    });

    it("renders an checked Work image toggle if current fileset is a representative Work image", async () => {
      setUpTests(mockFileSets[0].id);
      await waitFor(() => {
        const toggleEl = screen.getByTestId("work-image-selector");
        expect(toggleEl).toBeChecked();
      });
    });

    it("renders an unchecked Work image toggle if current fileset is NOT a representative Work image", async () => {
      setUpTests("ABC123");
      await waitFor(() => {
        const toggleEl = screen.getByTestId("work-image-selector");
        expect(toggleEl).not.toBeChecked();
      });
    });
  });

  describe("when editing", () => {
    beforeEach(() => {
      return renderWithReactHookForm(
        withReactBeautifulDND(WorkTabsStructureFileset, {
          fileSet: mockFileSets[0],
          index: 0,
          isEditing: true,
        })
      );
    });

    it("renders the component", async () => {
      expect(screen.findByTestId("fileset-item"));
    });

    it("renders label and description form elements", () => {
      expect(screen.getByTestId("fileset-image"));
      expect(screen.getByTestId("input-label"));
      expect(screen.getByTestId("textarea-metadata-description"));
    });

    it("does not render the toggle representative Work checkbox", () => {
      expect(screen.queryByTestId("work-image-selector")).toBeNull();
    });
  });
});
