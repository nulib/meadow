import React from "react";
import { render, screen, waitFor } from "@testing-library/react";
import WorkFilesetListItemImage from "./ListItem";
import { mockFileSets } from "@js/mock-data/filesets";
import {
  renderWithReactHookForm,
  withReactBeautifulDND,
} from "@js/services/testing-helpers";
import { mockUser } from "@js/components/Auth/auth.gql.mock";
import useIsAuthorized from "@js/hooks/useIsAuthorized";
import { WorkProvider } from "@js/context/work-context";

jest.mock("@js/hooks/useIsAuthorized");
useIsAuthorized.mockReturnValue({
  user: mockUser,
  isAuthorized: () => true,
});

describe("Fileset component", () => {
  describe("when not editing", () => {
    function setUpTests(workImageFilesetId) {
      return render(
        <WorkProvider>
          <WorkFilesetListItemImage
            fileSet={mockFileSets[0]}
            workImageFilesetId={workImageFilesetId}
          />
        </WorkProvider>
      );
    }
    it("renders the image preview, label and description", async () => {
      setUpTests();
      await waitFor(() => {
        expect(screen.getByTestId("fileset-item"));
        expect(screen.getByTestId("fileset-image"));
        expect(screen.getByText(mockFileSets[0].coreMetadata.label));
        expect(screen.getByText(mockFileSets[0].coreMetadata.description));
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
      const Wrapped = withReactBeautifulDND(WorkFilesetListItemImage, {
        fileSet: mockFileSets[0],
        index: 0,
        isEditing: true,
      });

      return renderWithReactHookForm(<WorkProvider>{Wrapped}</WorkProvider>);
    });

    it("renders the component", async () => {
      expect(await screen.findByTestId("fileset-item"));
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
